package Acme::2zicon::Base;

use strict;
use warnings;
use DateTime;
use base qw(Class::Accessor);

our $VERSION = '0.7';

__PACKAGE__->mk_accessors(qw(
    name_ja
    first_name_ja
    family_name_ja
    name_en
    first_name_en
    family_name_en
    nick
    birthday
    age
    blood_type
    hometown
    introduction
    twitter
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
    $self->{name_ja} = $self->family_name_ja.$self->first_name_ja;
    $self->{name_en} = $self->first_name_en.' '.$self->family_name_en;
    $self->{age}     = $self->_calculate_age;
    $self->{introduction} = $self->_introduction($info{introduction});

    return 1;
}

sub _calculate_age {
    my $self  = shift;
    my $today = DateTime->today;

    if (($today->month - $self->birthday->month) >= 0) {
        if (($today->day - $self->birthday->day  ) >= 0) {
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
    my ($year, $month, $day) = ($date =~ /(\d{4})\.(\d{2})\.(\d{2})/);

    DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );
}

sub _introduction {
    my ($self, $introduction) = @_;
    $introduction =~ s/\[(\w+)\]/$self->{$1}/g;
    return $introduction;
}

1;

__END__

=head1 NAME

Acme::2zicon::Base

=head1 SYNOPSIS

  use Acme::2zicon;

  my $nizicon = Acme::2zicon->new;

  # retrieve the members as a list of
  # Acme::2zicon::Base based objects
  my @members = $nizicon->members;

  for my $member (@members) {
      my $name_ja        = $member->name_ja;
      my $first_name_ja  = $member->first_name_ja;
      my $family_name_ja = $member->family_name_ja;
      my $name_en        = $member->name_en;
      my $first_name_en  = $member->first_name_en;
      my $family_name_en = $member->family_name_en;
      my $nick           = $member->nick;           # arrayref
      my $birthday       = $member->birthday;       # DateTime object
      my $age            = $member->age;
      my $blood_type     = $member->blood_type;
      my $hometown       = $member->hometown;
      my $twitter        = $member->twitter;
  }

=head1 DESCRIPTION

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

=head2 blood_type

=head2 hometown

=head2 twitter

=head1 SEE ALSO

=over 4

=item * L<DateTime>

=back

=head1 AUTHOR

=head1 COPYRIGHT AND LICENSE (The MIT License)

=cut
