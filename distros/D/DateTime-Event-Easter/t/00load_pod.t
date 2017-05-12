# -*- perl -*-

#     t/00load_pod.t - check module loading and documentation
#     Test script for DateTime::Event::Easter
#     Copyright (C) 2003, 2004, 2015, Rick Measham and Jean Forget
#
#     This program is distributed under the same terms as Perl:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
#     and L<http://www.gnu.org/licenses/gpl-1.0.html>.
#
#     Here is the summary of GPL:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 1, or (at your option)
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software Foundation,
#     Inc., <http://www.fsf.org/>.
#

use Test::More tests => 3;

BEGIN { use_ok( 'DateTime::Event::Easter' ); }

my $object = DateTime::Event::Easter->new ();
isa_ok ($object, 'DateTime::Event::Easter');


SKIP: {
	eval{ require Test::Pod };
	skip "Test::Pod isn't installed. Believe me: the POD is ok!", 1 if $@;
	
	Test::Pod::pod_file_ok('lib/DateTime/Event/Easter.pm','Pod tests OK');
}


