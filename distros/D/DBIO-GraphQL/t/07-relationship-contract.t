use strict;
use warnings;
use Test::More;
use lib 't/lib', 'lib';

use GraphQL::Type::Object;
use GraphQL::Type::List;
use GraphQL::Type::Scalar qw($String);
use DBIO::GraphQL::Relationship;

# KARR #1: relationship resolution depends on two undocumented keys of
# $source->relationship_info($rel):
#
#   $info->{source}            - target result class
#   $info->{attrs}{accessor}   - 'multi' for has_many, 'single' otherwise
#
# These tests pin the hardened contract: build_field must raise a clear,
# relationship-naming error when a key is missing (instead of silently
# dropping the field), and on_error => 'warn' must downgrade that to a
# warning + undef so the caller can skip.

# Minimal mock standing in for a DBIO source. Only the two methods that
# build_field touches at build time are implemented.
{
  package My::MockSource;
  sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
  }
  sub source_name      { $_[0]->{source_name} }
  sub relationship_info { $_[0]->{rels}{ $_[1] } }
}

my $target_type = GraphQL::Type::Object->new(
  name   => 'Book',
  fields => sub { { id => { type => $String } } },
);
my %snapshot = ( Book => $target_type );

#
# Happy path - plural (multi) resolves to a List of the target type
#
{
  my $src = My::MockSource->new(
    source_name => 'Author',
    rels => { books => { source => 'My::Schema::Result::Book',
                         attrs  => { accessor => 'multi' } } },
  );
  my $rel = DBIO::GraphQL::Relationship->new(schema => undef);
  my $field = $rel->build_field($src, 'books', \%snapshot);
  ok($field, 'multi relationship builds a field');
  isa_ok($field->{type}, 'GraphQL::Type::List',
    'multi relationship field is a List type');
}

#
# Happy path - singular (single) resolves to the bare target type
#
{
  my $src = My::MockSource->new(
    source_name => 'Book',
    rels => { author => { source => 'My::Schema::Result::Author',
                          attrs  => { accessor => 'single' } } },
  );
  # snapshot keyed by stripped moniker
  my %snap = ( Author => $target_type );
  my $rel  = DBIO::GraphQL::Relationship->new(schema => undef);
  my $field = $rel->build_field($src, 'author', \%snap);
  ok($field, 'single relationship builds a field');
  ok(!$field->{type}->isa('GraphQL::Type::List'),
    'single relationship field is not a List type');
}

#
# die path - missing {source}
#
{
  my $src = My::MockSource->new(
    source_name => 'Author',
    rels => { books => { attrs => { accessor => 'multi' } } },   # no source
  );
  my $rel = DBIO::GraphQL::Relationship->new(schema => undef);
  eval { $rel->build_field($src, 'books', \%snapshot) };
  my $err = $@;
  like($err, qr/\bsource\b/,  'missing source key dies mentioning source');
  like($err, qr/'books'/,     'error names the relationship');
  like($err, qr/'Author'/,    'error names the source');
}

#
# die path - missing {attrs}{accessor}
#
{
  my $src = My::MockSource->new(
    source_name => 'Author',
    rels => { books => { source => 'My::Schema::Result::Book' } },  # no attrs
  );
  my $rel = DBIO::GraphQL::Relationship->new(schema => undef);
  eval { $rel->build_field($src, 'books', \%snapshot) };
  like($@, qr/accessor/,  'missing attrs.accessor dies mentioning accessor');
  like($@, qr/'books'/,   'error names the relationship');
}

#
# die path - target type absent from the snapshot
#
{
  my $src = My::MockSource->new(
    source_name => 'Author',
    rels => { widgets => { source => 'My::Schema::Result::Widget',
                           attrs  => { accessor => 'multi' } } },
  );
  my $rel = DBIO::GraphQL::Relationship->new(schema => undef);
  eval { $rel->build_field($src, 'widgets', \%snapshot) };
  like($@, qr/snapshot/,   'absent target type dies mentioning the snapshot');
  like($@, qr/'Widget'/,   'error names the missing target moniker');
}

#
# warn path - on_error => 'warn' downgrades to a warning + undef
#
{
  my $src = My::MockSource->new(
    source_name => 'Author',
    rels => { books => { attrs => { accessor => 'multi' } } },   # no source
  );
  my $rel = DBIO::GraphQL::Relationship->new(
    schema => undef, on_error => 'warn',
  );

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my $field = $rel->build_field($src, 'books', \%snapshot);

  is($field, undef, 'on_error=warn returns undef instead of dying');
  is(scalar(@warnings), 1, 'on_error=warn emits exactly one warning');
  like($warnings[0], qr/'books'/, 'warning names the relationship');
  like($warnings[0], qr/skipping/, 'warning states the field is skipped');
}

done_testing;
