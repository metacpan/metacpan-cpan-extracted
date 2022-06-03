package Data::Gimei::Name;

use warnings;
use v5.22;
use Carp;
use File::Share qw( dist_file );
use YAML::XS;

use Class::Tiny qw(
  gender
  given
  family
);

our $names;

sub BUILDARGS {
    my $class = shift;
    my %args  = @_;

    $names //= load();

    $args{'gender'} //= Data::Gimei::sample( [ 'male', 'female' ] );
    $args{'given'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $names->{'first_name'}->{ $args{'gender'} } ) );
    $args{'family'} =
      Data::Gimei::Word->new( Data::Gimei::sample( $names->{'last_name'} ) );

    return \%args;
}

sub load {
    my $yaml_path = shift // dist_file( 'Data-Gimei', 'names.yml' );
    Carp::croak("failed to load name data: $yaml_path") unless (-r $yaml_path);

    $names = YAML::XS::LoadFile($yaml_path);
}

sub kanji {
    my $self = shift;
    return $self->family->kanji . " " . $self->given->kanji;
}

sub hiragana {
    my $self = shift;
    return $self->family->hiragana . " " . $self->given->hiragana;
}

sub katakana {
    my $self = shift;
    return $self->family->katakana . " " . $self->given->katakana;
}

sub romaji {
    my $self = shift;
    return $self->given->romaji . " " . $self->family->romaji;
}

1;
