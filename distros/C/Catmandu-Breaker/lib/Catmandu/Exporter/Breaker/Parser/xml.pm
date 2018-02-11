package Catmandu::Exporter::Breaker::Parser::xml;

use Catmandu::Sane;
use Moo;
use Catmandu::Breaker;
use Carp;
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

    $self->xpath_gen($data,[],sub {
        my ($tag,$value) = @_;

        $self->tags->{$tag} = 1;
        
        $io->print(
            $self->breaker->to_breaker(
                $identifier ,
                $tag ,
                $value)
        );
    });

    1;
}

sub xpath_gen {
    my ($self,$data,$path,$callback) = @_;

    if (ref($data) eq 'HASH') {
        for my $key (keys %$data) {
            my $value = $data->{$key};
            if (ref($value)) {
                $self->xpath_gen($value,[@$path,$key],$callback);
            }
            else {
                $callback->(join("/",@$path,$key),$value);
            }
        }
        return;
    }
    elsif (ref($data) eq 'ARRAY') {
        for my $value (@$data) {
            if (ref($value)) {
                $self->xpath_gen($value,$path,$callback);
            }
            else {
                $callback->(join("/",@$path),$value);
            }
        }
    }
}

1;

__END__

=head1 NAME

Catmandu::Exporter::Breaker::Parser::xml - handler for XML format

=head1 DESCRIPTION

This L<Catmandu::Breaker> handler breaks XML format.

=head1 SEE ALSO

L<Catmandu::XML>

=cut
