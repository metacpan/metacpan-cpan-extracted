#!/usr/bin/perl
#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 03/01/2009 02:10:35 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

=head1 NAME

102-changelog.t - test Archive::RPM changelog functionality

=head1 DESCRIPTION 

This test exercises the changelog functionality of Archive::RPM.

=head1 TESTS

This module defines the following tests.

=cut

use strict;
use warnings;

use English qw{ -no_match_vars };  # Avoids regex performance penalty

use Test::More tests => 4;

use Archive::RPM;
use FindBin;

=head2 changelog functionality

These tests exercise the changelog functionality.

=for author changelog 
* Thu Feb 05 2009 Chris Weyl <cweyl@alumni.drew.edu> 0.06-1
- update for submission
.
* Thu Feb 05 2009 Chris Weyl <cweyl@alumni.drew.edu> 0.06-0
- initial RPM packaging
- generated with cpan2dist (CPANPLUS::Dist::RPM version 0.0.8)

=cut


my $test_rpm = 'perl-DateTime-Format-ISO8601-0.06-1.fc10.noarch.rpm';

my $rpm = Archive::RPM->new("$FindBin::Bin/$test_rpm");

isa_ok($rpm => 'Archive::RPM');

is $rpm->num_changelog_entries => 2, 'count OK';

my $entry = $rpm->first_changelog_entry;
isa_ok $entry => 'Archive::RPM::ChangeLogEntry', 'isa A::RPM::CLE ok';

is $entry->name => 'Chris Weyl <cweyl@alumni.drew.edu> 0.06-1', 'name OK';

__END__

=head1 SEE ALSO

L<Archive::RPM>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



