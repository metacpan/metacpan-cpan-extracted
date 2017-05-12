#
#     Configuration script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (c) 2003, 2004, 2010, 2011, 2012, 2014, 2016 Jean Forget. All rights reserved.
#
#     This program is distributed under the same terms as Perl 5.16.3:
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
use Module::Build;

Module::Build->new (module_name => 'DateTime::Calendar::FrenchRevolutionary'
    , license => 'perl'
    , requires => { perl => '5.8.5'
                  , Roman => 1.22
                  , DateTime => 0.14
                  , 'Params::Validate' => 0
                  }
    , abstract => 'This modules allows converting dates to or from the French Revolutionary calendar'
    )->create_build_script;
