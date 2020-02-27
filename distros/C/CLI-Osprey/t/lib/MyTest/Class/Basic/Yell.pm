package MyTest::Class::Basic::Yell;

use Moo;
use CLI::Osprey;

sub run {
    my ($self) = @_;
    print uc $self->parent_command->message, "\n";
}


1;
