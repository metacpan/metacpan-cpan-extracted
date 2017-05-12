package DBICx::Backend::Move::Test::Schema::Result::Host;
use strict;
use warnings;

use base 'DBIx::Class::Core';

# let dzil know we need the components
use DBIx::Class::FilterColumn;
use DBIx::Class::TimeStamp;
use DBIx::Class::InflateColumn::DateTime;

=head1 NAME

DBICx::Backend::Move::Test::Schema::Result::Host;

=cut

=head1 ACCESSORS

=head2 idx

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->table("host");
__PACKAGE__->load_components(qw/FilterColumn InflateColumn::DateTime TimeStamp Core/);
__PACKAGE__->add_columns(
"idx",           { data_type => "integer", extra => { unsigned => 1 }, is_auto_increment => 1, is_nullable => 0, },
"name",          { data_type => "text",    is_nullable => 1 },
"desc",          { data_type => "text",    is_nullable => 1 },
"is_compressed", { data_type => "INT",      default_value => 0,      is_nullable => 0,                                         },
"created_at",    { data_type => "DATETIME", default_value => undef,  is_nullable => 0, set_on_create => 1,                     },
"updated_at",    { data_type => "DATETIME", default_value => undef,  is_nullable => 0, set_on_create => 1, set_on_update => 1, },
);
__PACKAGE__->set_primary_key('idx');
__PACKAGE__->filter_column('desc', {
                                    filter_from_storage => sub { my ($row, $element) = @_; return $row->is_compressed ? do {$element =~ s/compressed://; $element} : $element },
                                    filter_to_storage =>   sub { my ($row, $element) = @_; $row->is_compressed( 1 ); "compressed:$element"; },
                                   }
                          );


1;
