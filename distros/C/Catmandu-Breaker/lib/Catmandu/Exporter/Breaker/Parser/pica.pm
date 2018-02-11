package Catmandu::Exporter::Breaker::Parser::pica;

use Catmandu::Sane;
use Moo;
use Catmandu::Breaker;
use namespace::clean;

our $VERSION = '0.11';

has tags    => (is => 'ro' , default => sub { +{} });
has breaker => (is => 'lazy');

sub _build_breaker {
    Catmandu::Breaker->new;
}

sub add {
    my ($self, $data, $io) = @_;

    my $identifier = $data->{_id} // $self->breaker->counter;

    my $record = $data->{record};

    for my $field (@$record) {
        my ($tag, $occ, @data) = @$field;

        if (defined $occ && $occ ne '') {
            $tag = "$tag\[$occ]";
        }

        $self->tags->{$tag} = 1;

        for (my $i = 0 ; $i < @data ; $i += 2) {
            $io->print(
                $self->breaker->to_breaker(
                    $identifier,
                    $tag . $data[$i],
                    $data[$i+1])
            );
        }
    }

    1;
}

1;

__END__

=head1 NAME

Catmandu::Exporter::Breaker::Parser::pica - handler for PICA+ format

=head1 DESCRIPTION

This L<Catmandu::Breaker> handler breaks PICA+ format. Each path consists of a
PICA tag, optionally followed by the occurrence in brackets, followed by the
subfield code. This path format equals the format used by L<PICA::Path>, and
Catmandu Fix methods such as L<Catmandu::Fix::pica_map>.

 C</> and the occurrence, followed by C<$> and
the subfield code.

=head1 SEE ALSO

L<Catmandu::PICA>

L<PICA::Data>

=cut
