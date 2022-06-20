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

sub load {
    my $yaml_path = shift // dist_file( 'Data-Gimei', 'addresses.yml' );
    Carp::croak("failed to load address data: $yaml_path") unless -r $yaml_path;

    $addresses = YAML::XS::LoadFile($yaml_path);
}

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

sub to_s {
    my $self = shift;

    return sprintf( "%s, %s, %s",
        $self->kanji(' '),
        $self->hiragana(' '),
        $self->katakana(' ') );
}

sub kanji {
    my ( $self, $s ) = @_;

    return join $s // '',
      map { $_->kanji } ( $self->prefecture, $self->city, $self->town );
}

sub hiragana {
    my ( $self, $s ) = @_;

    return join $s // '',
      map { $_->hiragana } ( $self->prefecture, $self->city, $self->town );
}

sub katakana {
    my ( $self, $s ) = @_;

    return join $s // '',
      map { $_->katakana } ( $self->prefecture, $self->city, $self->town );
}

1;
