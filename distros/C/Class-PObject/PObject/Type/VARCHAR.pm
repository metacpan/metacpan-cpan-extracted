package Class::PObject::Type::VARCHAR;

# VARCHAR.pm,v 1.3 2003/09/09 00:11:59 sherzodr Exp

use strict;
#use diagnostics;
use vars ('$VERSION', '@ISA');
use Class::PObject::Type;
use overload (
    '""' => sub { $_[0]->id },
    bool => sub { $_[0]->id ? 1 : 0 },
    fallback => 1,
);

@ISA = ("Class::PObject::Type");

$VERSION = '1.02';





1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::PObject::Type::VARCHAR - Defines VARCHAR column type

=head1 DESCRIPTION

ISA L<Class::PObject::Type|Class::PObject::Type>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
