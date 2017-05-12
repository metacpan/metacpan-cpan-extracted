package CrawlApache;
use strict;
use utf8;
use warnings qw(all);
use feature qw(say);

use Moo;
use MooX::Types::MooseLike::Base qw(InstanceOf);
use Web::Scraper::LibXML;

extends 'YADA::Worker';

has scrap => (
    is      => 'ro',
    isa     => InstanceOf['Web::Scraper'],
    default => sub {
        scraper {
            process q(//a),
                q(links[]) => q(@href)
        };
    },
    lazy    => 1,
);

has '+use_stats' => (default => sub { 1 });

after finish => sub {
    my ($self, $result) = @_;

    say $result . "\t" . $self->final_url;

    if (
        not $self->has_error
        and $self->getinfo('content_type') =~ m{^text/html}x
    ) {
        my $res = $self
            ->scrap
            ->scrape(
                ${$self->data},
                $self->final_url
            );
        for my $link (
            grep {
                $_->scheme eq 'http'
                and $_->host eq 'localhost'
            } @{$res->{links}}
        ) {
            $self->queue->prepend(sub {
                CrawlApache->new(
                    initial_url => $link,
                    scrap       => $self->scrap,
                );
            });
        }
    }
};

1;
