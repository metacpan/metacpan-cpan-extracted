package Data::AnyXfer::To::Elasticsearch::DataFile;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);


use Data::AnyXfer::Elastic::Role::IndexInfo;
use Data::AnyXfer::Elastic::Import::DataFile;
use Data::AnyXfer::Elastic::Importer;

use DateTime      ();
use Sys::Hostname ();

requires 'log';

=head1 NAME

Data::AnyXfer::To::Elasticsearch::DataFile - Transfer to Elasticsearch datafile

=head1 SYNOPSYS

    package DbicToElasticsearchDataFile;

    use Moo;
use MooX::Types::MooseLike::Base qw(:all);


    extends 'Data::AnyXfer';

    with 'Data::AnyXfer::From::DBIC';
    with 'Data::AnyXfer::To::Elasticsearch::DataFile';

    1;

=head1 DESCRIPTION

This role can be used to implement a L<Core::Elasticsearch::Import::DataFile> AnyXfer target
for AnyXfer subclasses.

=head1 ATTRIBUTES

=head2 index_info

Required. An instance of L<Data::AnyXfer::Elastic::Role::IndexInfo>.

=head2 dir

Optional.

An instance of L<Path::Class::Dir>, or a path C<STRING>.
See L<Data::AnyXfer::Elastic::Import::DataFile/dir> for more info.

=head2 file

Optional.

An instance of L<Path::Class::File>, or a path C<STRING>.
See L<Data::AnyXfer::Elastic::Import::DataFile/file> for more info.

=head2 datafile

Readonly.

The datafile instance target.
An instance of L<Data::AnyXfer::Elastic::Import::DataFile>.

=head2 importer

Optional.

The importer that will be used to play / execute the datafile if
L<./autoplay_datafile> is set, or L<./deploy> is called.

An instance of L<Data::AnyXfer::Elastic::Importer>.

=head2 autoplay_datafile

Optional.

A boolean indicating whether this AnyXfer instance should execute / play
the resulting datafile immediately when the import has finished, using
L<./importer>, and L<Data::AnyXfer::Elastic::Importer/deploy>.

Defaults to C<0>.

=head2 datafile_part_size

Optional.

An integer used to control the maximum part-size for the datafile.
See L<Data::AnyXfer::Elastic::Import::DataFile/part_size> for more info.

=head2 datafile_buffer_size

Optional.

An integer used to control the maximum amount of buffered data before
a write occurs.
See L<Data::AnyXfer::Elastic::Import::DataFile/data_buffer_size> for more info.

=head2 datafile_compress

Optional.

A boolean value used to apply compression to the datafile.
See L<Data::AnyXfer::Elastic::Import::DataFile/compress> for more info.

=cut



has index_info => (
    is       => 'ro',
    isa      => ConsumerOf['Data::AnyXfer::Elastic::Role::IndexInfo'],
    required => 1,
);


has 'dir' => (
    is  => 'ro',
    isa => AnyOf[Str, InstanceOf['Path::Class::Dir']],
);


has 'file' => (
    is  => 'ro',
    isa => AnyOf[Str, InstanceOf['Path::Class::File']],
);


has 'datafile' => (
    is     => 'rw',
    isa    => InstanceOf['Data::AnyXfer::Elastic::Import::DataFile'],
    writer => '_set_datafile',
);


has 'datafile_part_size' => (
    is  => 'ro',
    isa => Int,
);


has 'datafile_buffer_size' => (
    is  => 'ro',
    isa => Int,
);

has 'datafile_compress' => (
    is  => 'ro',
    isa => Bool,
);

has 'autoplay_datafile' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


has 'importer' => (
    is      => 'rw',
    isa     => InstanceOf['Data::AnyXfer::Elastic::Importer'],
    lazy    => 1,
    default => sub {
        Data::AnyXfer::Elastic::Importer->new;
    },
);


has 'datafile_author_comment' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub {
        sprintf 'Datafile created on %s by `%s` @ %s (by-program: %s)',
            Sys::Hostname::hostname,
            ref( $_[0] ),
            DateTime->now,
            $0;
    },
);



around 'initialize' => sub {
    my ( $orig, $self, @orig_args ) = @_;

    # call parent initialise
    $self->$orig(@orig_args) or return;

    my $log      = $self->log;
    my $datafile = $self->datafile;

    unless ($datafile) {

        # attempt to create the datafile
        eval {
            my ( $file, $dir ) = ( $self->file, $self->dir );

            # prepare general args
            my @args = ( index_info => $self->index_info );
            push @args, file => $file if $file;
            if ($dir) {
                Path::Class::dir($dir)->mkpath;
                push @args, dir => $dir;
            }

            # buffering / perf options
            push @args, part_size => $self->datafile_part_size
                if $self->datafile_part_size;
            push @args, data_buffer_size => $self->datafile_buffer_size
                if $self->datafile_buffer_size;
            push @args, compress => 1 if $self->datafile_compress;

            # create datafile
            $datafile
                = Data::AnyXfer::Elastic::Import::DataFile->new(
                @args);
        };
        $log->logdie("Unable to create datafile. $@") if $@;

        # datafile created. set it
        $self->_set_datafile($datafile);
    }
    return 1;
};


around 'store' => sub {
    my ( $orig, $self, $rec ) = @_;

    # call parent store
    $self->$orig($rec) or return;

    # store the record in the datafile
    eval { $self->datafile->add_document($rec) };
    $self->log->logdie("store failed: $@") if $@;

    return 1;
};


around 'finalize' => sub {
    my ( $orig, $self ) = @_;

    # call parent finalise
    $self->$orig or return;

    my $log      = $self->log;
    my $datafile = $self->datafile;

    # write the datafile to its final location
    if ( my $comment = $self->datafile_author_comment ) {
        $datafile->author_comment($comment);
    }
    $datafile->write;

    # auto-deploy the datafile if set
    if ( $self->autoplay_datafile ) {

        # allow playing to be overridden by environment variable
        # as not all import scripts correctly expose autoplay as optional
        unless ( $ENV{DATA_ANYXFER_NO_AUTOPLAY} ) {

            $self->importer->deploy( datafile => $datafile );
        } else {

            # display a message indicating where the datafile was generated
            # to so that it can be played later if desired
            printf "Skipping playing of datafile: %s\n",
                $datafile->storage->get_destination_info;
        }
    }

    return 1;
};



use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

