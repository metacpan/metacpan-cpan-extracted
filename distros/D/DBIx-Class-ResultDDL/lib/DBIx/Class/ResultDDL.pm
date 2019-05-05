package DBIx::Class::ResultDDL;
# capture the default values of $^H and $^W for this version of Perl
BEGIN { $DBIx::Class::ResultDDL::_default_h= $^H; $DBIx::Class::ResultDDL::_default_w= $^W; }
use Exporter::Extensible -exporter_setup => 1;
use B::Hooks::EndOfScope 'on_scope_end';
use Carp;

# ABSTRACT: Sugar methods for declaring DBIx::Class::Result data definitions
our $VERSION = '0.01'; # VERSION


our $CALLER; # can be used localized to wrap caller context into an anonymous sub

sub swp :Export(-) {
	my $self= shift;
	require strict; strict->import if $^H == $DBIx::Class::ResultDDL::_default_h;
	require warnings; warnings->import if $^W == $DBIx::Class::ResultDDL::_default_w;
	unless ($self->{into}->can('add_column')) {
		require DBIx::Class::Core;
		no strict 'refs';
		push @{ $self->{into} . '::ISA' }, 'DBIx::Class::Core';
	}
}


sub autoclean :Export(-) {
	my $x;
	shift->{scope} ||= \$x;
	on_scope_end { undef $x };
}


sub V0 :Export(-) {
	shift->exporter_also_import('-swp',':V0','-autoclean');
}


my @V0= qw(
	table
	col
	  null default auto_inc fk
	  integer unsigned tinyint smallint bigint decimal numeric
	  char varchar nchar nvarchar binary varbinary blob text ntext
	  date datetime timestamp enum bool boolean
	  inflate_json
	primary_key
	rel_one rel_many has_one might_have has_many belongs_to many_to_many
	  ddl_cascade dbic_cascade
);
our %EXPORT_TAGS;
$EXPORT_TAGS{V0}= \@V0;
export @V0;


sub table {
	my $name= shift;
	DBIx::Class::Core->can('table')->(scalar($CALLER||caller), $name);
}


sub col {
	my $name= shift;
	croak "Odd number of arguments for col(): (".join(',',@_).")"
		if scalar(@_) & 1;
	my $opts= { is_nullable => 0 };
	# Apply options to the hash in order, so that they get overwritten as expected
	while (@_) {
		my ($k, $v)= (shift, shift);
		$opts->{$k}= $v, next
			unless index($k, '.') >= 0;
		# We support "foo.bar => $v" syntax which we convert to "foo => { bar => $v }"
		# because "foo => { bar => 1 }, foo => { baz => 2 }" would overwrite eachother.
		my @path= split /\./, $k;
		$k= pop @path;
		my $dest= $opts;
		$dest= ($dest->{$_} ||= {}) for @path;
		$dest->{$k}= $v;
	}
	($CALLER||caller)->add_column($name, $opts);
}


sub null       { is_nullable => 1 }
sub auto_inc   { is_auto_increment => 1 }
sub fk         { is_foreign_key => 1 }
#sub pk        { is_primary_key => 1 }
sub default    { default_value => (@_ > 1? [ @_ ] : $_[0]) }


sub integer     { data_type => 'integer',   size => (defined $_[0]? $_[0] : 11) }
sub unsigned    { 'extra.unsigned' => 1 }
sub tinyint     { data_type => 'tinyint',   size => 4 }
sub smallint    { data_type => 'smallint',  size => 6 }
sub bigint      { data_type => 'bigint',    size => 22 }
sub decimal     {
	croak "2 size parameters are required" unless scalar(@_) == 2;
	return data_type => 'decimal',   size => [ @_ ];
}
sub numeric     { &decimal, data_type => 'numeric' }


sub char        { data_type => 'char',      size => (defined $_[0]? $_[0] : 1) }
sub nchar       { data_type => 'nchar',     size => (defined $_[0]? $_[0] : 1) }
sub varchar     { data_type => 'varchar',   size => (defined $_[0]? $_[0] : 255) }
sub nvarchar    { data_type => 'nvarchar',  size => (defined $_[0]? $_[0] : 255) }
sub MAX         { 'MAX' }
sub binary      { data_type => 'binary',    size => (defined $_[0]? $_[0] : 255) }
sub varbinary   { data_type => 'varbinary', size => (defined $_[0]? $_[0] : 255) }

sub blob        { data_type => 'blob',      (defined $_[0]? (size => $_[0]) : ()) }
sub tinyblob    { data_type => 'tinyblob',  size => 0xFF }
sub mediumblob  { data_type => 'mediumblob',size => 0xFFFFFF }
sub longblob    { data_type => 'longblob',  size => 0xFFFFFFFF }

sub text        { data_type => 'text',      (defined $_[0]? (size => $_[0]) : ()) }
sub ntext       { data_type => 'ntext',     size => (defined $_[0]? $_[0] : 0x3FFFFFFF) }
sub tinytext    { data_type => 'tinytext',  size => 0xFF }
sub mediumtext  { data_type => 'mediumtext',size => 0xFFFFFF }
sub longtext    { data_type => 'longtext',  size => 0xFFFFFFFF }


sub enum        { data_type => 'enum', 'extra.list' => [ @_ ]}
sub boolean     { data_type => 'boolean' }
sub bool        { data_type => 'boolean' }
sub bit         { data_type => 'bit',  size => (defined $_[0]? $_[0] : 1) }


sub date        { data_type => 'date',     (@_? (time_zone => $_[0]) : ()) }
sub datetime    { data_type => 'datetime', (@_? (time_zone => $_[0]) : ()) }
sub timestamp   { data_type => 'timestamp',(@_? (time_zone => $_[0]) : ()) }


sub inflate_json {
	my $pkg= ($CALLER||caller);
	$pkg->load_components('InflateColumn::Serializer')
		unless $pkg->isa('DBIx::Class::InflateColumn::Serializer');
	return serializer_class => 'JSON';
}


sub primary_key { ($CALLER||caller)->set_primary_key(@_); }


sub rel_one {
	_add_rel(scalar($CALLER||caller), 'rel_one', @_);
}
sub rel_many {
	_add_rel(scalar($CALLER||caller), 'rel_many', @_);
}
sub might_have {
	_add_rel(scalar($CALLER||caller), 'might_have', @_);
}
sub has_one {
	_add_rel(scalar($CALLER||caller), 'has_one', @_);
}
sub has_many {
	_add_rel(scalar($CALLER||caller), 'has_many', @_);
}
sub belongs_to {
	_add_rel(scalar($CALLER||caller), 'belongs_to', @_);
}
sub many_to_many {
	DBIx::Class::Core->can('many_to_many')->(scalar($CALLER||caller), @_);
}

sub _add_rel {
	my ($pkg, $reltype, $name, $maybe_colmap, @opts)= @_;
	my ($rel_pkg, $dbic_colmap)= ref $maybe_colmap eq 'HASH'? _translate_colmap($maybe_colmap, $pkg)
		: !ref $maybe_colmap? ( _interpret_pkg_name($maybe_colmap, $pkg), shift(@opts) )
		: croak "Unexpected arguments";
	
	if ($reltype eq 'rel_one' || $reltype eq 'rel_many') {
		# Are we referring to the foreign row's primary key?  DBIC load order might not have
		# gotten there yet, so take a guess that if it isn't a part of our primary key, then it
		# is a part of their primary key.
		my @pk= $pkg->primary_columns;
		my $is_f_key= !grep { defined $dbic_colmap->{$_} || defined $dbic_colmap->{"self.$_"} } @pk;
		
		$pkg->add_relationship(
			$name,
			$rel_pkg,
			$dbic_colmap,
			{
				accessor => ($reltype eq 'rel_one'? 'single' : 'multi'),
				join_type => 'LEFT',
				($is_f_key? (
					fk_columns => { map { do {(my $x= $_) =~ s/^self\.//; $x } => 1 } values %$dbic_colmap },
					is_depends_on => 1,
					is_foreign_key_constraint => 1,
					undef_on_null_fk => 1,
				) : (
					is_depends_on => 0,
				)),
				cascade_copy => 0, cascade_delete => 0,
				@opts
			}
		);
	} else {
		require DBIx::Class::Core;
		DBIx::Class::Core->can($reltype)->($pkg, $name, $rel_pkg, $dbic_colmap, { @opts });
	}
}

sub _interpret_pkg_name {
	my ($rel_class, $current_pkg)= @_;
	# Related class may be relative to same namespace as current
	return $rel_class if index($rel_class, '::') >= 0;
	my ($parent_namespace)= ($current_pkg =~ /(.*)::[^:]+$/);
	return $parent_namespace.'::'.$rel_class;
}

# DBIC is normally { foreign.col => self.col } but I don't think that's very intuitive,
# so allow an alternate notation of { self_col => CLASS.col } and automatically determine
# which the user is using.
sub _translate_colmap {
	my ($colmap, $self_pkg)= @_;
	my ($rel_class, $direction, %result, $inconsistent)= ('',0);
	# First pass, find the values for $rel_class and $reverse
	for (keys %$colmap) {
		my ($key, $val)= ($_, $colmap->{$_});
		if ($key =~ /([^.]+)\.(.*)/) {
			if ($1 eq 'self') {
				$direction ||= 1;
				++$inconsistent if $direction < 0;
			}
			else {
				$direction ||= -1;
				++$inconsistent if $direction > 0;
				if ($1 ne 'foreign') {
					$rel_class ||= $1;
					++$inconsistent if $rel_class ne $1;
				}
			}
		}
		if ($val =~ /([^.]+)\.(.*)/) {
			if ($1 eq 'self') {
				$direction ||= -1;
				++$inconsistent if $direction > 0;
			}
			else {
				$direction ||= 1;
				++$inconsistent if $direction < 0;
				if ($1 ne 'foreign') {
					$rel_class ||= $1;
					++$inconsistent if $rel_class ne $1;
				}
			}
		}
	}
	croak "Inconsistent {self=>foreign} notation found in relation mapping"
		if $inconsistent;
	croak "Must reference foreign Result class name in one of the keys or values of relation mapping"
		unless $rel_class && $direction;
	# Related class may be relative to same namespace as current
	$rel_class= _interpret_pkg_name($rel_class, $self_pkg);
	
	# Second pass, rename the keys & values to DBIC canonical notation
	for (keys %$colmap) {
		my ($key, $val)= ($_, $colmap->{$_});
		$key =~ s/.*\.//;
		$val =~ s/.*\.//;
		$result{ $direction > 0? "foreign.$val" : "foreign.$key" }= $direction > 0? "self.$key" : "self.$val";
	}
	return $rel_class, \%result;
}


sub ddl_cascade {
	my $mode= shift;
	$mode= 'CASCADE' if !defined $mode || $mode eq '1';
	$mode= 'RESTRICT' if $mode eq '0';
	return
		on_update => $mode,
		on_delete => $mode;
}


sub dbic_cascade {
	my $mode= defined $_[0]? $_[0] : 1;
	return
		cascade_copy => $mode,
		cascade_delete => $mode;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::ResultDDL - Sugar methods for declaring DBIx::Class::Result data definitions

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use DBIx::Class::ResultDDL -V0;
  table 'artist';
  col id   => integer, unsigned, auto_inc;
  col name => varchar(25), null;
  primary_key 'id';
  
  has_many albums => { id => 'Album.artist_id' };
  rel_many impersonators => { name => 'Artist.name' };

=head1 DESCRIPTION

This is Yet Another Sugar Module for building DBIC result classes.  It provides a
domain-specific-language that feels almost like writing DDL.

This module heavily pollutes your symbol table in the name of extreme convenience, so the
C<-V0> option has the added feature of automatically removing those symbols at end-of-scope
as if you had said C<use namespace::clean;>.

This module has a versioned API, to help prevent name collisions.  If you request the C<-v0>
behavior, you can rely on that to remain the same across upgrades.

=head1 EXPORTED FEATURES

This module is based on L<Exporter::Extensible>, allowing all the import notations that module
provides.  Every export beginning with a dash indicates custom behavior, rather than just a
simple export of symbols.

=head2 C<-swp>

Enable C<use strict> and C<use warnings> (unless those flags have been changed from the default
via other means), and C<< use parent "DBIx::Class::Core" >> unless
C<< __PACKAGE__->can('add_column') >>.

=head2 C<-autoclean>

Remove all added symbols at the end of current scope.

=head2 C<-V0>

Implies C<-swp>, C<:V0>, and C<-autoclean>.

=head1 EXPORTED COLLECTIONS

=head2 C<:V0>

This tag selects the following symbols:

  table
  col
    null default auto_inc fk
    integer unsigned tinyint smallint bigint decimal numeric
    char varchar nchar nvarchar binary varbinary blob text ntext
    tinyblob mediumblob longblob tinytext mediumtext longtext
    date datetime timestamp enum bool boolean
    inflate_json
  primary_key
  rel_one rel_many has_one might_have has_many belongs_to many_to_many
    ddl_cascade dbic_cascade

=head1 EXPORTED METHODS

=head2 table

  table 'foo';
  # becomes...
  __PACKAGE__->table('foo');

=head2 col

  col $name, @options;
  # becomes...
  __PACKAGE__->add_column($name, { is_nullable => 0, @merged_options });

Define a column.  This calls add_column after sensibly merging all your options.
It defaults the column to not-null for you, but you can override that by saying
C<null> in your options.
You will probably use many of the methods below to build the options for the column:

=over

=item null

  is_nullable => 1

=item auto_inc

  is_auto_increment => 1

=item fk

  is_foreign_key => 1

=item default($value | @value)

  default_value => $value
  default_value => [ @value ] # if more than one param

=item integer, integer($size)

  data_type => 'integer', size => $size // 11

=item unsigned

  extra => { unsigned => 1 }

MySQL specific flag to be combined with C<integer>

=item tinyint

  data_type => 'tinyint', size => 4

=item smallint

  data_type => 'smallint', size => 6

=item bigint

  data_type => 'bigint', size => 22

=item decimal( $whole, $deci )

  data_type => 'decimal', size => [ $whole, $deci ]

=item numeric( $whole, $deci )

  data_type => 'numeric', size => [ $whole, $deci ]

=item char, char($size)

  data_type => 'char', size => $size // 1

=item varchar, varchar($size), varchar(MAX)

  data_type => 'varchar', size => $size // 255

=item nchar

SQL Server specific type for unicode char

=item nvarchar, nvarchar($size), nvarchar(MAX)

SQL Server specific type for unicode character data.

  data_type => 'nvarchar', size => $size // 255

=item MAX

Constant for 'MAX', used by SQL Server for C<< varchar(MAX) >>.

=item binary, binary($size)

  data_type => 'binary', size => $size // 255

=item varbinary, varbinary($size)

  data_type => 'varbinary', size => $size // 255

=item blob, blob($size)

  data_type => 'blob',
  size => $size if defined $size

Note: For MySQL, you need to change the type according to '$size'.  A MySQL blob is C<< 2^16 >>
max length, and probably none of your binary data would be that small.  Consider C<mediumblob>
or C<longblob>, or consider overriding C<< My::Schema::sqlt_deploy_hook >> to perform this
conversion automatically according to which DBMS you are connected to.

For SQL Server, newer versions deprecate C<blob> in favor of C<VARCHAR(MAX)>.  This is another
detail you might take care of in sqlt_deploy_hook.

=item tinyblob

MySQL-specific type for small blobs

  data_type => 'tinyblob', size => 0xFF

=item mediumblob

MySQL-specific type for larger blobs

  data_type => 'mediumblob', size => 0xFFFFFF

=item longblob

MySQL-specific type for the longest supported blob type

  data_type => 'longblob', size => 0xFFFFFFFF

=item text, text($size)

  data_type => 'text',
  size => $size if defined $size

See MySQL notes in C<blob>.  For SQL Server, you might want C<ntext> or C<< varchar(MAX) >> instead.

=item tinytext

  data_type => 'tinytext', size => 0xFF

=item mediumtext

  data_type => 'mediumtext', size => 0xFFFFFF

=item longtext

  data_type => 'longtext', size => 0xFFFFFFFF

=item ntext

SQL-Server specific type for unicode C<text>.  Note that newer versions prefer C<< nvarchar(MAX) >>.

  data_type => 'ntext', size => 0x3FFFFFFF

=item enum( @values )

  data_type => 'enum', extra => { list => [ @values ] }

=item bool, boolean

  data_type => 'boolean'

Note that SQL Server has 'bit' instead.

=item bit, bit($size)

  data_type => 'bit', size => $size // 1

To be database agnostic, consider using 'bool' and override C<< My::Scema::sqlt_deploy_hook >>
to rewrite it to 'bit' when deployed to SQL Server.

=item date, date($timezone)

  data_type => 'date'
  time_zone => $timezone if defined $timezone

=item datetime, datetime($timezone)

  data_type => 'datetime'
  time_zone => $timezone if defined $timezone

=item timestamp, timestamp($timezone)

  date_type => 'timestamp'
  time_zone => $timezone if defined $timezone

=item inflate_json

  serializer_class => 'JSON'

Also adds the component 'InflateColumn::Serializer' to the current package if it wasn't
added already.

=back

=head2 primary_key

  primary_key(@cols)

Shortcut for __PACKAGE__->set_primary_key(@cols)

=head2 belongs_to

  belongs_to $rel_name, $peer_class, $condition, @attr_list;
  belongs_to $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->belongs_to($rel_name, $peer_class, $condition, { @attr_list });

Note that the normal DBIC belongs_to requires conditions to be of the form

  { "foreign.$their_col" => "self.$my_col" }

but all these sugar functions allow it to be written the other way around, and use a table
name in place of "foreign.".

=head2 might_have

  might_have $rel_name, $peer_class, $condition, @attr_list;
  might_have $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->might_have($rel_name, $peer_class, $condition, { @attr_list });

=head2 has_one

  has_one $rel_name, $peer_class, $condition, @attr_list;
  has_one $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->has_one($rel_name, $peer_class, $condition, { @attr_list });

=head2 has_many

  has_many $rel_name, $peer_class, $condition, @attr_list;
  has_many $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->has_one($rel_name, $peer_class, $condition, { @attr_list });

=head2 many_to_many

  many_to_many $name => $rel_to_linktable, $rel_from_linktable;
  # becomes...
  __PACKAGE__->many_to_many(@_);

=head2 rel_one

Declares a single-record left-join relation B<without implying ownership>.
Note that the DBIC relations that do imply ownership like C<might_have> I<cause an implied
deletion of the related row> if you delete a row from this table that references it, even if
your schema did not have a cascading foreign key.  This DBIC feature is controlled by the
C<cascading_delete> option, and using this sugar function to set up the relation defaults that
feature to "off".

  rel_one $rel_name, $peer_class, $condition, @attr_list;
  rel_one $rel_name, { $mycol => "$ResultClass.$fcol", ... }, @attr_list;
  # becomes...
  __PACKAGE__->add_relationship(
    $rel_name, $peer_class, { "foreign.$fcol" => "self.$mycol" },
    {
      join_type => 'LEFT',
      accessor => 'single',
      cascade_copy => 0,
      cascade_delete => 0,
      is_depends_on => $is_f_pk, # auto-detected, unless specified
      ($is_f_pk? fk_columns => { $mycol => 1 } : ()),
      @attr_list
    }
  );

=head2 rel_many

  rel_many $name => { $my_col => "$class.$col", ... }, @options;

Same as L</rel_one>, but generates a one-to-many relation with a multi-accessor.

=head2 ddl_cascade

  ddl_cascade;     # same as ddl_cascade("CASCADE");
  ddl_cascade(1);  # same as ddl_cascade("CASCADE");
  ddl_cascade(0);  # same as ddl_cascade("RESTRICT");
  ddl_cascade($mode);

Helper method to generate C<@options> for above.  It generates

  on_update => $mode, on_delete => $mode

This does not affect client-side cascade, and is only used by Schema::Loader to generate DDL
for the foreign keys when the table is deployed.

=head2 dbic_cascade

  dbic_cascade;  # same as dbic_cascade(1)
  dbic_cascade($enabled);

Helper method to generate C<@options> for above.  It generates

  cascade_copy => $enabled, cascade_delete => $enabled

This re-enables the dbic-side cascading that was disabled by default in the C<rel_> functions.

=head1 MISSING FUNCTIONALITY

The methods above in most cases allow you to insert plain-old-DBIC notation
where appropriate, instead of relying purely on sugar methods.
If you are missing your favorite column flag or something, feel free to
contribute a patch.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
