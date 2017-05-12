package Bio::Chado::Schema::Result::Stock::StockDbxref;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::StockDbxref::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::StockDbxref::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Stock::StockDbxref

=head1 DESCRIPTION

stock_dbxref links a stock to dbxrefs. This is for secondary identifiers; primary identifiers should use stock.dbxref_id.

=cut

__PACKAGE__->table("stock_dbxref");

=head1 ACCESSORS

=head2 stock_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_dbxref_stock_dbxref_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_current

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

The is_current boolean indicates whether the linked dbxref is the current -official- dbxref for the linked stock.

=cut

__PACKAGE__->add_columns(
  "stock_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_dbxref_stock_dbxref_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_current",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("stock_dbxref_id");
__PACKAGE__->add_unique_constraint("stock_dbxref_c1", ["stock_id", "dbxref_id"]);

=head1 RELATIONS

=head2 dbxref

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::General::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Bio::Chado::Schema::Result::General::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 stock

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Stock::Stock>

=cut

__PACKAGE__->belongs_to(
  "stock",
  "Bio::Chado::Schema::Result::Stock::Stock",
  { stock_id => "stock_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 stock_dbxrefprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockDbxrefprop>

=cut

__PACKAGE__->has_many(
  "stock_dbxrefprops",
  "Bio::Chado::Schema::Result::Stock::StockDbxrefprop",
  { "foreign.stock_dbxref_id" => "self.stock_dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pxnrDZQWD/fcN3ciUtGbNA


=head2 create_stock_dbxrefprops

  Usage: $set->create_stock_dbxrefprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create stock_dbxref properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given stock_dbxrefprop name.  Default false.

            cv_name => cv.name to use for the given stock_dbxrefprops.
                       Defaults to 'stock_dbxref_property',

            db_name => db.name to use for autocreated dbxrefs,
                       default 'null',

            dbxref_accession_prefix => optional, default
                                       'autocreated:',
            definitions => optional hashref of:
                { cvterm_name => definition,
                }
             to load into the cvterm table when autocreating cvterms

             rank => force numeric rank. Be careful not to pass ranks that already exist
                     for the property type. The function will die in such case.

             allow_duplicate_values => default false.
                If true, allow duplicate instances of the same stock_dbxref
                and value in the properties of the stock_dbxref.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new stock_dbxrefprop object }

=cut

sub create_stock_dbxrefprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'stock_dbxref_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'stock_dbxrefprops',
        );
}

1;
