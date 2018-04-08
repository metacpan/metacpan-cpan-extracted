package Acme::Keyakizaka46::Base;

use strict;
use warnings;
use DateTime;
use base qw(Class::Accessor);

our $VERSION = '0.0.1';

__PACKAGE__->mk_accessors(qw(
        first_name_en
        family_name_en
        first_name_ja
        family_name_ja
        birthday
        zodiac_sign
        height
        hometown
        blood_type
        team
        class
        center
        name_ja
        name_en
        age
));

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    $self->_initialize;

    return $self;
}

sub _initialize {
    my $self = shift;
    my %info = $self->info;

    $self->{$_}      = $info{$_} for keys %info;
    $self->{name_ja} = $self->family_name_ja.' '.$self->first_name_ja;
    $self->{name_en} = $self->first_name_en .' '.$self->family_name_en;
    $self->{age}     = $self->_calculate_age;

    return 1;
}

sub _calculate_age {
    my $self  = shift;
    my $today = DateTime->today->ymd('');
    my $birthday = $self->birthday->ymd('');

    return int(($today-$birthday)/10000);
}

sub _datetime_from_date {
    my ($self, $date) = @_;
    my ($year, $month, $day) = ($date =~ /(\d{4})-(\d{2})-(\d{2})/);

    DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );
}

1;

__END__

=head1 NAME

Acme::Keyakizaka46::Base - A baseclass of the class represents each
member of Keyakizaka46.

=head1 SYNOPSIS

  use Acme::Keyakizaka46;

  my $keyaki = Acme::Keyakizaka46->new;

  # retrieve the members as a list of
  # Acme::Keyakizaka46::Base based objects
  my @members = $keyaki->team_members;

  for my $member (@members) {
      my $name_en        = $member->name_en;
      my $first_name_en  = $member->first_name_en;
      my $family_name_en = $member->family_name_en;
      my $name_ja        = $member->name_ja;
      my $first_name_ja  = $member->first_name_ja;
      my $family_name_ja = $member->family_name_ja;
      my $birthday       = $member->birthday;
      my $height         = $member->height;
      my $hometown       = $member->hometown;
      my $blood_type     = $member->blood_type;
      my $class          = $member->class;
      my $center         = $member->center;
      my $age            = $member->age;
  }

=head1 DESCRIPTION

Acme::Keyakizaka46::Base is a baseclass of the class represents each
member of Keyakizaka46.

=head1 ACCESSORS

=over 4

=item * name_ja

=item * first_name_ja

=item * family_name_ja

=item * name_en

=item * first_name_en

=item * family_name_en

=item * birthday

=item * height

=item * hometown

=item * blood_type

=item * class

=item * center

=item * age

=back

=head1 SEE ALSO

=head1 AUTHOR

Okawara Ayato E<lt>2044taiga@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
