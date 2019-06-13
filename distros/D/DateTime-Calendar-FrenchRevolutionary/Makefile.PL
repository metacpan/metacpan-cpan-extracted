#
#     Configuration script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (c) 2003, 2004, 2010, 2011, 2012, 2014, 2016, 2019 Jean Forget. All rights reserved.
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<https://dev.perl.org/licenses/artistic.html>
#     and L<https://www.gnu.org/licenses/gpl-1.0.html>.
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
#     Inc., <https://www.fsf.org/>.
#
use strict;
use ExtUtils::MakeMaker;
WriteMakefile
(
    'ABSTRACT'       => 'Converting dates to or from the French Revolutionary calendar',
    'PL_FILES'       => {},
    'INSTALLDIRS'    => 'site',
    'NAME'           => 'DateTime::Calendar::FrenchRevolutionary',
    'EXE_FILES'      => [],
    'VERSION_FROM'   => 'lib/DateTime/Calendar/FrenchRevolutionary.pm',
    'PREREQ_PM' => {
                     'Test::More'                     => 0,
                     'DateTime'                       => 0.14,
                     'Roman'                          => 1.22,
                     'Params::Validate'               => 0,
                     'strict'                         => 0,
                     'warnings'                       => 0,
                   },
    'AUTHOR'         => [ 'Jean Forget <JFORGET@cpan.org>' ],
    'LICENSE'        => 'perl',
    MIN_PERL_VERSION => '5.8.5',
    META_MERGE       => {
       dynamic_config => 0,
       prereqs => {
         build => {
           requires => {
             'strict'                         => 0,
             'warnings'                       => 0,
           },
         },
         runtime => {
           requires => {
             'DateTime'                       => 0.14,
             'Roman'                          => 1.22,
             'Params::Validate'               => 0,
             'perl'                           => '5.8.5',
             'strict'                         => 0,
             'warnings'                       => 0,
           },
         },
         test => {
           requires => {
             'Test::More'                     => '0',
             'List::Util'                     => 1.33,
             'strict'                         => 0,
             'warnings'                       => 0,
           },
         },
       },
       provides       => {
           'DateTime::Calendar::FrenchRevolutionary' => {
                file => 'lib/DateTime/Calendar/FrenchRevolutionary.pm',
                version => '0.15',
           },
       },
       'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/jforget/DateTime-Calendar-FrenchRevolutionary.git',
               web  => 'https://github.com/jforget/DateTime-Calendar-FrenchRevolutionary',
           },
       },
    },
)
;

