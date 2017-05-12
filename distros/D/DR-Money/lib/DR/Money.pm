package DR::Money;

use 5.008008;
use strict;
use warnings;

use base 'Exporter';
use Carp;
our %EXPORT_TAGS = ( 'all' => [ qw(Money) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(Money);

our $VERSION = '0.02';

use overload
    '""'        => \&value,
    '0+'        => \&value,
    'bool'      => sub { $_[0][1] || $_[0][2] },
    'cmp'       => \&_cmp,
    '<=>'       => \&_dcmp,
    '='         => sub { $_[0]->new($_[1]) },
    'int'       => \&_int,
    '+'         => \&_add,
    '*'         => \&_mul,
    '-'         => \&_sub,
    '/'         => \&_div,

    '++'        => \&_inc,
    '--'        => \&_dec,
    '+='        => \&_addself,
    '-='        => \&_subself,
    '*='        => \&_mulself,
    '/='        => \&_divself,
;


=head1 NAME

DR::Money - module to manipulate by money in perl scripts

=head1 SYNOPSIS

    my $m = Money(2.3);
    print $m;           # prints 2.30
    $m += 2.3;          # 4.60
    $m += Money(4.2);   # 8.80

The module supports negative moneys.

=head1 Functions

=head2 Money

Functional constructor.

    my $money = Money(0.1);
    printf '%s', $money;        # prints 0.10

=cut

sub Money($) { __PACKAGE__->new($_[0]) }


=head1 Methods

=head2 new

Class or instance's method. Construct new instance.

=cut

sub new {
    my ($class, $value) = @_;

    my $self;

    if (ref $class) {
        $self = bless [ '+', 0, 0, '0.00' ] => ref $class;
        $self->_assign( $class );
    } else {
        $self = bless [ '+', 0, 0, '0.00' ] => $class;
    }

    $self->_assign($value) if @_ > 1;
    return $self;
}


=head2 value

Returns value (string).

    my $money = Money(0.1);
    $v = $money->value;         # 0.10
    $v = "$money";              # the same

=cut

sub value { $_[0][3] }



=head1 Private (overload methods)

=head2 _assign($value)

Private method. Assigns new value to instance. Returns instance.

    my $money = Money(0.1);

    $money->_assign( 0.2 );
    $money = 0.2;               # the same

=cut

sub _assign {
    my ($self, $value) = @_;
    croak 'usage $money->_assign($value)' unless @_ > 1;

    if (!$value) {
        @$self = ('+', 0, 0, '0.00');
        return $self;
    }

    if (ref $value and $value->isa(__PACKAGE__)) {
        @$self = @{ $value }[0, 1, 2, 3];
        return $self;
    }

    $value =~ s/\s+//g;

    my ($sign, $r, $k, $s);

    if ($value =~ /^(-)?0*(\d+)[,\.]?$/) {
        $sign = $1 || '+';
        $r = int $2;
        $k = 0;
        $s = sprintf '%s%d.00', ($sign eq '-' ? '-' : ''), $r;
    } elsif ($value =~ /^(-)?0*(\d*)[,\.](\d+)$/) {
        $sign = $1 || '+';
        $r = int($2 || 0);
        $k = substr($3 . '0', 0, 2);
        $k =~ s/^0//;
        $k = int $k;
        $sign = '+' unless $r or $k;
        $s = sprintf '%s%d.%02d', ($sign eq '-' ? '-' : ''), $r, $k;
    } else {
        croak "wrong money value: $value";
    }

    @$self = ($sign, $r, $k, $s);

    return $self;
}

=head2 _cmp

Private method. Compares two instances as string.

    my $money1 = Money(0.1);
    my $money2 = Money(0.01);

    $money1->_cmp($money2);

    $money1 cmp $money2; # the same

=cut

sub _cmp {
    my ($self, $cv, $flip) = @_;
    return $self->[3] cmp Money($cv)->[3] unless $flip;
    return Money($cv)->[3] cmp $self->[3];
}


=head2 _dcmp

Private method. Compares two instances as digit.

    my $money1 = Money(0.1);
    my $money2 = Money(0.01);

    $money1->_dcmp($money2);

    $money1 <=> $money2; # the same

=cut

sub _dcmp {
    my ($self, $cv, $flip) = @_;
    return Money($self)->_kop <=> Money($cv)->_kop unless $flip;
    return Money($cv)->_kop   <=> Money($self)->_kop;
}


sub _kop {
    my ($self) = @_;
    my ($sign, $r, $k) = @$self;
    return -($r * 100 + $k) if $sign eq '-';
    return $r * 100 + $k;
}

sub _from_kop {
    my ($class, $kop) = @_;
    my ($sign, $r, $k, $s);

    $k = abs($kop) % 100;
    $r = (abs($kop) - $k) / 100;

    if ($kop < 0) {
        $sign = '-';
        $s = sprintf '-%d.%02d', $r, $k;
    } else {
        $sign = '+';
        $s = sprintf '%d.%02d', $r, $k;
    }

    return bless [ $sign, $r, $k, $s ] => ref($class) || $class;
}

=head2 _add

Private method. Add two instances (or instance and number).

    my $money1 = Money(1.23);
    my $money2 = Money(2.34);
    my $money3 = $money1->_add($money2);

    $money3 = $money1 + $money2; # the same

=cut

sub _add {
    my ($self, $value) = @_;
    return $self->_from_kop($self->_kop + Money($value)->_kop);

}


=head2 _mul

Private method. Multiplicate money to number

    my $money = Money(1.23);
    
    $money = $money->_mul(234);

    $money = $money * 234; # the same

=cut

sub _mul {
    my ($self, $mul) = @_;
    croak "Can't multiply money to money"
        if ref $mul and $mul->isa(__PACKAGE__);
    return $self->_from_kop(int($self->_kop * $mul));
}


=head2 _sub

Private method. Substract money.

    my $money = Money(1.23);

    $money = $money->_sub(1.22);

    $money  = $money - 1.22; # the same

=cut

sub _sub {
    my ($self, $sv, $flip) = @_;
    my $v = Money($sv);

    return $self->_from_kop( $self->_kop - $v->_kop ) unless $flip;
    return $self->_from_kop( $v->_kop - $self->_kop );
}


=head2 _div

Private method. Divide money.

    my $money = Money(1.22);

    $money = $money / 2;
    $number = $money / Money(2.54);
    $number = 1.23 / $money;

=cut

sub _div {
    my ($self, $div, $flip) = @_;

    croak "Division by zero"
        if (($div == 0 and !$flip) or ($flip and !$self));

    if (ref $div and $div->isa(__PACKAGE__)) {

        return $self->_kop / $div->_kop unless $flip;
        return $div->_kop / $self->_kop;
    }

    return $self->_from_kop( int($self->_kop / $div) ) unless $flip;
    return 100 * $div / $self->_kop;
}
   

=head2 _inc

Private method. Increment money.

    my $money = Money(1.22);
    $money->_inc;       # 1.23

    $money++;           # the same

=cut

sub _inc {
    my ($self) = @_;
    @$self = @{ $self->_from_kop($self->_kop + 1) };
    return $self;
}


=head2 _dec

Private method. Decrement money.

    my $money = Money(2.54);
    $money->_dec;       # 2.53

    $money--;           # the same

=cut

sub _dec {
    my ($self) = @_;
    @$self = @{ $self->_from_kop($self->_kop - 1) };
    return $self;
}



=head2 _addself

Private method. Add value to money.

    $money->_addself(23);

    $money += 23;   # the same

=cut

sub _addself {
    my ($self, $av) = @_;
    @$self = @{ $self->_add($av) };
    return $self;
}


=head2 _mulself

Private method. Mull value to money.

    $money->_mulself(23);
    $money *= 23;       # the same

=cut

sub _mulself {
    my ($self, $av) = @_;
    @$self = @{ $self->_mul($av) };
    return $self;
}


=head2 _subself

Private method. Substract value from money.

    $money->_subself(12.34);
    $money -= 12.34; # the same

=cut

sub _subself {
    my ($self, $av) = @_;
    @$self = @{ $self->_sub($av) };
    return $self;
}

=head2 _divself

Private method. Divide value by number.

    $money->_subself(12.34);
    $money -= 12.34; # the same

=cut

sub _divself {
    my ($self, $av) = @_;
    croak "Can't divide money to money in-place"
        if ref $av and $av->isa(__PACKAGE__);
    @$self = @{ $self->_div($av) };
    return $self;
}


=head2 _int

Private method.
    my $money = Money(100.11);
    my $r = $money->_int;   # 100
    my $r = int Money;      # the same

=cut

sub _int {
    my ($self) = @_;
    return $self->[1] if $self->[0] eq '+';
    return -$self->[1];
}


=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available

=cut

1;
