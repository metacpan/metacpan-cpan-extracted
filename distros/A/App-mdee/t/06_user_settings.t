use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));

use File::Temp qw(tempdir);

use lib '.';
use t::Util;
use lib 't/runner';
use Runner qw(get_path);

# ansicolumn and ansifold are called as functions by the md module,
# and the rc files of the user must not change their output.  The
# module names them in GETOPTEX_NO_USER_SETTINGS (Getopt::EX >= 3.05).

delete $ENV{GETOPTEX_NO_USER_SETTINGS};
$ENV{HOME} = tempdir(CLEANUP => 1);

my %rc = (
    ansifold   => "option default --padding --padchar=%\n",
    ansicolumn => "option default --table-cell-mark=X\n",
);
for my $prog (sort keys %rc) {
    my $path = "$ENV{HOME}/.${prog}rc";
    open my $fh, '>', $path or die "$path: $!\n";
    print $fh $rc{$prog};
    close $fh;
}

my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; s/\e\]8;;[^\e]*\e\\//g; $_ };

# control: the rc files take effect when the commands run by themselves
{
    my $ansifold = get_path('ansifold', 'App::ansifold');
    my $out = `echo a quick brown fox jumps over the lazy dog | $^X $ansifold -w 20`;
    like($out, qr/%{3}/, 'control: .ansifoldrc pads the folded lines');

    my $ansicolumn = get_path('ansicolumn', 'App::ansicolumn');
    my $table = "| a | b |\n| - | - |\n| 1 | a quick brown fox jumps |\n";
    $out = `printf '%s' '$table' | $^X $ansicolumn -s '|' -t -w 16 --table-head 2`;
    like($out, qr/X/, 'control: .ansicolumnrc marks the table cells');
}

# folded list items are not padded
{
    my $out = $strip->(run("'-Mmd::config(colorize=0,foldlist=1,foldwidth=30)' t/test.md")->stdout);
    my @long = grep { /^- Third item/ } split /\n/, $out;
    ok(@long, 'the long item is still there');
    ok((grep { length($_) <= 30 } split /\n/, $out) > 5, 'items are folded');
    unlike($out, qr/%{3}/, 'folded lines are not padded by .ansifoldrc');
}

# wrapped table cells are not marked
{
    my $out = $strip->(run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40)' t/table_wrap.md")->stdout);
    like($out, qr/\x{253C}/, 'the table is formatted');
    unlike($out, qr/^\s*\x{2502}?\s*X/m, 'cells are not marked by .ansicolumnrc');
}

# the names are added to the variable, existing ones are kept
{
    require App::Greple::md;
    for my $case (
	[ undef,                 'ansicolumn ansifold' ],
	[ '',                    'ansicolumn ansifold' ],
	[ 'sdif',                'sdif ansicolumn ansifold' ],
	[ 'ansifold,cdif',       'ansifold,cdif ansicolumn' ],
	[ '1',                   '1' ],
	[ '*',                   '*' ],
    ) {
	my($in, $want) = @$case;
	local $ENV{GETOPTEX_NO_USER_SETTINGS} = $in;
	delete $ENV{GETOPTEX_NO_USER_SETTINGS} unless defined $in;
	App::Greple::md::no_user_settings(qw(ansicolumn ansifold));
	is($ENV{GETOPTEX_NO_USER_SETTINGS}, $want,
	   sprintf("no_user_settings: %s", $in // 'undef'));
    }
}

done_testing;
