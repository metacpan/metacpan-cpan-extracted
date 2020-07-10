#
#     Configuration script for DateTime::Event::Sunrise
#     Copyright © 2003, 2004, 2013, 2015, 2020 Ron Hill and Jean Forget
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
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'DateTime::Event::Sunrise',
    'VERSION_FROM'      => 'lib/DateTime/Event/Sunrise.pm', # finds $VERSION
    'ABSTRACT'          => 'Perl DateTime extension for computing the sunrise/sunset on a given day',
    'PREREQ_PM'         => { 'DateTime::Set'    => '0.16',
                             'DateTime'         => '0.21',
                             'POSIX'            => '0',     # how can I find the minimum version without trying all of them? At least mention the dependency.
                             'Math::Trig'       => '0',
                             'Carp'             => '0',
                             'Params::Validate' => '0',
                             'Set::Infinite'    => '0',
                           },
    'AUTHOR'            => [ 'Ron Hill <rkhill@firstlight.net>', 'Jean Forget <JFORGET@cpan.org>' ],
    'LICENSE'           => 'perl',
    # The oldest Perl to check DT::E::Sunrise 0.0504 is 5.8.5. Therefore, I guess DT::E::Sunrise 0.0505 and next will work in 5.8.5 too.
    MIN_PERL_VERSION => '5.8.5',
    'BUILD_REQUIRES'    => { 'Test::More'         => '0',   # should be 'TEST_REQUIRES', except that ExtUtils::MakeMaker 6.5705 does not accept it
                             'DateTime::Duration' => '0',
                             'DateTime::Span'     => '0',
                             'DateTime::SpanSet'  => '0',
                             'Test::Exception'    => '0',
                             'ExtUtils::MakeMaker' => '6.57_02', # the first version to accept several authors in an arrayref
                           },
    META_MERGE       => {
       dynamic_config => 0,
       prereqs => {
         runtime => {
           requires => {
               'DateTime'           => '0.16',
               'DateTime::Duration' => '0',
               'DateTime::Span'     => '0',
               'DateTime::SpanSet'  => '0',
               'perl'               => '5.8.5',
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
           'DateTime::Event::Sunrise' => {
                file => 'lib/DateTime/Event/Sunrise.pm',
                version => '0.0506',
           },
       },
       'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/jforget/DateTime-Event-Sunrise.git',
               web  => 'https://github.com/jforget/DateTime-Event-Sunrise',
           },
       },
    },
);
