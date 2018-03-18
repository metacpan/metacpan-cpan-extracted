#!/usr/bin/env perl

use strict;
use warnings;

use App::Wax;
use Method::Signatures::Simple;
use Test::Differences qw(eq_or_diff);
use Test::More tests => 30;
use Test::TinyMocker qw(mock);

my @FILENAMES     = ('1.json', '2.html');
my @KEEP          = map { "/cache/file$_" } @FILENAMES;
my @TEMP          = map { "/tmp/file$_" } @FILENAMES;
my @URL           = map { "http://example.com/$_" } @FILENAMES;
my %FILENAME_TEMP = map { $URL[$_] => $TEMP[$_] } 0 .. $#FILENAMES;
my %FILENAME_KEEP = map { $URL[$_] => $KEEP[$_] } 0 .. $#FILENAMES;

func wax_ok ($args, $want) {
    # if $want isn't supplied, the caller expects an exception
    # to be thrown
    $want ||= 'ERROR';

    my $wax  = App::Wax->new();
    my @args = ref($args) ? @$args : split(/\s+/, $args);
    my @want = ref($want) ? @$want : split(/\s+/, $want);

    my $description = sprintf(
        '%s => %s',
        $wax->dump_command(\@args),
        $wax->dump_command(\@want)
    );

    my $got = $wax->run([ '--test', @args ]);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff $got, \@want, $description;
}

mock(
    'App::Wax::resolve',
    method ($url) {
        my $filename = $self->keep ? $FILENAME_KEEP{$url} : $FILENAME_TEMP{$url};
        my @resolved = ($filename, undef);

        return wantarray ? @resolved : \@resolved;
    }
);

######################## unit tests ###########################

{
    my $wax = App::Wax->new;
    my $user_agent = 'Testbot 1.0';
    $wax->user_agent($user_agent);
    is($wax->user_agent, $user_agent, 'get/set user agent');
}

######################## no downloads ###########################

wax_ok(
    'cmd foo bar baz',
    'cmd foo bar baz'
);

wax_ok(
    'cmd -foo -bar -baz',
    'cmd -foo -bar -baz'
);

wax_ok(
    'cmd --foo --bar --baz',
    'cmd --foo --bar --baz'
);

wax_ok(
    'cmd foo -bar --baz',
    'cmd foo -bar --baz'
);

######################## separator ###########################

# implicit default separator (no option): --
wax_ok(
    "cmd foo -bar --baz -- $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# explicit default separator (short option): --
wax_ok(
    "-s -- cmd foo -bar --baz -- $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# explicit default separator (long option): --
wax_ok(
    "--separator -- cmd foo -bar --baz -- $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# no separator (short option)
wax_ok(
    "-S cmd foo -bar -- $URL[0] --baz --quux",
    "cmd foo -bar -- $TEMP[0] --baz --quux"
);

# no separator (long option)
wax_ok(
    "--no-separator cmd foo -bar -- $URL[0] --baz --quux",
    "cmd foo -bar -- $TEMP[0] --baz --quux"
);

# custom separator (short option): short separator
wax_ok(
    "-s -X cmd foo -bar --baz -X $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): short separator
wax_ok(
    "--separator -X cmd foo -bar --baz -X $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (short option): long separator
wax_ok(
    "-s --no-wax cmd foo -bar --baz --no-wax $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): long separator
wax_ok(
    "--separator --no-wax cmd foo -bar --baz --no-wax $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (short option): lowercase word
wax_ok(
    "-s separator cmd foo -bar -- $URL[0] --baz separator $URL[0] --quux",
    "cmd foo -bar -- $TEMP[0] --baz $URL[0] --quux"
);

# custom separator (long option): lowercase word
wax_ok(
    "--separator separator cmd foo -bar -- $URL[0] --baz separator $URL[0] --quux",
    "cmd foo -bar -- $TEMP[0] --baz $URL[0] --quux"
);

# custom separator (short option): uppercase word
wax_ok(
    "-s SEPARATOR cmd foo -bar --baz SEPARATOR $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): uppercase word
wax_ok(
    "--separator SEPARATOR cmd foo -bar --baz SEPARATOR $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (short option): non-word
wax_ok(
    "-s :: cmd foo -bar --baz :: $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): non-word
wax_ok(
    "--separator :: cmd foo -bar --baz :: $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

######################## temp file ###########################

wax_ok(
    "cmd --foo $URL[0]",
    "cmd --foo $TEMP[0]"
);

wax_ok(
    "cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $TEMP[0] -bar --baz $TEMP[1]"
);

########################### cache ###########################

wax_ok(
    "-c cmd --foo $URL[0]",
    "cmd --foo $KEEP[0]"
);

wax_ok(
    "--cache cmd --foo $URL[0]",
    "cmd --foo $KEEP[0]"
);

wax_ok(
    "-c cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $KEEP[0] -bar --baz $KEEP[1]"
);

wax_ok(
    "--cache cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $KEEP[0] -bar --baz $KEEP[1]"
);

########################### mirror ###########################

wax_ok(
    "-m cmd --foo $URL[0]",
    "cmd --foo $KEEP[0]"
);

wax_ok(
    "--mirror cmd --foo $URL[0]",
    "cmd --foo $KEEP[0]"
);

wax_ok(
    "-m cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $KEEP[0] -bar --baz $KEEP[1]"
);

wax_ok(
    "--mirror cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $KEEP[0] -bar --baz $KEEP[1]"
);
