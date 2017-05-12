use strict;
use warnings;
use lib '../lib';
use Config::IPFilter;
use 5.010;

#
my $filter = Config::IPFilter->new;
my $rule =
    $filter->add_rule('89.238.128.0', '89.238.191.255', 127, 'Example range');

# A list of example IPv4 addresses
my @ipv4 = qw[89.238.156.165 89.238.156.169 89.238.156.170 89.238.167.84
    89.238.167.86 89.238.167.99];

# Check a list of ips
say sprintf '%15s is %sbanned', $_, $filter->is_banned($_) ? '' : 'not '
    for @ipv4;

# Lower the acces level by one pushes it below our ban threshold
$rule->decrease_access_level;

# Check a list of ips
say sprintf '%15s is %sbanned', $_,
    $filter->is_banned($_) ? 'now ' : 'still not '
    for @ipv4;

=pod

=head1 Author

=begin :html

L<Sanko Robinson|http://sankorobinson.com/>
<L<sanko@cpan.org|mailto://sanko@cpan.org>> -
L<http://sankorobinson.com/|http://sankorobinson.com/>

CPAN ID: L<SANKO|http://search.cpan.org/~sanko>

=end :html

=begin :text

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=end :text

=head1 License and Legal

Copyright (C) 2010, 2011 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=for rcs $Id: synopsis.pl c785a0b 2010-12-27 05:26:21Z sanko@cpan.org $

=cut
