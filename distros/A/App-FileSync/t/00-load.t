use strict;
use warnings;
use Test::Most;

use_ok('App::FileSync');
use_ok('App::FileSync::Admin');
use_ok('App::FileSync::Args');
use_ok('App::FileSync::Base');
use_ok('App::FileSync::CLI');
use_ok('App::FileSync::Client');
use_ok('App::FileSync::Config');
use_ok('App::FileSync::Constants');
use_ok('App::FileSync::Delta');
use_ok('App::FileSync::I18N');
use_ok('App::FileSync::I18N::en');
use_ok('App::FileSync::Ignore');
use_ok('App::FileSync::IO');
use_ok('App::FileSync::Lock');
use_ok('App::FileSync::Merge');
use_ok('App::FileSync::Platform');
use_ok('App::FileSync::Process');
use_ok('App::FileSync::Protocol');
use_ok('App::FileSync::Scan');
use_ok('App::FileSync::Server');
use_ok('App::FileSync::Settings');
use_ok('App::FileSync::Snapshot');
use_ok('App::FileSync::Store');
use_ok('App::FileSync::Transport::Local');
use_ok('App::FileSync::Transport::SSH');
use_ok('App::FileSync::Trash');
use_ok('App::FileSync::Verify');

# The named stat() fields must pick the same values as the numbers they
# replace, and must stay read-only without being tied (a tied scalar costs a
# method call on every read, and some are read once per file).
{
	use App::FileSync::Constants qw($STAT_MODE $STAT_SIZE $STAT_MTIME $MODE_MASK);

	my @stat = stat($0);
	is($stat[$STAT_SIZE], -s $0, '$STAT_SIZE picks the size');
	is($stat[$STAT_MTIME], (stat _)[9], '$STAT_MTIME picks the modification time');
	is($stat[$STAT_MODE] & $MODE_MASK, (stat _)[2] & oct('7777'), '$STAT_MODE picks the mode');

	for my $name (qw(STAT_MODE STAT_SIZE STAT_MTIME MODE_MASK)) {
		no strict 'refs';	## no critic (TestingAndDebugging::ProhibitNoStrict)
		my $ref = \${"App::FileSync::Constants::$name"};
		ok(!tied(${$ref}), "\$$name is not tied");
		throws_ok { ${$ref} = 0 } qr/read-?only/i, "\$$name cannot be changed";
	}
}

done_testing();
