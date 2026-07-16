package DBIx::Class::Valiant::Util::Exception::BadParameterFK;

use Moo;
extends 'Valiant::Util::Exception';

has [qw/fk_field fk_value pk_field pk_value related me/] => (is=>'ro', required=>1);

sub _build_message {
  my ($self) = @_;
  return "Relationship @{[ $self->related]} on @{[ ref $self->me ]} provided parameter @{[ $self->fk_field]} with illegal value @{[ $self->fk_value]}, was expecting @{[ $self->pk_field]} to match value @{[ $self->pk_value]} ";
  return $self->msg;
}

1;

=head1 NAME

DBIx::Class::Valiant::Util::Exception - Bad value for a foreign key

=head1 SYNOPSIS

     DBIx::Class::Valiant::Util::Exception->throw(msg=>'validations argument in unsupported format');

=head1 DESCRIPTION

A non categorized exception

=head1 ATTRIBUTES

=head2 msg 

Message that the exception will stringify to.

=head2 message

The actual exception message

=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
