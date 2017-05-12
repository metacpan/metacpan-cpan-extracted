package App::Toodledo::InternalWrapper;

use Carp;
use Package::Stash;
use Moose;
use MooseX::Method::Signatures;
with 'MooseX::Log::Log4perl';

our $VERSION = '1.01';

# Because delegation doesn't get attributes
sub BUILD
{
  my ($self, $argref) = @_;

  $self->object->$_( $argref->{$_} ) for keys %$argref;
}


sub internal_attributes
{
  my ($class, $meta) = @_;

  map { $_, $_ } $class->attribute_list( $meta );
}


sub attribute_list
{
  my ($class, $meta) = @_;

  no strict 'refs';
  ref $class and $class = ref $class;
  my $array = '@ATTRS';
  my $stash = Package::Stash->new( $class );
  $stash->has_symbol( $array ) and return @{ $stash->get_symbol( $array ) };
  my @attrs = grep { $_ ne 'meta' } $meta->get_attribute_list;
  $stash->add_symbol( $array, \@attrs );
  @attrs;
}


method delete ( App::Toodledo $todo! ) {
  my $id = $self->id;
  (my $type = lc ref $self) =~ s/.*://;
  my $deleted_ref = $todo->call_func( $type => delete => { id => $id } );
  $deleted_ref->[0]{id} == $id or $self->log->logdie("Did not get ID back from delete");
}


1;

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 BUILD

=head2 attribute_list

=head2 internal_attributes

=head2 delete

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
