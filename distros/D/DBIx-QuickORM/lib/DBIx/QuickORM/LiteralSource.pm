package DBIx::QuickORM::LiteralSource;
use strict;
use warnings;

our $VERSION = '0.000015';

use Role::Tiny::With qw/with/;

use Carp qw/croak/;

with 'DBIx::QuickORM::Role::Source';

sub new {
    my $class = shift;
    my ($literal) = @_;

    $literal = \$literal unless ref($literal);
    croak "'$literal' is not a scalar reference" unless ref($literal) eq 'SCALAR';

    return bless($literal, $class);
}

sub cachable { 0 }

sub source_db_moniker { ${$_[0]} }
sub source_orm_name { 'LITERAL' }

sub fields_list_all { ['*'] }
sub fields_to_fetch { ['*'] }

sub field_affinity { 'string' }
sub field_type     { }
sub fields_to_omit { }
sub has_field      { }
sub primary_key    { }
sub row_class      { }

1;
