#!/usr/bin/env perl

use strict;
use warnings;

use App::Wax;
use Method::Signatures::Simple;
use Test::Differences qw(eq_or_diff);
use Test::Fatal qw(exception);
use Test::More tests => 21;
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

    my $wax         = App::Wax->new();
    my @args        = ref($args) ? @$args : split(/\s+/, $args);
    my @want        = ref($want) ? @$want : split(/\s+/, $want);
    my $description = sprintf '%s => %s', $wax->render(\@args), $wax->render(\@want);
    my $got         = $wax->run([ '--test', @args ]);

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

wax_ok(
    "-s --no-wax cmd foo -bar --baz --no-wax $URL[0]",
    "cmd foo -bar --baz $URL[0]"
);

wax_ok(
    "--separator --no-wax cmd foo -bar --baz --no-wax $URL[0]",
    "cmd foo -bar --baz $URL[0]"
);

wax_ok(
    "-s :: cmd foo -bar --baz :: $URL[0]",
    "cmd foo -bar --baz $URL[0]"
);

wax_ok(
    "--separator :: cmd foo -bar --baz :: $URL[0]",
    "cmd foo -bar --baz $URL[0]"
);

wax_ok(
    "-s SEPARATOR cmd foo -bar --baz SEPARATOR $URL[0]",
    "cmd foo -bar --baz $URL[0]"
);

wax_ok(
    "--separator SEPARATOR cmd foo -bar --baz SEPARATOR $URL[0]",
    "cmd foo -bar --baz $URL[0]"
);

# confirm `--` is no longer the default separator
wax_ok(
    "cmd foo -bar --baz -- $URL[0]",
    "cmd foo -bar --baz -- $TEMP[0]"
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
