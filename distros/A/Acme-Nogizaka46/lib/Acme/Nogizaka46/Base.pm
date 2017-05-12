package Acme::Nogizaka46::Base;

use strict;
use warnings;
use DateTime;
use base qw(Class::Accessor);

our $VERSION = 0.3;

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
    class
    center
    graduate_date
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

    return 1;
}

sub _calculate_age {
    my $self  = shift;
    my $today = DateTime->today;

    if (($today->month - $self->birthday->month) > 0) {
        return $today->year - $self->birthday->year;
    } elsif (($today->month - $self->birthday->month) == 0) {
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

Acme::Nogizaka46::Base - A baseclass of the class represents each
member of Nogizaka46.

=head1 SYNOPSIS

  use Acme::Nogizaka46;

  my $nogizaka = Acme::Nogizaka46->new;

  # retrieve the members as a list of
  # Acme::Nogizaka46::Base based objects
  my @members = $nogizaka->members;

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
      my $emoticon       = $member->emoticon;       # arrayref
      my $class          = $member->class;
      my $graduate_date  = $member->graduate_date;  # DateTime object
  }

=head1 DESCRIPTION

Acme::Nogizaka46::Base is a baseclass of the class represents each
member of Nogizaka46.

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

=head2 class

=head2 graduate_date

=head1 SEE ALSO

=over 4

=item * L<DateTime>

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2015, Takaaki TSUJIMOTO E<lt>2gmon.t@gmail.comE<gt>

Original Copyright (c) 2005 - 2007, Kentaro Kuribayashi
E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
