# MIT License
#
# Copyright (c) 2017 Lari Taskula  <lari@taskula.fi>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use warnings;

use ExtUtils::MakeMaker;
use FindBin;

use lib "$FindBin::Bin/lib";

use Binance::PerlDependencies;

WriteMakefile(
    NAME            => 'Binance::API',
    VERSION_FROM    => 'lib/Binance/API.pm',
    AUTHOR          => 'Lari Taskula <lari@taskula.fi>',
    ABSTRACT        => 'Perl module for interacting with the Binance API.',
    PREREQ_PM       => $Binance::PerlDependencies::required,
    PREREQ_FATAL    => 1,
    TEST_REQUIRES   => $Binance::PerlDependencies::required_test,
    META_MERGE      => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/taskula/binance-perl-api/issues'
            },
            homepage => 'https://github.com/taskula/binance-perl-api',
            repository => {
                type => 'git',
                url  => 'https://github.com/taskula/binance-perl-api.git',
                web  => 'https://github.com/taskula/binance-perl-api',
            },
        },
    },
    test => { TESTS => 't/*.t t/*/*.t t/*/*/*.t'},
);
