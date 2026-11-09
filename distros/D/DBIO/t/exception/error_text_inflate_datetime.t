# ABSTRACT: the inflate error of a datetime column names column and class, not the value
use strict;
use warnings;

use Test::More;

BEGIN {
  eval { require DateTime; require DateTime::Format::Strptime; 1 }
    or plan skip_all => "DateTime / DateTime::Format::Strptime not installed: $@";
}

use DBIO::Test::Storage;

# ADR 0075. What this file claims: the error of an inflate that fails names the
# column and the class of the row; neither the value of the column nor the
# text of the parser that quotes it is in the message. The parser here refuses
# every value and quotes it, as parsers do.

{
  package T::ICDT::Parser;
  sub parse_datetime  { die "Invalid date format: $_[1] at somewhere line 1\n" }
  sub format_datetime { die "Cannot format $_[1]\n" }
  sub new { bless {}, shift }

  package T::ICDT::Schema;
  use base 'DBIO::Schema';

  package T::ICDT::Schema::Result::Event;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw/InflateColumn::DateTime/);
  __PACKAGE__->table('event');
  __PACKAGE__->add_columns(
    id          => { data_type => 'integer', is_auto_increment => 1 },
    starts_when => { data_type => 'datetime' },
  );
  __PACKAGE__->set_primary_key('id');
}

T::ICDT::Schema->register_class(Event => 'T::ICDT::Schema::Result::Event');
T::ICDT::Schema->storage_type('+DBIO::Test::Storage');
my $schema  = T::ICDT::Schema->connect(sub { });
my $storage = DBIO::Test::Storage->new($schema);
$storage->datetime_parser_type('T::ICDT::Parser');
$schema->storage($storage);

my $row = $schema->resultset('Event')->new_result({});
$row->store_column(starts_when => 'geheim-datum-2026');

my $err;
eval { $row->starts_when; 1 } or $err = "$@";

like $err, qr/Error while inflating column 'starts_when' of class T::ICDT::Schema::Result::Event/,
  'the message names column and class';
unlike $err, qr/geheim-datum/, 'the value is not in the message';
like $err, qr/Invalid date format: \*\*\*/, 'the text of the parser is kept, its value masked';

# the deflate side
my $err2;
eval { $row->starts_when(DateTime->new(year => 2026)); $row->get_column('starts_when'); 1 }
  or $err2 = "$@";
unlike $err2 // '', qr/2026/, 'a failing deflate holds no value either';

done_testing;
