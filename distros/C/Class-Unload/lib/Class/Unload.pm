package Class::Unload;
# ABSTRACT: Unload a class
$Class::Unload::VERSION = '0.11';
use warnings;
use strict;
no strict 'refs'; # we're fiddling with the symbol table

use Class::Inspector;


sub unload {
    my ($self, $class) = @_;

    return unless Class::Inspector->loaded( $class );

    # Flush inheritance caches
    @{$class . '::ISA'} = ();

    my $symtab = $class.'::';
    # Delete all symbols except other namespaces
    for my $symbol (keys %$symtab) {
        next if $symbol =~ /\A[^:]+::\z/;
        delete $symtab->{$symbol};
    }

    my $inc_file = join( '/', split /(?:'|::)/, $class ) . '.pm';
    delete $INC{ $inc_file };

    if (Class::Inspector->loaded('Class::MOP')) {
        Class::MOP::remove_metaclass_by_name($class);
    }

    return 1;
}


1; # End of Class::Unload

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Unload - Unload a class

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use Class::Unload;
    use Class::Inspector;

    use Some::Class;

    Class::Unload->unload( 'Some::Class' );
    Class::Inspector->loaded( 'Some::Class' ); # Returns false

    require Some::Class; # Reloads the class

=head1 METHODS

=head2 unload $class

Unloads the given class by clearing out its symbol table and removing it
from %INC.  If it's a L<Moose> class, the metaclass is also removed.

=head1 SEE ALSO

L<Class::Inspector>

=head1 ACKNOWLEDGEMENTS

Thanks to Matt S. Trout, James Mastros and Uri Guttman for various tips
and pointers.

=head1 AUTHOR

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>;

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dagfinn Ilmari Mannsåker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
