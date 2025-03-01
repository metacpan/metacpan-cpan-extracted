package main;
use 5.020;
use Mojo::JSON 'decode_json';
use experimental 'signatures';
use AI::Ollama::Client;
use Future::Utils 'repeat';

my $ol = AI::Ollama::Client->new(
    server => 'http://192.168.1.97:11434/api',
);

$ol->on('request' => sub( $ol, $tx ) {
    use Data::Dumper;
    warn Dumper $tx->req;
});

$ol->on('response' => sub( $ol, $tx, $err='' ) {
    if( $err ) {
        warn $err if $err;
    } else {
        #use Data::Dumper;
        warn $tx->code;
    }
});

my $tx = $ol->pullModel(
    name => 'llava:latest',
)->catch(sub {
    use Data::Dumper; warn Dumper \@_;
})->get;

my @images = @ARGV ? @ARGV : ('t/testdata/objectdetection.jpg');

for my $image (@images) {
    my $response = $ol->generateCompletion(
        model => 'llava:latest',
        prompt => 'You are tagging images. Please list all the objects in this image as tags. Also list the location where it was taken.',
        images => [
            { filename => $image },
        ],
    );
    my $responses = $response->get;

    repeat {
        my ($res) = $responses->shift;
        my $info;
        if( $res ) {
            $info = $res->get;
            local $| = 1;
            print $info->response;
        };
        Future::Mojo->done( $info->done || !defined $res );
    } until => sub($done) { my $res = $done->get; return $res };
}
