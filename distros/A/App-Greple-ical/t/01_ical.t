use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Time::Local qw(timegm);

##
## End-to-end test with a fake Calendar.sqlitedb under a temporary
## HOME directory.
##

chomp(my $sqlite3 = `sh -c 'command -v sqlite3' 2>/dev/null` // '');
plan skip_all => 'sqlite3 not available' unless $sqlite3;

chomp(my $greple = `sh -c 'command -v greple' 2>/dev/null` // '');
plan skip_all => 'greple not available' unless $greple;

my $home = tempdir(CLEANUP => 1);
my $dir = File::Spec->catdir($home, 'Library', 'Group Containers',
			     'group.com.apple.calendar');
make_path($dir) or die "make_path: $!";
my $db = File::Spec->catfile($dir, 'Calendar.sqlitedb');

# Core Data epoch (2001-01-01) offset from Unix epoch
use constant CD_EPOCH => 978307200;
sub cd { timegm(0, 0, $_[3] // 12, $_[2], $_[1] - 1, $_[0]) - CD_EPOCH }

my $sql = <<END;
CREATE TABLE CalendarItem (
    summary TEXT, description TEXT,
    start_date REAL, end_date REAL, all_day INTEGER, location_id INTEGER
);
CREATE TABLE Location (title TEXT);
INSERT INTO Location (title) VALUES ('Theater X');
INSERT INTO CalendarItem VALUES
    ('MOVIE: foo bar', NULL,        @{[cd(2026,1,2)]}, @{[cd(2026,1,2,14)]}, 0, 1),
    ('MOVIE: baz',    'good movie', @{[cd(2026,2,3)]}, @{[cd(2026,2,3,14)]}, 0, NULL),
    ('other event',    NULL,        @{[cd(2026,3,4)]}, @{[cd(2026,3,5)]},    1, NULL);
END

do {
    open my $fh, '|-', $sqlite3, $db or die "sqlite3: $!";
    print $fh $sql;
    close $fh or die "sqlite3 failed";
};

local $ENV{HOME} = $home;
local $ENV{PERL5LIB} = join ':', File::Spec->rel2abs('lib'), $ENV{PERL5LIB} // ();
delete local $ENV{GREPLEOPTS};

sub run_greple {
    my @cmd = ($^X, '-S', 'greple', @_);
    my $pid = open my $fh, '-|';
    defined $pid or die "fork: $!";
    if ($pid == 0) {
	open STDERR, '>&', \*STDOUT;
	exec @cmd or die "exec: $!";
    }
    local $/;
    my $out = <$fh>;
    close $fh;
    $out;
}

my $out = run_greple(qw(-Mical MOVIE --simple));
like($out, qr{^2026/01/02 .*MOVIE: foo bar.*\@\[Theater X\]$}m, 'simple: summary with location');
like($out, qr{^2026/02/03 .*MOVIE: baz\*$}m, 'simple: description mark');
unlike($out, qr{other event}, 'simple: unmatched event not printed');

$out = run_greple(qw(-Mical MOVIE --color=never));
like($out, qr{SUMMARY:MOVIE: foo bar}, 'default: VEVENT format');
like($out, qr{LOCATION:Theater X}, 'default: location line');

$out = run_greple(qw(-Mical MOVIE --detail --color=never));
like($out, qr{^2026/02/03 .*MOVIE: baz\*\nDESCRIPTION:good movie$}m, 'detail: description body');

done_testing;
