
package Test::CDBI::Variant;
use base qw(Class::DBI);
__PACKAGE__->connection("dbi:SQLite:dbname=t/variants.db");

__PACKAGE__->add_relationship_type(
	has_variant => 'Class::DBI::Relationship::HasVariant'
);

sub get_pristene_db  {
  unlink 't/variants.db';
  my $SQL = <<'SQL';
  CREATE TABLE albumattributes
  (albumattrid INTEGER, attribute, attr_value);

  INSERT INTO albumattributes VALUES (1, 'size', 16);

  INSERT INTO albumattributes VALUES (2, 'area', 16);

  INSERT INTO albumattributes VALUES (3, 'start_end', '1,100');

  CREATE TABLE booleans (bid INTEGER, boolean);

  INSERT INTO booleans VALUES (1, 0);

  INSERT INTO booleans VALUES (2, 1);

  INSERT INTO booleans VALUES (3, NULL);
SQL

  my $dbh = DBI->connect('dbi:SQLite:dbname=t/variants.db');
  $dbh->do($_) for split /\n\n/, $SQL;
}
       
package Boolean::Stored;
use base qw(Test::CDBI::Variant);

__PACKAGE__->table("booleans");
__PACKAGE__->columns(All => qw(bid boolean));

__PACKAGE__->has_variant(
	boolean => undef,
	deflate => sub {
		return undef unless defined $_[0];
		return undef if ($_[0] and $_[0] == 0);
		return 1 if $_[0];
		return 0 unless $_[0];
	}
);

package Music::Album::Attribute;
use base qw(Test::CDBI::Variant);

Music::Album::Attribute->add_relationship_type(
	has_variant =>
	'Class::DBI::Relationship::HasVariant'
);

Music::Album::Attribute->table("albumattributes");

Music::Album::Attribute->columns(All => qw(albumattrid attribute attr_value));

Music::Album::Attribute->has_variant(
	attr_value => 'Music::Album::Attribute::Transformer',
	inflate => 'inflate',
	deflate => 'deflate'
);

package Music::Album::Attribute::Transformer;

sub inflate { shift;
	my ($value, $obj) = @_;

	if ($obj->attribute eq 'size') {
		return Music::Album::Edge->new({value => $value});
	} elsif ($obj->attribute eq 'area') {
		return Music::Album::Edge->new({value => ($value ** (1/2))});
	} elsif ($obj->attribute eq 'start_end') {
		my ($start,$end) = ($value =~ /^(\d+),(\d+)$/);
		return Music::Album::StartEnd->new({start => $start, end => $end});
	}
	return $value;
}

sub deflate { shift;
	my ($value, $obj) = @_;
	
	return $value unless ref $value;

	if ($obj->attribute eq 'size') {
		return $value->value;
	} elsif ($obj->attribute eq 'area') {
		return $value->value ** 2;
	} elsif ($obj->attribute eq 'start_end') {
		return join(',', ($value->start, $value->end));
	}
	return $value;
}

package Music::Album::Edge;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(value));

package Music::Album::StartEnd;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(start end));

1;
