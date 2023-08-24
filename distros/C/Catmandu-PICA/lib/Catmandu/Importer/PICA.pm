package Catmandu::Importer::PICA;
use strict;
use warnings;

our $VERSION = '1.17';

use Catmandu::Sane;
use PICA::Data qw(pica_parser);
use Moo;

with 'Catmandu::Importer';

has type   => ( is => 'ro', default => sub { 'xml' } );
has parser => ( is => 'lazy' );
has level  => ( is => 'ro', default => sub { -1 } );
has queue  => ( is => 'ro', default => sub { [] } );

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
        my $queue = $self->queue;
        my $next  = @$queue ? shift @$queue : $self->parser->next;
        return unless $next;

        if ( $self->level > -1 ) {
            push @$queue, $next->split( $self->level );
            $next = shift @$queue;
        }

        # Catmandu does not like blessed objects/arrays
        $next->{record} = [ map { [@$_] } @{ $next->{record} } ];
        return {%$next};
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
C<picaplus> for normalized PICA+, C<import> for PICA import format, C<binary>
for binary PICA+ and C<ppxml> for the PICA+ XML variant of the DNB.

=item level

Split and reduce records to level 0, 1 or 2 with identifiers of broader levels
included.

=back

=cut
