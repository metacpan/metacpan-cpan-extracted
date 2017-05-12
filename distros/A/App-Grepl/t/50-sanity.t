#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More 'no_plan';    # tests => 1;
my $can_capture_output;

BEGIN {
    eval "use Test::Output";
    $can_capture_output = $@ ? 0 : 1;
}
my $SKIP_REASON = 'Test::Output needed to test STDERR and STDOUT';
use App::Grepl;

my $grepl = App::Grepl->new;
can_ok $grepl, 'warnings';
ok !$grepl->warnings, '... and by default they should be off';
ok $grepl->warnings(1), '... and we should be able to enable them';
ok $grepl->warnings, '... and now they should be on';
ok $grepl->warnings(0), '... and we should be able to disable them';
ok !$grepl->warnings, '... and now they should be off';

{
    no warnings 'redefine', 'once';
    local *PPI::Document::new = sub { };

    # for some reason, PPI happily attempts to parse this file
    $grepl = App::Grepl->new(
        {
            files    => 't/lib/ruby.rb',
            warnings => 1
        }
    );
    SKIP: {
        skip $SKIP_REASON, 1 unless $can_capture_output;
        stderr_is(
            sub { $grepl->search },
            "Cannot create a PPI document for (t/lib/ruby.rb).  Skipping.\n",
            'We should be able to warn if we cannot create a PPI doc'
        );
    }
}

# new block so that PPI::Document->new is restored
$grepl = App::Grepl->new(
    {
        files    => 't/lib/quotes/quote1.pl',
        look_for => 'comment',
    }
);
SKIP: {
    skip $SKIP_REASON, 1 unless $can_capture_output;
    my $stdout = qr/quote1.pl\n.*comment.*matched.*\n.*perl/;
    stdout_like( sub { $grepl->search },
        $stdout,
        'We should be able to print output if search in void context' );
}
