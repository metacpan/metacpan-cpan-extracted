#
#     Configuration script for Astro::Sunrise
#     Copyright (C) 2001, 2002, 2003, 2013, 2015, 2017, 2019 Ron Hill and Jean Forget
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
    NAME           => 'Astro::Sunrise',
    VERSION_FROM   => 'lib/Astro/Sunrise.pm', # finds $VERSION
    ABSTRACT       => 'Perl extension for computing the sunrise/sunset on a given day',
    PREREQ_PM      => { # DateTime => '0.16',
                        POSIX        => 0,
                       'strict'      => 0,
                       'warnings'    => 0,
                       'Carp'        => 0,
                       'Math::Trig'  => 0, },
    AUTHOR         => [ 'Ron Hill <rkhill@firstlight.net>', 'Jean Forget <JFORGET@cpan.org>' ],
    LICENSE        => 'perl',
    # The oldest Perl to check Astro::Sunrise 0.92 is 5.6.2. Therefore, I guess Astro::Sunrise 0.93 and next will work in 5.6.2 too.
    MIN_PERL_VERSION => '5.6.2',
    BUILD_REQUIRES => { 'Test::More'         => '0',        # should be 'TEST_REQUIRES', except that ExtUtils::MakeMaker 6.5705 does not accept it
                        'ExtUtils::MakeMaker' => '6.57_02', # the first version to accept several authors in an arrayref
                           },
    META_MERGE       => {
       dynamic_config => 0,
       prereqs => {
         runtime => {
           recommends => {
               DateTime => '0.16',
           },
         },
       },
       provides       => {
           'Astro::Sunrise' => {
                file => 'lib/Astro/Sunrise.pm',
                version => '0.98',
           },
       },
       'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/jforget/Astro-Sunrise.git',
               web  => 'https://github.com/jforget/Astro-Sunrise',
           },
       },
    },
);
