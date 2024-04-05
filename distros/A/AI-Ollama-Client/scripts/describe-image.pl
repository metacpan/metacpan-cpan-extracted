package main;
use 5.020;
use Mojo::JSON 'decode_json';
use experimental 'signatures';
use AI::Ollama::Client;
use Future::Utils 'repeat';

my $ol = AI::Ollama::Client->new(
    server => 'http://192.168.1.97:11434/api',
);

my $tx = $ol->pullModel(
    name => 'llava:latest',
)->get;

my @images = @ARGV ? @ARGV : ('t/testdata/objectdetection.jpg');

for my $image (@images) {
    my $responses = $ol->generateCompletion(
        model => 'llava:latest',
        prompt => 'You are tagging images. Please list all the objects in this image as tags. Also list the location where it was taken.',
        images => [
            { filename => $image },
        ],
    );

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
