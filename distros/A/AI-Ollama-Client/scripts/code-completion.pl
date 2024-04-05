package main;
use 5.020;
use Mojo::JSON 'decode_json';
use experimental 'signatures';
use AI::Ollama::Client;
use Future::Utils 'repeat';

#use Getopt::Long;
#GetOptions(
#    'prefix|p=s' => \my $prefix,
#    'suffix|s=s' => \my $suffix,
#);

my $ol = AI::Ollama::Client->new(
    server => 'http://192.168.1.97:11434/api',
);

my $model = 'codellama:13b-code';
my $tx = $ol->pullModel(
    name => $model,
)->get;

my @prompts = @ARGV ? @ARGV : (qq{fetch an url and print its content with Mojolicious; write concise code <PRE> sub fetch {\n <SUF> } <MID>});

for my $prompt (@prompts) {
    my $responses = $ol->generateCompletion(
        model => $model,
        prompt => $prompt,
    );

    my $code;
    repeat {
        my ($res) = $responses->shift;
        my $info;
        if( $res ) {
            $info = $res->get;
            local $| = 1;
            print $info->response;
            $code .= $info->response;
        };
        Future::Mojo->done( $info->done || !defined $res );
    } until => sub($done) { my $res = $done->get; return $res };

    if( $code =~ /\A(.*?)<EOT>/s ) {
        my $insert = $1;
        my ($pre,$suf) = ($prompt =~ /<PRE>(.*?)<SUF>(.*?)<MID>/s);
        print "$pre$insert$suf";
    }
}
