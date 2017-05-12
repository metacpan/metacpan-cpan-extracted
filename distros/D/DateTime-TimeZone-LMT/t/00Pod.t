#     t/00Pod.t - checking the POD documentation
#     Test script for DateTime::TimeZone::LMT
#     Copyright (C) 2003, 2016 Rick Measham and Jean Forget
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
use Test::More tests=>1;

SKIP: {
	eval{ require Test::Pod };
	skip "Test::Pod isn't installed. Believe me: the POD is ok!", 1 if $@;
	
	Test::Pod::pod_file_ok('lib/DateTime/TimeZone/LMT.pm','Pod tests OK');
}


