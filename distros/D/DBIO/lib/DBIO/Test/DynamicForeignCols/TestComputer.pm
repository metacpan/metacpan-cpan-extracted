package DBIO::Test::DynamicForeignCols::TestComputer;
# ABSTRACT: Test result class for dynamic foreign column joining

use warnings;
use strict;

use base 'DBIO::Core';

__PACKAGE__->table('TestComputer');
__PACKAGE__->add_columns(qw( test_id ));
__PACKAGE__->_add_join_column({ class => 'DBIO::Test::DynamicForeignCols::Computer', method => 'computer' });
__PACKAGE__->set_primary_key('test_id', 'computer_id');
__PACKAGE__->belongs_to(computer => 'DBIO::Test::DynamicForeignCols::Computer', 'computer_id');

###
### This is a pathological case lifted from production. Yes, there is code
### like this in the wild
###
sub _add_join_column {
   my ($self, $params) = @_;

   my $class = $params->{class};
   my $method = $params->{method};

   $self->ensure_class_loaded($class);

   my @class_columns = $class->primary_columns;

   if (@class_columns = 1) {
      $self->add_columns( "${method}_id" );
   } else {
      my $i = 0;
      for (@class_columns) {
         $i++;
         $self->add_columns( "${method}_${i}_id" );
      }
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::DynamicForeignCols::TestComputer - Test result class for dynamic foreign column joining

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
