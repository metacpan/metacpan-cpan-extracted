use strict;
use warnings;

use Test::More;

# DBIO::Test::Conformance::conformance_quote_ident (ADR 0060, karr k349): the
# view definition of a case is built from identifiers the runner quotes
# through the hook, so a driver that always quotes finds the table the
# install created. Default: the quoting rule of the connected storage.

use DBIO::Test::Conformance;
use DBIO::Test::Conformance::Cases::DDL;
use DBIO::Test::Storage;

{
  package QConf;
  use base 'DBIO::Test::Conformance';

  our (%SEEN, $STORAGE, %ATTRS);

  sub conformance_live_available { 1 }
  sub conformance_connect {
    my ($class, $schema_class) = @_;
    $schema_class->storage_type($STORAGE);
    return $schema_class->connect(sub { }, { %ATTRS });
  }
  sub conformance_install {
    my ($class, $schema, $case) = @_;
    $SEEN{definition} = $schema->source('BaseView')->view_definition;
  }
  sub conformance_cleanup { }
  sub conformance_diff_is_empty { 1 }
  sub conformance_fact { undef }
  # the fake storage has no server behind it: the one row of the case is there
  sub conformance_count { 1 }

  package QConf::Bracket;
  use base 'QConf';
  sub conformance_quote_ident {
    my ($class, $schema, $name) = @_;
    return "[$name]";
  }

  package QConf::Square;  # a pair quote char
  use base 'DBIO::Test::Storage';
  __PACKAGE__->sql_quote_char([ '[', ']' ]);
}

sub definition_with {
  my ($conf, $storage, %attrs) = @_;
  local $QConf::STORAGE = $storage;
  local %QConf::ATTRS = %attrs;
  local %QConf::SEEN;
  $conf->results('DDL', only => ['ddl-view-declared']);
  return $QConf::SEEN{definition};
}

is definition_with('QConf::Bracket', 'DBIO::Test::Storage'),
  'SELECT [id], [name] FROM [base]',
  'the hook of the driver quotes every identifier of the view definition';

is definition_with('QConf', 'DBIO::Test::Storage'),
  'SELECT "id", "name" FROM "base"',
  'default: the quoting rule of the storage';

is definition_with('QConf', 'DBIO::Test::Storage', quote_names => 0),
  'SELECT id, name FROM base',
  'default: no quote char, no quoting';

is definition_with('QConf', 'QConf::Square'),
  'SELECT [id], [name] FROM [base]',
  'default: a pair quote char opens and closes';

# a closing quote character inside the name is doubled
{
  { package QConf::Schema; use base q{DBIO::Schema}; }
  my $base = q{QConf::Schema};
  $base->storage_type(q{DBIO::Test::Storage});
  my $quote = sub {
    my ($name, %attrs) = @_;
    my $schema = $base->connect(sub { }, { %attrs });
    return DBIO::Test::Conformance->conformance_quote_ident($schema, $name);
  };

  is $quote->('a"b'), '"a""b"',
    'single quote char: the character itself is doubled';
  is $quote->('a`b"c', quote_char => '`', name_sep => '.'), '`a``b"c`',
    'backtick: only the backtick is doubled';
  is $quote->('a]b[c', quote_char => [ '[', ']' ], name_sep => '.'), '[a]]b[c]',
    'pair: only the closing character is doubled';
}

done_testing;
