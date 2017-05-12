use Test::Base;
use Config::Any::YAML;
use Config::Multi;
use FindBin;
use File::Spec;
use File::Basename;
use Data::Dumper;

sub is_supported_yaml {
    eval { require YAML::Syck; YAML::Syck->VERSION( '0.70' ) };
    return 1 unless $@;
    eval { require YAML; };
    return $@ ? 0 : 1;
}

if ( is_supported_yaml ) {
    plan tests => 3 * blocks ;
}
else {
    plan skip_all => 'YAML format not supported';
}

my $dir = File::Spec->catfile( $FindBin::Bin , 'conf' );

run { 
    my $block = shift;
    my $cm = Config::Multi->new({dir => $dir , app_name => 'myapp' , prefix => $block->prefix , extension => 'yml' });
    my $config = $cm->load();

    is( $block->love, $config->{love} );
    is( $block->animal, $config->{animal} );
    is( $block->boin, $config->{boin} );
}

__END__
=== prefix foo
--- prefix chomp
foo
--- love chomp
cat
--- animal chomp
shark
--- boin chomp
shark
=== prefix web
--- prefix chomp
web
--- love chomp
pig
--- animal chomp
shark
--- boin chomp
oppai
