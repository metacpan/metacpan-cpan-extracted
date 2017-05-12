package Apache::HEADRegistry;

use Apache::Constants qw(DONE);
use Apache::RegistryNG;
use strict;

@Apache::HEADRegistry::ISA = qw(Apache::RegistryNG);

$Apache::HEADRegistry::VERSION = '0.01';

sub new {

  my ($class, $r) = @_;

  $r ||= Apache->request;

  tie *STDOUT, $class, $r;

  return tied *STDOUT;
}

sub PRINT {

  my ($self, @data) = @_;

  my $r = $self->{r};

  # we're emulating mod_cgi, where there is no auto-dereferencing...
  my $data = join '', @data;

  my $dlm = "\015?\012"; # a bit borrowed from LWP::UserAgent
  my ($key, $value);

  unless ($r->sent_header) {
    # if we have already sent the headers, no reason to scan the output

    while((my $header, $data) = split /$dlm/, $data, 2) {
      # scan the incoming data for headers

      if ($header && $header =~ m/^(\S+?):\s*(.*)$/) {
        # if the data looks like a header, add it to the header table

        ($key, $value) = ($1, $2);

        last unless $key;

        $r->cgi_header_out($key, $value);
      }
      else {
        # since we're done with the headers, send them along...

        $r->send_http_header;
        $r->sent_header(DONE);

        last;
      }
    }
  }

  # if this is a HEAD request, we're done
  return if $r->header_only;

  # otherwise, send whatever data we have left to the client
  $r->write_client($data);
}

# note that the perltie manpage is wrong - no need to append a newline
# verified by #p5p (thanks rafael :) and fixed in bleedperl
sub PRINTF {

  my $self = shift;

  $self->PRINT(sprintf(shift, @_));
}

# BINMODE and CLOSE are both no-ops in Apache.xs
sub BINMODE {};
sub CLOSE {};


sub TIEHANDLE {

  my ($class, $r) = @_;

  return bless { r => $r }, $class;
}

1;

__END__

=head1 NAME 

Apache::HEADRegistry - Apache::Registry drop-in for HEAD requests

=head1 SYNOPSIS

httpd.conf:

 PerlModule Apache::HEADRegsitry

 <Location /perl-bin>
    SetHandler perl-script
    PerlHandler Apache::HEADRegistry

    Options +ExecCGI
    PerlSendHeader On
 </Location>  

=head1 DESCRIPTION

Apache::HEADRegistry is a drop-in for Apache::Registry that
properly handles HEAD requests.  Currently, Apache::Registry
incorrectly handles HEAD requests - it acts as though they are
GET requests, returning both the headers and content.  So, not
only does represent a way in which mod_cgi and Apache::Registry
are different, but Apache::Registry is not RFC compliant and
causes trouble with some modern browsers.  This module attempts
to correct the wrong in Apache::Registry by intercepting headers
much in the way that mod_perl does, but then respecting the value 
of $r->header_only.

=head1 NOTES

Apache::HEADRegistry is a subclass of Apache::RegistryNG, which
means that it doesn't behave _exactly_ the same as Apache::Registry.
Namely, it uses the filename of the script to determine the 
unique package namespace, whereas Apache::Registry uses the URI.
HEADRegistry also does not do any of the auto-dereferencing in its
print() method - if you want that type of thing, then you are
obviously relying on the mod_perl API and can therefore check
$r->header_only yourself.  This module is meant for those who
want mod_cgi emulation only.

=head1 FEATURES/BUGS

The only current bug seems to be for scripts that handle redirects,
such as:

use CGI;
$cgi = CGI->new;
print $cgi->redirect ("http://www.foo.com/");

or 

print "Location: http://www.foo.com/";

What happens is that the default Apache 302 error is displayed
instead of just the headers.  This is a bug both with Apache::Registry
and Apache::HEADRegistry and seems to lie with mod_perl and it's
internal messing with the $r->assbackwards flag (but I'm not entirely
sure).

This module also does not handle write() calls at the moment - if
you have a need for that let me know.

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3), Apache::Registry(3), 
Apache::RegistryNG

=head1 AUTHOR

Geoffrey Young <geoff@modperlcookbook.org>

=head1 COPYRIGHT

Copyright (c) 2002, Geoffrey Young.
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived in part from examples in the 
"The mod_perl Developer's Cookbook"

For more information, visit http://www.modperlcookbook.org/

It also contains code lifted from various mod_perl internal
sources, such as Apache.pm and mod_perl.c, and LWP.  Thanks
all for being good open source contributors.

=cut
