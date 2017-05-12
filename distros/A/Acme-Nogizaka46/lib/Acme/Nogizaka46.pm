package Acme::Nogizaka46;

use strict;
use warnings;

use Carp  qw(croak);
use DateTime;

our $VERSION = '0.3';

my @members = qw(
    AkimotoManatsu
    AndoMikumo
    IkutaErika
    IkomaRina
    IchikiRena
    ItoNene
    ItoMarika
    InoueSayuri
    IwaseYumiko
    EtoMisa
    KashiwaYukina
    KawagoHina
    KawamuraMahiro
    SaitoAsuka
    SaitoChiharu
    SaitoYuri
    SakuraiReika
    ShiraishiMai
    TakayamaKazumi
    NakadaKana
    NakamotoHimeka
    NagashimaSeira
    NishinoNanase
    NojoAmi
    HashimotoNanami
    HatanakaSeira
    HiguchiHina
    FukagawaMai
    HoshinoMinami
    MatsumuraSayuri
    MiyazawaSeira
    YamatoRina
    YamamotoHonoka
    YoshimotoAyaka
    WakatsukiYumi
    WadaMaaya
    ItoKarin
    ItoJunna
    KitanoHinako
    SagaraIori
    SasakiKotoko
    ShinuchiMai
    SuzukiAyane
    TeradaRanze
    NishikawaNanami
    HoriMiona
    YadaRisako
    YamazakiRena
    YonetokuKyoka
    WatanabeMiria
    MatsuiRena
);

my %date_joined = map {
    my ($class, $year, $month, $day) = ($_ =~ /(\w+):(\d{4})-(\d{2})-(\d{2})/);
    $class => DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
    );
} qw(
    1:2011-08-21
    2:2013-05-11
    MatsuiRena:2014-02-24
);

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
            $date_joined{$_->class} <= $type and
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
    my ($self, $type, $num_or_str, $operator, @members) = @_;

    $self->_die('invalid operator was passed in')
        unless grep {$operator eq $_} qw(== >= <= > < eq ne);

    @members = $self->members unless @members;
    if ($type eq 'center') {
    } else {
        my $compare = eval "(sub { \$num_or_str $operator \$_[0] })";

        return grep { $compare->($_->$type) } @members;
    }
}

sub _initialize {
    my $self = shift;

    for my $member (@members) {
        my $module_name = 'Acme::Nogizaka46::'.$member;

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

Acme::Nogizaka46 - All about "Nogizaka46"

=head1 SYNOPSIS

  use Acme::Nogizaka46;

  my $nogizaka = Acme::Nogizaka46->new;

  # retrieve the members on their activities
  my @members              = $nogizaka->members;             # retrieve all
  my @active_members       = $nogizaka->members('active');
  my @graduate_members     = $nogizaka->members('graduate');
  my @at_some_time_members = $nogizaka->members(DateTime->now->subtract(years => 5));

  # retrieve the members under some conditions
  my @sorted_by_age        = $nogizaka->sort('age', 1);
  my @sorted_by_class      = $nogizaka->sort('class', 1);
  my @selected_by_age      = $nogizaka->select('age', 18, '>=');
  my @selected_by_class    = $nogizaka->select('class', 5, '==');

=head1 DESCRIPTION

"Nogizaka46" is a Japanese female idol group.

This module, Acme::Nogizaka46, provides an easy method to catch up
with Nogizaka46.

=head1 METHODS

=head2 new

=over 4

  my $nogizaka = Acme::Nogizaka46->new;

Creates and returns a new Acme::Nogizaka46 object.

=back

=head2 members ( $type )

=over 4

  # $type can be one of the values below:
  #  + active              : active members
  #  + graduate            : graduate members
  #  + DateTime object     : members at the time passed in
  #  + undef               : all members

  my @members = $nogizaka->members('active');

Returns the members as a list of the L<Acme::Nogizaka46::Base>
based object represents each member. See also the documentation of
L<Acme::Nogizaka46::Base> for more details.

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

  my @sorted_members = $nogizaka->sort('age', 1); # sort by age in descending order

Returns the members sorted by the I<$type> field.

=back

=head2 select ( $type, $number, $operator [, @members] )

=over 4

  # $type can be one of the same values above:
  my @selected_members = $nogizaka->select('age', 18, '>=');

Returns the members satisfy the given I<$type> condition. I<$operator>
must be a one of '==', '>=', '<=', '>', and '<'. This method compares
the given I<$type> to the member's one in the order below:

  $number $operator $member_value

=back

=head1 SEE ALSO

=over 4

=item * Nogizaka46

L<http://www.nogizaka46.com/>

=item * Nogizaka46 - Wikipedia

L<https://en.wikipedia.org/wiki/Nogizaka46>

=back

=head1 AUTHOR

=over 4

=item * Takaaki TSUJIMOTO E<lt>2gmon.t@gmail.comE<gt>

=back

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2015, Takaaki TSUJIMOTO E<lt>2gmon.t@gmail.comE<gt>

Original Copyright (c) 2005 - 2013, Kentaro Kuribayashi
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
