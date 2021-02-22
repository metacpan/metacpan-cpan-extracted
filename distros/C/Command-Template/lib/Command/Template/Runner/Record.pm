package Command::Template::Runner::Record;
use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

sub command           ($self) { $self->{command} }
sub command_as_string ($self) { join ' ', @{$self->command} }
sub exit_code         ($self) { $self->{ec} >> 8 }
sub failure           ($self) { $self->full_exit_code != 0 }
sub full_exit_code    ($self) { $self->{ec} }
sub merged            ($self) { $self->stderr . $self->stdout }
sub new               ($pack, $data) { return bless { $data->%* }, $pack }
sub options           ($self) { $self->{options} }
sub signal            ($self) { $self->{ec} & 0x7F }
sub stderr            ($self) { $self->{stderr} }
sub stdout            ($self) { $self->{stdout} }
sub success           ($self) { $self->full_exit_code == 0 }
sub timed_out         ($self) { $self->timeout }
sub timeout           ($self) { $self->{timeout} }

1;
