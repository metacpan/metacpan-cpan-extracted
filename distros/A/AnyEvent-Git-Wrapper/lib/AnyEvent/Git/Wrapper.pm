package AnyEvent::Git::Wrapper;

use strict;
use warnings;
use Carp qw( croak );
use base qw( Git::Wrapper );
use File::pushd;
use AnyEvent;
use AnyEvent::Open3::Simple;
use Git::Wrapper::Exception;
use Git::Wrapper::Statuses;
use Git::Wrapper::Log;
use Scalar::Util qw( blessed );

# ABSTRACT: Wrap git command-line interface without blocking
our $VERSION = '0.10'; # VERSION


sub new
{
  my $class = shift;
  
  my $args;
  if(scalar @_ == 1)
  {
    my $arg = shift;
    if(ref $arg eq 'HASH') { $args = $arg }
    elsif(blessed $arg)    { $args = { dir => "$arg" } }
    elsif(! ref $arg)      { $args = { dir => $arg } }
    else { die "Singlearg must be hashref, scalar or stringify-able object" }
  }
  else
  {
    my($dir, %opts) = @_;
    $dir = "$dir" if blessed $dir;
    $args = { dir => $dir, %opts };
  }
  my $cache_version = delete $args->{cache_version};
  my $self = $class->SUPER::new($args);
  $self->{ae_cache_version} = $cache_version;
  $self;
}


sub RUN
{
  my($self) = shift;
  my $cv;
  if(ref($_[-1]) eq 'CODE')
  {
    $cv = AE::cv;
    $cv->cb(pop);
  }
  elsif(eval { $_[-1]->isa('AnyEvent::CondVar') })
  {
    $cv = pop;
  }
  else
  {
    return $self->SUPER::RUN(@_);
  }

  my $cmd = shift;

  my $customize;
  $customize = pop if ref($_[-1]) eq 'CODE';
  
  my ($parts, $in) = Git::Wrapper::_parse_args( $cmd, @_ );
  my @out;
  my @err;

  my $ipc = AnyEvent::Open3::Simple->new(
    on_stdout => \@out,
    on_stderr => \@err,
    on_error  => sub {
      #my($error) = @_;
      $cv->croak(
        Git::Wrapper::Exception->new(
          output => \@out,
          error  => \@err,
          status => -1,
        )
      );
    },
    on_exit   => sub {
      my(undef, $exit, $signal) = @_;
      
      # borrowed from superclass, see comment there
      my $stupid_status = $cmd eq 'status' && @out && ! @err;
      
      if(($exit || $signal) && ! $stupid_status)
      {
        $cv->croak(
          Git::Wrapper::Exception->new(
            output => \@out,
            error  => \@err,
            status => $exit,
          )
        );
      }
      else
      {
        $self->{err} = \@err;
        $self->{out} = \@out;
        $cv->send(\@out, \@err);
      }
    },
    $customize ? $customize->() : ()
  );
  
  do {
    my $d = pushd $self->dir unless $cmd eq 'clone';
    
    my @cmd = ( $self->git, @$parts );
    
    local $ENV{GIT_EDITOR} = $^O eq 'MSWin32' ? 'cmd /c "exit 2"' : '';
    $ipc->run(@cmd, \$in);
    
    undef $d;
  };
  
  $cv;
}


my %STATUS_CONFLICTS = map { $_ => 1 } qw<DD AU UD UA DU AA UU>;

sub status
{
  my($self) = shift;
  my $cv;
  if(ref($_[-1]) eq 'CODE')
  {
    $cv = AE::cv;
    $cv->cb(pop);
  }
  elsif(eval { $_[-1]->isa('AnyEvent::CondVar') })
  {
    $cv = pop;
  }
  else
  {
    return $self->SUPER::status(@_);
  }

  my $opt = ref $_[0] eq 'HASH' ? shift : {};
  $opt->{porcelain} = 1;

  $self->RUN('status' => $opt, @_, sub {
    my $out = shift->recv;
    my $stat = Git::Wrapper::Statuses->new;

    for(@$out)
    {
      my ($x, $y, $from, $to) = $_ =~ /\A(.)(.) (.*?)(?: -> (.*))?\z/;
      if ($STATUS_CONFLICTS{"$x$y"})
      {
        $stat->add('conflict', "$x$y", $from, $to);
      }
      elsif ($x eq '?' && $y eq '?')
      {
        $stat->add('unknown', '?', $from, $to);
      }
      else
      {
        $stat->add('changed', $y, $from, $to)
          if $y ne ' ';
        $stat->add('indexed', $x, $from, $to)
          if $x ne ' ';
      }
    }
    
    $cv->send($stat);
  });
  
  $cv;
}


sub log
{
  my($self) = shift;
  my $cv;
  if(ref($_[-1]) eq 'CODE')
  {
    $cv = AE::cv;
    $cv->cb(pop);
  }
  elsif(eval { $_[-1]->isa('AnyEvent::CondVar') })
  {
    $cv = pop;
  }
  else
  {
    return $self->SUPER::log(@_);
  }
  
  my $cb;
  if(ref($_[-1]) eq 'CODE')
  {
    $cb = pop;
  }

  my $opt = ref $_[0] eq 'HASH' ? shift : {};
  $opt->{no_color}         = 1;
  $opt->{pretty}           = 'medium';
  $opt->{no_abbrev_commit} = 1
    if $self->supports_log_no_abbrev_commit;
  
  my $raw = defined $opt->{raw} && $opt->{raw};

  my $out = [];
  my @logs;
  
  my $process_commit = sub {
    if(my $line = shift @$out)
    {
      unless($line =~ /^commit (\S+)/)
      {
        $cv->croak("unhandled: $line");
        return;
      }
      
      my $current = Git::Wrapper::Log->new($1);
      
      $line = shift @$out;  # next line
      
      while($line =~ /^(\S+):\s+(.+)$/)
      {
        $current->attr->{lc $1} = $2;
        $line = shift @$out; # next line
      }
      
      if($line)
      {
        $cv->croak("no blank line separating head from message");
        return;
      }
      
      my($initial_indent) = $out->[0] =~ /^(\s*)/ if @$out;
      
      my $message = '';
      while(@$out and $out->[0] !~ /^commit (\S+)/ and length($line = shift @$out))
      {
        $line =~ s/^$initial_indent//; # strip just the indenting added by git
        $message .= "$line\n";
      }
      
      $current->message($message);
      
      if($raw)
      {
        my @modifications;
        while(@$out and $out->[0] =~ m/^\:(\d{6}) (\d{6}) (\w{7})\.\.\. (\w{7})\.\.\. (\w{1})\t(.*)$/)
        {
          push @modifications, Git::Wrapper::File::RawModification->new($6,$5,$1,$2,$3,$4);
          shift @$out;
        }
        $current->modifications(@modifications) if @modifications;
      }
      
      if($cb)
      { $cb->($current) }
      else
      { push @logs, $current }
    }
  };
  
  my $on_stdout = sub {
    my $line = pop;
    push @$out, $line;
    $process_commit->() if $line =~ /^commit (\S+)/ && @$out > 1;
  };
  
  $self->RUN(log => $opt, @_, sub { on_stdout => $on_stdout }, sub {
    eval { shift->recv };
    $cv->croak($@) if $@;
    
    while($out->[0]) {
      $process_commit->();
    }
    
    $cv->send(@logs);
  });
  
  $cv;
}


sub version
{
  my($self) = @_;
  my $cv;
  if(ref($_[-1]) eq 'CODE')
  {
    $cv = AE::cv;
    $cv->cb(pop);
  }
  elsif(eval { $_[-1]->isa('AnyEvent::CondVar') })
  {
    $cv = pop;
  }
  else
  {
    if($self->{ae_cache_version} && $self->{ae_version})
    { return $self->{ae_version} }
    $self->{ae_version} = $self->SUPER::version(@_);
    return $self->{ae_version};
  }
  
  if($self->{ae_cache_version} && $self->{ae_version})
  {
    $cv->send($self->{ae_version});
  }
  else
  {
    $self->RUN('version', sub {
      my $out = eval { shift->recv };
      if($@)
      {
        $cv->croak($@);
      }
      else
      {
        $self->{ae_version} = $out->[0];
        $self->{ae_version} =~ s/^git version //;
        $cv->send($self->{ae_version});
      }
    });
  }
  
  $cv;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Git::Wrapper - Wrap git command-line interface without blocking

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use AnyEvent::Git::Wrapper;
 
 # add all files and make a commit...
 my $git = AnyEvent::Git::Wrapper->new($dir);
 $git->add('.', sub {
   $git->commit({ message => 'initial commit' }, sub {
     say "made initial commit";
   });
 });

=head1 DESCRIPTION

B<DEPRECATED>: May go away at some point.

This module provides a non-blocking and blocking API for git in the style and using the data 
structures of L<Git::Wrapper>.  For methods that execute the git binary, if the last argument is 
either a code reference or an L<AnyEvent> condition variable, then the command is run in 
non-blocking mode and the result will be sent to the condition variable when the command completes.  
For most commands (all those but C<status>, C<log> and C<version>), the result comes back via the 
C<recv> method on the condition variable as two array references, one representing the standard out 
and the other being the standard error.  Because C<recv> will return just the first value if 
called in scalar context, you can retrieve just the output by calling C<recv> in scalar context.

 # ignoring stderr
 $git->branch(sub {
   my $out = shift->recv;
   foreach my $line (@$out)
   {
     ...
   }
 });
 
 # same thing, but saving stderr
 $git->branch(sub {
   my($out, $err) = shit->recv;
   foreach my $line(@$out)
   {
     ...
   }
 });

Like L<Git::Wrapper>, you can also access the standard output and error via the C<OUT> and C<ERR>, but care
needs to be taken that you either save the values immediately if other commands are being run at the same
time.

 $git->branch(sub {
   my $out = $git->OUT;
   foreach my $line (@$out)
   {
     ...
   }
 });

If git signals an error condition the condition variable will croak, so you will need to wrap your call
to C<recv> in an eval if you want to handle it:

 $git->branch(sub {
   my $out = eval { shift->recv };
   if($@)
   {
     warn "error: $@";
     return;
   }
   ...
 });

=head1 CONSTRUCTOR

=head2 new

 my $git = AnyEvent::Git::Wrapper->new('.');

The constructor takes all the same arguments as L<Git::Wrapper>, in addition to 
these options:

=over 4

=item cache_version

The first time the C<version> command is executed the value will be cached so
that C<git version> doesn't need to be executed again (via the C<version> method
only, this doesn't include if you call C<git version> using the C<RUN> method).
The default is false (no cache).

=back

=head1 METHODS

=head2 RUN

Run the given git command with the given arguments (see L<Git::Wrapper>).  If the last argument is
either a code reference or a condition variable then the command will be run in non-blocking mode
and a condition variable will be returned immediately.  Otherwise the command will be run in 
normal blocking mode, exactly like L<Git::Wrapper>.

If you provide this method with a condition variable it will use that to send the results of the
command.  If you provide a code reference it will create its own condition variable and attach
the code reference  to its callback.  Either way it will return the condition variable.

 # blocking
 $git->RUN($command, @arguments);
 
 # non-blocking callback
 $git->RUN($command, @arguments, sub {
   # $out is a list ref of stdout
   # $err is a list ref of stderr
   my($out, $err) = shift->recv;
 });
 
 # non-blocking cv
 my $cv = $git->RUN($command, @arguments, AE::cv);
 $cv->cb(sub {
   my($out, $err) = shift->recv;
 });

=head2 status

If called in blocking mode (without a code reference or condition variable as the last argument),
this method works exactly as with L<Git::Wrapper>.  If run in non blocking mode, the L<Git::Wrapper::Statuses>
object will be passed back via the C<recv> method on the condition variable.

 # blocking
 # $statuses isa Git::Wrapper::Statuses
 my $statuses = $git->status;

 # with a code ref
 $git->status(sub {
   # $statuses isa Git::Wrapper::Statuses 
   my $statuses = shift->recv;
   ...
 });
 
 # with a condition variable
 my $cv = $git->status(AE::cv)
 $cv->cb(sub {
   # $statuses isa Git::Wrapper::Statuses
   my $statuses = shift->recv;
   ...   
 });

=head2 log

This method has three different calling modes, blocking, non-blocking as commits arrive and non-blocking
processed at completion.

=over 4

=item blocking mode

 $git->log(@args);

Works exactly like L<Git::Wrapper>

=item as commits arrive

 # without a condition variable
 $git->log(@args, sub {
   # $commit isa Git::Wrapper::Log
   my $commit;
   ...
 }, sub {
   # called when complete
   ...
 });
 
 # with a condition variable
 my $cv = AnyEvent->condvar;
 $git->log(@args, sub {
   # $commit isa Git::Wrapper::Log
   my $commit;
   ...
  }, $cv); 
  $cv->cb(
    # called when complete
    ...
  });

With this calling convention the first callback is called for each commit,as it arrives from git.
The second callback, or condition variable is fired after the command has completed and all commits
have been processed.

=item at completion

 # with a callback
 $git->log(@args, sub {
   # @log isa array of Git::Wrapper::Log
   my @log = shift->recv;
 });
 
 # with a condition variable
 my $cv = AnyEvent->condvar;
 $git->log(@args, $cv);
 $cv->cb(
   # @log isa array of Git::Wrapper::Log
   my @log = shift->recv;
 });

With this calling convention the commits are processed by C<AnyEvent::Git::Wrapper> as they come
in but they are gathered up and returned to the callback or condition variable at completion.

=back

In either non-blocking mode the condition variable for the completion of the command is returned,
so you can pass in C<AE::cv> (or C<AnyEvent->condvar>) as the last argument and retrieve it like
this:

 my $cv = $git->log(@args, AE::cv);

=head2 version

In blocking mode works just like L<Git::Wrapper>.  With a code reference or condition variable it runs in
blocking mode and the version is returned via the condition variable.

 # blocking
 my $version = $git->version;

 # cod ref
 $git->version(sub {
   my $version = shift->recv;
   ...
 });
 
 # cond var
 my $cv = $git->version(AE::cv);
 $cv->cb(sub {
   my $version = shift->recv;
   ...
 });

=head1 CAVEATS

L<AnyEvent> (a dependency of this module) is no longer supported on Perl 5.22
or later by its author.  It may work there, or it may not.

This module necessarily uses the private _parse_args method from L<Git::Wrapper>, so changes
to that module may break this one.  Also, some functionality is duplicated because there
isn't a good way to hook into just parts of the commands that this module overrides.  The
author has made a good faith attempt to reduce the amount of duplication.

You probably don't want to be doing multiple git write operations at once (strange things are
likely to happen), but you may want to do multiple git read operations or mix git and other
L<AnyEvent> operations at once.

=head1 BUNDLED FILES

In addition to inheriting from L<Git::Wrapper>, this distribution includes tests that come
with L<Git::Wrapper>, and are covered by this copyright:

This software is copyright (c) 2008 by Hand Dieter Pearcey.

This is free software you can redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself.

Thanks also to Chris Prather and John SJ Anderson for their work on L<Git::Wrapper>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
