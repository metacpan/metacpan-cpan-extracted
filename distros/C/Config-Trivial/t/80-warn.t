#	$Id: 80-warn.t 62 2014-05-23 09:41:11Z adam $

use strict;
use Test;

my $run_tests;

BEGIN {
    $run_tests = eval { require IO::Capture::Stderr; };
    plan tests => 7
};

if (! $run_tests) {
    for(1 .. 7) { skip "IO::Capture::Stderr not installed, skipping test." }
    exit;
}

use Config::Trivial;
ok(1);

my $capture = IO::Capture::Stderr->new();

#
#	Test Warnings
#
my $config = Config::Trivial->new(debug => "on");
ok($config);

# duped keys, strict mode (3-5)
ok($config->set_config_file("./t/bad.data"));
$capture->start;
my $settings = $config->read();
$capture->stop;
ok(defined($settings->{test1}));
ok($capture->read =~ /WARNING: Duplicate key "test1" found in config file on line 5 at t.80-warn\.t line 32/);

# Missing File (6)
$capture->start;
$config->set_config_file("./t/file.that.is.not.there");
$capture->stop;
ok($capture->read =~ /File error: Cannot find \..t.file\.that\.is\.not\.there at t.80-warn\.t line 39/);

# Empty file, Strict mode (7)
$capture->start;
$config->set_config_file("./t/empty");
$capture->stop;
ok($capture->read =~ /File error: \..t.empty is zero bytes long at t.80-warn\.t line 45/);

exit;

__END__
