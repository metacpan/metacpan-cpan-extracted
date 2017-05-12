package Acme::MorningMusume;

use strict;
use warnings;

use Carp  qw(croak);
use DateTime;

our $VERSION = '0.20';

my @members = qw(
    FukudaAsuka
    NakazawaYuko
    IidaKaori
    AbeNatsumi
    IshiguroAya
    IchiiSayaka
    YaguchiMari
    YasudaKei
    GotohMaki
    IshikawaRika
    YoshizawaHitomi
    TsujiNozomi
    KagoAi
    TakahashiAi
    KonnoAsami
    OgawaMakoto
    NiigakiRisa
    KameiEri
    TanakaReina
    MichishigeSayumi
    FujimotoMiki
    KusumiKoharu
    MitsuiAika
    LiChun
    QianLin
    SuzukiKanon
    IkutaErina
    FukumuraMizuki
    SayashiRiho
    IikuboHaruna
    IshidaAyumi
    SatohMasaki
    KudohHaruka
    OdaSakura
    OgataHaruna
    NonakaMiki
    MakinoMaria
    HagaAkane
);

my @date_joined = map {
    my ($year, $month, $day) = ($_ =~ /(\d{4})-(\d{2})-(\d{2})/);
    DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );
} qw(
    1997-09-07
    1998-05-03
    1999-08-04
    2000-04-16
    2001-08-26
    2003-01-19
    2005-05-01
    2006-12-10
    2011-01-02
    2011-09-29
    2012-09-14
    2014-09-30
);
unshift @date_joined, undef;

sub new {
    my $class = shift;
    my $self  = bless {members => []}, $class;

    $self->_initialize;

    return $self;
}

sub members {
    my ($self, $type, @members) = @_;
    @members = @{$self->{members}} unless @members;

    return @members unless $type;

    if ($type eq 'active') {
        return grep {!$_->graduate_date} @members;
    }
    elsif ($type eq 'graduate') {
        return grep {$_->graduate_date}  @members;
    }
    elsif ($type->isa('DateTime')) {
        return grep {
            $date_joined[$_->class] <= $type and
            (!$_->graduate_date or $type <= $_->graduate_date)
        } @members;
    }
}

sub sort {
    my ($self, $type, $order, @members) = @_;
    @members = $self->members unless @members;

    # order by desc if $order is true
    if ($order) {
        return sort {$b->$type <=> $a->$type} @members;
    }
    else {
        return sort {$a->$type <=> $b->$type} @members;
    }
}

sub select {
    my ($self, $type, $number, $operator, @members) = @_;

    $self->_die('invalid operator was passed in')
        unless grep {$operator eq $_} qw(== >= <= > <);

    @members = $self->members unless @members;
    my $compare = eval "(sub { \$number $operator \$_[0] })";

    return grep { $compare->($_->$type) } @members;
}

sub _initialize {
    my $self = shift;

    for my $member (@members) {
        my $module_name = 'Acme::MorningMusume::'.$member;

        eval qq|require $module_name;|;
        push @{$self->{members}}, $module_name->new;
    }

    return 1;
}

sub _die {
    my ($self, $message) = @_;
    Carp::croak($message);
}

1;

__END__

=head1 NAME

Acme::MorningMusume - All about Japanese pop star "Morning Musume"

=head1 SYNOPSIS

  use Acme::MorningMusume;

  my $musume = Acme::MorningMusume->new;

  # retrieve the members on their activities
  my @members              = $musume->members;             # retrieve all
  my @active_members       = $musume->members('active');
  my @graduate_members     = $musume->members('graduate');
  my @at_some_time_members = $musume->members(DateTime->now->subtract(years => 5));

  # retrieve the members under some conditions
  my @sorted_by_age        = $musume->sort('age', 1);
  my @sorted_by_class      = $musume->sort('class', 1);
  my @selected_by_age      = $musume->select('age', 18, '>=');
  my @selected_by_class    = $musume->select('class', 5, '==');

=head1 DESCRIPTION

"Morning Musume" is one of highly famous Japanese pop stars.

It consists of many pretty girls and has been known as a group which
members change one after another so frequently that people can't
completely tell who is who in the group.

This module, Acme::MorningMusume, provides an easy method to catch up
with Morning Musume.

=head1 METHODS

=head2 new

=over 4

  my $musume = Acme::MorningMusume->new;

Creates and returns a new Acme::MorningMusume object.

=back

=head2 members ( $type )

=over 4

  # $type can be one of the values below:
  #  + active              : active members
  #  + graduate            : graduate members
  #  + DateTime object     : members at the time passed in
  #  + undef               : all members

  my @members = $musume->members('active');

Returns the members as a list of the L<Acme::MorningMusume::Base>
based object represents each member. See also the documentation of
L<Acme::MorningMusume::Base> for more details.

=back

=head2 sort ( $type, $order [ , @members ] )

=over 4

  # $type can be one of the values below:
  #  + age   :  sort by age
  #  + class :  sort by class
  #
  # $order can be a one of the values below:
  #  + something true value  :  sort in descending order
  #  + something false value :  sort in ascending order

  my @sorted_members = $musume->sort('age', 1); # sort by age in descending order

Returns the members sorted by the I<$type> field.

=back

=head2 select ( $type, $number, $operator [, @members] )

=over 4

  # $type can be one of the same values above:
  my @selected_members = $musume->select('age', 18, '>=');

Returns the members satisfy the given I<$type> condition. I<$operator>
must be a one of '==', '>=', '<=', '>', and '<'. This method compares
the given I<$type> to the member's one in the order below:

  $number $operator $member_value

=back

=head1 SEE ALSO

=over 4

=item * MORNING MUSUME -Hello! Project-

L<http://www.helloproject.com/>

=item * Morning Musume - Wikipedia

L<http://en.wikipedia.org/wiki/Morning_Musume>

=item * L<Acme::MorningMusume::Base>

=back

=head1 AUTHOR

=over 4

=item * Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=item * Kaneko Tatsuya L<https://github.com/catatsuy>

=back

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2005 - 2013, Kentaro Kuribayashi
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
