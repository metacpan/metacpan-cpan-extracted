use strict;
use warnings;
package Data::Rx::Type::Rx;
BEGIN {
  $Data::Rx::Type::Rx::VERSION = '0.103520';
}
# ABSTRACT: an individual Rx type definition


sub new {
    my ($class, %options) = @_;
    bless \%options, $class;
}


sub type_uri { $_[0]->{type_uri} }


sub new_checker {
    my ($self, $schema_arg, $rx) = @_;

    $self->{checker} = $rx->make_schema($self->{as});

    return $self;
}


sub check {
    my ($self, $value) = @_;
    
    return $self->{checker}->check($value);
}

1;

__END__
=pod

=head1 NAME

Data::Rx::Type::Rx - an individual Rx type definition

=head1 VERSION

version 0.103520

=head1 DESCRIPTION

This is the class that actually encapsulates the Rx type alias definition. You probably want to see L<Data::Rx::TypeBundle::Rx> instead.

=head1 METHDOS

=head2 new

Constructs a new type.

=head2 type_uri

Returns the type URI that has been set for the type alias.

=head2 new_checker

Called by L<Data::Rx> when building a schema. Builds the actual checker based upon the type definition and returns itself.

=head2 check

This checks to see if the given value matches the Rx type defined.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

