package Catmandu::Importer::SRU::Parser::struct;
use strict;
use Moo;
use XML::Struct ();

our $VERSION = '0.425';

has _reader => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        XML::Struct::Reader->new();
    }
);

sub parse {
    my ($self, $record) = @_;
    my $stream = XML::LibXML::Reader->new(
        string => $record->{recordData}->toString(0, 0));
    $self->_reader->readDocument($stream);
}

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser::struct - transform SRU responses into structured XML records

=head1 SYNOPSIS

    my $importer = Catmandu::Importer::SRU->new(
        base   => $base,
        query  => $query,
        parser => 'struct'
    );

=head1 DESCRIPTION

Each SRU response record will be transformed into order-preserving, structured
XML as defined by L<XML::Struct>.

=head1 CONFIGURATION

Options of L<XML::Struct::Reader> are not supported. As workaround wrap the
reader as following, if needed:

    my $reader = XML::Struct::Reader->new( %options );

    my $importer = Catmandu::Importer::SRU->new(
        base   => $base,
        query  => $query,
        parser => sub {
            $reader->readDocument(
                XML::LibXML::Reader->new( string => $_[0]->{recordData} )
            );
        },

    );

=head1 AUTHOR

Jakob Voss C<< voss@gbv.de >>

=cut
