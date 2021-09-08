package Catmandu::Importer::PICA;
use strict;
use warnings;

our $VERSION = '1.07';

use Catmandu::Sane;
use PICA::Data qw(pica_parser);
use Moo;

with 'Catmandu::Importer';

has type => ( is => 'ro', default => sub { 'xml' } );
has parser => ( is => 'lazy' );

sub _build_parser {
    my ($self) = @_;

    my $type = lc $self->type;

    if ( $type eq 'xml' ) {
        $self->{encoding} = ':raw'
          ; # set encoding to :raw to drop PerlIO layers, as required by libxml2
        PICA::Parser::XML->new( $self->fh );
    }
    elsif ( $type =~ m/^p(ica)?p(plus)?xml$/ ) {
        $self->{encoding} = ':raw'
          ; # set encoding to :raw to drop PerlIO layers, as required by libxml2
        PICA::Parser::PPXML->new( $self->fh );
    }
    else {
        pica_parser( $type, fh => $self->fh );
    }
}

sub generator {
    my ($self) = @_;

    sub {
        my $next = $self->parser->next;
        return $next ? {%$next} : undef;
    };
}

1;
__END__

=head1 NAME

Catmandu::Importer::PICA - Package that imports PICA+ data

=head1 SYNOPSIS

    use Catmandu::Importer::PICA;

    my $importer = Catmandu::Importer::PICA->new(file => "pica.xml", type=> "XML");

    my $n = $importer->each(sub {
        my $hashref = shift;
        # ...
    });

To convert between PICA+ syntax variants with the L<catmandu> command line client:

    catmandu convert PICA --type xml to PICA --type plain < picadata.xml

=head1 DESCRIPTION

Parses PICA format to native Perl hash containing two keys C<_id> and
C<record>. See L<PICA::Data> for more information about PICA data format and
record structure.

=head1 METHODS

This module inherits all methods of L<Catmandu::Importer> and by this
L<Catmandu::Iterable>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Importer> (C<file>,
C<fh>, etc.) the importer can be configured with the following parameters:

=over

=item type

Describes the PICA+ syntax variant. Supported values (case ignored) include the
default value C<xml> for PicaXML, C<plain> for human-readable PICA+
serialization (where C<$> is used as subfield indicator), C<plus> or
C<picaplus> for normalized PICA+, C<binary> for binary PICA+ and C<ppxml> for the PICA+ XML variant of the DNB.

=back

=cut
