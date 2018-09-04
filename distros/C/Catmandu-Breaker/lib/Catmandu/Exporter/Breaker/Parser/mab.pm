package Catmandu::Exporter::Breaker::Parser::mab;

use Catmandu::Sane;
use Moo;
use Catmandu::Breaker;
use namespace::clean;

our $VERSION = '0.14';

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
        my ($tag,$ind,@data) = @$field;

        $self->tags->{$tag} = 1;

        for (my $i = 0 ; $i < @data ; $i += 2) {
            if ($i == 0 && $data[$i] eq '_') {
                $io->print(
                    $self->breaker->to_breaker(
                        $identifier ,
                        $tag ,
                        $data[$i+1])
                );
            }
            else {
                $io->print(
                    $self->breaker->to_breaker(
                        $identifier ,
                        $tag . $data[$i] ,
                        $data[$i+1])
                );
            }
        }
    }

    1;
}

1;

__END__

=head1 NAME

Catmandu::Exporter::Breaker::Parser::mab - handler for MAB2 format

=head1 DESCRIPTION

This L<Catmandu::Breaker> handler breaks MAB2 format.

=head1 SEE ALSO

L<Catmandu::MARC>

=cut
