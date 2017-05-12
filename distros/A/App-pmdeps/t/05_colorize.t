#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture/;
use FindBin;
use File::Spec::Functions qw/catfile/;
use Term::ANSIColor qw/colored/;
use App::pmdeps;

use Test::More;

plan skip_all => "Test::Vars required for testing variables" if $^O eq 'MSWin32';

subtest 'colorize ok' => sub {
    my $app = App::pmdeps->new;

    my ($got) = capture {
        $app->run('-p', '5.008001', '-l', catfile($FindBin::Bin, 'resource'));
    };

    my $expected_core_index     = colored['green'],  'Depends on 2 core modules:';
    my $expected_non_core_index = colored['yellow'], 'Depends on 8 non-core modules:';

    is $got, <<EOS;
Target: perl-5.008001
$expected_core_index
\tCarp
\tGetopt::Long
$expected_non_core_index
\tAcme
\tAcme::Anything
\tAcme::Buffy
\tFurl
\tJSON
\tModule::Build
\tModule::CoreList
\tTest::Perl::Critic
EOS
};

done_testing;
