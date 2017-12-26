#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use Encode qw(encode_utf8);
use Fcntl 'SEEK_SET';
use File::Temp qw(tempdir);
use Test::More;
use Time::Local qw(timelocal);
use POSIX qw(tzset);
BEGIN {
    if (!eval q{ use Time::Fake; 1 }) {
	plan skip_all => 'Time::Fake not available';
    }
}

my $can_tzset = $^O !~ m{^(MSWin32|cygwin)$};
if ($can_tzset) {
    $ENV{TZ} = 'Europe/Berlin'; tzset;
}

plan 'no_plan';

sub create_org_file ($);
sub test_seek ($$$);

require "$FindBin::RealBin/../bin/org-daemon";
pass 'required org-daemon';

{ # empty file
    my $tmp = create_org_file <<'EOF';
* org file without dates
EOF
    is_deeply [App::orgdaemon::find_dates_in_org_file($tmp->filename)], [], 'empty file';
}

my $epoch = timelocal(0,0,0,1,1-1,2016); # 2016-01-01 00:00:00
Time::Fake->offset($epoch);

{ # date in far past
    my $tmp = create_org_file <<'EOF';
* TODO normal date :tag: <2013-12-31 Fr 23:59>
EOF
    is_deeply [App::orgdaemon::find_dates_in_org_file($tmp->filename)], [], 'date in far past';
}

{ # timeless date in far past
    my $tmp = create_org_file <<'EOF';
* TODO normal date :tag: <2013-12-31 Fr>
EOF
    is_deeply [App::orgdaemon::find_dates_in_org_file($tmp->filename, include_timeless => 1)], [], 'timeless date in far past';
}

{ # fake a currently displayed and due date (somewhat complicated)
    my $tmp = create_org_file <<'EOF';
* TODO normal date :tag: <2015-12-31 Fr 23:59>
EOF
    my $date_id = '* TODO normal date :tag: <2015-12-31 Fr 23:59>|2015-12-31 Fr'; # strange id formatting...

    # First: simulate usage outside of org-daemon ---
    # in this case all due dates are returned.
    # Here find_dates_in_org_file should be used.
    {
	my @dates = App::orgdaemon::find_dates_in_org_file($tmp->filename);
	is scalar(@dates), 1;
    }

    no warnings 'redefine', 'once';

    # Second: simulate running Tk and date is not displayed
    {
	local $App::orgdaemon::window_for_date{$date_id};
	local *Tk::Exists = sub { $_[0] eq 'fake window id' };
	my @dates = App::orgdaemon::find_relevant_dates_in_org_file($tmp->filename);
	is scalar(@dates), 0;
    }

    # Third: simulate running Tk and date is currently displayed
    local $App::orgdaemon::window_for_date{$date_id} = 'fake window id';
    local *Tk::Exists = sub { $_[0] eq 'fake window id' };

    my @dates = App::orgdaemon::find_relevant_dates_in_org_file($tmp->filename);
    is scalar(@dates), 1;
    is $dates[0]->id, $date_id;
    is $dates[0]->state, 'due', 'date in past, but current display in a window faked...';
    is $dates[0]->date, '2015-12-31 Fr';
    is $dates[0]->date, $dates[0]->{date};
    is $dates[0]->date_of_date, '2015-12-31';
    is $dates[0]->time, '23:59';
    is $dates[0]->time, $dates[0]->{time};
    ok !$dates[0]->start_is_timeless;
    ok !$dates[0]->early_warning;
    is $dates[0]->file, $tmp->filename;
    is $dates[0]->file, $dates[0]->{file};
    is $dates[0]->line, 1;
    is $dates[0]->line, $dates[0]->{line};
    is_deeply [$dates[0]->tags], ['tag'], 'parsed tag';
    test_seek $tmp, $dates[0]->{seek}, '* TODO normal date :tag: <2015-12-31 Fr 23:59>';

    is_deeply [App::orgdaemon::find_dates_in_org_file($tmp->filename, ignore_tags => ['tag'])], [], 'matching ignore_tag';
    is_deeply [App::orgdaemon::find_dates_in_org_file($tmp->filename, ignore_tags => ['something_else'])], \@dates, 'non-matching ignore_tag';
}

{ # a normal date, neither due nor early warning
    my $tmp = create_org_file <<'EOF';
* TODO normal date :tag: <2016-01-02 Sa 0:00>
EOF
    my @dates = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    is scalar(@dates), 1;
    is $dates[0]->epoch, $epoch + 86400;
    is $dates[0]->epoch, $dates[0]->{epoch};
    is $dates[0]->text, '* TODO normal date :tag: <2016-01-02 Sa 0:00>';
    is $dates[0]->text, $dates[0]->{text};
    is $dates[0]->id, '* TODO normal date :tag: <2016-01-02 Sa 0:00>|2016-01-02 Sa'; # strange id formatting...
    is $dates[0]->formatted_text, 'normal date :tag: <2016-01-02 Sa 0:00>';
    is $dates[0]->date_of_date, "2016-01-02";
    is $dates[0]->time, '0:00';
    is $dates[0]->time, $dates[0]->{time};
    ok !$dates[0]->start_is_timeless;
    ok !$dates[0]->early_warning;
    is $dates[0]->early_warning_epoch, $epoch + 86400 - 30*60;
    is $dates[0]->state, 'wait';
    is $dates[0]->file, $tmp->filename;
    is $dates[0]->file, $dates[0]->{file};
    is $dates[0]->line, 1;
    is $dates[0]->line, $dates[0]->{line};
    is_deeply [$dates[0]->tags], ['tag'], 'parsed tag';
}

{ # a timeless date, neither due nor early warning
    my $tmp = create_org_file <<'EOF';
* TODO normal date :tag: <2016-01-02 Sa>
EOF
    my @dates = App::orgdaemon::find_dates_in_org_file($tmp->filename, include_timeless => 1);
    is scalar(@dates), 1;
    is $dates[0]->epoch, $epoch + 86400, 'timeless';
    is $dates[0]->text, '* TODO normal date :tag: <2016-01-02 Sa>';
    is $dates[0]->id, '* TODO normal date :tag: <2016-01-02 Sa>|2016-01-02 Sa'; # strange id formatting...
    is $dates[0]->formatted_text, 'normal date :tag: <2016-01-02 Sa>';
    is $dates[0]->date_of_date, "2016-01-02";
    ok !defined $dates[0]->time || !length $dates[0]->time;
    ok $dates[0]->start_is_timeless;
    is $dates[0]->state, 'early';
    is $dates[0]->line, 1;
    is_deeply [$dates[0]->tags], ['tag'], 'parsed tag';
}

{ # a timeless date, neither due nor early warning, with time_fallback set
    my $tmp = create_org_file <<'EOF';
* TODO normal date :tag: <2016-01-02 Sa>
EOF
    my @dates = App::orgdaemon::find_dates_in_org_file($tmp->filename, include_timeless => 1, time_fallback => "08:00");
    is scalar(@dates), 1;
    is $dates[0]->epoch, $epoch + 86400 + 8*3600, 'timeless with time_fallback';
    is $dates[0]->text, '* TODO normal date :tag: <2016-01-02 Sa>';
    is $dates[0]->id, '* TODO normal date :tag: <2016-01-02 Sa>|2016-01-02 Sa'; # strange id formatting...
    is $dates[0]->formatted_text, 'normal date :tag: <2016-01-02 Sa>';
    is $dates[0]->date_of_date, "2016-01-02";
    ok !defined $dates[0]->time || !length $dates[0]->time;
    ok $dates[0]->start_is_timeless;
    is $dates[0]->state, 'wait';
    is $dates[0]->line, 1;
    is_deeply [$dates[0]->tags], ['tag'], 'parsed tag';
}

{ # DONE items are ignored
    my $tmp = create_org_file <<'EOF';
* DONE normal date :tag: <2016-01-02 Sa 0:00>
EOF
    is_deeply [App::orgdaemon::find_dates_in_org_file($tmp->filename)], [], 'DONE dates are ignored';
}

{ # WONTFIX items are ignored
    my $tmp = create_org_file <<'EOF';
* WONTFIX normal date :tag: <2016-01-02 Sa 0:00>
EOF
    is_deeply [App::orgdaemon::find_dates_in_org_file($tmp->filename)], [], 'WONTFIX dates are ignored';
}

{ # missing weekday
    my $tmp_with = create_org_file <<'EOF';
* TODO weekday is optional <2016-01-01 Sa 0:15>
EOF
    my($date_with) = App::orgdaemon::find_dates_in_org_file($tmp_with->filename);

    my $tmp_without = create_org_file <<'EOF';
* TODO weekday is optional <2016-01-01 0:15>
EOF
    my($date_without) = App::orgdaemon::find_dates_in_org_file($tmp_without->filename);
    is $date_without->epoch, $date_with->epoch, 'weekday is optional';
}

{ # spaces do not matter
    my $tmp_with = create_org_file <<'EOF';
* TODO spaces do not matter <2016-01-01     Sa   0:15>
EOF
    my($date_with) = App::orgdaemon::find_dates_in_org_file($tmp_with->filename);

    my $tmp_without = create_org_file <<'EOF';
* TODO spaces do not matter <2016-01-01 Sa 0:15>
EOF
    my($date_without) = App::orgdaemon::find_dates_in_org_file($tmp_without->filename);
    is $date_without->epoch, $date_with->epoch, 'spaces do not matter';
}

{ # test early warning --- default early warning is set to 30*60s
    my $tmp = create_org_file <<'EOF';
* TODO early warning <2016-01-01 Sa 0:15>
EOF
    my($date) = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    is $date->state, 'early';
}

{ # early warning with individual date setting
    my $tmp = create_org_file <<'EOF';
** TODO Perl-Mongers-Treffen <2016-01-01 Sa 00:55 -60min>
EOF
    my($date) = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    is $date->state, 'early', 'modified early warning';
    is $date->early_warning, '-60min';
    is $date->early_warning_epoch, $epoch - 5*60;
}

{ # date with repeater and early warning
    my $tmp = create_org_file <<'EOF';
** TODO Perl-Mongers-Treffen <2016-01-01 Sa 00:55 +1m -60min>
EOF
    my($date) = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    is $date->state, 'early', 'modified early warning, ignored repeater';
    is $date->early_warning, '-60min';
}

{ # date not in first line (and also: leap day, and English weekday name)
    my $tmp = create_org_file <<'EOF';
* TODO normal date :tag:
  Some text.
  Now comes the date: <2016-02-29 Mon 00:00>
  More text.
* WAITING another date :tagfoo:tagbar:
  <2016-03-01 Tue 23:59>
EOF
    my @dates = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    is scalar(@dates), 2;
    is $dates[0]->date_of_date, '2016-02-29';
    is $dates[0]->formatted_text, 'normal date :tag:   Now comes the date: <2016-02-29 Mon 00:00>';
    is_deeply [$dates[0]->tags], ['tag'], 'parsed tag';
    test_seek $tmp, $dates[0]->{seek}, '* TODO normal date :tag:';
    is $dates[1]->date_of_date, '2016-03-01';
    is $dates[1]->formatted_text, 'another date :tagfoo:tagbar:   <2016-03-01 Tue 23:59>';
    is_deeply [$dates[1]->tags], ['tagfoo','tagbar'], 'parsed multiple tags';
    test_seek $tmp, $dates[1]->{seek}, '* WAITING another date :tagfoo:tagbar:';
}

{ # multi line item
    my $tmp = create_org_file <<'EOF';
** TODO multi-line item <2016-01-02 Sa 0:00>
   Blubber bla
   * foo bar
   * another item
   : some code
#+BEGIN_EXAMPLE
literal example
#+END_EXAMPLE
** TODO 2nd item  <2016-01-03 So 0:00>
EOF
    my @dates = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    like $dates[0]->formatted_text, qr{multi-line item};
    is   $dates[0]->date_of_date, '2016-01-02';
    is_deeply [$dates[0]->tags], [], 'tag-less item';
    test_seek $tmp, $dates[0]->{seek}, '** TODO multi-line item <2016-01-02 Sa 0:00>';
    like $dates[1]->formatted_text, qr{2nd item};
    is   $dates[1]->date_of_date, '2016-01-03';
    test_seek $tmp, $dates[1]->{seek}, '** TODO 2nd item  <2016-01-03 So 0:00>';
    is_deeply [$dates[1]->tags], [], 'another tag-less item';
}

{
    my $tmp = create_org_file encode_utf8(<<"EOF");
** TODO this contains utf-8: \x{20ac} <2016-01-02 Sa 0:00>
EOF
    my($date) = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    like $date->formatted_text, qr{this contains utf-8: \x{20ac}};
    test_seek $tmp, $date->{seek}, encode_utf8("** TODO this contains utf-8: \x{20ac} <2016-01-02 Sa 0:00>");
}

{
    my $tmp_en = create_org_file <<"EOF";
** TODO non-English weekdays <2016-01-07 Thu 0:00>
EOF
    my $tmp_hr = create_org_file encode_utf8(<<"EOF");
** TODO non-English weekdays <2016-01-07 \x{010C}et 0:00>
EOF
    my($date_en) = App::orgdaemon::find_dates_in_org_file($tmp_en->filename);
    my($date_hr) = App::orgdaemon::find_dates_in_org_file($tmp_hr->filename);
    is $date_hr->epoch, $date_en->epoch;
    like $date_hr->date, qr{^2016-01-07 \x{010C}et};
    is $date_hr->date_of_date, '2016-01-07';
}

{
    local $TODO = "does not work --- cannot switch encoding while reading from a scalar?";
    local $SIG{__WARN__} = sub {}; # cease warnings because of this problem
    my $tmp = create_org_file <<'EOF';
                      -*- coding: iso-8859-1 -*-
** TODO this contains latin1: הצü <2016-01-02 Sa 0:00>
EOF
    my($date) = App::orgdaemon::find_dates_in_org_file($tmp->filename);
    like $date->formatted_text, qr{this contains latin1: הצü};
}

{   # range with double dash
    my $tmp1 = create_org_file encode_utf8(<<"EOF");
** TODO range test <2016-01-02 Sa 0:00>--<2016-01-03 So 0:00>
EOF
    my @dates1 = App::orgdaemon::find_dates_in_org_file($tmp1->filename);
    is scalar(@dates1), 1, 'end date not separately parsed';
 SKIP: {
	skip "cannot set TZ", 1 if !$can_tzset;
	is $dates1[0]->epoch, 1451689200;
    }
    is $dates1[0]->date, '2016-01-02 Sa';
    is $dates1[0]->time, '0:00';
    is $dates1[0]->date_end, '2016-01-03 So';
    is $dates1[0]->time_end, '0:00';

    # range with single dash
    my $tmp2 = create_org_file encode_utf8(<<"EOF");
** TODO range test <2016-01-02 Sa 0:00>-<2016-01-03 So 0:00>
EOF
    my @dates2 = App::orgdaemon::find_dates_in_org_file($tmp2->filename);
    is scalar(@dates2), 1, 'end date not separately parsed';
    is $dates2[0]->epoch, $dates1[0]->epoch;
    is $dates2[0]->date, '2016-01-02 Sa';
    is $dates2[0]->time, '0:00';
    is $dates2[0]->date_end, '2016-01-03 So';
    is $dates2[0]->time_end, '0:00';
}

{   # timeless range
    my $tmp1 = create_org_file encode_utf8(<<"EOF");
** TODO range test <2016-01-02 Sa>--<2016-01-03 So>
EOF
    my @dates1 = App::orgdaemon::find_dates_in_org_file($tmp1->filename, include_timeless => 1);
    is scalar(@dates1), 1, 'end date not separately parsed, timeless variant';
 SKIP: {
	skip "cannot set TZ", 1 if !$can_tzset;
	is $dates1[0]->epoch, 1451689200;
    }
    is $dates1[0]->date, '2016-01-02 Sa';
    ok !defined $dates1[0]->time || !length $dates1[0]->time;
    is $dates1[0]->date_end, '2016-01-03 So';
    ok !defined $dates1[0]->time_end || !length $dates1[0]->time_end;
}

{ # slow emacs writes
    my $tmpdir = tempdir(CLEANUP => 1);
    my $tmpfile = "$tmpdir/test.org";
    if (fork == 0) {
	select undef,undef,undef,0.1;
	open my $ofh, '>', $tmpfile or die $!;
	print $ofh <<'EOF';
** TODO slow writing                <2016-01-02 Sa 0:00>
EOF
	close $ofh or die $!;
	exit 0;
    }
    my @warnings; local $SIG{__WARN__} = sub { push @warnings, @_ };
    my($date) = App::orgdaemon::find_dates_in_org_file($tmpfile);
    if (@warnings) {
	like $warnings[0], qr{NOTE: file '.*/test.org' probably vanished or is saved in this moment. Will retry again.};
    } else {
	diag 'No warnings seen. Slow fork?';
    }
    like $date->text, qr{slow writing};
}

{ # non-existent file (run rather last, as it's waiting for 1s)
    my $non_existent_file = '/tmp/non-existent-file/' . time . $$ . rand(1);
    {
	my @warnings; local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @dates = App::orgdaemon::find_dates_in_org_file($non_existent_file);
	like $warnings[-1], qr{Can't open \Q$non_existent_file\E:};
	is_deeply \@dates, [];
    }
    # we have slightly different code paths the 2nd time
    {
	my @warnings; local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @dates = App::orgdaemon::find_dates_in_org_file($non_existent_file);
	like $warnings[-1], qr{Can't open \Q$non_existent_file\E:};
	is_deeply \@dates, [];
    }    
}


sub create_org_file ($) {
    my $contents = shift;
    my $tmp = File::Temp->new(SUFFIX => '.org');
    $tmp->print($contents);
    $tmp->close;
    $tmp;
}

# expected_line should be octets
sub test_seek ($$$) {
    my($tmp, $seek_pos, $expected_line) = @_;
    open my $fh, "$tmp" or die "Can't open $tmp: $!";
    seek $fh, $seek_pos, SEEK_SET or die "Can't seek: $!";
    chomp(my $got_line = <$fh>);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is $got_line, $expected_line;
}

__END__
