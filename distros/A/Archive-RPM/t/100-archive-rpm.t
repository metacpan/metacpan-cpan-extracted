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

use Test::More tests => 12;

use Archive::RPM;
use FindBin;

my $test_rpm = 'perl-DateTime-Format-ISO8601-0.06-1.fc10.noarch.rpm';

=head2 Basic checks

Make sure we can open a rpm, create an object instance, methods, etc...

=cut

my $rpm = Archive::RPM->new("$FindBin::Bin/$test_rpm");

isa_ok($rpm => 'Archive::RPM');

is "$rpm" => $test_rpm, 'stringifies OK';

# just a couple, to make sure the include/exclude bit is working
ok  $rpm->can('tag') => 'method tag() OK';
#ok !$rpm->can('files') => 'no changelog()

=head2 Header checks

Poke at some of the RPM2-provided functionality.

=cut

# RPM2 header bits
is $rpm->name => 'perl-DateTime-Format-ISO8601',             'name OK';
is $rpm->nvre => 'perl-DateTime-Format-ISO8601-0.06-1.fc10', 'nvre OK';
is $rpm->nvr  => 'perl-DateTime-Format-ISO8601-0.06-1.fc10', 'nvr OK';
is $rpm->arch => 'noarch',                                   'noarch OK';

ok !$rpm->is_srpm, 'is rpm OK';

# our files bits
ok $rpm->has_files,       'we have files';
is $rpm->num_files => 19, 'file count OK';

my @files = $rpm->grep_files(sub { /LICENSE$/ });

is scalar @files => 1, 'found one LICENSE';
is $files[0]->basename => 'LICENSE', 'spec found!';

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



