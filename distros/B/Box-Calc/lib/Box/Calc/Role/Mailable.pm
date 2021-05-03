package Box::Calc::Role::Mailable;
$Box::Calc::Role::Mailable::VERSION = '1.0206';
use strict;
use warnings;
use Moose::Role;

=head1 NAME

Box::Calc::Role::Mailable - Role to make an object mailable.

=head1 VERSION

version 1.0206

=head1 METHODS

This role installs these methods:

=head2 mail_container

Defaults to C<undef>.

=head2 mail_size

Defaults to 'Regular'.

=head2 mail_machinable

Returns C<undef>.

=head2 mail_type

Returns 'Package'.

=head2 girth

Returns y * z

=cut

has mail_container => (
    is          => 'rw',
    default     => undef,
);

has mail_size => (
    is          => 'rw',
    default     => 'Regular',
);

has mail_machinable => (
    is          => 'rw',
    default     => undef,
);

has mail_type => (
    is          => 'rw',
    default     => 'Package',
);

sub girth {
    my $self = shift;
    return $self->y * $self->z;
}

has mail_pobox_flag => (
    is          => 'rw',
    default     => 'N',
);

has mail_gift_flag => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'N',
);

has value_of_contents => (
    is          => 'rw',
    isa         => 'Num',
    default     => 0,
);

has mail_service_name => (
    is          => 'rw',
    isa         => 'Str',
    default     => '',
);


1;
