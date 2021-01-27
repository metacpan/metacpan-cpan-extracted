#
#     Configuration script for Date::Holidays::FR
#     Copyright (c) 2004, 2019, 2021 Fabien Potencier and Jean Forget, all rights reserved
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
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Date::Holidays::FR',
    VERSION_FROM      => 'lib/Date/Holidays/FR.pm',
    PREREQ_PM         => {
        'Time::Local'  => 1.28,
        'Date::Easter' => 0,
        'strict'       => 0,
        'warnings'     => 0,
        'Readonly'     => 0,
    },
    'LICENSE'           => 'perl',
    ABSTRACT_FROM  => 'lib/Date/Holidays/FR.pm',
    AUTHOR         => [   'Fabien POTENCIER <fabpot@cpan.org>'
                        , 'Jean Forget <JFORGET@cpan.org>'
                      ],
    'MIN_PERL_VERSION' => '5.6.0', # because of use utf8
    BUILD_REQUIRES => {       # should be 'TEST_REQUIRES', except that ExtUtils::MakeMaker 6.5705 does not accept it
        'Test::More'          => '0'
      , 'ExtUtils::MakeMaker' => '6.57_02' # the first version to accept several authors in an arrayref
                           },
    META_MERGE       => {
       dynamic_config => 0,
       provides       => {
           'Date::Holidays::FR' => {
                file    => 'lib/Date/Holidays/FR.pm'
              , version => '0.04'
           },
       },
       'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/jforget/Date-Holidays-FR.git',
               web  => 'https://github.com/jforget/Date-Holidays-FR',
           },
           bugtracker => {
               web  => 'https://github.com/jforget/Date-Holidays-FR/issues',
           },
       },
    },
);
