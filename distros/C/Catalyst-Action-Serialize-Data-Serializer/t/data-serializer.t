use strict;
use warnings;
use Test::More;
use FindBin;

use lib ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib" );
use Test::Rest;

use_ok 'Catalyst::Test', 'Test::Serialize';

my %ctypes =( 
            'text/x-data-dumper' =>   'Data::Dumper' ,
            'text/x-data-denter' =>   'Data::Denter' ,
            'text/x-data-taxi'   =>   'Data::Taxi'   ,
            'application/x-storable'    =>   'Storable'     ,
            'application/x-freezethaw'  =>   'FreezeThaw'   ,
            'text/x-config-general' =>   'Config::General' ,
            'text/x-php-serialization' =>   'PHP::Serialization' ,
        );

my $has_serializer = eval "require Data::Serializer";

foreach my $content_type (keys(%ctypes)) {
    my $dso;
    my $skip = 0;
    my $loadclass = $ctypes{$content_type};
    $loadclass =~ s/::/\//g;
    $loadclass .= '.pm';
    eval {
       require $loadclass 
    };
    if ($@) {
        $skip = 1;
    }
    SKIP: {
        skip "$ctypes{$content_type} not installed", 4 if $skip;
        $dso = Data::Serializer->new( serializer => $ctypes{$content_type} );
        my $t = Test::Rest->new( 'content_type' => $content_type );

        my $monkey_template = { monkey => 'likes chicken!', };
        my $mres = request( $t->get( url => '/monkey_get' ) );
        ok( $mres->is_success, "GET $content_type succeeded" );
        is_deeply( $dso->raw_deserialize( $mres->content ),
            $monkey_template, "GET $content_type has the right data" );

        my $post_data = { 'sushi' => 'is good for monkey', };
        my $mres_post = request(
            $t->post(
                url  => '/monkey_put',
                data => $dso->raw_serialize($post_data)
            )
        );
        ok( $mres_post->is_success, "POST $content_type succeeded" );
        is_deeply(
            $mres_post->content,
            "is good for monkey",
            "POST $content_type data matches"
        );
    }
}

{
        my $t = Test::Rest->new( 'content_type' => 'text/x-data-dumper' );

        my $post_data = "{ 'sushi' => die('hack attempt') }";
        my $mres_post = request(
            $t->post(
                url  => '/monkey_put',
                data => $post_data,
            )
        );
        ok( ! $mres_post->is_success, "POST Data::Dumper fails due to invalid input" );
        like(
            $mres_post->content,
            qr%Content-Type text/x-data-dumper had a problem with your request.*'die' trapped by operation mask%s,
            "POST Data::Dumper data error matches"
        );
}

1;

done_testing;
