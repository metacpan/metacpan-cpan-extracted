#
# This file is part of DBIx-Class-FilterColumn-ByType
#
# This software is copyright (c) 2012 by Matthew Phillips.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package DBIx::Class::FilterColumn::ByType;
# ABSTRACT: Apply FilterColumn by type instead of name
BEGIN {
our $VERSION = '1.122121'; # VERSION
}

use strict;
use warnings;

use base qw/DBIx::Class::FilterColumn/;

__PACKAGE__->mk_classdata(
  __filter_column_pairs => {}
);

sub filter_columns_by_type {
  my ($self, $types, $hash) = @_;

  # flatten
  my @types = map { (ref) ? @$_ : $_ } $types;

  # find matching columns
  for my $type (@types) {
    # cache
    $self->__filter_column_pairs->{$type} = $hash;

    # this function can be called in two contexts
    # 1. in a base result class, for applying to an entire schema
    # 2. in an instantiated result class
      # in the case of 1, result_source_instance does not exist at invocation.
    if ($self->can('result_source_instance')) {
      my $cols = $self->columns_info;
      while (my ($col, $attrs) = each %$cols) {
        next unless $attrs->{data_type} && $attrs->{data_type} eq $type;

        # pass through to filter_columns. let validation happen there
        $self->filter_column($col => $hash);
      }
    }
  }
}


sub add_columns {
  my $self = shift;

  $self->next::method(@_);

  while (my ($col, $attrs) = splice @_, 0, 2) {
    next if not $attrs->{data_type};
    if (my $spec = $self->__filter_column_pairs->{$attrs->{data_type}}) {
      $self->filter_column($col => $spec);
    }
  }
}

1;



=pod

=head1 NAME

DBIx::Class::FilterColumn::ByType - Apply FilterColumn by type instead of name

=head1 VERSION

version 1.122121

=head1 SYNOPSIS

In your Schema or DB class add "FilterColumn::ByType" to the top of the
component list.

  __PACKAGE__->load_components(qw( FilterColumn::ByType ... ));

Set up filters for the column types you want to convert.

 __PACKAGE__->filter_columns_by_type( [qw/varchar text/] => {
     filter_to_storage => 'to_utf8',
     filter_from_storage => 'from_utf8',
 });

 use Encode;
 sub to_utf8 { encode('utf8', $_[1]) }

 sub from_utf8 { decode('utf8', $_[1]) }

 1;

=head1 DESCRIPTION

This module is a subclass of L<DBIx::Class::FilterColumn>, which allows you to
attach filters by column type, as well as by column name. You should look at
L<DBIx::Class::FilterColumn> documentation for a full explanation of how
FilterColumn works.

If you'd like to do something like filter all varchars in your entire schema,
you would only need to create a base result class, then call
filter_columns_by_type from there. See t/lib/A/Schema inside the dist for an
example.

=encoding utf-8

=head1 METHODS

=head2 filter_column_by_type

 __PACKAGE__->filter_columns_by_type( coltype => { ... })

 __PACKAGE__->filter_columns_by_type( [qw/coltype/] => { ... })

This method takes two arguments. The first, coltype, can be either an array of
scalars, or a scalar that describe the type(s) the filters will be attached to.
The second argument is passed straight through to FilterColumn::filter_column()
without modification.

=head1 SEE ALSO

L<DBIx::Class>, L<DBIx::Class::FilterColumn>

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Matthew Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

