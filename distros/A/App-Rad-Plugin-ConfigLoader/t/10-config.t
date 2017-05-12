use FindBin;
my $path = $FindBin::RealBin . '/etc';
use Test::More tests => 5;

use App::Rad;

# kids, don't try this at home...
my $c = {};
bless $c, 'App::Rad';
$c->_init();

use Config::Any;

#-> teste cada plugin e faca skip se o plugin nao estiver instalado
my %has = ();
foreach ( Config::Any->extensions ) {
    if ($_ eq 'yml') {
        $has{'yaml'} = 1;
    }
    elsif ($_ eq 'xml') {
        $has{'xml'} = 1;
    }
    elsif ($_ eq 'ini') {
        $has{'ini'} = 1;
    }
}

SKIP: {
    skip 'No YAML plugin detected', 2 unless $has{'yaml'};

    $c->load_config("$path/config1.yml");
    $c->load_config("$path/config1.yml",
                    "$path/config2.yml"
                   );
    is(keys( %{$c->config} ), 4, 'load_config() should have loaded 4 unique elements');
    is($c->config->{'dois'  }, 'two'  , 'config value mismatch');
    is($c->config->{'quatro'}, 'four' , 'config value mismatch');
    is($c->config->{'tres'  }, 'trois', 'config value mismatch');
    is($c->config->{'um'    }, 'one'  , 'config value mismatch');
};


