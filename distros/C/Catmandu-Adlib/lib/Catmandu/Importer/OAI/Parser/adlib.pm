package Catmandu::Importer::OAI::Parser::adlib;

use Catmandu::Sane;
use Moo;
use Catmandu;
use XML::Struct::Reader;

with 'Catmandu::Logger';

has type       => (is => 'ro', default => sub { 'simple' });
has path       => (is => 'ro');
has root       => (is => 'lazy', default => sub { defined $_[0]->path ? 1 : 0 });
has depth      => (is => 'ro');
has ns         => (is => 'ro', default => sub { '' });
has attributes => (is => 'ro', default => sub { 1 });
has whitespace => (is => 'ro', default => sub { 0 });

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    my $reader = do {
        my %options = (
           from       => $dom,
           whitespace => $self->whitespace,
           attributes => $self->attributes,
           depth      => $self->depth,
           ns         => $self->ns,
        );

        $options{path} = $self->path if defined $self->path;
        if ($self->type eq 'simple') {
            $options{simple} = 1;
            $options{root} = $self->root;
        } elsif ($self->type ne 'ordered') {
            return;
        }
        XML::Struct::Reader->new(%options);
    };

    my $item = $reader->readNext;

    return { _metadata => $item }
}

1;

__END__

=encoding utf8

=head1 NAME

Catmandu::Importer::OAI::Parser::adlib - An Adlib XML OAI-PMH handler

=head1 SYNOPSIS

Command line client C<catmandu>:

  catmandu convert OAI \
    --url http://example.com/oai \
    --metadataPrefix adlib \
    --handler adlib to YAML \

=head1 SEE ALSO

L<Catmandu::OAI>

=cut
