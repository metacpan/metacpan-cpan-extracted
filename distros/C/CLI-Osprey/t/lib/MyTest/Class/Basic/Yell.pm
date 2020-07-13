package MyTest::Class::Basic::Yell;

use Moo;
use CLI::Osprey;

option excitement_level => (
    is => 'ro',
    format => 'i',
    doc => 'Level of excitement for yelling',
    default => 0,
);

sub run {
    my ($self) = @_;
    print uc $self->parent_command->message, "!" x $self->excitement_level, "\n";
}


1;
