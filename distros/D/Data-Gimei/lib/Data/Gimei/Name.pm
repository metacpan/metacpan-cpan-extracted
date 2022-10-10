package Data::Gimei::Name;

use warnings;
use v5.22;
use Carp;
use File::Share qw( dist_file );
use YAML::XS;

use Class::Tiny qw(
  gender
  forename
  surname
);

our $names;

sub load {
    my $yaml_path = shift // dist_file( 'Data-Gimei', 'names.yml' );
    Carp::croak("failed to load name data: $yaml_path") unless -r $yaml_path;

    $names = YAML::XS::LoadFile($yaml_path);
}

sub BUILDARGS {
    my $class = shift;
    my %args  = @_;

    $names //= load();

    $args{'gender'} //= Data::Gimei::sample( [ 'male', 'female' ] );
    $args{'forename'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $names->{'first_name'}->{ $args{'gender'} } ) );
    $args{'surname'} =
      Data::Gimei::Word->new( Data::Gimei::sample( $names->{'last_name'} ) );

    return \%args;
}

sub to_s {
    my $self = shift;

    return sprintf( "%s, %s, %s, %s, %s",
        $self->gender, $self->kanji, $self->hiragana, $self->katakana, $self->romaji );
}

sub kanji {
    my ( $self, $s ) = @_;
    return join $s // ' ', map { $_->kanji } ( $self->surname, $self->forename );
}

sub hiragana {
    my ( $self, $s ) = @_;
    return join $s // ' ', map { $_->hiragana } ( $self->surname, $self->forename );
}

sub katakana {
    my ( $self, $s ) = @_;
    return join $s // ' ', map { $_->katakana } ( $self->surname, $self->forename );
}

sub romaji {
    my ( $self, $s ) = @_;
    return join $s // ' ', map { $_->romaji } ( $self->forename, $self->surname );
}

1;
