package Acme::MomoiroClover;

use strict;
use warnings;

use Carp  qw(croak);
use Date::Simple ();
use Acme::MomoiroClover::Z;

our $VERSION = '0.2';

my @members = qw(
    AriyasuMomoka
    FujishiroSumire
    HayamiAkari
    IkuraManami
    KashiwaYukina
    MomotaKanako
    SasakiAyaka
    TakagiReni
    TakaiTsukina
    TamaiShiori
    WagawaMiyuu
);

sub new {
    my $class = shift;
    my $self  = bless {members => []}, $class;

    $self->_check();
    $self->_initialize;

    return $self;
}

sub _check {
    my $self = shift;
    Date::Simple::today() <= Acme::MomoiroClover::Z::change_date() or croak('MomoiroClover is obsolete. Please use Acme::MomoiroClover::Z ');
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
    elsif ($type->isa('Date::Simple')) {
        return grep {
            $_->join_date <= $type and
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
        my $module_name = 'Acme::MomoiroClover::Members::'.$member;

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

Acme::MomoiroClover - All about Japanese lock star "Momoiro Clover"

=head1 SYNOPSIS

  use Acme::MomoiroClover;

  my $momoclo_chan = Acme::Momoiro::Z->new;

  # retrieve the members on their activities
  my @members              = $momoclo_chan->members;             # retrieve all
  my @active_members       = $momoclo_chan->members('active');
  my @graduate_members     = $momoclo_chan->members('graduate');
  my @at_some_time_members = $momoclo_chan->members(Date::Simple->new('2001-01-01'));

  # retrieve the members under some conditions
  my @sorted_by_age        = $momoclo_chan->sort('age', 1);
  my @sorted_by_class      = $momoclo_chan->sort('class', 1);
  my @selected_by_age      = $momoclo_chan->select('age', 17, '>=');
  my @selected_by_class    = $momoclo_chan->select('class', 5, '==');

=head1 DESCRIPTION

"Morning Clover" is one of highly famous Japanese lock stars.

This module, Acme::MomoiroClover, provides an easy method to catch up
with Momoiro Clover.

=head1 METHODS

=head2 new

=over 4

  my $momoclo_chan = Acme::MomoiroClover->new; // now obsolete
  $momoclo_chan = Acme::MomoiroClover::Z->new;

Creates and returns a new Acme::MomoiroClover::Z object.

=back

=head2 members ( $type )

=over 4

  # $type can be one of the values below:
  #  + active              : active members
  #  + graduate            : graduate members
  #  + Date::Simple object : members at the time passed in
  #  + undef               : all members

  my @members = $momoclo_chan->members('active');

Returns the members as a list of the L<Acme::MomoiroClover::Base>
based object represents each member. See also the documentation of
L<Acme::MomoiroClover::Base> for more details.

=back

=head2 sort ( $type, $order [ , @members ] )

=over 4

  # $type can be one of the values below:
  #  + age       :  sort by age
  #  + join_date :  sort by join_date
  #
  # $order can be a one of the values below:
  #  + something true value  :  sort in descending order
  #  + something false value :  sort in ascending order

  my @sorted_members = $momoclo_chan->sort('age', 1); # sort by age in descending order

Returns the members sorted by the I<$type> field.

=back

=head2 select ( $type, $number, $operator [, @members] )

=over 4

  # $type can be one of the same values above:
  my @selected_members = $momoclo_chan->select('age', 17, '>=');

Returns the members satisfy the given I<$type> condition. I<$operator>
must be a one of '==', '>=', '<=', '>', and '<'. This method compares
the given I<$type> to the member's one in the order below:

  $number $operator $member_value

=back

=head1 SEE ALSO

=over 4

=item * Momoiro Clover - Official WebPage

L<http://www.momoclo.net/>

=item * Momoiro Clover Z - Wikipedia

L<http://ja.wikipedia.org/wiki/%E3%82%82%E3%82%82%E3%81%84%E3%82%8D%E3%82%AF%E3%83%AD%E3%83%BC%E3%83%90%E3%83%BCZ>

=item * L<Acme::MomoiroClover::Members::Base>

=back

=head1 AUTHOR

Yuichi TatenoE<lt>hotchpotch@gmail.com<gt>

Based on Acme::MomoiroClover (Kentaro Kuribayashi).

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2011, Yuichi Tateno
E<lt>hotchpotch@gmail.com<gt>

Original Copyright, Kentaro Kuribayashi.

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
