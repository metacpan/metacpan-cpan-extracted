package MyTest::Class::Basic;

use Moo;
use CLI::Osprey;

option 'message' => (
    is => 'ro',
    format => 's',
    doc => 'The message to display',
    default => 'Hello world!',
);

subcommand yell => 'MyTest::Class::Basic::Yell';

subcommand whisper => sub {
    my ($self) = @_;
    print lc $self->message, "\n";
};

sub run {
    my ($self) = @_;
    print $self->message, "\n";
}

1;
