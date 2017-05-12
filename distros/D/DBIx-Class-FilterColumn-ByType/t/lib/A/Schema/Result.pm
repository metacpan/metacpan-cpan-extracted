#
# This file is part of DBIx-Class-FilterColumn-ByType
#
# This software is copyright (c) 2012 by Matthew Phillips.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package A::Schema::Result;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('FilterColumn::ByType');

__PACKAGE__->filter_columns_by_type([qw/varchar text/] => {
  filter_from_storage => sub { $A::Schema::Result::Artist::from_storage_ran++; $_[1] . '2' },
  filter_to_storage   => sub { $A::Schema::Result::Artist::to_storage_ran++; $_[1] . '1' },
});

__PACKAGE__->filter_columns_by_type([qw/real/] => {
  filter_from_storage => sub { $A::Schema::Result::Artist::from_storage_ran++; $_[1] * 10 },
  filter_to_storage   => sub { $A::Schema::Result::Artist::to_storage_ran++; $_[1] * 10 },
});

1;
