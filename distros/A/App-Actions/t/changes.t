use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec;
use Readonly;
use Test::Most;

use App::Actions;

# The Changes file is what CPAN shows as the release notes, and what a
# packager reads to learn what moved.  Test::CPAN::Changes wants W3CDTF dates;
# this distribution writes the date as date(1) prints it, so the shape is
# checked here instead: a header, then each release as its version, a tab and
# its date, followed by tab-indented "- " items.

Readonly::Scalar my $FILE   => File::Spec->catfile(dirname(__FILE__), '..', 'Changes');
Readonly::Scalar my $HEADER => qr/\ARevision history for App-Actions\b/;

# A release line: the version, then (once released) a tab and the date.
Readonly::Scalar my $RELEASE => qr/\A(\d+\.\d+\.\d+)(?:\t(.*))?\z/;

# The date as date(1) prints it in an English locale, with or without AM/PM,
# for example "Thu Oct 22 12:40:02 PM EDT 2026".
Readonly::Scalar my $DATE => qr{
	\A (?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)
	\x20 (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
	\x20{1,2} (\d{1,2})
	\x20 \d{1,2}:\d{2}:\d{2} (?:\x20[AP]M)?
	\x20 [A-Z]{2,5}
	\x20 (\d{4}) \z
}x;

Readonly::Hash my %MONTH => (
	Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
	Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12,
);

# The first line of an item, and a line that continues one.
Readonly::Scalar my $ITEM         => qr/\A\t- \S/;
Readonly::Scalar my $CONTINUATION => qr/\A\t  \S/;

open my $fh, '<', $FILE or BAIL_OUT("Unable to read '$FILE': $!");
my @lines = <$fh>;
close $fh;
# A CRLF checkout (git with core.autocrlf, as on Windows) ends each line in
# \r\n; chomp would leave the \r behind.
s/\r?\n\z// for @lines;

like($lines[0], $HEADER, 'Changes starts with its header');

# Each release with the line its heading is on, its date, and its items.
my (@releases, @stray);
for my $number (1 .. $#lines) {
	my $line = $lines[$number];
	next unless length $line;

	if ($line =~ $RELEASE) {
		push @releases, { version => $1, date => $2, line => $number + 1, items => 0 };
	} elsif (@releases && $line =~ $ITEM) {
		$releases[-1]{items}++;
	} elsif (!(@releases && $releases[-1]{items} && $line =~ $CONTINUATION)) {
		push @stray, $number + 1;
	}
}

ok(scalar @releases, 'Changes lists at least one release') or BAIL_OUT('no releases in Changes');
is_deeply(\@stray, [], 'every line is a release, a "- " item or the continuation of one')
	or diag("lines not in that shape: @stray");
is_deeply([ grep { $lines[$_ - 1] =~ /[ \t]\z/ } 1 .. @lines ], [], 'no line ends in white space');

is($releases[0]{version}, $App::Actions::VERSION, 'the newest release is the version in the modules');

for my $release (@releases) {
	ok($release->{items}, "$release->{version} says what changed");
}

# version.pm reads "0.002.0" as the dotted 0.2.0, so the comparison follows
# the numbers rather than the strings.
for my $index (1 .. $#releases) {
	my ($newer, $older) = @releases[$index - 1, $index];
	ok(version->parse($newer->{version}) > version->parse($older->{version}),
		"$newer->{version} is listed above the older $older->{version}");
}

# The newest entry is dated by hand when it is released to CPAN, so until
# then it may be undated.  Every older one has been released and carries
# its date.
for my $index (0 .. $#releases) {
	my $release = $releases[$index];
	if (!defined $release->{date}) {
		ok($index == 0, "$release->{version} is dated, or is the newest release")
			or diag("set the date of $release->{version} (line $release->{line}): only the newest release may be undated");
		next;
	}
	like($release->{date}, $DATE, "$release->{version} has a date in the form date(1) prints");
}

# Dates must not go backwards: a newer release cannot be older than the one
# below it.
my @dated = map {
	my @part = defined $_->{date} ? $_->{date} =~ $DATE : ();
	@part ? { version => $_->{version}, day => sprintf('%04d-%02d-%02d', $part[2], $MONTH{ $part[0] }, $part[1]) } : ()
} @releases;
for my $index (1 .. $#dated) {
	my ($newer, $older) = @dated[$index - 1, $index];
	ok($newer->{day} ge $older->{day}, "$newer->{version} ($newer->{day}) is no older than $older->{version} ($older->{day})");
}

done_testing();
