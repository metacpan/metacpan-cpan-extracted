package Class::PObject::Type::ENCRYPT;

# ENCRYPT.pm,v 1.3 2003/09/09 00:11:59 sherzodr Exp

use strict;
#use diagnostics;
use vars ('$VERSION', '@ISA');
use Carp "croak";
use overload (
    'eq' => sub { crypt($_[1], $_[0]->id) eq $_[0]->id },
    bool  => sub { $_[0]->id ? 1 : 0 },
    fallback => 1
);

@ISA = ("Class::PObject::Type");
$VERSION = "1.00";

sub _init {
    my $self = shift;
    defined( $self->id ) or return undef;

    my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
    $self->{id} =  crypt($self->id, $salt)
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::PObject::Type::ENCRYPT - Defines ENCRYPT column type

=head1 DESCRIPTION

ISA L<Class::PObject::Type|Class::PObject::Type>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
