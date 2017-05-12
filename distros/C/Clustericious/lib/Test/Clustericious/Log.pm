package Test::Clustericious::Log;

use strict;
use warnings;
use 5.010001;
use if !$INC{'File/HomeDir/Test.pm'}, 'File::HomeDir::Test';
use File::HomeDir;
use Test::Builder::Module;
use Clustericious::Log ();
use Carp qw( carp );
use base qw( Test::Builder::Module Exporter );
use YAML::XS qw( Dump );

our @EXPORT = qw( log_events log_context log_like log_unlike );
our %EXPORT_TAGS = ( all => \@EXPORT );

# ABSTRACT: Clustericious logging in tests.
our $VERSION = '1.24'; # VERSION


sub log_events
{
  @{ Test::Clustericious::Log::Appender->new->{list} };
}


sub log_context (&)
{
  my($code) = @_;
  my $old = Test::Clustericious::Log::Appender->new->{list};
  local Test::Clustericious::Log::Appender->new->{list} = [];
  
  my @ret;
  my $ret;
  
  if(wantarray)
  {
    @ret = $code->()
  }
  elsif(defined wantarray)
  {
    $ret = $code->();
  }
  else
  {
    $code->();
  }
  
  push @$old, @{ Test::Clustericious::Log::Appender->new->{list} };

  wantarray ? @ret : $ret;
}


sub _event_match
{
  my($pattern, $event) = @_;

  my $match = 1;
  foreach my $key (keys %$pattern)
  {
    my $pattern = $pattern->{$key};
    if(ref $pattern eq 'Regexp')
    {
      $match = 0 unless $event->{$key} =~ $pattern;
    }
    else
    {
      $match = 0 unless $event->{$key} eq $pattern;
    }
  }
  
  $match;
}


sub log_like ($;$)
{
  my($pattern, $message) = @_;
  
  $message ||= "log matches pattern";
  $pattern = { message => $pattern } unless ref $pattern eq 'HASH';
  
  my $tb = __PACKAGE__->builder;
  my $ok = 0;
  
  foreach my $event (log_events)
  {
    if(_event_match($pattern, $event))
    {
      $ok = 1;
      last;
    }
  }
  
  $tb->ok($ok, $message);

  unless($ok)
  {
    
    $tb->diag("None of the events matched the pattern:");
    $tb->diag(
      Dump({
        events => [log_events],
        pattern => $pattern,
      })
    );
  }
  
  $ok;
}

sub log_unlike ($;$)
{
  my($pattern, $message) = @_;
  
  $message ||= "log does not match pattern";
  $pattern = { message => $pattern } unless ref $pattern eq 'HASH';

  my $tb = __PACKAGE__->builder;
  my @match;
  
  foreach my $event (log_events)
  {
    if(_event_match($pattern, $event))
    {
      push @match, $event;
    }
  }
  
  $tb->ok(!scalar @match, $message);
  
  foreach my $match (@match)
  {
    $tb->diag("This event matched, but should not have:");
    $tb->diag(
      Dump({
        event => $match,
        pattern => $pattern,
      })
    );
  }
  
  !scalar @match;
}

sub import
{
  my($class) = shift;

  # first caller wins
  state $counter = 0;
  if($counter++)
  {
    my $caller = caller;
    unless($caller eq 'Test::Clustericious::Cluster')
    {
      my $tb = Test::Builder::Module->builder;
      $tb->diag("you must use Test::Clustericious::Log before Test::Clustericious::Cluster");
    }
    return;
  }

  my $home = File::HomeDir->my_home;
  mkdir "$home/etc" unless -d "$home/etc";
  mkdir "$home/log" unless -d "$home/log";

  my $config = {
    FileX => [ 'TRACE', 'FATAL'  ],
    NoteX => [ 'DEBUG', 'WARN'  ],
    DiagX => [ 'ERROR', 'FATAL' ],
    TestX => [ 'TRACE', 'FATAL' ],
  };

  my $args;
  if(@_ == 1)
  {
    die;
  }
  else
  {
    $args = { @_ };
  }
  
  foreach my $type (qw( file note diag ))
  {
    if(defined $args->{$type})
    {
      my $name = ucfirst($type) . 'X';
      if($args->{$type} =~ /^(TRACE|DEBUG|INFO|WARN|ERROR|FATAL)(..(TRACE|DEBUG|INFO|WARN|ERROR|FATAL)|)$/)
      {
        my($min,$max) = ($1,$3);
        $max = $min unless $max;
        $config->{$name} = [ $min, $max ];
      }
      elsif($args->{$type} eq 'NONE')
      {
        delete $config->{$name};
      }
      elsif($args->{$type} eq 'ALL')
      {
        $config->{$name} = [ 'TRACE', 'FATAL' ];
      }
      else
      {
        carp "illegal log range: " . $args->{$type};
      }
    }
  }
  
  open my $fh, '>', "$home/etc/log4perl.conf";

  print $fh "log4perl.rootLogger=TRACE, ";
  print $fh "FileX, " if defined $config->{FileX};
  print $fh "NoteX, " if defined $config->{NoteX};
  print $fh "DiagX, " if defined $config->{DiagX};
  print $fh "TestX, " if defined $config->{TestX};
  print $fh "\n";
  
  while(my($appender, $levels) = each %$config)
  {
    my($min, $max) = @{ $levels };
    print $fh "log4perl.filter.Match$appender = Log::Log4perl::Filter::LevelRange\n";
    print $fh "log4perl.filter.Match$appender.LevelMin = $min\n";
    print $fh "log4perl.filter.Match$appender.LevelMax = $max\n";
    print $fh "log4perl.filter.Match$appender.AcceptOnMatch = true\n";
  }
  
  print $fh "log4perl.appender.FileX=Log::Log4perl::Appender::File\n";
  print $fh "log4perl.appender.FileX.filename=$home/log/test.log\n";
  print $fh "log4perl.appender.FileX.mode=append\n";
  print $fh "log4perl.appender.FileX.layout=PatternLayout\n";
  print $fh "log4perl.appender.FileX.layout.ConversionPattern=[%P %p{1} %rms] %F:%L %m%n\n";
  print $fh "log4perl.appender.FileX.Filter=MatchFileX\n";

  print $fh "log4perl.appender.TestX=Test::Clustericious::Log::Appender\n";
  print $fh "log4perl.appender.TestX.layout=PatternLayout\n";
  print $fh "log4perl.appender.TestX.layout.ConversionPattern=%m\n";
  print $fh "log4perl.appender.TestX.Filter=MatchTestX\n";
  
  print $fh "log4perl.appender.NoteX=Log::Log4perl::Appender::TAP\n";
  print $fh "log4perl.appender.NoteX.method=note\n";
  print $fh "log4perl.appender.NoteX.layout=PatternLayout\n";
  print $fh "log4perl.appender.NoteX.layout.ConversionPattern=%5p %m%n\n";
  print $fh "log4perl.appender.NoteX.Filter=MatchNoteX\n";

  print $fh "log4perl.appender.DiagX=Log::Log4perl::Appender::TAP\n";
  print $fh "log4perl.appender.DiagX.method=diag\n";
  print $fh "log4perl.appender.DiagX.layout=PatternLayout\n";
  print $fh "log4perl.appender.DiagX.layout.ConversionPattern=%5p %m%n\n";
  print $fh "log4perl.appender.DiagX.Filter=MatchDiagX\n";
  
  close $fh;  

  if($args->{import})
  {
    @_ = ($class, ref $args->{import} ? @{ $args->{import} } : ($args->{import}));
    goto &Exporter::import;
  }
}

END
{
  my $tb = Test::Builder::Module->builder;
  my $home = File::HomeDir->my_home;
  
  unless($tb->is_passing)
  {
    if($ENV{CLUSTERICIOUS_LOG_SPEW_OFF})
    {
      $tb->diag("not spewing the entire log (unset CLUSTERICIOUS_LOG_SPEW_OFF to turn back on)");
    }
    elsif(-r "$home/log/test.log")
    {
      $tb->diag("detailed log");
      open my $fh, '<', "$home/log/test.log";
      $tb->diag(<$fh>);
      close $fh;
    }
    else
    {
      $tb->diag("no detailed log");
    }
  }
}

package Test::Clustericious::Log::Appender;

use Storable ();
use Carp ();
our @ISA = qw( Log::Log4perl::Appender );

sub new
{
  my($class) = @_;
  
  Carp::croak "not subclassable"
    unless $class eq __PACKAGE__;
  
  state $self;
  
  unless(defined $self)
  {
    $self = bless { list => [] }, __PACKAGE__;
  }
  
  $self;
}

sub log
{
  my($self, %args) = @_;
  
  push @{ $self->{list} }, Storable::dclone(\%args);

  ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Clustericious::Log - Clustericious logging in tests.

=head1 VERSION

version 1.24

=head1 SYNOPSIS

 use Test::Clustericious::Log;
 use Test::More;
 use MyClustericiousApp;
 
 my $app = MyClustericiousApp->new;
 
 ok $test, 'test description';
 ...

=head1 DESCRIPTION

This module redirects the L<Log::Log4perl> output from a 
L<Clustericious> application to TAP using L<Test::Builder>.  By default 
it sends DEBUG to WARN messages to C<note> and ERROR to FATAL to 
C<diag>, so you should only see error and fatal messages if you run 
C<prove -l> on your test but will see debug and warn messages if you run 
C<prove -lv>.

If the test fails for any reason, the entire log file will be printed 
out using C<diag> when the test is complete.  This is useful for CPAN 
testers reports.

In order to control the verbosity of the various logs, you can specify a 
range of level for each of C<note>, C<diag> and C<file> (file being the 
log file that is spewed IF the test file as a whole fails).

 use Test::Clustericious::Log note => 'TRACE..ERROR', diag => 'FATAL';

Note that only one set of ranges can be specified for the entire 
process, so the first module that uses L<Test::Clustericious::Log> gets 
to specify the ranges.  The defaults are somewhat reasonable: the log 
file gets everything (C<TRACE..FATAL>), C<note> gets most stuff 
(C<DEBUG..WARN>) and C<diag> gets errors, including fatal errors 
(C<ERROR..FATAL>).

This module also provides some functions for testing the log events of a 
Clustericious application.

=head1 FUNCTIONS

In order to import functions from L<Test::Clustericious::Log>, you must 
pass an "import" to your use line.  The value is a list in the usual 
L<Exporter> format.

 use Test::Clustericious::Log import => ':all';
 use Test::Clustericious::Log import => [ 'log_events', 'log_like' ];

=head2 log_events

 my @events = log_events;

Returns the set of log events for the current log scope as a list of 
hash references.

=head2 log_context

 log_context {
   # code
 }

Creates a log context for other L<Test::Clustericious::Log> functions to 
operate on.

=head2 log_like

 log_like \%pattern, $message;
 log_like $pattern, $message;

Test that at least one log event in the given context matches the 
pattern defined by C<\%pattern> or C<$patter>.  If you provide a hash 
reference, then each key in the event much match the pattern values.  
The pattern values may be either strings or regular expressions.  If you 
use the scalar form (second) then the pattern (either a regular 
expression or string) must match the events message element.

Note that only ONE message in the current context has to match because 
usually you want to make sure that particular message shows up in the 
log, but you don't care if other messages get added at a later time, and 
you do not want that common type of change to cause tests to break.

Examples:

 ERROR "Some error";
 INFO "Exact message";
 NOTE "some notice";
 
 log_like 'Exact message", 'this should pass';
 log_like 'xact messag',   'but this would fail';
 log_like qr{xact messg},  'but this regex would pass';
 
 log_like { message => 'Exact message', log4p_level => 'INFO' }, 'also passes';
 log_like { message => 'Exact message', log4p_level => 'ERROR' }, 'Fails, level does not match';

=head2 log_unlike

 log_unlike \%pattern, $message;
 log_unlike $pattern, $message;

C<log_unlike> works like C<log_like>, except NONE of the events in the 
current log context must match in order for the test to pass.

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
