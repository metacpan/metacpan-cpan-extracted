package
    My::ArgsListRole;

use Moo::Role;

requires 'got_args';
sub got_args_list {
    my ( $self ) = @_;
    return @{ $self->got_args };
}

1;
