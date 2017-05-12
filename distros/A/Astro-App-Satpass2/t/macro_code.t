package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test::App;	# For environment clean-up

use Astro::App::Satpass2;
use Astro::App::Satpass2::Utils ();
use Astro::App::Satpass2::Macro::Code;
use Test::More 0.88;	# Because of done_testing();

use constant LIB_DIR => 'eg';

-d LIB_DIR
    or plan skip_all => "Can not find @{[ LIB_DIR ]}/ directory";

my ( $mac, $sp );

eval {
    $sp = Astro::App::Satpass2->new();
    $sp->set(
	location	=> '1600 Pennsylvania Ave NW Washington DC 20502',
	latitude	=> 38.898748,
	longitude	=> -77.037684,
	height		=> 16.68,
    );
    1;
} or plan skip_all => "Can not instantiate Satpass2: $@";

eval {
   $mac = Astro::App::Satpass2::Macro::Code->new(
	lib		=> LIB_DIR,
	relative	=> 1,
	name		=> 'My::Macros',
	generate	=> \&Astro::App::Satpass2::_macro_load_generator,
	parent	=> $sp,
	warner	=> $sp->{_warner},	# TODO Encapsulation violation
    );
    1;
} or plan skip_all => "Can not instantiate macro: $@";

cmp_ok scalar $mac->implements(), '==', 5, 'Module implements 5 macros';

ok $mac->implements( 'after_load' ), 'Module implements after_load()';

ok $mac->implements( 'angle' ), 'Module implements angle()';

ok $mac->implements( 'dumper' ), 'Module implements dumper()';

ok $mac->implements( 'hi' ), 'Module implements hi()';

ok $mac->implements( 'test' ), 'Module implements test()';

is $mac->generator(), <<'EOD', 'Module serializes correctly';
macro load -lib eg -relative My::Macros after_load
macro load -lib eg -relative My::Macros angle
macro load -lib eg -relative My::Macros dumper
macro load -lib eg -relative My::Macros hi
macro load -lib eg -relative My::Macros test
EOD

is $mac->generator( 'angle' ), <<'EOD', 'Single macro serializes';
macro load -lib eg -relative My::Macros angle
EOD

is $mac->execute( hi => 'sailor' ), <<'EOD', q{Macro 'hi' executes};
Hello, sailor!
EOD

eval {
    is $mac->execute(
        qw{ angle -places 2 sun moon 20130401T120000Z } ),
	<<'EOD', q{Macro 'angle' executes with command options};
112.73
EOD
    1;
} or diag "Macro 'angle' failed: $@";

eval {
    is $mac->execute(
	angle => { places => 3 }, qw{ sun moon 20130401T120000Z } ),
	<<'EOD', q{Macro 'angle' executes with hash ref options};
112.727
EOD
    1;
} or diag "Macro 'angle' failed: $@";

{
    my $warning = '';

    local $SIG{__WARN__} = sub {
	$warning = $_[0];
	return;
    };

    my $msg = 'By the pricking of my thumbs';

    $mac->whinge( $msg );

    like $warning, qr/ \A \Q$msg\E /smx, 'Whinge';
}

{
    local $@ = '';

    my $msg = 'Something wicked this way comes';

    eval {
	$mac->wail( $msg );
    };

    like $@, qr/ \A \Q$msg\E /smx, 'Wail';

    $msg = 'Open locks, whoever knocks';

    eval {
	$mac->weep( $msg );
    };

    like $@, qr/ \A \QProgramming Error - $msg\E /smx, 'Weep';

}

done_testing;

1;

# ex: set textwidth=72 :
