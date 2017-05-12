package Bio::Chado::Schema::Result::Stock::StockCvterm;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::StockCvterm::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::StockCvterm::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Stock::StockCvterm

=head1 DESCRIPTION

stock_cvterm links a stock to cvterms. This is for secondary cvterms; primary cvterms should use stock.type_id.

=cut

__PACKAGE__->table("stock_cvterm");

=head1 ACCESSORS

=head2 stock_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_cvterm_stock_cvterm_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_not

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_cvterm_stock_cvterm_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_not",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("stock_cvterm_id");
__PACKAGE__->add_unique_constraint(
  "stock_cvterm_c1",
  ["stock_id", "cvterm_id", "pub_id", "rank"],
);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "cvterm_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 pub

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Pub::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Bio::Chado::Schema::Result::Pub::Pub",
  { pub_id => "pub_id" },
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

=head2 stock_cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockCvtermprop>

=cut

__PACKAGE__->has_many(
  "stock_cvtermprops",
  "Bio::Chado::Schema::Result::Stock::StockCvtermprop",
  { "foreign.stock_cvterm_id" => "self.stock_cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:14:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lOiXJCZBCZBxj+MAZdMnQw

=head2 create_stock_cvtermprops

  Usage: $set->create_stock_cvtermprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create stock_cvterm properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given stock_cvtermprop name.  Default false.

            cv_name => cv.name to use for the given stock_cvtermprops.
                       Defaults to 'stock_cvterm_property',

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
                If true, allow duplicate instances of the same stock_cvterm
                and value in the properties of the stock_cvterm.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new stock_cvtermprop object }

=cut

sub create_stock_cvtermprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'stock_cvterm_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'stock_cvtermprops',
        );
}


1;
