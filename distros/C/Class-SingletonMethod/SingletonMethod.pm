package Class::SingletonMethod;

use 5.006;

our $VERSION = '1.0';

1;

package UNIVERSAL; 
 
no warnings; no strict; # no guarantee

sub singleton_method { 
    my ($object, $method, $subref) = @_; 
 
    my $parent_class = ref $object; 
    my $new_class = "_Singletons::".(0+$object); 
    *{$new_class."::".$method} = $subref; 
    if ($new_class ne $parent_class) {
        @{$new_class."::ISA"} = ($parent_class); 
        bless $object, $new_class; 
    }
} 

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::SingletonMethod - Extend individual objects with additional methods

=head1 SYNOPSIS

    my $a = Some::Class->new; 
    my $b = Some::Class->new; 
     
    $a->singleton_method( dump => sub { 
      my $self = shift; 
      require Data::Dumper; 
      print STDERR Date::Dumper::Dumper($self)  
    }); 
     
    $a->dump; # Prints a representation of the object. 
    $b->dump; # Can't locate method "dump" 

=head1 DESCRIPTION

This module provides a Perl implementation of singleton methods. The
Ruby FAQ defines singleton methods like so:

    (Q)     What is a singleton method?

    (A)     A singleton method is defined for the particular object but
            in the class. A singleton method allows appending or
            changing methods without making subclasses.

            msg = "Hello"
            def msg.print
              $>.print self, "\n"
            end
            msg.print   #=> Hello

That is, you can add or override methods on a per-object basis. 

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

ruby(1)

=cut
