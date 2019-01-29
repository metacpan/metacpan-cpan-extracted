#
#     Configuration script for DateTime::Format::Roman
#     Copyright (C) 2003, 2004, 2018, 2019 Eugene van der Pijll, Dave Rolsky and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.28.0:
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
    NAME         => 'DateTime::Format::Roman',
    VERSION_FROM => 'lib/DateTime/Format/Roman.pm',
    PREREQ_PM    => { DateTime     => 0.22,
                      Roman        => 0,
                      Test::More   => 0,
                     'strict'      => 0,
                     'warnings'    => 0,
                       },
    AUTHOR       => [ 'Eugene van der Pijll (pijll@gmx.net)'
                    , 'Dave Rolsky <autarch@urth.org>'
                    , 'Jean Forget <JFORGET@cpan.org>' ],
    ABSTRACT     => 'Roman day names (kalends, ides, nones) for DateTime objects',
    LICENSE        => 'perl',
    BUILD_REQUIRES => { 'Test::More'         => '0',        # should be 'TEST_REQUIRES', except that ExtUtils::MakeMaker 6.5705 does not accept it
                        'ExtUtils::MakeMaker' => '6.57_02', # the first version to accept several authors in an arrayref
                           },
    MIN_PERL_VERSION => '5.6.1',
    META_MERGE       => {
       dynamic_config => 0,
       provides       => {
           'DateTime::Format::Roman' => {
                file => 'lib/DateTime/Format/Roman.pm',
                version => '0.04',
           },
       },
       'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/jforget/DateTime-Format-Roman.git',
               web  => 'https://github.com/jforget/DateTime-Format-Roman',
           },
       },
       prereqs => {
         build => {
           requires => {
             'strict'                         => 0,
             'warnings'                       => 0,
           },
         },
         runtime => {
           requires => {
             'strict'                         => 0,
             'warnings'                       => 0,
             'DateTime'                       => '0.22',
             'Roman'                          => 0,
             'Params::Validate'               => 0,
             'perl'                           => '5.6.1',
           },
         },
         test => {
           requires => {
             'Test::More'                     => '0',
             'strict'                         => 0,
             'warnings'                       => 0,
           },
           recommends => {
             'Test::Pod'                      => '0',
           },
         },
       },
    },
);
