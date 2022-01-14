package Data::Gimei::Name;

use utf8;
use feature ':5.30';
use File::Share ':all';
use YAML::XS;

use Moo;
use namespace::clean;

has gender     => ( is => 'ro' );
has first_name => ( is => 'ro' );
has last_name  => ( is => 'ro' );

our $names;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    $names //= load();

    $args{'gender'} //= Data::Gimei::sample( [ 'male', 'female' ] );
    $args{'first_name'} = Data::Gimei::Word->new(
        Data::Gimei::sample( $names->{'first_name'}->{ $args{'gender'} } ) );
    $args{'last_name'} =
      Data::Gimei::Word->new( Data::Gimei::sample( $names->{'last_name'} ) );
    return $class->$orig(%args);
};

sub load {
    my $yaml_path = shift // dist_file( 'Data-Gimei', 'names.yml' );

    $names = YAML::XS::LoadFile($yaml_path);
}

sub kanji {
    my $self = shift;
    return $self->last_name->kanji . " " . $self->first_name->kanji;
}

sub hiragana {
    my $self = shift;
    return $self->last_name->hiragana . " " . $self->first_name->hiragana;
}

sub katakana {
    my $self = shift;
    return $self->last_name->katakana . " " . $self->first_name->katakana;
}

sub romaji {
    my $self = shift;
    return $self->first_name->romaji . " " . $self->last_name->romaji;
}

1;
