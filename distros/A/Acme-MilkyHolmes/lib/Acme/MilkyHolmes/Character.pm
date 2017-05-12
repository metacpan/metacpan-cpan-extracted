package Acme::MilkyHolmes::Character;
use Mouse;

use Data::Section::Simple;
use Localizer::Resource;
use Localizer::Style::Gettext;
use YAML::Tiny;
use utf8;

has localizer => (
    is  => 'ro',
);

has locale => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'ja',
);

has common => (
    is => 'ro',
);

no Mouse;

sub name {
    my ($self) = @_;

    my $sep = $self->_localized_field('name_separator');
    $sep = ' ' if ( !defined $sep );

    if ( defined $self->_localized_field('name') ) {
        return $self->_localized_field('name');
    }
    elsif ( $self->locale eq 'ja' ) {
        if( defined $sep && $sep eq '・' ) {
            return $self->firstname . $sep . $self->familyname;
        }
        return $self->familyname . $sep . $self->firstname;
    }
    return $self->firstname . $sep . $self->familyname;
}

sub firstname {
    my ($self) = @_;
    return $self->_localized_field('firstname');
}

sub familyname {
    my ($self) = @_;
    return $self->_localized_field('familyname');
}

sub nickname {
    my ($self) = @_;
    if ( defined $self->_localized_field('nickname') ) {
        return $self->_localized_field('nickname');
    }
    return $self->_localized_field('firstname');
}

sub birthday {
    my ($self) = @_;
    return $self->_localized_field('birthday');
}

sub voiced_by {
    my ($self) = @_;
    return $self->_localized_field('voiced_by');
}

sub nickname_voiced_by {
    my ($self) = @_;
    return $self->_localized_field('nickname_voiced_by');
}

sub _localized_field {
    my ($self, $name) = @_;
    if ( exists $self->localizer->{ $self->locale } ) {
        my $localizer = $self->localizer->{ $self->locale };
        return $localizer->maketext($name);
    }
    return $self->{$name};
}

sub BUILD {
    my ($self, $args) = @_;

    my $ds = Data::Section::Simple->new( ref $self );
    my $sections = $ds->get_data_section();
    if ( exists $sections->{common} ) {
        my $common = YAML::Tiny->read_string( delete $sections->{common} );
        $self->{common} = $common;
    }

    for my $section_name ( keys %{ $sections || {} } ) {
        my $yaml = YAML::Tiny->read_string($sections->{$section_name});

        my $localizer = Localizer::Resource->new(
            dictionary => $yaml->[0],
            format     => Localizer::Style::Gettext->new(),
        );
        $self->{localizer}->{$section_name} = $localizer;
    }
}

1;
__END__

=encoding utf-8

=for stopwords ja

=head1 NAME

Acme::MilkyHolmes::Character - Character base class for Milky Holmes

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use Acme::MilkyHolmes::Character::SherlockShellingford;

    my $sherlock = Acme::MilkyHolmes::Character::SherlockShellingford->new();
    $sherlock->locale('en');
    $sherlock->name;       # => 'Sherlock Shellingford'
    $sherlock->firstname;  # => 'Sherlock'
    $sherlock->familyname; # => 'Shellingford'
    $sherlock->nickname;   # => 'Sheryl'
    $sherlock->birthday;   # => 'March 31'
    $sherlock->voiced_by;  # => 'Suzuko Mimori'

=head1 METHODS

=head2 C<name>

=head2 C<firstname>

=head2 C<familyname>

=head2 C<nickname>

=head2 C<birthday>

=head2 C<voiced_by>


=head1 SEE ALSO

=over 4

=item * Characters in Milky Holmes (Wikipedia - ja)

L<http://ja.wikipedia.org/wiki/%E6%8E%A2%E5%81%B5%E3%82%AA%E3%83%9A%E3%83%A9_%E3%83%9F%E3%83%AB%E3%82%AD%E3%82%A3%E3%83%9B%E3%83%BC%E3%83%A0%E3%82%BA%E3%81%AE%E7%99%BB%E5%A0%B4%E4%BA%BA%E7%89%A9>

=item * Milky Holmes (Wikipedia - en)

L<http://en.wikipedia.org/wiki/Tantei_Opera_Milky_Holmes>

=back

=cut
