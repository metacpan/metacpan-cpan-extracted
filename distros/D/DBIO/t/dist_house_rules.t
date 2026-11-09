use strict;
use warnings;

use Test::More;

# The house rules load into every turn of every family session; their size is
# bounded, and what they hand off to skills has to be where they say it is.

sub slurp { open my $fh, '<', $_[0] or die "$_[0]: $!"; local $/; <$fh> }

my $rules = '.claude/rules/dbio-rules.md';
plan skip_all => "$rules not in this tree" unless -f $rules;

my $text = slurp($rules);
my $lines = () = $text =~ /\n/g;
cmp_ok $lines, '<=', 90, 'house rules stay within the 90-line house size';

my $live = slurp('.claude/skills/dbio-driver-development/references/live-testing.md');
like $live, qr/capped-test/, 'live-testing reference carries the capped-test rule';
like $live, qr/dev-dbio/,    'live-testing reference carries the maintainer infrastructure';
like $live, qr/^9\. /m,      'live-testing reference keeps rule 9';
like slurp('.claude/skills/dbio-driver-development/SKILL.md'),
  qr{references/live-testing\.md}, 'driver-development skill points at the live-testing reference';

like slurp('.claude/skills/dbio-perl-class-patterns/SKILL.md'),
  qr/Composition seams.*\n(?:.*\n)*.*an extension never determines the driver/,
  'class-patterns skill carries the composition-seams rule';
like slurp('.claude/skills/dbio-perl-release/SKILL.md'),
  qr/## Changes — the change, not the card/,
  'release skill carries the Changes rule';
unlike slurp('.claude/skills/dbio-coordination/SKILL.md'),
  qr/abandoned/i, 'every driver is a live driver: no abandoned-drivers rule';

for my $pointer (qw(driver-development perl-class-patterns perl-release coordination)) {
  like $text, qr/dbio-\Q$pointer\E/, "rules point at skill dbio-$pointer";
}

done_testing;
