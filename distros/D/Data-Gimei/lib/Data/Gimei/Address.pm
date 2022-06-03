package Data::Gimei::Address;

use warnings;
use v5.22;
use Carp;
use File::Share qw( dist_file );
use YAML::XS;

use Class::Tiny qw(
  prefecture
  city
  town
);

our $addresses;

sub BUILDARGS {
    my $class = shift;
    my %args  = @_;

    $addresses //= load();

    $args{'prefecture'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $addresses->{'addresses'}->{'prefecture'} ) );
    $args{'city'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $addresses->{'addresses'}->{'city'} ) );
    $args{'town'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $addresses->{'addresses'}->{'town'} ) );

    return \%args;
}

sub load {
    my $yaml_path = shift // dist_file( 'Data-Gimei', 'addresses.yml' );
    Carp::croak("failed to load address data: $yaml_path") unless (-r $yaml_path);

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
