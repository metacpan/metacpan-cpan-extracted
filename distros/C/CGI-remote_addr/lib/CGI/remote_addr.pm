package CGI::remote_addr;

use strict;
use warnings;
use Regexp::Common qw(net);
use List::MoreUtils qw(uniq);
use namespace::clean;

our $VERSION = '0.03';

sub remote_addr {
    my @ips;

    # gather all available IP addresses
    if ($ENV{'HTTP_X_FORWARDED_FOR'}) {
        push( @ips, split(/\s*,\s*/, $ENV{'HTTP_X_FORWARDED_FOR'}) );
    }
    if ($ENV{'REMOTE_ADDR'}) {
        push( @ips, $ENV{'REMOTE_ADDR'} );
    }

    # trim list to a unique list of valid IPs
    @ips = uniq grep { /^$RE{net}{IPv4}$/ } @ips;

    # return IP back to caller
    return wantarray ? @ips : $ips[0];
}

# redefine CGI::remote_addr() so that it uses our version instead of the one
# that comes with CGI.pm
{
    no warnings;
    *CGI::remote_addr = \&remote_addr;
}

1;

=head1 NAME

CGI::remote_addr - Enhanced version of CGI.pm's "remote_addr()"

=head1 SYNOPSIS

  use CGI;
  use CGI::remote_addr;

  my $cgi  = CGI->new();
  my $addr = $cgi->remote_addr();

=head1 DESCRIPTION

C<CGI::remote_addr> implements an enhanced version of the C<remote_addr()>
method provided by C<CGI.pm>, which attempts to return the original IP address
that the connection originated from (which is not necessarily the IP address
that we received the connection from).

Simply loading C<CGI::remote_addr> causes it to over-ride the existing
C<remote_addr()> method.  Do note, though, that this is a global over-ride; if
you're running under mod_perl you've just over-ridden it for B<all> of your
applications.

=head2 Differences from CGI.pm

=over

=item *

We check not only C<$ENV{REMOTE_ADDR}> to find the IP address, but also look in
C<$ENV{HTTP_X_FORWARDED_FOR}> to find the IP address.  If
C<$ENV{HTTP_X_FORWARDED_FOR}> is defined, we try that first.

=item *

Only valid IP addresses are returned, regardless of whatever exists in
C<$ENV{REMOTE_ADDR}> or C<$ENV{HTTP_X_FORWARDED_FOR}>.  I've seen lots of cases
where the values for C<$ENV{HTTP_X_FORWARDED_FOR}> were stuffed with garbage,
and we make sure that you only get a real IP back.

=item *

We return IPs in both a scalar and a list context.  In scalar context you get
the first (originating) IP address.  In list context you get a unique list of
all of the IPs that the connection was received through.

=item *

In the event that we cannot find a valid IP address, this method returns
C<undef>, B<NOT> 127.0.0.1 (like C<CGI.pm> does).

=back

=head1 METHODS

=over

=item remote_addr()

Returns the IP address(es) of the remote host.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2008 Graham TerMarsch.  All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over

=item L<CGI>

=back

=cut
