#!/usr/bin/perl
#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 02/25/2009 11:35:29 PM PST
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

hm.t -  

=head1 DESCRIPTION 

This test exercises...

=head1 TESTS

This module defines the following tests.

=cut

use strict;
use warnings;

use English qw{ -no_match_vars };  # Avoids regex performance penalty

use Test::More tests => 11;

use Archive::RPM;
use FindBin;

my $test_srpm = 'perl-DateTime-Format-ISO8601-0.06-1.fc10.src.rpm';

=head2 Basic checks

Make sure we can open a rpm, create an object instance, methods, etc...

=cut

my $srpm = Archive::RPM->new("$FindBin::Bin/$test_srpm");

isa_ok($srpm => 'Archive::RPM');

is "$srpm" => $test_srpm, 'stringifies OK';

# just a couple, to make sure the include/exclude bit is working
ok  $srpm->can('tag') => 'method tag() OK';
#ok !$srpm->can('files') => 'no changelog()

=head2 Header checks

Poke at some of the RPM2-provided functionality.

=cut

# RPM2 header bits
is $srpm->name => 'perl-DateTime-Format-ISO8601',             'name OK';
is $srpm->nvre => 'perl-DateTime-Format-ISO8601-0.06-1.fc10', 'nvre OK';
is $srpm->nvr  => 'perl-DateTime-Format-ISO8601-0.06-1.fc10', 'nvr OK';

ok $srpm->is_srpm, 'is srpm OK';

# our files bits
ok $srpm->has_files,      'we have files';
is $srpm->num_files => 2, 'file count OK';

my @files = $srpm->grep_files(sub { /\.spec$/ });

is scalar @files => 1, 'found one spec';
is $files[0]->basename => 'perl-DateTime-Format-ISO8601.spec', 'spec found!';

=head2 changelog functionality

These tests exercise the changelog functionality.

=cut


my @cl = $srpm->changelog;
#use Smart::Comments '###', '####';
### @cl

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



