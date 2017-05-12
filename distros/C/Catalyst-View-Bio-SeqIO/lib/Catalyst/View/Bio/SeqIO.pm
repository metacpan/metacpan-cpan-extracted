package Catalyst::View::Bio::SeqIO;
BEGIN {
  $Catalyst::View::Bio::SeqIO::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Catalyst::View::Bio::SeqIO::VERSION = '0.02';
}
# ABSTRACT: use BioPerl's Bio::SeqIO as a Catalyst view

use Moose;
use namespace::autoclean;

use IO::String;
use Bio::SeqIO;

extends 'Catalyst::View';



has 'sequences_stash_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'sequences',
  );


has 'format_stash_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'seqio_format',
  );


has 'object_stash_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'seqio_object',
  );


has 'default_seqio_args' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
  );


has 'content_type_map' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            'fasta' => 'application/x-fasta',
        }
    },
  );


has 'default_content_type' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'text/plain',
  );


sub process {
    my ( $self, $c ) = @_;

    my $format = $c->stash->{ $self->format_stash_key } || 'fasta';

    my $out_string = '';
    my $seq_out =
      $c->stash->{ $self->object_stash_key }
      || Bio::SeqIO->new(
          %{ $self->default_seqio_args || {} },
          -format => $format,
          -fh     => IO::String->new( \$out_string ),
        );

    $seq_out->write_seq( $_ )
        for @{ $c->stash->{ $self->sequences_stash_key } || [] };

    $c->res->content_length( length $out_string );
    $c->res->content_type(
        $self->content_type_map->{$format} || $self->default_content_type
      );
    $c->res->body( IO::String->new( \$out_string ) );
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::View::Bio::SeqIO - use BioPerl's Bio::SeqIO as a Catalyst view

=head1 SYNOPSIS

    ## subclassing to making your view
    package MyApp::View::SeqIO;
    use Moose;
    extends 'Catalyst::View::Bio::SeqIO';

    __PACKAGE__->config(
        default_seqio_args => {
            -width => 80,
         },
        default_format       => 'fasta',
        default_content_type => 'text/plain',
        content_type_map     => {
            fasta => 'application/x-fasta',
        },
      );

    ## using in a controller

    sub foo :Path('/foo') {
        my ( $self, $c ) = @_;

        # get an array of Bio::SeqI-compliant objects.
        my @sequences = get_sequences_somehow();

        # set the sequences and the format in the stash, and forward
        # to your subclassed view
        $c->stash->{sequences}    = \@sequences;
        $c->stash->{seqio_format} = 'genbank';
        $c->forward( 'View::SeqIO' );
    }

=head1 CONFIGURABLE ATTRIBUTES

Like all Catalyst components, the values for these can be set in a
package config statement or in your myapp.conf file.

=head2 sequences_stash_key

Stash key to use for arrayref of sequences to print out.  Default
'sequences'.

=head2 format_stash_key

Stash key to use for the sequence format.  Default
'seqio_format'.

=head2 object_stash_key

Stash key under which to look for a custom-constructed
Bio::SeqIO-compliant object to use for rendering sequences.  Default
'seqio_object'.

If a SeqIO object is provided in the stash under this key, this view
will use that for rendering the sequences, instead of constructing its
own SeqIO object.

=head2 default_seqio_args

Hashref of default arguments to pass to constructed SeqIO objects.
Defaults to empty.

=head2 content_type_map

Hashref giving the mapping of SeqIO formats to content types.
Currently defaults to just

    {  fasta => 'application/x-fasta' }

Do you know proper MIME types for other formats?  Please tell me and
I'll add them.

=head2 default_content_type

Default content type to use when a format is not found in the
content_type_map.  Defaults to 'text/plain'.

=head1 AUTHOR

Robert Buels <rbuels@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

