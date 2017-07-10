package Catmandu::Importer::MAB2;

our $VERSION = '0.19';

use Catmandu::Sane;
use Moo;
use MAB2::Parser::Disk;
use MAB2::Parser::RAW;
use MAB2::Parser::XML;

with 'Catmandu::Importer';

has type => ( is => 'ro', default => sub {'RAW'} );
has id   => ( is => 'ro', default => sub {'001'} );

sub mab_generator {
    my $self = shift;

    my $file;
    my $type = lc($self->type);
    if ( $type eq 'raw' ) {
        $file = MAB2::Parser::RAW->new( $self->fh );
    }
    elsif ( $type eq 'xml' ) {
        $self->{encoding} = ':raw'; # set encoding to :raw to drop PerlIO layers, as required by libxml2
        $file = MAB2::Parser::XML->new( $self->fh );
    }
    elsif ( $type eq 'disk' ) {
        $file = MAB2::Parser::Disk->new( $self->fh );
    }
    else {
        die "unknown format";
    }

    my $id = $self->id;

    sub {
        my $record = $file->next();
        return unless $record;
        return $record;
    };
}

sub generator {
    my ($self) = @_;
    
    my $type = lc($self->type);
    if ( $type =~ /raw|xml|disk$/ ) {
        return $self->mab_generator;
    }
    else {
        die "need MAB2 Disk, RAW or XML data";
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Importer::MAB2 - Package that imports MAB2 data

=head1 SYNOPSIS

    use Catmandu::Importer::MAB2;

    my $importer = Catmandu::Importer::MAB2->new(file => "./t/mab2.dat", type=> "raw");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

To convert between MAB2 syntax variants with the L<catmandu> command line client:

    catmandu convert MAB2 --type raw to MAB2 --type xml < mab2.dat

=head1 MAB2

The parsed MAB2 record is a HASH containing two keys '_id' containing the 001 field (or the system
identifier of the record) and 'record' containing an ARRAY of ARRAYs for every field:

 {
  'record' => [
                [
                    '001',
                    ' ',
                    '_',
                    'fol05882032 '
                ],
                [
                    245,
                    'a',
                    'a',
                    'Cross-platform Perl /',
                    'c',
                    'Eric F. Johnson.'
                ],
        ],
  '_id' => 'fol05882032'
 } 

=head1 METHODS

This module inherits all methods of L<Catmandu::Importer> and by this
L<Catmandu::Iterable>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Importer> (C<file>,
C<fh>, etc.) the importer can be configured with the following parameters:

=over

=item type

Describes the MAB2 syntax variant. Supported values (case ignored) include the
default value C<xml> for MABxml, C<disk> for human-readable MAB2 serialization 
("Diskettenformat") or C<raw> for data-exchange MAB2 serialization ("Bandformat").

=back

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
