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
    my $cm = Config::Multi->new({dir => $dir , app_name => 'myapp' , prefix => 'web' , extension => 'yml' });
    my $config = $cm->load();

    is( $block->boin , $config->{Boin} );
    is( $block->oppai , $config->{Oppai} );
    is( $block->cat , $config->{Cat} );
    
}

__END__
=== test
--- boin chomp
Boin
--- oppai chomp
Oppai
--- cat chomp
Cat

