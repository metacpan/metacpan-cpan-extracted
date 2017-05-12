use 5.006;    # our
use strict;
use warnings;

package DBIx::Class::InflateColumn::Serializer::JSYNC;

our $VERSION = '0.002001';

# ABSTRACT: Basic JSON Object Serialization Support for DBIx::Class.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use JSYNC;
use Carp qw( croak );

sub get_freezer {
  my ( undef, undef, $col_info, undef ) = @_;
  if ( defined $col_info->{'size'} ) {
    my $size = $col_info->{'size'};
    return sub {
      my $v = JSYNC::Dumper->new()->dump( $_[0] );
      croak('Value Serialization is too big')
        if length($v) > $size;
      return $v;
    };
  }
  return sub {
    return JSYNC::Dumper->new()->dump( $_[0] );
  };
}

sub get_unfreezer {
  return sub {
    return JSYNC::Loader->new()->load( $_[0] );
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::Serializer::JSYNC - Basic JSON Object Serialization Support for DBIx::Class.

=head1 VERSION

version 0.002001

=head1 DESCRIPTION

This is basically the only serialization backend I could find that wasn't "Dumper()",
and actually seemed to work with arbitrary C<bless()>

    package Foo::Result::Thing;
    __PACKAGE__->load_components('InflateColumn::Serializer', 'Core');
    __PACKAGE__->table('thing');

    ....

    __PACKAGE__->add_column(
        data => {
            data_type => 'text',
            serializer_class => 'JSYNC',
        }
    );

=head1 METHODS

=head2 get_freezer

    my $freezer = ::JSYNC->get_freezer( $column, $info, $args );
    my $string = $freezer->( $object );
    # $data isa string

=head2 get_unfreezer

    my $unfreezer = ::JSYNC->get_unfreezer( $column, $info, $args );
    my $object = $unfreezer->( $string );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
