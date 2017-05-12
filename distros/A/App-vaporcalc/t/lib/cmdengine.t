use Test::Modern;
use strict; use warnings FATAL => 'all';

use Lowu 'array';

use App::vaporcalc::CmdEngine;
use App::vaporcalc::Recipe;

my $cmdeng;
# if we have 'missing _subject' or suchlike warnings for stale command
# modules, they should show up during construction:
diag warnings { $cmdeng = App::vaporcalc::CmdEngine->new };

ok $cmdeng->does('App::vaporcalc::Role::UI::ParseCmd'),
  'does Role::UI::ParseCmd';
ok $cmdeng->does('App::vaporcalc::Role::UI::PrepareCmd'),
  'does Role::UI::PrepareCmd';

my @subject_consistency_chk = (
  'help',
  'recipe',
  'target amount',
  'flavor',
  'nic base',
  'nic target',
  'nic type',
  'pg',
  'vg',
  'notes',
);

for my $subj (@subject_consistency_chk) {
  ok $cmdeng->subject_list->has_any(sub { $_ eq $subj }),
    "subject_list has $subj";
}

my $diff = array(@subject_consistency_chk)->diff($cmdeng->subject_list);
if ($diff->has_any) {
  diag
    "Note; did find unknown-to-us command subjects;\n".
    " probably not alarming:\n".
    $diff->map(sub { "'$_'" })->join("\n")
} else {
  diag "Did not find any unknown-to-us command subjects"
}

diag warnings { $cmdeng->rebuild_subject_list };
for my $subj (@subject_consistency_chk) {
  ok $cmdeng->subject_list->has_any(sub { $_ eq $subj }),
    "subject_list has $subj after rebuild";
}


done_testing
