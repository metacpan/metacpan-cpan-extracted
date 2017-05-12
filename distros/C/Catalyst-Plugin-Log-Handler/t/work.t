#!perl
use strict;
use warnings;
#
# This test verifies that all log level functions work correctly.
#

use Test::More;
use constant LEVELS => qw(debug info warn error fatal);


{
    package Catalyst::Plugin::Log::Handler::Test;
    use base qw(Catalyst::Plugin::Log::Handler Class::Accessor::Fast);

    __PACKAGE__->mk_accessors(qw(log config));

}

my $c = Catalyst::Plugin::Log::Handler::Test->new();

my $testfn = "t/log-handler-test-$$-" . time();
END { unlink($testfn) if defined ($testfn); }

$c->config( {
   'Log::Handler' => {
      filename => $testfn,
      mode => 'append',
      newline => 1,
   },
});

$c->setup();

for my $level (LEVELS) {
   $c->log->$level("This is a $level test message.");
}

$c->log->handler->crit('This is a crit test message.');

my $logtext = do {
    local $/; open FH, '<', $testfn or die "open: $testfn: $!"; <FH> };
defined $logtext or die "read: $testfn: $!";

my $numberlevels = () = LEVELS;

plan (tests => 2 + 2 * $numberlevels);

my $numberlines = () = $logtext =~ /^.+$/gm;

ok (1 + $numberlevels == $numberlines, 'newlines');

for my $level (LEVELS, 'crit') {
    ok($logtext =~ /This is a \Q$level\E test message/, $level);
}

# For now I don't test that is_stuff actually returns the right thing
# (especially if some levels are disabled), merely I just want to see
# if all the dynamic sub generation worked.
for my $level (LEVELS) {
    my $is_method = "is_$level";
    ok($c->log->$is_method, $is_method);
}
