#
#     Configuration script for Date::Convert::French_Rev
#     Copyright (C) 2001, 2002, 2003, 2013, 2015 Jean Forget
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

WriteMakefile(
      'NAME'         => 'Date::Convert::French_Rev'
   ,  'VERSION_FROM' => 'lib/Date/Convert/French_Rev.pm'
   ,  'PREREQ_PM'    => {   Roman => 0
                          , Date::Convert   => '0.16'
                          , Test::Exception => 0 }
   ,  'ABSTRACT'     => 'Date conversions using the French Revolutionary calendar'
   ,  'AUTHOR'       => 'Jean Forget <JFORGET@cpan.org>'
   ,  'LICENSE'      => 'perl'
   ,  'MIN_PERL_VERSION' => '5.8.8'
   ,  'BUILD_REQUIRES'   => { 'Test::More'         => '0',        # should be 'TEST_REQUIRES', except that ExtUtils::MakeMaker 6.5705 does not accept it
                        'ExtUtils::MakeMaker' => '6.57_02',
                           },
   , META_MERGE       => {
       'meta-spec' => { version => 2 },
       'prereqs' => {
          'build' => {
             'requires' => {
                'ExtUtils::MakeMaker' => '0',
             }
          },
          'configure' => {
             'requires' => {
                'ExtUtils::MakeMaker' => '0',
             }
          },
          'runtime' => {
             'requires' => {
                'Date::Convert'   => '0.16',
                'Roman'           => '0',
                'perl'            => '5.008008',
             }
          },
          'test' => {
             'requires' => {
                'Test::Exception' => '0',
             }
          },
       },
       provides       => {
           'Date::Convert::French_Rev' => {
                file => 'lib/Date/Convert/French_Rev.pm',
                version => '0.08',
           },
       },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/jforget/Date-Convert-French_Rev.git',
               web  => 'https://github.com/jforget/Date-Convert-French_Rev',
           },
       },
    },
);
