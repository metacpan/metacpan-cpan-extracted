#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib $FindBin::RealBin;

use File::Temp qw(tempdir);
use IPC::Run qw(run);
use Test::More 'no_plan';

use TestUtil;

my @full_script = get_full_script('org2ical');

{
    {
	my $success = run [@full_script], '2>', \my $stderr;
	ok !$success, 'usage (missing argument --ics-file)';
	like $stderr, qr{Please specify --ics-file};
	like $stderr, qr{usage:};
    }

    {
	my $success = run [@full_script, '--ics-file=something'], '2>', \my $stderr;
	ok !$success, 'usage (missing argument --todo-file)';
	like $stderr, qr{Please specify one or more --todo-file};
	like $stderr, qr{usage:};
    }

    {
	my $success = run [@full_script, '--unknown-option'], '2>', \my $stderr;
	ok !$success, 'usage (unknown option)';
	like $stderr, qr{Unknown option:};
	like $stderr, qr{usage:};
    }

    my $dir = tempdir("org2ical.t-XXXXXXXX", CLEANUP => 1);

    {
	open my $ofh, '>:encoding(utf-8)', "$dir/test.org" or die $!;
	print $ofh <<EOF;
* TODO normal date :tag: <9999-01-01 Fr 00:00>
  Initial details.
EOF
	close $ofh or die $!;
    }

    {
	my $success = run [@full_script, '--domain-id=example.org', "--todo-file=$dir/test.org", "--ics-file=$dir/test.ics"];
	ok $success, 'initial run';
    }

    my $original_ics_contents = my $ics_contents = slurp "$dir/test.ics";

    {
	# normalize stuff (e.g. prog version)
	$ics_contents =~ s{^(PRODID.*org2ical )[\d.]+(.*)}{$1."0.00".$2}e;
	$ics_contents =~ s{^(CREATED|DTSTAMP|LAST-MODIFIED):\d{8}T\d{6}Z$}{$1.":19700101T000000Z"}egm;

	is_deeply [split /\n/, $ics_contents], [split /\n/, <<EOF], 'expected ics contents after initial creation';
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:-//Slaven Rezic//NONSGML rezic.de org2ical 0.05//EN
BEGIN:VEVENT
UID:Blcatps/EWPbXGJBkLi7Iw\@example.org
DTSTART:99990101T000000
CREATED:19700101T000000Z
DTSTAMP:19700101T000000Z
LAST-MODIFIED:19700101T000000Z
SUMMARY:normal date
TRANSP:OPAQUE
BEGIN:VALARM
ACTION:DISPLAY
DESCRIPTION:Reminder
TRIGGER:-PT30M
UID:ALARM-Blcatps/EWPbXGJBkLi7Iw\@example.org
END:VALARM
END:VEVENT
END:VCALENDAR
EOF
    }

    {
	my $success = run [@full_script, '--domain-id=example.org', "--todo-file=$dir/test.org", "--ics-file=$dir/test.ics"];
	ok $success, 'run on existing .ics file, no changes';
	my $ics_contents = slurp "$dir/test.ics";
	is $original_ics_contents, $ics_contents, 'no changes on 2nd run';
    }

    {
	open my $ofh, '>:encoding(utf-8)', "$dir/test.org" or die $!;
	print $ofh <<EOF;
* TODO normal date :tag: <9999-01-01 Fr 00:00>
  Changes details.
EOF
	close $ofh or die $!;
    }

    {
	my $success = run [@full_script, '--domain-id=example.org', "--todo-file=$dir/test.org", "--ics-file=$dir/test.ics"];
	ok $success, 'run on existing .ics file, with changes';
	my $ics_contents = slurp "$dir/test.ics";
	is $original_ics_contents, $ics_contents, 'no changes in ics file (only details changed)';
    }

    {
	open my $ofh, '>:encoding(utf-8)', "$dir/test.org" or die $!;
	print $ofh <<EOF;
* TODO normal date :tag: <9999-01-02 Fr 00:00>
  A new date.
EOF
	close $ofh or die $!;
    }

    {
	my $success = run [@full_script, '--debug', '--domain-id=example.org', "--todo-file=$dir/test.org", "--ics-file=$dir/test.ics"], '>', \my $stdout, '2>', \my $stderr;
	ok $success, 'run on existing .ics file, changed date';
	my $ics_contents = slurp "$dir/test.ics";
	isnt $original_ics_contents, $ics_contents, 'changes in ics file';
	if ($stderr !~ m{but no diff available}) {
	    like $stdout, qr{^--- org2ical.t-.*/test.ics}, 'looks like a diff header';
	    like $stdout, qr{^-UID:Blcatps/EWPbXGJBkLi7Iw\@example.org}m, 'an expected diff line';
	}
    }

    {
	open my $ofh, '>:encoding(utf-8)', "$dir/test.org" or die $!;
	print $ofh <<EOF;
* TODO normal date :positivetag: <9999-01-01 Fr 00:00>
  Changes details.
EOF
	close $ofh or die $!;
    }

    for my $def (
	[["--include-tags", "doesnotexist"], 0 ],
	[["--include-tags", "positivetag"], 1 ],
	[["--exclude-tags", "doesnotexist"], 1 ],
	[["--exclude-tags", "positivetag"], 0 ],
    ) {
	my($tag_options, $match) = @$def;
	unlink "$dir/test.ics";
	my $success = run [@full_script, "--todo-file=$dir/test.org", "--ics-file=$dir/test.ics", @$tag_options];
	ok $success, "run with @$tag_options";
	my $ics_contents = slurp "$dir/test.ics";
	if ($match) {
	    like $ics_contents, qr{BEGIN:VEVENT}, "match for '@$tag_options' expected";
	} else {
	    unlike $ics_contents, qr{BEGIN:VEVENT}, "no match for '@$tag_options' expected";
	}
    }

}

__END__
