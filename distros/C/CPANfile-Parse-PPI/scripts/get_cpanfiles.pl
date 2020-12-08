#!/usr/bin/perl

use strict;
use warnings;

use MetaCPAN::Client;
use Mojo::File qw(curfile);
use Mojo::UserAgent;

my $tx = Mojo::UserAgent->new->post(
    'https://fastapi.metacpan.org/v1/file' => json => {
        "query"=> {
            "match_all"=> {}
        },
        "filter"=> {
            "and"=> [
                {
                    "term"=> {
                        "path"=> "cpanfile"
                    }
                },
                {
                    "term"=> {
                        "status"=> "latest"
                    }
                }
            ]
        },
        "fields"=> [
            "author",
            "distribution",
            "release"
        ],
        "size"=> 20
    }
);

my $data = $tx->res->json;
my @files = map {
     +{
         dist => $_->{fields}->{distribution},
         path => (sprintf "%s/%s/cpanfile", $_->{fields}->{author}, $_->{fields}->{release}),
     };
} @{ $data->{hits}->{hits} };

my $mcpan = MetaCPAN::Client->new;

my $path = curfile->dirname->child(qw/.. t data/);
for my $cpanfile ( @files ) {
    warn "handle $cpanfile->{path}";
    my $file = $mcpan->file( $cpanfile->{path} );

    $path->child( $cpanfile->{dist} . '-cpanfile' )->spurt( $file->source );
}
