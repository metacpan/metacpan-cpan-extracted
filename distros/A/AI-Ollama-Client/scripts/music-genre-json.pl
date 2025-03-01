package main;
use 5.020;
use Mojo::JSON 'decode_json';
use experimental 'signatures';
use AI::Ollama::Client;
use Future::Utils 'repeat';

my $ol = AI::Ollama::Client->new(
    server => 'http://192.168.1.97:11434/api',
);

#my $model = 'llava:13b';
my $model = 'llama2';
my $tx = $ol->pullModel(
    name => $model,
    stream => JSON::PP::false(),
)->get;
warn "Pulled '$model'";
my @prompts = @ARGV ? @ARGV : (
    qq!Please tell me three musical genres of the song "Go West" by "The Pet Shop Boys" as JSON like ```[{"genre":"the genre name"}, ...]```!
);

for my $prompt (@prompts) {
    my $response = $ol->generateChatCompletion(
        model => $model,
        prompt => $prompt,
        temperature => '0.0',
        messages => [
            {role => 'system',
             content => join "\n",
                       'You are a music expert.',
                       'You are given an artist name and song title.',
                       'Please suggest three musical genres of that title and performer.',
                       'Only list the musical genres.',
                       #'Answer in JSON only with an array containing objects { "genre": "the genre", "sub-genre": "the sub genre" }.',
            },
            { role => 'user', content => $prompt },
        ],
    );

    my $chat;
    my $responses = $response->get;
    repeat {
        my $check = eval {
        my ($res) = $responses->shift;
        my $info;
        if( $res ) {
            $info = $res->get;
            local $| = 1;
            #print $info->message->{content};
            $chat .= $info->message->{content};
        };

        Future::Mojo->done( $info->done || !defined $res );
    }; warn $@ if $@;
    $check
    } until => sub($done) { my $res = $done->get; return $res };

    # Try to extract from a text list
    #my @genres = ($chat =~ /^\s*[\d]+\.\s*(.*?)$/mg);
    # Try to extract from a JSON string
    my @genres;
    my ($json) = ($chat =~ /^(\[.*\])$/msg);
    if( $json ) {
        @genres = decode_json( $json )->@*;
    };

    if( ! @genres ) {
        say "Did not find genres in:";
        say $chat;
    };
    use Data::Dumper; warn Dumper \@genres;

    #if( $code =~ /\A(.*?)<EOT>/s ) {
    #    my $insert = $1;
    #    my ($pre,$suf) = ($prompt =~ /<PRE>(.*?)<SUF>(.*?)<MID>/s);
    #    print "$pre$insert$suf";
    #}
}
