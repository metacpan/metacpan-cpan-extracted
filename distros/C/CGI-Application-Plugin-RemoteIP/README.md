NAME
    CGI::Application::Plugin::RemoteIP - Unified Remote IP handling

SYNOPSIS
      use CGI::Application::Plugin::RemoteIP;


      # Your application
      sub run_mode {
        my ($self) = ( @_);

        my $ip = $self->remote_ip();
      }

DESCRIPTION
    This module simplifies the detection of the remote IP address of your
    visitors.

MOTIVATION
    This module allows you to remove scattered references in your code, such
    as:

        # Get IP
        my $ip = $ENV{'REMOTE_ADDR'};

        # Remove faux IPv6-prefix.
        $ip =~ s/^::ffff://g;
        ..

    Instead your code and use the simpler expression:

        my $ip = $self->remote_ip();

SECURITY
    The code in this module will successfully understand the
    "X-Forwarded-For" header and trust it.

    Unless you have setup any proxy, or webserver, to scrub this header this
    means the value that is used is at risk of being spoofed, bogus, or
    otherwise malicious.

METHODS
  import
    Add our three public-methods into the caller's namespace:

    remote_ip
            The remote IP of the client.

    is_ipv4 A method to return 1 if the visitor is using IPv4 and 0
            otherwise.

    is_ipv6 A method to return 1 if the visitor is using IPv6 and 0
            otherwise.

  remote_ip
    Return the remote IP of the visitor, whether via the "X-Forwarded-For"
    header or via the standard CGI environmental variable "REMOTE_ADDR".

  is_ipv4
    Determine whether the remote IP address is IPv4.

  is_ipv6
    Determine whether the remote IP address is IPv6.

AUTHOR
    Steve Kemp <steve@steve.org.uk>

COPYRIGHT AND LICENSE
    Copyright (C) 2015 Steve Kemp <steve@steve.org.uk>.

    This library is free software. You can modify and or distribute it under
    the same terms as Perl itself.

