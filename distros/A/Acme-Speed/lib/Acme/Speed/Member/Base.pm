package Acme::Speed::Member::Base;

use strict;
use warnings;
use DateTime;
use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(
    name_ja
    first_name_ja
    family_name_ja
    name_en
    first_name_en
    family_name_en
    birthday
    age
));

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->_initialize;

    return $self;
}

sub _initialize {
    my $self = shift;
    my %info = $self->info;

    $self->{$_}      = $info{$_} for keys %info;
    $self->{name_ja} = $self->family_name_ja.$self->first_name_ja;
    $self->{name_en} = $self->first_name_en.' '.$self->family_name_en;
    $self->{age}     = $self->_calculate_age;

    return 1;
}

sub _calculate_age {
    my $self = shift;
    my $today = DateTime->today;

    if (($today->month - $self->birthday->month) >= 0) {
        if (($today->day - $self->birthday->day) >= 0) {
            return $today->year - $self->birthday->year;
        } else {
            return ($today->year - $self->birthday->year) - 1;
        }
    } else {
        return ($today->year - $self->birthday->year) - 1;
    }
}

sub _datetime_from_date {
    my ($self, $date) = @_;
    my ($year, $month, $day) = ($date =~ /(\d{4})-(\d{2})-(\d{2})/);

    return DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );
}

1;

__END__

=head1 NAME

Acme::Speed::Member::Base - A base class of the class represents each
member of SPEED

=head1 SYNOPSIS

  use Acme::Speed;

  my $speed = Acme::Speed->new;

  # retrieve the members as a list of
  # Acme::Speed::Member::Base based objects
  my @members = $speed->members;

  for my $member (@members) {
      my $name_ja        = $member->name_ja;
      my $first_name_ja  = $member->first_name_ja;
      my $family_name_ja = $member->family_name_ja;
      my $name_en        = $member->name_en;
      my $first_name_en  = $member->first_name_en;
      my $family_name_en = $member->family_name_en;
      my $nick           = $member->nick;
      my $birthday       = $member->birthday;       # DateTime object
      my $age            = $member->age;
  }

=head1 DESCRIPTION

Acme::Speed::Member::Base is a base class of the class represents each member of SPEED.

=head1 ACCESSORS

=head2 name_ja       

=head2 first_name_ja 

=head2 family_name_ja

=head2 name_en       

=head2 first_name_en 

=head2 family_name_en

=head2 nick          

=head2 birthday      

=head2 age           

=head1 LICENSE

Copyright (C) Keisuke KITA.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Keisuke KITA E<lt>kei.kita2501@gmail.comE<gt>

=cut
