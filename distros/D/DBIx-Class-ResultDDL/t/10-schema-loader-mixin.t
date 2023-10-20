use Test2::V0;
use File::Temp;

my $can_inflate_json;
BEGIN {
	# Test can't run without these, but this dist does not depend on them.
	for (qw( DBIx::Class::Schema::Loader DBIx::Class::Schema::Loader::DBI::SQLite DBD::SQLite )) {
		plan(skip_all => "Missing optional dependency $_")
			unless eval "require $_";
	}
	$can_inflate_json= !!eval "require DBIx::Class::InflateColumn::Serializer::JSON;";
}

{ # Example of subclassing the DBI::SQLite schema loader
	package MyLoader;
	use parent
		'DBIx::Class::ResultDDL::SchemaLoaderMixin',
		'DBIx::Class::Schema::Loader::DBI::SQLite';
	1;
}

{ # another example, but with json inflation
	package MyLoaderWithJson;
	use parent
		'DBIx::Class::ResultDDL::SchemaLoaderMixin',
		'DBIx::Class::Schema::Loader::DBI::SQLite';
	sub generate_resultddl_import_line {
		return "use DBIx::Class::ResultDDL qw/ -V2 -inflate_json /;\n"
	}
	sub generate_column_info_sugar {
		my ($self, $class, $colname, $colinfo)= @_;
		if ($colname eq 'jsoncol' || $colname eq 'textcol') {
			$colinfo->{serializer_class}= 'JSON'
		}
		$self->next::method($class, $colname, $colinfo);
	}
	1;
}

{ # another example, but with date inflation
	package MyLoaderWithDatetime;
	use parent
		'DBIx::Class::ResultDDL::SchemaLoaderMixin',
		'DBIx::Class::Schema::Loader::DBI::SQLite';
	sub generate_resultddl_import_line {
		return "use DBIx::Class::ResultDDL qw/ -V2 -inflate_datetime /;\n"
	}
	sub generate_column_info_sugar {
		my ($self, $class, $colname, $colinfo)= @_;
		if ($colname eq 'textcol') {
			$colinfo->{inflate_datetime}= 1;
		}
		if ($colname eq 'datetimecol') {
			$colinfo->{inflate_datetime}= 0;
		}
		elsif ($colname eq 'datetimecol2') {
			$colinfo->{timezone}= 'America/New_York';
		}
		$self->next::method($class, $colname, $colinfo);
	}
	1;
}

# Create a temp dir for writing the SQLite database and dumping the schema
my $tmpdir= File::Temp->newdir;
my $dsn= "dbi:SQLite:$tmpdir/db.sqlite";
mkdir "$tmpdir/lib" or die "mkdir: $!";

# Populate the SQLite with a schema
my $db= DBI->connect($dsn, undef, undef, { AutoCommit => 1, RaiseError => 1 });
$db->do($_) for split /;\n/, <<SQL;
CREATE TABLE example (
	id integer primary key autoincrement not null,
	textcol text not null,
	varcharcol varchar(100),
	datetimecol datetime not null default CURRENT_TIMESTAMP,
	datetimecol2 datetime null,
	jsoncol json null
);
CREATE TABLE artist (
	name varchar(100) not null primary key
);
CREATE TABLE album (
	artist_name varchar(100) not null,
	album_name varchar(255) not null,
	release_date datetime not null,
	primary key (artist_name, album_name),
	foreign key (artist_name) references artist(name)
);
SQL
undef $db;

my %loader_options= (
	debug => 1,
	dump_directory => "$tmpdir/lib",
	naming => 'v7',
	relationship_attrs => {
		has_many => {
			cascade_delete => 0,
			cascade_copy   => 0,
		},
		might_have => {
			cascade_delete => 0,
			cascade_copy   => 0,
		},
		belongs_to => {
			on_delete => 'CASCADE',
			on_update => 'CASCADE',
			is_deferrable => 1,
		},
	},
);

subtest standard => sub {
	# Run Schema Loader on the SQLite database
	DBIx::Class::Schema::Loader::make_schema_at(
		'My::Schema',
		\%loader_options,
		[ $dsn, '', '', { loader_class => 'MyLoader' } ],
	);

	# Load the generated classes and verify the data that they declare
	unshift @INC, "$tmpdir/lib";
	ok( (eval 'require My::Schema' || diag $@), 'Able to load generated schema' );
	is( [ sort My::Schema->sources ], [qw( Album Artist Example )], 'ResultSource list' );
	is( [ My::Schema->source('Example')->columns ], [qw( id textcol varcharcol datetimecol datetimecol2 jsoncol )], 'Example column list' );

	# Verify the sugar methods got used in the source code
	my $example_src= slurp("$tmpdir/lib/My/Schema/Result/Example.pm");
	verify_contains_lines( $example_src, <<'PL', 'Result::Example.pm' ) or diag "Unexpected sourcecode:\n$example_src";
	use DBIx::Class::ResultDDL qw/ -V2 /;
	table 'example';
	col id           => integer, is_auto_increment => 1;
	col textcol      => text;
	col varcharcol   => varchar(100), null;
	col datetimecol  => datetime default(\'current_timestamp');
	col datetimecol2 => datetime null;
	col jsoncol      => json null;
	primary_key 'id';
PL

	# Verify has_many & belongs_to between artist and album
	my $artist_src= slurp("$tmpdir/lib/My/Schema/Result/Artist.pm");
	my $album_src=  slurp("$tmpdir/lib/My/Schema/Result/Album.pm");
	verify_contains_lines( $artist_src, <<'PL', 'Result::Artist.pm' ) or diag "Unexpected sourcecode:\n$artist_src";
	table 'artist';
	col name => varchar(100);
	primary_key 'name';
	
	has_many albums => { name => 'Album.artist_name' }, dbic_cascade(0);
PL
	verify_contains_lines( $album_src, <<'PL', 'Result::Album.pm' ) or diag "Unexpected sourcecode:\n$album_src";
	table 'album';
	col artist_name  => varchar(100), fk;
	col album_name   => varchar(255);
	col release_date => datetime;
	primary_key 'artist_name', 'album_name';
	
	belongs_to artist_name => { artist_name => 'Artist.name' }, ddl_cascade, is_deferrable => 1;
PL
};

subtest with_inflate_json => sub {
	plan skip_all => 'Require DBIx::Class::InflateColumn::Serializer::JSON for this test'
		unless $can_inflate_json;

	# Run Schema Loader on the SQLite database
	DBIx::Class::Schema::Loader::make_schema_at(
		'My::SchemaWithJson',
		\%loader_options,
		[ $dsn, '', '', { loader_class => 'MyLoaderWithJson' } ],
	);

	# Load the generated classes and verify the data that they declare
	unshift @INC, "$tmpdir/lib";
	ok( (eval 'require My::SchemaWithJson' || diag $@), 'Able to load generated schema' );
	is( [ My::SchemaWithJson->source('Example')->columns ], [qw( id textcol varcharcol datetimecol datetimecol2 jsoncol )], 'Example column list' );

	# Verify the sugar methods got used in the source code
	my $example_src= slurp("$tmpdir/lib/My/SchemaWithJson/Result/Example.pm");
	verify_contains_lines( $example_src, <<'PL', 'Result::Example.pm' ) or diag "Unexpected sourcecode:\n$example_src";
	use DBIx::Class::ResultDDL qw/ -V2 -inflate_json /;
	col textcol => text inflate_json;
	col jsoncol => json null;
PL
};

subtest with_inflate_datetime => sub {
	# Run Schema Loader on the SQLite database
	DBIx::Class::Schema::Loader::make_schema_at(
		'My::SchemaWithDatetime',
		\%loader_options,
		[ $dsn, '', '', { loader_class => 'MyLoaderWithDatetime' } ],
	);

	# Load the generated classes and verify the data that they declare
	unshift @INC, "$tmpdir/lib";
	ok( (eval 'require My::SchemaWithDatetime' || diag $@), 'Able to load generated schema' );
	is( [ My::SchemaWithDatetime->source('Example')->columns ], [qw( id textcol varcharcol datetimecol datetimecol2 jsoncol )], 'Example column list' );

	# Verify the sugar methods got used in the source code
	my $example_src= slurp("$tmpdir/lib/My/SchemaWithDatetime/Result/Example.pm");
	verify_contains_lines( $example_src, <<'PL', 'Result::Example.pm' ) or diag "Unexpected sourcecode:\n$example_src";
	use DBIx::Class::ResultDDL qw/ -V2 -inflate_datetime /;
	col textcol      => text, inflate_datetime => 1;
	col datetimecol  => datetime default(\'current_timestamp'), inflate_datetime => 0;
	col datetimecol2 => datetime('America/New_York'), null;
PL
};

done_testing;


sub slurp { open my $fh, '<', $_[0] or die "open:$!"; local $/= undef; <$fh> }

# Run a subtest that ensures each line of $lines is found in-order in $text,
# ignoring whitespace differences and ignoring arbitrary lines inbetween.
sub verify_contains_lines {
	my ($text, $lines, $message)= @_;
	subtest $message => sub {
		pos($text)= 0;
		for (split /\n/, $lines) {
			my $regex= quotemeta($_).'\\ ';
			# replace run of escaped literal whitespace with whitespace wildcard
			$regex =~ s/(\\\s)+/\\s*/g;
			my $p= pos($text);
			unless ( ok( $text =~ /^$regex/mgc, "Found line '$_'" ) ) {
				note "Searching from: ".($text =~ /(.*)/gc? "'$1'" : '(end of input)');
				pos($text)= $p;
			}
		}
	};
}
