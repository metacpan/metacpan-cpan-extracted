package Context::Set::Storage::Split::Rule;
use Moose;

has 'name' => ( is => 'ro' , isa => 'Str' , required => 1 );
has 'test' => ( is => 'ro', isa => 'CodeRef', required => 1 );
has 'storage' => ( is => 'rw', isa => 'Context::Set::Storage', required => 1 );

__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Context::Set::Storage::Split::Rule - Private class.
