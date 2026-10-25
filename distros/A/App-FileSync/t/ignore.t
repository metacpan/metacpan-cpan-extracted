use strict;
use warnings;
use Test::Most;

use App::FileSync::Ignore;

my $ignore = App::FileSync::Ignore->new(patterns => [
	'# a comment',
	'',
	'*.swp',
	'.DS_Store',
	'build/',
	'**/cache',
	'notes/*.txt',
	'!notes/keep.txt',
]);

ok($ignore->match('a.swp'), 'extension pattern matches at the root');
ok($ignore->match('deep/dir/a.swp'), 'extension pattern matches in a subdirectory');
ok(!$ignore->match('a.swp.bak'), 'pattern does not match a longer name');
ok($ignore->match('.DS_Store'), 'exact name matches');
ok($ignore->match('x/.DS_Store'), 'exact name matches in a subdirectory');

ok($ignore->match('cache'), '** matches at the root');
ok($ignore->match('a/b/cache'), '** matches deep');
ok($ignore->match('a/b/cache/file.txt'), '** prefix prunes the whole directory');

ok($ignore->match('notes/a.txt'), 'anchored pattern matches');
ok(!$ignore->match('notes/keep.txt'), 'negation re-includes');

ok(!$ignore->match('src/main.c'), 'ordinary file is not ignored');
ok(!$ignore->match('notes/deep/a.txt'), 'anchored pattern does not cross directories');

my $case = App::FileSync::Ignore->new(patterns => ['*.SWP'], case_insensitive => 1);
ok($case->match('file.swp'), 'case-insensitive matching');

my $sensitive = App::FileSync::Ignore->new(patterns => ['*.SWP']);
ok(!$sensitive->match('file.swp'), 'case-sensitive by default');

my $suffix = App::FileSync::Ignore->new(patterns => ['*~', '.#*', '#*#', '.filesync-tmp-*']);
ok($suffix->match('report.txt~'), 'trailing tilde');
ok($suffix->match('.#lockfile'), 'emacs lock file');
ok($suffix->match('#auto-save#'), 'emacs auto-save');
ok($suffix->match('.filesync-tmp-123-456'), 'our own temporary files');

done_testing();
