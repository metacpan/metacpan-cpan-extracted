package Catmandu::Exporter::XML;

our $VERSION = '0.16';

use Catmandu::Sane;
use Moo;

use XML::Struct::Writer;
use Catmandu::Util qw(io);

with 'Catmandu::Exporter';

has directory => (
    is  => 'ro',
    isa => sub { die "output directory not found\n" unless -d $_[0] },
);
has field => ( 
    is      => 'ro',
    lazy    => 1, 
);
has filename  => ( 
    is => 'ro', 
    lazy    => 1, 
    default => sub { defined $_[0]->directory ? '_id' : undef }
);

our @WRITER_OPTIONS;
BEGIN {
    @WRITER_OPTIONS = qw(attributes xmldecl encoding version standalone pretty);
    has $_ => (is => 'rw') for @WRITER_OPTIONS;
}

has writer => (
    is        => 'ro',
    predicate => 1,
    lazy      => 1,
    default   => sub {
        XML::Struct::Writer->new( 
            to => $_[0]->fh,
            map { $_ => $_[0]->$_ } grep { defined $_[0]->$_ } 
            @WRITER_OPTIONS
        );
    },
);

sub add {
    my ($self, $data) = @_;

    my $xml = defined $self->field ? $data->{$self->field} : $data;

    if (defined $self->directory) {
        my $filename = $data->{$self->filename};
        $filename .= '.xml' if $filename !~ /\.xml/;
        if ($filename !~ qr{^[^/\0]+$}) {
            $self->log->error("disallowed filename: $filename");
            # TODO: check for disallowed characters on non-Unix systems
            return;
        } else {
            my $filename = $self->directory . "/$filename";
            $self->log->debug("exporting XML to $filename");
            $self->writer->handler->{fh} = io( $filename, mode => 'w' ); 
                # TODO: binmode => $self->writer->encoding // ':utf8'
            $self->writer->write($xml);
            $self->writer->handler->fh->close;
        }
    } else {
        $self->writer->write($xml);
    }
}

1;
__END__

=head1 NAME

Catmandu::Exporter::XML - serialize and export XML documents

=head1 DESCRIPTION

This L<Catmandu::Exporter> exports items serialized as XML. Serialization is
implemented based on L<XML::Struct::Writer::Stream>. By default, each item is
written to STDOUT.

=head1 CONFIGURATION

=over

=item attributes

=item xmldecl

=item encoding

=item version

=item standalone

=item pretty

These options are passed to L<XML::Struct::Writer>. The target (option C<to>)
is based on L<Catmandu::Exporter>'s option C<fh> or C<file>.

=item field

Take XML from a given field of each item, e.g. field C<xml> as following:

    { xml => [ root => { xmlns => 'http://example.org/' }, [ ... ] ] }

=item directory

Serialize to multiple files in a given directory.

=item filename

Field to take filenames from if option C<directory> is set. Defaults to C<_id>.
The file extension C<.xml> is appended unless given.

=back

=cut
