package Apache::Filter;
 
use strict;
use Symbol;
use Apache::Constants(':common');
use vars qw($VERSION @ISA);
$VERSION = '1.024';
@ISA = qw(Apache);

# $r->pnotes('FilterInfo') contains a hashref ($info) which works like member data of $r.
# 
# $info->{'fh_in'} is a Apache::Filter filehandle containing the output of the previous filter
# $info->{'is_dir'} is true if $r->filename() is a directory
# $info->{'count'} is incremented every time $r->filter_input() is called, so it contains
#                the position of the current filter in the handler stack.
# $info->{'determ'}{$i} contains a true value if handler number $i has declared that it
#                     is deterministic (see docs).

sub Apache::filter_register {
  my $r = shift;
  
  # Apache->request($r) doesn't seem to work, so we cache the derived $r in
  # pnotes().  Unfortunately this means that Apache->request in other
  # code will return the regular $r, not the Apache::Filter object.
  
  $r = Apache->request->pnotes('filterobject') if Apache->request->pnotes('filterobject');
  unless ($r->isa(__PACKAGE__)) {
    if (ref($r) ne 'Apache') {
      # $r could be an Apache::Request object, or a different subclass
      # of Apache.  Make an on-the-fly subclass of whatever it is.
      @ISA = (ref $r);
      $r->register_cleanup(sub {@ISA = qw(Apache)});
    }
    Apache->request($r = bless {_r => $r});
  }
  Apache->request->pnotes(filterobject => $r);
  $r->{'count'}++;
  #warn "************ registering @{[$r->filename]}: count=$r->{count}\n";

  # Don't touch anything if there is only one filter in the chain
  return $r if $r->is_first_filter and $r->is_last_filter;

  if ($r->is_first_filter) {
    $r->{browser} = ref tied(*STDOUT);
  } else {
    $r->rotate_filters;
  }
  
  if ($r->is_last_filter) {
    #warn "Tie()ing STDOUT to '$r->{browser}' for finish";
    untie *STDOUT;
    tie *STDOUT, $r->{browser} if $r->{browser}; # sfio doesn't tie STDOUT
  } else {
    #warn "Tie()ing STDOUT to ", ref($r);
    tie *STDOUT, ref $r;
  }
  
  return $r;
}

sub rotate_filters {
  my $self = shift;
  
  #warn "Turning STDOUT (@{[ref tied *STDOUT]}) into fh_in";
  delete $self->{'fh_in'};
  $self->{'fh_in'} = gensym;
  tie *{$self->{'fh_in'}}, ref($self), tied *STDOUT;
  local $^W;  # Ignore "untie attempted while %d inner references still exist" warning from next line
  untie *STDOUT;
}

sub filter_input {
  my $self = shift;

  # Don't handle directories
  if ($self->is_first_filter and -d $self->finfo) {
    $self->{'is_dir'} = 1; # Let mod_dir handle it
  }
  if ($self->{'is_dir'}) {
    $self->{fh_in} = undef;
    return wantarray ? ($self->{fh_in}, DECLINED) : $self->{fh_in};
  }

  my $status = OK;
  
  unless (exists $self->{fh_in}) {
    # Open $self->filename
    #warn "+++++++++++ @{[$self->filename]}: This is the first filter";
    $self->{fh_in} = gensym;
    if (not -e $self->finfo) {
      $self->log_error($self->filename() . " not found");
      $status = NOT_FOUND;
    } elsif ( not open (*{$self->{'fh_in'}}, $self->filename()) ) {
      $self->log_error("Can't open " . $self->filename() . ": $!");
      $status = FORBIDDEN;
    }
  }

  #warn "END info is @{[%$self]} ";
  return wantarray ? ($self->{fh_in}, $status) : $self->{fh_in};
}

sub is_last_filter {
  my $self = shift;
  return $self->{count} == @{$self->get_handlers('PerlHandler')};
}

sub is_first_filter {
  my $self = shift;
  return $self->{count} == 1;
}

sub send_http_header {
  my $self = shift;
  unless ($self->is_last_filter) {
    # This lets previous filters set content_type, which becomes default for final filter.
    $self->content_type($_[0]) if @_;

    # Prevent early filters from messing up the content-length of late filters
    $self->header_out('Content-Length'=> undef);
    return;
  }

  return $self->SUPER::send_http_header(@_);
}

sub send_fd {
  my $self = shift;
  if ($self->is_last_filter and eval{fileno $_[0]}) {
    # Can send native filehandle directly to client
    $self->SUPER::send_fd(@_);
  } else {
    my $fd = shift;
    print while <$fd>;
  }
}

sub print {
  my $self = shift;
  $self->send_http_header() unless $self->sent_header;
  print STDOUT @_;
}

sub changed_since {
    my $self = shift;
    # If any previous handlers are non-deterministic, then the content is 
    # volatile, so tell them it's changed.

    if ($self->{'count'} > 1) {
        return 1 if grep {not $self->{'determ'}{$_}} (1..$self->{'count'}-1);
    }
    
    # Okay, only deterministic handlers have touched this.  If the file has
    # changed since the given time, return true.  Otherwise, return false.
    return 1 if ((stat $self->finfo)[9] > shift);
    return 0;
}

sub deterministic {
    my $self = shift;

    if (@_) {
        $self->{'determ'}{$self->{'count'}} = shift;
    }
    return $self->{'determ'}{$self->{'count'}};
}

# This package is a TIEHANDLE package, so it can be used like this:
#  tie(*HANDLE, 'Apache::Filter');
# All it does is save strings that are written to the filehandle, and
# spits them back out again when you read from the filehandle.

sub TIEHANDLE {
    my $class = shift;
    my $self = (@_ ? shift : { content => '' });
    return bless $self, $class;
}

sub PRINT {
    shift()->{'content'} .= join "", @_;
}

sub PRINTF {
    my $self = shift;
    my $format = shift;
    $self->{'content'} .= sprintf($format, @_);
}

sub READLINE {
    # I've tried to emulate the behavior of real filehandles here
    # with respect to $/, but I might have screwed something up.
    # It's kind of a mess.  Beautiful code is welcome.
 
    my $self = shift;
    my $debug = 0;
    warn "reading line from $self, content is $self->{'content'}" if $debug;
    return unless length $self->{'content'};
        
    if (wantarray) {
        # This handles list context, i.e. @list = <FILEHANDLE> .
        my @lines;
        while (defined $self->{'content'} and length $self->{'content'}) {
            push @lines, scalar $self->READLINE();
        }
        return @lines;
    }
    
    if (defined $/) {
        if (my $l = length $/) {
            my $spot = index($self->{'content'}, $/);
            if ($spot > -1) {
	        return substr $self->{'content'}, 0, $spot + $l, '';
            } else {
                return delete $self->{'content'};
            }
        } else {
            return $1 if $self->{'content'} =~ s/^([^\n]*\n+)//;
            return delete $self->{'content'};
        }
    } else {
        return delete $self->{'content'};
    }
}

sub READ {
    my $self = shift;    # @_ is now ($buf, $len[, $offset])

    # I use $_[...] directly rather than assigning to variables
    # because I need to do that for $_[0] anyway to affect the
    # caller's copy.

    return length (substr($_[0], $_[2]||0) = substr $self->{'content'}, 0, $_[1], '');
}

sub GETC {
    my $self = shift;
    
    return substr $self->{'content'}, 0, 1, '';
}

# You can't do low-level operations on these filehandles.
sub FILENO { undef }

1;

__END__

=head1 NAME

Apache::Filter - Alter the output of previous handlers

=head1 SYNOPSIS

  #### In httpd.conf:
  PerlModule Apache::Filter
  # That's it - this isn't a handler.
  
  <Files ~ "*\.blah">
   SetHandler perl-script
   PerlSetVar Filter On
   PerlHandler Filter1 Filter2 Filter3
  </Files>
  
  #### In Filter1, Filter2, and Filter3:
  $r = $r->filter_register();  # Required
  my $fh = $r->filter_input(); # Optional (you might not need the input FH)
  while (<$fh>) {
    s/ something / something else /;
    print;
  }
  
  #### or, alternatively:
  $r = $r->filter_register();
  my ($fh, $status) = $r->filter_input(); # Get status information
  return $status unless $status == OK;
  while (<$fh>) {
    s/ something / something else /;
    print;
  }

=head1 DESCRIPTION

In basic operation, each of the handlers Filter1, Filter2, and Filter3 will make a call
to $r->filter_input(), which will return a filehandle.  For Filter1,
the filehandle points to the requested file.  For Filter2, the filehandle
contains whatever Filter1 wrote to STDOUT.  For Filter3, it contains
whatever Filter2 wrote to STDOUT.  The output of Filter3 goes directly
to the browser.

Note that the modules Filter1, Filter2, and Filter3 are listed in
B<forward> order, in contrast to the reverse-order listing of
Apache::OutputChain.

When you've got this module, you can use the same handler both as
a stand-alone handler, and as an element in a chain.  Just make sure
that whenever you're chaining, B<all> the handlers in the chain
are "Filter-aware," i.e. they each call $r->filter_register() exactly
once, before they start printing to STDOUT.  There should be almost
no overhead for doing this when there's only one element in the chain.

Currently the following public modules are Filter-aware.  Please tell
me of others you know about.

 Apache::Registry (using Apache::RegistryFilter, included here)
 Apache::SSI
 Apache::ASP
 HTML::Mason
 Apache::SimpleReplace
 Text::Forge

=head1 METHODS

Apache::Filter is a subclass of Apache, so all Apache methods are available.

This module doesn't create an Apache handler class of its own - rather, it adds some
methods to the Apache:: class.  Thus, it's really a mix-in package
that just adds functionality to the $r request object.

=over 4

=item * $r = $r->filter_register()

Every Filter-aware module must call this method exactly once, so that
Apache::filter can properly rotate its filters from previous handlers,
and so it can know when the output should eventually go to the
browser.

=item * $r->filter_input()

This method will give you a filehandle that contains either the file 
requested by the user ($r->filename), or the output of a previous filter.
If called in a scalar context, that filehandle is all you'll get back.  If
called in a list context, you'll also get an Apache status code (OK, 
NOT_FOUND, or FORBIDDEN) that tells you whether $r->filename was successfully
found and opened.  If it was not, the filehandle returned will be undef.

=item * $r->changed_since($time)

Returns true or false based on whether the current input seems like it 
has changed since C<$time>.  Currently the criteria to figure this out
is this: if the file pointed to by C<$r-E<gt>finfo> hasn't changed since
the time given, and if all previous filters in the chain are deterministic
(see below), then we return false.  Otherwise we return true.

This method is meant to be useful in implementing caching schemes.

A caution: always call the C<changed_since()> and C<deterministic()> methods
B<AFTER> the C<filter_register()> method.  This is because Apache::Filter uses a 
crude counting method to figure out which handler in the chain is currently 
executing, and calling these routines out of order messes up the counting.

=item * $r->deterministic(1|0);

As of version 0.07, the concept of a "deterministic" filter is supported.  A
deterministic filter is one whose output is entirely determined by the contents
of its input file (whether the $r->filename file or the output of another filter),
and doesn't depend at all on outside factors.  For example, a filter that translates
all its output to upper-case is deterministic, but a filter that adds a date
stamp to a page, or looks things up in a database which may vary over time, is not.

Why is this a big deal?  Let's say you have the following setup:

 <Files ~ "\.boffo$">
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::FormatNumbers Apache::DoBigCalculation
  # The above are fake modules, you get the idea
 </Files>

Suppose the FormatNumbers module is deterministic, and the DoBigCalculation module
takes a long time to run.  The DoBigCalculation module can now cache its results,
so that when an input file is unchanged on disk, its results will remain known
when passed through the FormatNumbers module, and the DoBigCalculation module
will be able to used cached results from a previous run.

The guts of the modules would look something like this:

 sub Apache::FormatNumbers::handler {
    my $r = shift;
    $r->content_type("text/html");
    my ($fh, $status) = $r->filter_input();
    return $status unless $status == OK;
    $r->deterministic(1); # Set to true; default is false
    
    # ... do some formatting, print to STDOUT
    return OK;
 }
 
 sub Apache::DoBigCalculation::handler {
    my $r = shift;
    $r->content_type("text/html");
    my ($fh, $status) = $r->filter_input();
    return $status unless $status == OK;
    
    # This module implements a caching scheme by using the 
    # %cache_time and %cache_content hashes.
    my $time = $cache_time{$r->filename};
    my $output;
    if ($r->changed_since($time)) {
        # Read from <$fh>, perform a big calculation on it, and print to STDOUT
    } else {
        print $cache_content{$r->filename};
    }
    
    return OK;
 }

A caution: always call the C<changed_since()> and C<deterministic()> methods
B<AFTER> the C<filter_register()> method.  This is because Apache::Filter uses a 
crude counting method to figure out which handler in the chain is currently 
executing, and calling these routines out of order messes up the counting.


=back


=head1 HEADERS

In previous releases of this module, it was dangerous to call
$r->send_http_header(), because a previous/postvious filter might also
try to send headers, and then you'd have duplicate headers getting
sent.  In current releases you can simply send the headers.  If the
current filter is the last filter, the headers will be sent as usual,
and otherwise send_http_header() is a no-op.

=head1 NOTES

You'll notice in the SYNOPSIS that I say C<"PerlSetVar Filter On">.  That
information isn't actually used by this module, it's used by modules which
are themselves filters (like Apache::SSI).  I hereby suggest that filtering
modules use this parameter, using it as the switch to detect whether they 
should call $r->filter_register.  However, it's often not necessary -
there is very little overhead in simply calling $r->filter_register
even when you don't need to do any filtering, and $r->filter_input can
be a handy way of opening the $r->filename file.

VERY IMPORTANT: if one handler in a stacked handler chain uses 
C<Apache::Filter>, then THEY ALL MUST USE IT.  This means they all must
call $r->filter_register exactly once.  Otherwise C<Apache::Filter> couldn't
capture the output of the handlers properly, and it wouldn't know when
to release the output to the browser.

The output of each filter (except the last) is accumulated in memory
before it's passed to the next filter, so memory requirements are
large for large pages.  Apache::OutputChain only needs to keep one
item from print()'s argument list in memory at a time, so it doesn't
have this problem, but there are others (each chunk is filtered
independently, so content spanning several chunks won't be properly
parsed).  In future versions I might find a way around this, or cache
large pages to disk so memory requirements don't get out of hand.
We'll see whether it's a problem.

A couple examples of filters are provided with this distribution in the t/
subdirectory: UC.pm converts all its input to upper-case, and Reverse.pm
prints the lines of its input reversed.

Finally, a caveat: in version 0.09 I started explicitly setting the
Content-Length to undef.  This prevents early
filters from incorrectly setting the content length, which will almost
certainly be wrong if there are any filters after it.  This means that
if you write any filters which set the content length, they should do
it B<after> the $r->filter_register call.

=head1 TO DO

Add a buffered mode to the final output, so that we can send a proper
Content-Length header. [gozer@hbesoftware.com (Philippe M. Chiasson)]

=head1 BUGS

This uses some funny stuff to figure out when the currently executing
handler is the last handler in the chain.  As a result, code that
manipulates the handler list at runtime (using push_handlers and the
like) might produce mayhem.  Poke around a bit in the code before you 
try anything.  Let me know if you have a better idea.

As of 0.07, Apache::Filter will automatically return DECLINED when
$r->filename points to a directory.  This is just because in most
cases this is what you want to do (so that mod_dir can take care of
the request), and because figuring out the "right" way to handle
directories seems pretty tough - the right way would allow a directory
indexing handler to be a filter, which isn't possible now.  Also, you
can't properly pass control to a non-mod_perl indexer like
mod_autoindex.  Suggestions are welcome.

I haven't considered what will happen if you use this and you haven't
turned on PERL_STACKED_HANDLERS.  So don't do it.

=head1 AUTHOR

Ken Williams (kwilliams@cpan.org)

=head1 COPYRIGHT

Copyright 1998,1999,2000 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
