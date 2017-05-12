#
#     Configuration script for DateTime::Format::Baby
#     Copyright (C) 2003, 2016 Rick Measham and Jean Forget
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
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'DateTime::Format::Baby',
    'VERSION_FROM' => 'lib/DateTime/Format/Baby.pm', # finds $VERSION
    'AUTHOR'       => [ 'Rick Measham (rickm@cpan.org)', 'Jean Forget <JFORGET@cpan.org>' ],
    'ABSTRACT'     => 'Parse and format baby-style time',
    'PREREQ_PM'    => {
                    'DateTime'         => 0.06,
                    'Carp'             => 0,
                    'Params::Validate' => 0,
   },
    'LICENSE'		=> 'perl',
    'MIN_PERL_VERSION' => '5.6.1',
    META_MERGE       => {
       prereqs => {
         runtime => {
           requires => {
               'DateTime'           => '0.16',
               'Carp'               => '0',
               'Params::Validate'   => '0',
               'perl'               => '5.6.1',
           },
         },
         build => {
           requires => {
             'Test::More'          => '0',
             'ExtUtils::MakeMaker' => '6.57_02', # the first version to accept several authors in an arrayref
           },
         },
       },
       provides       => {
           'DateTime::Format::Baby' => {
                file => 'lib/DateTime/Format/Baby.pm',
                version => '1.0200',
           },
       },
       'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/jforget/DateTime-Format-Baby.git',
               web  => 'https://github.com/jforget/DateTime-Format-Baby',
           },
       },
    },
);
