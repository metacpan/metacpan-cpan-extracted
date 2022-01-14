package Data::Gimei::Address;

use utf8;
use feature ':5.30';
use File::Share ':all';
use YAML::XS;

use Moo;
use namespace::clean;

has prefecture => ( is => 'ro' );
has city       => ( is => 'ro' );
has town       => ( is => 'ro' );

our $addresses;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    $addresses //= load();

    $args{'prefecture'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $addresses->{'addresses'}->{'prefecture'} ) );
    $args{'city'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $addresses->{'addresses'}->{'city'} ) );
    $args{'town'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $addresses->{'addresses'}->{'town'} ) );
    return $class->$orig(%args);
};

sub load {
    my $yaml_path = shift // dist_file( 'Data-Gimei', 'addresses.yml' );

    $addresses = YAML::XS::LoadFile($yaml_path);
}

sub kanji {
    my $self = shift;
    return $self->prefecture->kanji . $self->city->kanji . $self->town->kanji;
}

sub hiragana {
    my $self = shift;
    return $self->prefecture->hiragana . $self->city->hiragana . $self->town->hiragana;
}

sub katakana {
    my $self = shift;
    return $self->prefecture->katakana . $self->city->katakana . $self->town->katakana;
}

1;
