package Data::Tersify::Plugin;

=head1 NAME

Data::Tersify::Plugin - how to write a Data::Tersify plugin

=head1 SYNOPSIS

 package Data::Tersify::Plugin::Foo;
 
 sub handles { 'Foo' }
 sub tersify {
     my ($object) = @_;
     return q{They're all the same};
 }

 package Data::Tersify::Plugin::ManyThings;
 
 sub handles { ['Bar', 'Bletch'] }
 sub tersify {
     my ($object) = @_;
     if (ref($object) eq 'Bar') {
         return 'ID ' . $object->id;
     } elsif (ref($object) eq 'Bletch') {
         return sprintf('UUID %s for %s',
             $object->uuid, $object->parent->id);
     }
 }

=head1 DESCRIPTION

Any Data::Tersify plugin must (a) be in the Data::Tersify::Plugin namespace,
and (b) implement the class methods L<handles> and L<tersify>.

=head2 handles

 Out: $class or \@classes

This method returns either a single scalar class name, or an arrayref of
class names. These are classes that you're prepared to handle in your
L<tersify> method.

=head2 tersify

 In: $object
 Out: $terse_description

Supplied with an object you have said in your L<handles> that you know how
to handle, this returns a scalar description of said object. Ideally
descriptions should be short (40 characters or less), and provide only
enough information needed to differentiate two similarly terse object
descriptions.

Data::Tersify will mention the type of the object, and the refaddr, so
you do not need to mention anything like this in your description.

=cut

1;