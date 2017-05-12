use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use Path::Class;
use Config::JFDI;

{
    my $config = Config::JFDI->new( 
        qw{ name substitute path t/assets },
        substitute => {
            literal => sub {
                return "Literally, $_[1]!";
            },
            two_plus_two => sub {
                return 2 + 2;
            },
        },
     );
    ok( $config->get );

    #is( $config->get->{default}, dir( 'a-galaxy-far-far-away/' ) );
    is( $config->get->{default}, file( 'a-galaxy-far-far-away', '' ) ); # Not dir because path_to treats a non-existent directory as a file
    is( $config->get->{default_override}, "Literally, this!" );
    is( $config->get->{original}, 4 );
    is( $config->get->{original_embed}, "2 + 2 = 4" );
}

{
    my $path = dir(qw/ t assets /)->absolute;
    my $config = Config::JFDI->new( 
        qw{ name substitute-path-to }, path => "$path",
     );
    ok( $config->get );

    is( $config->get->{default}, "$path" );
    is( $config->get->{template}, $path->file( 'root/template' ) );
}
