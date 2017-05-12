package Acme::MomoiroClover::Members::Base;

use strict;
use warnings;
use Date::Simple ();
use base qw(Class::Accessor);

our $ansi_colors = {
  red    => "\x1b[38;5;1m",
  green  => "\x1b[38;5;2m",
  blue   => "\x1b[38;5;4m",
  purple => "\x1b[38;5;5m",
  pink   => "\x1b[38;5;13m",
  yellow => "\x1b[38;5;3m",
};


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
    emoticon
    graduate_date
    join_date
    color
));

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    $self->_initialize;

    return $self;
}

sub say {
    my ($self, $comment) = @_;
    print $ansi_colors->{$self->color} if ($self->color);
    print $self->nick->[0] || $self->name_ja;
    print  ': ';
    print $comment, "\x1b[0m\n";
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
    my $self  = shift;
    my $today = Date::Simple::today;

    if (($today->month - $self->birthday->month) == 0) {
        if (($today->day - $self->birthday->day) >= 0) {
            return $today->year - $self->birthday->year;
        } else {
            return ($today->year - $self->birthday->year) - 1;
        }
    } elsif (($today->month - $self->birthday->month) > 0) {
        return $today->year - $self->birthday->year;
    } else {
        return ($today->year - $self->birthday->year) - 1;
    }
}

1;

__END__

=head1 NAME

Acme::MomoiroClover::Members::Base - A baseclass of the class represents each
member of Momoiro Clover

=head1 SYNOPSIS

  use Acme::MomoiroClover::Z;

  my $momoclo_chan = Acme::MomoiroClover::Z->new;

  # retrieve the members as a list of
  # Acme::MomoiroClover::Base based objects
  my @members = $momoclo_chan->members;

  for my $member (@members) {
      my $name_ja        = $member->name_ja;
      my $first_name_ja  = $member->first_name_ja;
      my $family_name_ja = $member->family_name_ja;
      my $name_en        = $member->name_en;
      my $first_name_en  = $member->first_name_en;
      my $family_name_en = $member->family_name_en;
      my $nick           = $member->nick;           # arrayref
      my $birthday       = $member->birthday;       # Date::Simple object
      my $age            = $member->age;
      my $blood_type     = $member->blood_type;
      my $hometown       = $member->hometown;
      my $emoticon       = $member->emoticon;       # arrayref
      my $graduate_date  = $member->graduate_date;  # Date::Simple object
      my $join_date      = $member->join_date;      # Date::Simple object
      my $color          = $member->color;

      $member->say('momoclo chan!!');
  }

=head1 DESCRIPTION

Acme::MomoiroClover::::Member::Base is a baseclass of the class represents each
member of Momoiro Clover.

=head1 METHODS

=head2 say ( $comment )

  $member->say("momoclo chan!!");

=back

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

=head2 emoticon

=head2 graduate_date

=head2 join_date

=head2 color

=head1 SEE ALSO

=over 4

=item * L<Date::Simple>

=back

=cut
