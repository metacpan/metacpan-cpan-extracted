package Data::Morph::Backend::Object;
$Data::Morph::Backend::Object::VERSION = '1.140400';
#ABSTRACT: Provides a Data::Morph backend for talking to objects

use Moose;
use MooseX::Types::Moose(':all');
use MooseX::Params::Validate;
use namespace::autoclean;


sub epilogue { }

with 'Data::Morph::Role::Backend' =>
{
    input_type => Object,
    get_val => sub
    {
        my ($obj, $key) = @_;
        return $obj->$key;
    },
    set_val => sub
    {
        my ($obj, $key, $val) = @_;
        $obj->$key($val);
    },
};

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=head1 NAME

Data::Morph::Backend::Object - Provides a Data::Morph backend for talking to objects

=head1 VERSION

version 1.140400

=head1 DESCRIPTION

Data::Morph::Backend::Object provides a backend for interacting with arbitrary
objects. Directives defined in map should correspond to methods or attributes

=head1 PUBLIC_METHODS

=head2 epilogue

Implements L<Data::Morph::Role::Backend/epilogue> as a no-op

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
