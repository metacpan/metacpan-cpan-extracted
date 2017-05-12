package WebWorker;

use parent 'AnyEvent::Beanstalk::Worker';
use Mojo::UserAgent;

sub init {
    shift->{ua} = Mojo::UserAgent->new;
}

1;
