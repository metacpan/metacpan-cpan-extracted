package Data::AnyXfer::Elastic::Test::Import;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Carp;
use namespace::autoclean;

use Data::AnyXfer::Elastic::Import::DataFile;
use Data::AnyXfer::Elastic::Logger;

use Path::Class;
use Class::Load;
use Test::Exception;
use Test::More;
use Test::Deep qw( bag supersetof cmp_deeply );

extends 'Data::AnyXfer::Elastic::Importer';

our @EXPORT_OK = qw( datafile );

=head1 NAME

Data::AnyXfer::Elastic::Test::Import - es package for importing test data

=head1 SYNOPSIS

    my $import = Data::AnyXfer::Elastic::Test::Import->new;


    # play a datafile

    $import->import_test_data( file => 't/data/import.interiors-20140910160216.datafile' );


    # the same for a directory

    $import->import_test_data(
        dir => 't/data',
        index_info => 'Interiors::IndexInfo' );


    # or, if you had mixed data to import (going to multiple indexes)
    # you could use import_test_data_all

    $import->import_test_data_all(
        {
            dir => 't/data/property',
            index_info => 'Property::ES::IndexInfo'
        },
        {
            dir => 't/data/landreg',
            index_info => 'HeatmapData::Landreg::IndexInfo'
        },
        {
            dir => 't/data/interiors',
            index_info => 'Interiors::IndexInfo'
        },
    );


    # You may need test the contents of an Elasticsearch index...

    my $index = Interiors::IndexInfo->new->get_index;
    my $expected_documents = [{1},{2},{3},{4}];

    $import->index_contains($index, $expected_data,
        'Index contains expected documents');

    $import->index_contains_exact($index, $expected_data,
        'Index contains *only* the expected documents');


    # Or, you may need to test the contents of a datafile

    my $datafile = $import->datafile( file => 't/data/import.interiors-20140910160216.datafile' );
    my $expected_documents = [{1},{2},{3},{4}];

    $import->datafile_contains($datafile, $expected_documents,
        'Datafile contains expected documents');

    $import->datafile_contains_exact ($datafile, $expected_documents,
        'Datafile contains *only* the expected documents');


=head1 DESCRIPTION

This package can be used to create and play datafiles containing test data for use with tests.
The operations provided by this test will usually be used / performed in C<00-setup.t>.

I<B<All routines in this module may be used as either instance or package methods.>>

=head1 SEE ALSO

L<Data::AnyXfer::Elastic::Import::DataFile>,
L<Data::AnyXfer::Elastic::Importer>

=cut

=head1 METHODS

=cut

=head2 datafile

    my $datafile = Data::AnyXfer::Elastic::Test::Import
        ->datafile(
            dir => 't/data/landreg',
            index_info => 'HeatmapData::Landreg::IndexInfo'
        );

Creates or reads an existing L<Data::AnyXfer::Elastic::Import::DataFile|DataFile>, to
push test data to or read from.

Takes the same arguments as the L<Data::AnyXfer::Elastic::Import::DataFile>
constructor, but modfifies the datafile specifically to be run in test environments.

Returns the new C<DataFile> instance.

=cut

sub datafile {

    # optionally allow us to be called as a function directly
    shift if $_[0] =~ /::/;
    my %args = @_;

    # enforce test mode
    my $test_value = Data::AnyXfer->test;
    Data::AnyXfer->test(1);

    # override the silo to always be dev or test
    $args{silo} = Data::AnyXfer->test ? 'testing' : 'development';

    # create the datafile instance
    my $df = Data::AnyXfer::Elastic::Import::DataFile->new(%args);

    # restore previous mode and return the datafile
    Data::AnyXfer->test($test_value);
    return $df;
}

=head2 import_test_data_all

    $import->import_test_data_all(
        {
            dir => 't/data/property',
            index_info => 'Property::ES::IndexInfo'
        },
        {
            dir => 't/data/landreg',
            index_info => 'HeatmapData::Landreg::IndexInfo'
        },
        {
            dir => 't/data/interiors',
            index_info => 'Interiors::IndexInfo'
        },
    );

Convenience batch import method which takes multiple import configuration
C<HASH> refs and performs them in sequence.

If you had mixed data to import (going to multiple indexes) you could use
import_test_data_all.

See L</import_test_data> for supported hash arguments, and implementation
details.

Test output will be the output provided by L</import_test_data>.

Does not return anything.

=cut

sub import_test_data_all {

    my $self = shift;
    $self->import_test_data( %{$_} ) foreach @_;
    return;
}

=head2 import_test_data

    $import->import_test_data( file => 't/data/import.interiors-20140910160216.datafile' );

    #
    # play a datafile, overriding the original index information
    # test naming schemes are applied as previously
    # but the mappings and type information etc. will be used
    # from the current code-base and environment

    $import->import_test_data(
        file => 't/data/import.interiors-20140910160216.datafile',
        index_info => 'Interiors::IndexInfo' );


    # the same for a directory

    $import->import_test_data(
        dir => 't/data',
        index_info => 'Interiors::IndexInfo' );

"Plays" a datafile using L<Data::AnyXfer::Elastic::Importer> generating TAP
output for each index created and finalised.

Takes a key-value list of arguments.

Requires at least one of arguments C<file> or C<dir>,
which may be paths, or L<Path::Class::File> and L<Path::Class::Dir> objects
respectively.

=over 12

=item

If a C<file> attribute is supplied, this file will be imported.

=item

If a C<dir> attribute is supplied, all files matching C<*.datafile> will be imported
in the target directory.

=back

Any additional arguments will be passed directly to
L<Data::AnyXfer::Elastic::Importer/execute>.

Produces test output directly.

=cut


sub import_test_data {

    my ( $self, %args ) = @_;

    # override the silo to always be dev or test
    $args{silo} = Data::AnyXfer->test ? 'testing' : 'development';

    # get a list of datafiles to play
    my @datafiles = $self->_build_datafiles_from_args( \%args );

    # prepare common args for playing datafile
    my @importer_args = (
        delete_before_create => 1,
        logger               => Data::AnyXfer::Elastic::Logger->new(
            screen => 0,
            file   => 0,
        ),
        (   $args{bulk_max_count}
            ? ( bulk_max_count => $args{bulk_max_count} )
            : ()
        ),
    );

    # deploy each datafile and emit test output
    foreach my $datafile (@datafiles) {

        my $label
            = ( split /\//, $datafile->storage->get_destination_info )[-1];

        # create ad-hoc importer and play data
        my $import = ( ref($self) || $self )->new(@importer_args);
        my @clients
            = Data::AnyXfer::Elastic->default->all_clients_for( $args{silo}
                || $_->silo );

        note "playing data from ${label}";

        lives_ok {
            $import->deploy(
                clients     => \@clients,
                datafile    => $datafile,
                no_finalise => 1,
            );
        }
        "${label} - imported test data into index";

        # test passed, finalise
        unless ( ok $import->finalise,
            "${label} - finalised test data (aliases switched)" )
        {

            # report import error diagnostics
            # , cleanup, and move on
            diag($_) foreach $import->errors;
            $import->cleanup;
        }
    }
    return 1;
}


sub _build_datafiles_from_args {

    my ( $self, $args ) = @_;
    my ( @files, @datafiles );

    # handle direct datafile argument
    my $arg_df = delete $args->{datafile};
    push @datafiles, $arg_df if $arg_df;

    # handle file argument
    my $file = delete $args->{file};
    push @files, Path::Class::file($file) if $file;

    # handle directory arguments
    if ( my $dir = delete $args->{dir} ) {

        # filter files immediately within the directory
        # for datafiles
        push @files,
            grep { -f $_ && $_->basename =~ /\.datafile$/ }
            Path::Class::dir($dir)->children;
    }

    # create datafile instances
    foreach (@files) {

        my $df;
        eval {
            $df = Data::AnyXfer::Elastic::Import::DataFile->new(
                file       => $_,
                index_info => $args->{index_info}
            );
            push @datafiles, $df if $df;
        };
        if ($@) {
            fail "$_ - imported test data into index";
            diag $@;
            next;
        }
    }

    return @datafiles;
}


=head2 build_test_index

    my $index_info = Data::AnyXfer::Elastic::Test::Import->build_test_index(
        name      => 'some_stuff',
        documents => [
            { title => "This is document 1" },
            { title => "This is document 2" }
        ]
    );

Builds a one-off test index containing the specified data,
for quick mocking of data.

Takes 2 arguments which are both required. C<name>,
which can be any identifier (the alias etc. are generated off of this),
 and C<documents>, which must be an array of document C<HASH> refs.

=cut

sub build_test_index {

    my ( $self, %args ) = @_;

    my $name = $args{name} or croak q!argument 'name' is required!;
    my $documents = $args{documents}
        or croak q!argument 'documents' is required!;

    my $index_info = Data::AnyXfer::Elastic::IndexInfo->new(
        alias => $name,
        silo  => 'public_data',
        type  => $args{name} . '_data',
    );

    my $datafile = Data::AnyXfer::Elastic::Import::DataFile->new(
        index_info => $index_info );
    $datafile->add_document($_) for @{ $args{documents} };
    $datafile->write;

    Data::AnyXfer::Elastic::Test::Import->import_test_data(
        datafile => $datafile, );

    return $index_info;
}


=head2 datafile_contains

The same as L<./datafile_contains_exact>, except the datafile is allowed to contain
additional records not in the expected set.

This is simply a wrapper around L<./datafile_contains_exact>, using L<Test::Deep/supersetof>.

=cut

sub datafile_contains {

    croak 'Second argument is not a valid ARRAY ref'
        unless ref $_[2] eq 'ARRAY';

    return datafile_contains_exact( $_[0], $_[1], supersetof( @{ $_[2] } ),
        $_[3] );
}

=head2 index_contains

The same as L<./index_contains_exact>, except the index is allowed to contain
additional records not in the expected set.

This is simply a wrapper around L<./index_contains_exact>, using L<Test::Deep/supersetof>.

=cut

sub index_contains {

    croak 'Second argument is not a valid ARRAY ref'
        unless ref $_[2] eq 'ARRAY';

    return index_contains_exact( $_[0], $_[1], supersetof( @{ $_[2] } ),
        $_[3] );
}

=head2 datafile_contains_exact

    my $datafile = $import->datafile( file => 't/data/mytestdata.datafile' );
    my $expected = [{ document => 123, tags => qw( test entry sample ) }];

    $import->datafile_contains_exact($datafile, $expected,
        'Test datafile contains the required documents')

Compares the contents of a datafile to the supplied document C<ARRAY>,
supplied as a reference.

Takes 3 arguments.
The first argument must be a L<Data::AnyXfer::Elastic::Import::DataFile> instance,
the second argument must be a reference to an C<ARRAY> of expected document / data structures,
and the third argument is the test name.

Produces test output directly.

B<I<Note: Do not run this method on full datasets as all of the data
must be loaded into memory (x2)>>

=cut

sub datafile_contains_exact {

    my ( $self, $datafile, $expected, $name ) = @_;

    # defaults - no defaults

    # validate arguments
    croak 'First argument is not a valid DataFile instance'
        unless ref $datafile
        and UNIVERSAL::can( $datafile, 'isa' )
        and
        $datafile->isa('Data::AnyXfer::Elastic::Import::DataFile');

    # users may only supply arrays
    croak 'Second argument is not a valid ARRAY ref'
        unless _is_expected_array($expected);

    # create target bag structure (unordered array)
    $expected = bag( @{$expected} ) if ref $expected eq 'ARRAY';

    # create bag structure for datafile contents
    my $data = [];
    $datafile->fetch_data( sub { push @{$data}, @_ } );

    # execute compare and return
    return cmp_deeply( $data, $expected, $name );
}

=head2 index_contains_exact

    # get an index object / connection
    # (here we use the test datafile to create an ad-hoc connection)
    my $index = $datafile->export_index_info->get_index;

    # build a list of expected documents
    my $expected = [{ document => 123, tags => qw( test entry sample ) }];

    # test that they match
    $import->index_contains_exact($index, $expected,
        'Test index contains the required documents');

Compares the contents of an elasticsearch index to the supplied document C<ARRAY>,
supplied as a reference.

Takes 3 arguments.
The first argument must be a L<Data::AnyXfer::Elastic::Index> instance,
the second argument must be a reference to an C<ARRAY> of expected document / data structures,
and the third argument is the test name.

Produces test output directly.
The target index for comparison may contain no more than 10,000 documents.

B<I<Note: Do not run this method on full datasets as all of the data
must be loaded into memory (x2)>>

=cut

sub index_contains_exact {

    my ( $self, $index, $expected, $name ) = @_;

    # defaults - no defaults

    # validate arguments
    croak
        'First argument is not a valid Index instance in call to ->index_contains'
        unless ref $index
        and UNIVERSAL::can( $index, 'isa' )
        and $index->isa('Data::AnyXfer::Elastic::Index');

    croak
        'Second argument is not a valid ARRAY ref in call to ->index_contains'
        unless _is_expected_array($expected);

    # create target bag structure (unordered array)
    $expected = bag( @{$expected} ) if ref $expected eq 'ARRAY';

    # create bag structure for index contents
    my $data = [
        map     { $_->{_source} }
            map { @{ $_->{hits}->{hits} } } $index->search(
            size => 10_000,
            body => { query => { match_all => {} } }
            )
    ];

    # execute compare and return
    return cmp_deeply( $data, $expected, $name );
}

=head2 import_latest_test_data

    $import->import_latest_test_data( 'Property::Search::IndexInfo' );
    $import->import_latest_test_data( Property::Search::IndexInfo->new );

Creates a test index from the latest live datafile. Play a datafile, exactly as
originally generated, but will apply the test alias and index naming schemes.

 e.g. [index] interiors_20141201 -> HOSTN_USER_PKG_interiors_20141201
      [alias] interiors          -> HOSTN_USER_PKG_interiors

=cut

sub import_latest_test_data {
    my ( $self, $index_info ) = @_;

    my ($latest_datafile) = $self->find_latest_live_data($index_info);
    $self->import_test_data( datafile => $latest_datafile );

    return 1;
}

=head2 find_latest_live_data

    my ($datafile, $index_info) =
        $import->find_latest_live_data('POI');

Finds the latest live datafile for a given IndexInfo class. It does this
by knowing where datafile exports are stored on the SAN, and using the
information on index naming in the IndexInfo class supplied.

The datafile is returned as a path class object.

=cut

sub find_latest_live_data {
    my ( $self, $index_info ) = @_;

    unless ( ref $index_info ) {
        Class::Load::load_class($index_info);
        $index_info = $index_info->new;
    }

    my $dir  = Data::AnyXfer::Elastic->datafile_dir;
    my $role = 'Data::AnyXfer::Elastic::Role::IndexInfo';
    croak "index_info must consume ${role}" unless $index_info->does($role);

    # we have to access the original name here because it is immediately
    # redefined on instantiation.
    my $latest;
    my $name     = $index_info->_fields->{alias};
    my $limit    = DateTime->now->subtract( minutes => 20 );
    my @children = $dir                                        #
        ->subdir('datafiles')                                  #
        ->children( no_hidden => 1 );

    for my $child (@children) {
        if ( $child->is_dir && $child->basename eq $name ) {

            my $latest_mtime = 0;
            $child->recurse(
                callback => sub {
                    my $file = shift;
                    return undef if -d $file;

                    my $time = $file->stat->mtime;
                    my $older = $self->_older_than_limit( $limit, $time );

                    if ( $time > $latest_mtime && $older < 0 ) {
                        $latest       = $file;
                        $latest_mtime = $time;
                    }
                }
            );
        }
    }

    unless ($latest) {
        croak "no datafile found for index: ${name}";
    }
    return (
        Data::AnyXfer::Elastic::Import::DataFile->new(
            file       => $latest,
            index_info => $index_info,
        ),
        $index_info
    );
}

sub _older_than_limit {
    my $limit = $_[1];
    my $dt = DateTime->from_epoch( epoch => $_[2] );
    DateTime->compare( $dt, $limit );
}

# _is_expected_array - checks that a scalar may be used as
# an 'expected' argument in a test
sub _is_expected_array {

    my $expected = $_[0];

    # may be an array ref
    return 1 if ref $expected eq 'ARRAY';

    # may be a special test deep set object
    return 1
        if (ref $expected
        and UNIVERSAL::can( $expected, 'isa' )
        and $expected->isa('Test::Deep::Set') );

    # nothing else
    return 0;
}

# alias for Utils->wait_for_doc_count
sub _wait_for_doc_count {
    &Data::AnyXfer::Elastic::Utils::wait_for_doc_count;
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
