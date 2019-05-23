package Code::Style::Kit::Parts::Types;
use strict;
use warnings;
our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: type constraints


use Import::Into;

sub feature_types_default { 0 }
sub feature_types_export {
    my ($self, $caller) = @_;

    require Type::Params;
    Type::Params->import::into($caller);
    require Types::Standard;
    Types::Standard->import::into(
        $caller,
        "Any",
        "Item",
        "Bool",
        "Undef",
        "Defined",
        "Value",
        "Str",
        "Num",
        "Int",
        "ClassName",
        "RoleName",
        "Ref",
        "CodeRef",
        "RegexpRef",
        "FileHandle",
        "ArrayRef",
        "HashRef",
        "ScalarRef",
        "Object",
        "Maybe",
        "Map",
        "Optional",
        "Tuple",
        "Dict",
        "InstanceOf",
        "ConsumerOf",
        "HasMethods",
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Style::Kit::Parts::Types - type constraints

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit
                Code::Style::Kit::Parts::Common
                Code::Style::Kit::Parts::Types);
  1;

Then:

  use My::Kit 'types';

  sub thing {
      state $check = compile(Str,Int);
      my ($name, $value) = $check->(@_);
      ...
  }

=head1 DESCRIPTION

This part defines the C<types> feature, which imports L<<
C<Type::Params> >> and L<< C<Types::Standard> >>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
