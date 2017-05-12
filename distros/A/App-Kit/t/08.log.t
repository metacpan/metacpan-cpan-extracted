use Test::More;
use Capture::Tiny;

use App::Kit;

diag("Testing log() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

ok( !exists $INC{'Log/Dispatch.pm'}, 'lazy under pinning not loaded before' );
isa_ok( $app->log, 'Log::Dispatch' );
ok( exists $INC{'Log/Dispatch.pm'}, 'lazy under pinning loaded after' );

my $info = Capture::Tiny::capture_merged(
    sub {
        $app->log->notice("Your information here.");
    }
);

my $msg = qr/\A#   \xe3\x8f\x92\xc2\xa0. \d{4}-\d{2}-\d{2}\xc2\xa0\d{2}:\d{2}:\d{2} /;

like( $info, qr/$msg Your information here.\n\z/, 'msg format is correct' );
is( $info =~ m/\xc2\xa0(.)/ ? "$1" : undef, "N", "sanity: test does match" );

is( $app->log->debug("debug level 0"), undef, 'default debug() is not active' );
is( $app->log->info("debug level 1"),  undef, 'default info() is not active' );

my %levels = (
    debug     => { level => 0, short => "D" },
    info      => { level => 1, short => "I" },
    notice    => { level => 2, short => "N" },
    warning   => { level => 3, short => "W" },
    warn      => { level => 4, short => "W" },
    error     => { level => 4, short => "E" },
    err       => { level => 4, short => "E" },
    critical  => { level => 5, short => "C" },
    crit      => { level => 5, short => "C" },
    alert     => { level => 6, short => "A" },
    emergency => { level => 7, short => "M" },
    emerg     => { level => 7, short => "M" },
);

for my $level ( sort { $levels{$a}->{level} <=> $levels{$b}->{level} } keys %levels ) {
    next if $level eq 'debug' || $level eq 'info';

    my $ret;
    my $out = Capture::Tiny::capture_merged(
        sub {
            $ret = $app->log->$level("$level(), level $levels{$level}->{level}");
        }
    );

    is( $ret, '', "default $level() is on" );
    like( $out, qr/$msg $level\(\), level $levels{$level}->{level}\n\z/, 'msg format is correct' );
    is( $out =~ m/\xc2\xa0(.)/ ? "$1" : undef, $levels{$level}->{short}, "$level() type tag is $levels{$level}->{short}" );
}

$app->log->{outputs}{_anon_0}{min_level} = 0;    # eek, patches welcome

for my $level ( 'debug', 'info' ) {
    my $ret;
    my $out = Capture::Tiny::capture_merged(
        sub {
            $ret = $app->log->$level("$level(), level $levels{$level}->{level}");
        }
    );

    is( $ret, '', 'default $level() is on' );
    like( $out, qr/$msg $level\(\), level $levels{$level}->{level}\n\z/, 'msg format is correct' );
    is( $out =~ m/\xc2\xa0(.)/ ? "$1" : undef, $levels{$level}->{short}, "$level() type tag is $levels{$level}->{short}" );
}

done_testing;
