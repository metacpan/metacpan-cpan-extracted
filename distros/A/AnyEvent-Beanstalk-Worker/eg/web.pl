package AE::BS::Worker;

use blib;
use Mojo::UserAgent;
use parent 'AnyEvent::Beanstalk::Worker';

sub init {
    shift->{ua} = Mojo::UserAgent->new;
}

package main;

use JSON;
use feature 'say';

my $w = AE::BS::Worker->new(
    concurrency       => 10,
    max_jobs          => 10,
    initial_state     => 'fetch',
    beanstalk_watch   => 'web-jobs',
    beanstalk_decoder => sub {
        eval { decode_json(shift) };
    }
);

$w->on(
    fetch => sub {
        my $self = shift;
        my $job  = shift;

        say STDERR "trying to fetch " . $job->decode->{url} . "...";
        $self->{ua}->get(
            $job->decode->{url},
            sub {
                $self->emit( show => $job, @_ );
            }
        );
    }
);

$w->on(
    show => sub {
        my $self = shift;
        my ( $job, undef, $tx ) = @_;

        unless ( $tx->res->code and $tx->res->code =~ /^2/ ) {
            warn => "Moved or some error";
            return $self->finish(delete => $job->id);
        }

        if ($tx->res->headers->content_type =~ /html/i) {
            my $title = '';
            eval { $title = $tx->res->dom->html->head->title->text };

            if ($@) { warn $@ }
            else { say STDERR "found title: " . $title }
        }

        else {
            say STDERR "found body: " . $tx->res->body;
        }

        return $self->finish(delete => $job->id);
    }
);

$w->start;

EV::run;
