package DBIx::Class::Helper::Row::NumifyGet;
$DBIx::Class::Helper::Row::NumifyGet::VERSION = '2.036000';
# ABSTRACT: Force numeric "context" on numeric columns

use strict;
use warnings;

use parent 'DBIx::Class::Row';

use Try::Tiny;

sub get_column {
   my ($self, $col) = @_;

   my $value = $self->next::method($col);

   $value += 0 if defined($value) and # for nullable and autoinc fields
                  try { $self->_is_column_numeric($col) };

   return $value;
}

sub get_columns {
   my ($self, $col) = @_;

   my %columns = $self->next::method($col);

   for (keys %columns) {
      $columns{$_} += 0
         if defined($columns{$_}) and # for nullable and autoinc fields
            try { $self->_is_column_numeric($_) };
   }

   return %columns;
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::Row::NumifyGet - Force numeric "context" on numeric columns

=head1 SYNOPSIS

 package MyApp::Schema::Result::Foo_Bar;

 __PACKAGE__->load_components(qw{Helper::Row::NumifyGet Core});

 __PACKAGE__->table('Foo');
 __PACKAGE__->add_columns(
    foo => {
       data_type         => 'integer',
       is_nullable       => 0,
       is_numeric        => 1,
    },
 );

 sub TO_JSON {
    return {
       foo => $self->foo,  # this becomes 0 instead of "0" due to context
    }
 }

=head1 METHODS

=head2 get_column

This is the method that "converts" the values.  It just checks for
C<is_numeric> and if that is true it will numify the value.

=head2 get_columns

This method also "converts" values, but this one is called a lot more rarely.
Again, It just checks for C<is_numeric> and if that is true it will numify the
value.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
