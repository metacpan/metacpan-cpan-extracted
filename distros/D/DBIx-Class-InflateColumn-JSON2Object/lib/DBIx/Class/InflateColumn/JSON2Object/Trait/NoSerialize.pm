package DBIx::Class::InflateColumn::JSON2Object::Trait::NoSerialize;
use Moose::Role;

# ABSTRACT: NoSerialize trait for attributes

package Moose::Meta::Attribute::Custom::Trait::NoSerialize {
    sub register_implementation { 'DBIx::Class::InflateColumn::JSON2Object::Trait::NoSerialize' }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::JSON2Object::Trait::NoSerialize - NoSerialize trait for attributes

=head1 VERSION

version 0.900

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
