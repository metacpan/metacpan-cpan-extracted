use Test2::V0 -no_srand => 1;
use Alien::cargo;
use Env qw( @PATH );
use Capture::Tiny qw( capture );

push @PATH, Alien::cargo->bin_dir;

my($out, $err, $exit) = capture { system 'cargo', 'version' };

is $exit, 0, 'command returns success';
ok $out =~ /^cargo ([0-9\.]+)/, 'expected output';
is(Alien::cargo->version, $1, 'version matches');

diag '';
diag '';
diag '';

diag "version = @{[ Alien::cargo->version ]}";
diag "type    = @{[ Alien::cargo->install_type ]}";
diag "output  = @{[ $out ]}";
diag "bin_dir = $_" for Alien::cargo->bin_dir;

diag '';
diag '';

done_testing;


