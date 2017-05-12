package AnyMongo::BSON::Code;
BEGIN {
  $AnyMongo::BSON::Code::VERSION = '0.03';
}
# ABSTRACT: BSON type,it's used to represent JavaScript code and, optionally, scope.
use strict;
use warnings;
use namespace::autoclean;
use Any::Moose;


has code => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has scope => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 0,
);

# __PACKAGE__->meta->make_immutable (inline_destructor => 0);
__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

AnyMongo::BSON::Code - BSON type,it's used to represent JavaScript code and, optionally, scope.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 code

A string of JavaScript code.

=head2 scope

An optional hash of variables to pass as the scope.

=head1 NAME

AnyMongo::Code 

=head1 AUTHOR

=head1 COPYRIGHT

=head1 AUTHORS

=over 4

=item *

Pan Fan(nightsailer) <nightsailer at gmail.com>

=item *

Kristina Chodorow <kristina at 10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


