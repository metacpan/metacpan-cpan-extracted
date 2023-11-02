use v5.38;
use version;
use Test2::V0;

plan 13;

use CPANSEC::Admin::Command::Publish;
ok my $cmd = CPANSEC::Admin::Command::Publish->new, 'able to spawn obj';

ok my $ranges = CPANSEC::Admin::Command::Publish::split_version_range('<0.4, >= 1.2, != 1.5, < 2.0, == 3.1.4, >7'), 'split_version_range()';
is $ranges, { equal => ['1.2', '3.1.4'], greater => ['1.2', '7'], lower => ['0.4','2.0'], not_equal => ['1.5'] }, 'ranges parsed ok';

ok  CPANSEC::Admin::Command::Publish::version_in_range(version->parse('0.001'), $ranges), '0.001 is in range';
ok !CPANSEC::Admin::Command::Publish::version_in_range(version->parse('1.0'), $ranges), '1 is NOT in range';
ok  CPANSEC::Admin::Command::Publish::version_in_range(version->parse('1.2'), $ranges), '1.2 IS in range';
ok  CPANSEC::Admin::Command::Publish::version_in_range(version->parse('1.21'), $ranges), '1.2.0 IS in range';
ok  CPANSEC::Admin::Command::Publish::version_in_range(version->parse('1.499'), $ranges), '1.499 IS in range';
ok !CPANSEC::Admin::Command::Publish::version_in_range(version->parse('1.5'), $ranges), '1.5 is NOT in range';
ok  CPANSEC::Admin::Command::Publish::version_in_range(version->parse('1.51'), $ranges), '1.5.1 IS in range';
ok  CPANSEC::Admin::Command::Publish::version_in_range(version->parse('1.999_99'), $ranges), '1.999_99 IS in range';
ok !CPANSEC::Admin::Command::Publish::version_in_range(version->parse('3.1.3'), $ranges), '3.1.3 is NOT in range';
ok  CPANSEC::Admin::Command::Publish::version_in_range(version->parse('8'), $ranges), '8 is in range';