package DBIx::SchemaChecksum;

use 5.010;
use Moose;

# ABSTRACT: Generate and compare checksums of database schematas
our $VERSION = '1.006';

use DBI;
use Digest::SHA1;
use Data::Dumper;
use Path::Class;
use Carp;
use File::Find::Rule;

has 'dbh' => (
    is => 'ro',
    required => 1
);

has 'catalog' => (
    is => 'ro',
    isa => 'Str',
    default => '%',
    documentation => q[might be required by some DBI drivers]
);

has 'schemata' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { ['%'] },
    documentation => q[List of schematas to include in checksum]
);

has 'sqlsnippetdir' => (
    isa => 'Str',
    is => 'ro',
    documentation => q[Directory containing sql update files],
);

has 'driveropts' => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub {{}},
    documentation => q[Driver specific options],
);

has 'verbose' => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);

has '_update_path' => (
    is => 'rw',
    isa => 'Maybe[HashRef]',
    lazy_build => 1,
    builder => '_build_update_path',
);

has '_schemadump' => (
    isa=>'Str',
    is=>'rw',
    lazy_build=>1,
    clearer=>'reset_checksum',
    builder => '_build_schemadump',
);

sub BUILD {
    my ($self) = @_;

    # Apply driver role to instance
    my $driver = $self->dbh->{Driver}{Name};
    my $class = __PACKAGE__.'::Driver::'.$driver;
    if (Class::Load::try_load_class($class)) {
        $class->meta->apply($self);
    }
    return $self;
}



sub checksum {
    my $self = shift;
    return Digest::SHA1::sha1_hex($self->_schemadump);
}



sub _build_schemadump {
    my $self = shift;

    my %relevants = ();

    foreach my $schema ( @{ $self->schemata } ) {
        my $schema_relevants = $self->_build_schemadump_schema($schema);
        while (my ($type,$type_value) = each %{$schema_relevants}) {
            my $ref = ref($type_value);
            if ($ref eq 'ARRAY') {
                $relevants{$type} ||= [];
                foreach my $value (@{$type_value}) {
                    push(@{$relevants{$type}}, $value);
                }
            }
            elsif ($ref eq 'HASH') {
                while (my ($key,$value) = each %{$type_value}) {
                    $relevants{$type}{$key} = $value;
                }
            }
        }
    }

    my $dumper = Data::Dumper->new( [ \%relevants ] );
    $dumper->Sortkeys(1);
    $dumper->Indent(1);
    my $dump = $dumper->Dump;

    return $dump;
}


sub _build_schemadump_schema {
    my ($self,$schema) = @_;

    my %relevants = ();
    $relevants{tables}    = $self->_build_schemadump_tables($schema);

    return \%relevants;
}


sub _build_schemadump_tables {
    my ($self,$schema) = @_;

    my $dbh = $self->dbh;

    my %relevants;
    foreach my $table ( $dbh->tables( $self->catalog, $schema, '%' ) ) {
        next
            unless $table =~ m/^"?(?<schema>[^"]+)"?\."?(?<table>[^"]+)"?$/;
        my $this_schema = $+{schema};
        my $table = $+{table};

        my $table_data = $self->_build_schemadump_table($this_schema,$table);
        next
            unless $table_data;
        $relevants{$this_schema.'.'.$table} = $table_data;
    }

    return \%relevants;
}


sub _build_schemadump_table {
    my ($self,$schema,$table) = @_;

    my %relevants = ();

    my $dbh = $self->dbh;

    # Primary key
    my @primary_keys = $dbh->primary_key( $self->catalog, $schema, $table );
    $relevants{primary_keys} = \@primary_keys
        if scalar @primary_keys;

    # Columns
    my $sth_col = $dbh->column_info( $self->catalog, $schema, $table, '%' );
    my $column_info = $sth_col->fetchall_hashref('COLUMN_NAME');
    while ( my ( $column, $data ) = each %$column_info ) {
        my $column_data = $self->_build_schemadump_column($schema,$table,$column,$data);
        $relevants{columns}->{$column} = $column_data
            if $column_data;
    }

    # Foreign keys (only use a few selected meta-fields)
    my $sth_fk = $dbh->foreign_key_info( undef, undef, undef, $self->catalog, $schema, $table );
    if ($sth_fk) {
        my $fk={};
        while (my $data = $sth_fk->fetchrow_hashref) {
            my %useful = map { $_ => $data->{$_}} qw(UK_COLUMN_NAME UK_TABLE_NAME UK_TABLE_SCHEM);
            $fk->{$data->{FK_COLUMN_NAME}} = \%useful;
        }
        $relevants{foreign_keys} = $fk if keys %$fk;
    }

    return \%relevants;
}


sub _build_schemadump_column {
    my ($self,$schema,$table,$column,$data) = @_;

    my $relevants = { map { $_ => $data->{$_} } qw(COLUMN_NAME COLUMN_SIZE NULLABLE TYPE_NAME COLUMN_DEF) };

    # some cleanup
    if (my $default = $relevants->{COLUMN_DEF}) {
        if ( $default =~ /nextval/ ) {
            $default =~ m{'([\w\.\-_]+)'};
            if ($1) {
                my $new = $1;
                $new =~ s/^\w+\.//;
                $default = 'nextval:' . $new;
            }
        }
        $default=~s/["'\(\)\[\]\{\}]//g;
        $relevants->{COLUMN_DEF}=$default;
    }

    $relevants->{TYPE_NAME} =~ s/^(?:.+\.)?(.+)$/$1/g;

    return $relevants;
}


sub _build_update_path {
    my $self = shift;
    my $dir = $self->sqlsnippetdir;
    croak("Please specify sqlsnippetdir") unless $dir;
    croak("Cannot find sqlsnippetdir: $dir") unless -d $dir;

    say "Checking directory $dir for checksum_files" if $self->verbose;

    my %update_info;
    my @files = File::Find::Rule->file->name('*.sql')->in($dir);

    foreach my $file ( sort @files ) {
        my ( $pre, $post ) = $self->get_checksums_from_snippet($file);

        if ( !$pre && !$post ) {
            say "skipping $file (has no checksums)" if $self->verbose;
            next;
        }

        if ( $pre eq $post ) {
            if ( $update_info{$pre} ) {
                my @new = ('SAME_CHECKSUM');
                foreach my $item ( @{ $update_info{$pre} } ) {
                    push( @new, $item ) unless $item eq 'SAME_CHECKSUM';
                }
                $update_info{$pre} = \@new;
            }
            else {
                $update_info{$pre} = ['SAME_CHECKSUM'];
            }
        }

        if (   $update_info{$pre}
            && $update_info{$pre}->[0] eq 'SAME_CHECKSUM' )
        {
            if ( $post eq $pre ) {
                splice( @{ $update_info{$pre} },
                    1, 0, Path::Class::File->new($file), $post );
            }
            else {
                push( @{ $update_info{$pre} },
                    Path::Class::File->new($file), $post );
            }
        }
        else {
            $update_info{$pre} = [ Path::Class::File->new($file), $post ];
        }
    }

    return $self->_update_path( \%update_info ) if %update_info;
    return;
}


sub get_checksums_from_snippet {
    my ($self, $filename) = @_;
    die "need a filename" unless $filename;

    my %checksums;

    open( my $fh, "<", $filename ) || croak "Cannot read $filename: $!";
    while (<$fh>) {
        if (m/^--\s+(pre|post)SHA1sum:?\s+([0-9A-Fa-f]{40,})\s+$/) {
            $checksums{$1} = $2;
        }
    }
    close $fh;
    return map { $checksums{$_} || '' } qw(pre post);
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum - Generate and compare checksums of database schematas

=head1 VERSION

version 1.006

=head1 SYNOPSIS

    my $sc = DBIx::SchemaChecksum->new( dbh => $dbh );
    print $sc->checksum;

    # Or use the included script, scs.pl

=head1 DESCRIPTION

When you're dealing with several instances of the same database (eg.
developer, testing, stage, production), it is crucial to make sure
that all databases use the same schema. This can be quite an
hair-pulling experience, and this module should help you keep your
hair (if you're already bald, it won't make your hair grow back,
sorry...)

DBIx::SchemaChecksum gets schema information (tables, columns, primary keys,
foreign keys and some more depending on your DBD) and generates a SHA1 digest.
This digest can then be used to easily verify schema consistency across
different databases.

B<Caveat:> The same schema might produce different checksums on
different database versions.

DBIx::SchemaChecksum is tested with PostgreSQL 8.3 to 9.1 and SQLite (but see
below). I assume that thanks to the abstraction provided by the C<DBI>
it works with most databases. If you try DBIx::SchemaChecksum with
different database systems, I'd love to hear some feedback...

=head2 Scripts

Please take a look at the L<bin/scs.pl> script included in this distribution.

=head2 Talks

You can find more information on the rational, usage & implementation in the slides for my talk at the Austrian Perl Workshop 2012, available here: L<http://domm.plix.at/talks/dbix_schemachecksum.html>

=head1 METHODS

=head2 checksum

    my $sha1_hex = $self->checksum();

Gets the schemadump and runs it through Digest::SHA1, returning the current checksum.

=head2 schemadump

    my $schemadump = $self->schemadump;

Returns a string representation of the whole schema (as a Data::Dumper Dump).

Lazy Moose attribute.

=head2 _build_schemadump

Internal method to build L<schemadump>. Keep out!

=head2 _build_schemadump_schema

    my $hashref = $self->_build_schemadump_schema( $schema );

This is the main entry point for checksum calculations per schema.
Method-modifiy it if you need to alter the complete schema data
structure before/after checksumming.

Returns a HashRef like:

    {
        tables => $hash_ref
    }

=head2 _build_schemadump_tables

    my $hashref = $self->_build_schemadump_tables( $schema );

Iterate through all tables in a schema, calling
L<_build_schemadump_table> for each table and collecting the results
in a HashRef

=head2 _build_schemadump_table

    my $hashref = $self->_build_schemadump_table( $schema, $table );

Get metadata on a table (columns, primary keys & foreign keys) via DBI
introspection.

This is a good place to method-modify if you need some special processing for your database

Returns a hashref like

    {
        columns      => $data,
        primary_keys => $data,
        foreign_keys => $data,
    }

=head2 _build_schemadump_column

    my $hashref = $self->_build_schemadump_column( $schema, $table, $column, $raw_dbi_data );

Does some cleanup on the data returned by DBI.

=head2 update_path

    my $update_info = $self->update_path

Lazy Moose attribute that returns the datastructure needed by L<apply_sql_update>.

=head2 _build_update_path

C<_build_update_path> reads in all files ending in ".sql" in C<< $self->sqlsnippetdir >>.
It builds something like a linked list of files, which are chained by their
C<preSHA1sum> and C<postSHA1sum>.

=head2 get_checksums_from_snippet

    my ($pre, $post) = $self->get_checksums_from_snippet( $filename );

Returns a list of the preSHA1sum and postSHA1sum for the given file in C< sqlnippetdir>.

The file has to contain this info in SQL comments, eg:

  -- preSHA1sum: 89049e457886a86886a4fdf1f905b69250a8236c
  -- postSHA1sum: d9a02517255045167053ea92dace728e1389f8ca

  alter table foo add column bar;

=head2 dbh

Database handle (DBH::db). Moose attribute

=head2 catalog

The database catalog searched for data. Not implemented by all DBs. See C<DBI::table_info>

Default C<%>.

Moose attribute

=head2 schemata

An Arrayref containg names of schematas to include in checksum calculation. See C<DBI::table_info>

Default C<%>.

Moose attribute

=head2 sqlsnippetdir

Path to the directory where the sql change files are stored.

Moose attribute

=head2 verbose

Be verbose or not. Default: 0

=head2 driveropts

Additional options for the specific database driver.

=head1 NAME

DBIx::SchemaChecksum - Generate and compare checksums of database schematas

=head1 SEE ALSO

C< bin/scs.pl> for a commandline frontend powered by MooseX::App

=head1 ACKNOWLEDGEMENTS

Thanks to Klaus Ita and Armin Schreger for writing the core code. I 
just glued it together...

This module was written for revdev L<http://www.revdev.at>, a nice 
litte software company run by Koki, Domm 
(L<http://search.cpan.org/~domm/>) and Maros 
(L<http://search.cpan.org/~maros/>).

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@cpan.org>

=item *

Maroš Kollár <maros@cpan.org>

=item *

Klaus Ita <koki@worstofall.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Thomas Klausner, Maroš Kollár, Klaus Ita.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
