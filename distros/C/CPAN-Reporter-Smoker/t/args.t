use strict;
use warnings;

use Test::More 0.62;

use Config;
use File::Spec;
use lib 't/lib';
use DotDirs;
use IO::CaptureOutput 1.06 qw/capture/;

my @good_args = (
    {
        label => "no args",
        args => [],
    },
    {
        label => "clean_cache_after",
        args => [ clean_cache_after => 10 ],
    },
    {
        label => "restart_delay",
        args => [ restart_delay => 30],
    },
    {
        label => "set_term_title",
        args => [ set_term_title => 0 ],
    },
    {
        label => "status_file - dir/file",
        args => [ status_file => File::Spec->catfile( File::Spec->tmpdir, 'foo.txt') ],
    },
    {
        label => "status_file - bare filename",
        args => [ status_file => 'foo.txt' ],
    },
    {
        label => "reverse",
        args => [ 'reverse' => 1 ],
    },
    {
        label => "force_trust",
        args => [ 'force_trust' => 1 ],
    },
    {
        label => "skip_dev_versions",
        args => [ 'skip_dev_versions' => 1 ],
    },
    {
        label => "filter",
        args => [ 'filter' => sub {} ],
    },
    {
        label => "random",
        args => [ 'random' => 1 ],
    },
    {
        label => "_hook_after_test",
        args => [ 'filter' => sub {} ],
    },
);

my @bad_args = (
    {
        label => "args not % 2",
        args => [ 30 ],
    },
    {
        label => "clean_cache_after alpha",
        args => [ clean_cache_after => 'abc' ],
    },
    {
        label => "clean_cache_after negative",
        args => [ clean_cache_after => '-1' ],
    },
    {
        label => "clean_cache_after mixed alphanum",
        args => [ clean_cache_after => 'abc 123' ],
    },
    {
        label => "restart_delay with alpha",
        args => [ restart_delay => 'abc'],
    },
    {
        label => "set_term_title with alpha",
        args => [ set_term_title => 'y' ],
    },
    {
        label => "set_term_title with 2",
        args => [ set_term_title => 2 ],
    },
    {
        label => "status_file",
        args => [ status_file => 'slakjdflaksjdfkds/foo.txt' ],
    },
    {
        label => "reverse",
        args => [ 'reverse' => 2 ],
    },
    {
        label => "force_trust",
        args => [ 'force_trust' => 2 ],
    },
    {
        label => "filter",
        args => [ 'filter' => 'test' ],
    },
    {
        label => "_hook_after_test",
        args => [ 'filter' => 'test' ],
    },
);

plan tests =>  1 + 2 * ( @good_args + @bad_args );

#--------------------------------------------------------------------------#
# Setup test environment
#--------------------------------------------------------------------------#

# Setup CPAN::Reporter configuration and add mock lib path to @INC
$ENV{PERL_CPAN_REPORTER_DIR} = DotDirs->prepare_cpan_reporter;

# Setup CPAN dotdir with custom CPAN::MyConfig
DotDirs->prepare_cpan;

my ($stdout, $stderr);

#--------------------------------------------------------------------------#
# tests begin here
#--------------------------------------------------------------------------#

use_ok( 'CPAN::Reporter::Smoker' );

local $ENV{PERL_CR_SMOKER_SHORTCUT} = 1; # don't run at all, just check args

for my $c ( @good_args ) {
    my $rc = eval { capture { start( @{$c->{args}} ) } \$stdout, \$stderr };
    my $err = $@;
    is( $rc, 1, "$c->{label}: start() successful" );
    unlike( $err, qr/Invalid arguments? to start/, 
        "$c->{label}: no error message");
}

for my $c ( @bad_args ) {
    my $rc = eval { capture { start( @{$c->{args}} ) } \$stdout, \$stderr };
    my $err = $@;
    ok( ! $rc, "$c->{label}: start() failed" );
    like( $err, qr/Invalid arguments? to start/, 
        "$c->{label}: saw error message");
}

