package Catmandu::Exporter::MAB2;

our $VERSION = '0.20';

use Catmandu::Sane;
use MAB2::Writer::Disk;
use MAB2::Writer::RAW;
use MAB2::Writer::XML;
use Moo;

with 'Catmandu::Exporter';

has type            => ( is => 'ro', default => sub {'raw'} );
has xml_declaration => ( is => 'ro', default => sub {0} );
has collection      => ( is => 'ro', default => sub {0} );
has writer          => ( is => 'lazy' );

sub _build_writer {
    my ($self) = @_;

    my $type = lc( $self->{type} );
    if ( $type eq 'raw' ) {
        MAB2::Writer::RAW->new( fh => $self->fh );
    }
    elsif ( $type eq 'disk' ) {
        MAB2::Writer::Disk->new( fh => $self->fh );
    }
    elsif ( $type eq 'xml' ) {
        MAB2::Writer::XML->new(
            fh              => $self->fh,
            xml_declaration => $self->xml_declaration,
            collection      => $self->collection
        );
    }
    else {
        die "unknown type: $type";
    }
}

sub add {
    my ( $self, $data ) = @_;

    if ( !$self->count ) {
        if ( lc( $self->type ) eq 'xml' ) {
            $self->writer->start();
        }
    }

    $self->writer->write($data);

}

sub commit {
    my ($self) = @_;
    if ( $self->collection ) {
        $self->writer->end();
    }
    $self->writer->close_fh();

}
 

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Exporter::MAB2 - Package that exports MAB2 data

=head1 SYNOPSIS

    use Catmandu::Exporter::MAB2;
 
    my $exporter = Catmandu::Exporter::MAB2->new(file => "mab2.dat", type => "RAW");
    my $data = {
     record => [
        ...
        [245, '1', 'a', 'Cross-platform Perl /', 'c', 'Eric F. Johnson.'],
        ...
        ],
    };
 
    $exporter->add($data);
    $exporter->commit;

=head1 Arguments

=over

=item C<file>

Path to file with MAB2 records.

=item C<fh>

Open filehandle for file with MAB2 records.

=item C<type>

Specify type of MAB2 records: Disk (Diskette), RAW (Band), XML. Default: 001. Optional. 

=item C<xml_declaration>

Write XML declaration. Set to 0 or 1. Default: 0. Optional.

=item C<collection>

Wrap records in collection element (<datei>). Set to 0 or 1. Default: 0. Optional.

=back

=head1 METHODS

=head2 new(file => $file | fh => $filehandle [, type => XML, xml-declaration => 1, collection => 1])

Create a new Catmandu MAB2 exports which serializes into a $file.

=head2 add($data)

Add record to exporter. 

=head2 commit()

Close collection (optional) and filehandle.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Exporter> (C<file>,
C<fh>, etc.) the importer can be configured with the following parameters:

=over

=item type

MAB2 syntax variant. See L<Catmandu::Importer::MAB2>.

=item xml_declaration

Write XML declaration. Set to 0 or 1. Default: 0. Optional.

=item collection

Wrap records in collection element (<datei>). Set to 0 or 1. Default: 0. Optional.

=back

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
