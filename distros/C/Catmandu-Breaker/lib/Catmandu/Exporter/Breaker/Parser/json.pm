package Catmandu::Exporter::Breaker::Parser::json;

use Catmandu::Sane;
use Moo;
use Catmandu::Expander;
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

    my $collapse   = Catmandu::Expander->collapse_hash($data);
    delete $collapse->{_id};

    for my $tag (sort keys %$collapse) {
        my $value = $collapse->{$tag};

        $tag =~ s{\.\d+}{[]}g;

        $self->tags->{$tag} = 1;

        $io->print(
            $self->breaker->to_breaker(
                $identifier ,
                $tag ,
                $value)
        );
    }

    1;
}

1;

__END__

=head1 NAME

Catmandu::Exporter::Breaker::Parser::json - default handler

=head1 DESCRIPTION

This is the default L<Catmandu::Breaker> handler.

=cut
