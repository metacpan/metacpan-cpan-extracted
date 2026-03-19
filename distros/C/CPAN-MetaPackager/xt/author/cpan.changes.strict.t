use Test::More;
use Test::Changes::Strict::Simple qw(changes_strict_ok);

changes_strict_ok(changes_file => 'Changes', module_version => '1.00');
done_testing;
