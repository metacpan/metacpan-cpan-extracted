use utf8;

package ViewCacheSchema::Result::ViewCache;

=head1 NAME

ViewCacheSchema::Result::ViewCache

=cut

use strict;
use warnings;
use base qw(DBIx::Class::Core);

=head1 BASE CLASS: L<ViewCacheSchema::Result>

=cut

=head1 TABLE: C<view_cache>

=cut

__PACKAGE__->table("view_cache");

=head1 ACCESSORS

=head2 CACHE_ID

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'view_cache_CACHE_ID_seq'

=head2 code

  data_type: 'text'
  is_nullable: 0

=head2 html

  data_type: 'text'
  is_nullable: 0

=head2 delete_after_view

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 created_dt

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "cache_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "view_cache_cache_id_seq",
  },
  "code",
  { data_type => "text", is_nullable => 0 },
  "html",
  { data_type => "text", is_nullable => 0 },
  "delete_after_view",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_dt",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("cache_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<view_cache_code_key>

=over 4

=item * L</code>

=back

=cut

__PACKAGE__->add_unique_constraint( "view_cache_code_key", ["code"] );

1;
