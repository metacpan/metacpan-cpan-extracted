package Acme::Numbers;
use strict;
use Lingua::EN::Words2Nums qw(words2nums);
our $AUTOLOAD;
our $VERSION = '1.2';


=head1 NAME

Acme::Numbers - a fluent numeric interface

=head1 SYNOPSIS

    use Acme::Numbers;

    print one."\n";                       # prints 1
    print two.hundred."\n";               # prints 200
    print forty.two."\n";                 # prints 42
    print six.hundred.and.sixty.six."\n"; # prints 666
    print one.million."\n";               # prints 1000000

    print three.point.one.four."\n";      # prints 3.14
    print one.point.zero.two."\n";        # prints 1.02
    print zero.point.zero.five."\n";      # prints 0.05

    print four.pounds."\n";               # prints "4.00"
    print four.pounds.five."\n";          # prints "4.05"
    print four.pounds.fifty."\n";         # prints "4.50"
    print four.pounds.fifty.five."\n";    # prints "4.55"

    print fifty.pence."\n";               # prints "0.50"
    print fifty.five.pence."\n";          # prints "0.55"
    print four.pounds.fifty.pence."\n";   # prints "4.50"
    print four.pounds.and.fifty.p."\n";   # prints "4.50"

    print fifty.cents."\n";               # prints "0.50"
    print fifty.five.cents."\n";          # prints "0.55"
    print four.dollars.fifty.cents."\n";  # prints "4.55"

    

=head1 DESCRIPTION

Inspired by this post

http://beautifulcode.oreillynet.com/2007/12/the_cardinality_of_a_fluent_in.php

and a burning curiosity. At leats, I hope the burning 
was curiosity.

=head1 ONE BIIIIIIIIIIIILLION

By default billion is 10**12 because, dammit, that's right.

If you want it to be an American billion then do

    use Acme::Numbers billion => 10**9;

Setting this automatically changes all the larger numbers 
(trillion, quadrillion, etc) to match.

=head1 METHODS

You should never really use these methods on the class directly.

All numbers handled by C<Lingua::EN::Words2Nums> are handled by this module.

In addition ...

=cut

sub import {
    my $class = shift;
    my %opts  = @_;

    $opts{billion} = 10**12 unless defined $opts{billion};
    no strict 'refs';
    no warnings 'redefine';
    my ($pkg, $file) = caller; 
    $Lingua::EN::Words2Nums::billion = $opts{billion};
    foreach my $num ((keys %Lingua::EN::Words2Nums::nametosub, 
                      'and', 'point', 'zero', 
                      'pound', 'pounds', 'pence', 'p',
                      'dollars', 'cents')) 
    {
        *{"$pkg\::$num"} = sub { $class->$num };
    }
};



=head2 new <value> <operator>

C<operator> can be 'num', 'and' or 'point'

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $val   = shift;
    my $op    = shift;
    my $name  = shift || $op;
    bless { value => $val, operator => $op, name => $name }, $class;
}

=head2 name 

The name of this object (i.e the method that was originally called).

=cut

sub name {
	return $_[0]->{name};
}

=head2 value

The current numeric value

=cut

sub value { 
    my $self = shift;
    my $val = $self->{value};
    # if we're 'pence' then divide by 100 and then pretend we're pounds
    if ($self->{operator} =~ m!^p(ence)?$!) {
        # this fixes something where there's 0 
        # pounds and a trailing zero like 0.50
        $self->{last_added} = $val; 
        $val = $val/100;
        $self->{operator} = 'pounds';
    }
    if ($self->{operator} =~ m!^pounds?$!) {
        my ($num, $frac) = split /\./, $val;
        $frac ||= 0;
        # this also fixes 0 pounds trailing zero
        $frac = $self->{last_added} if defined $self->{last_added} && $self->{last_added}>$frac;
        # we substr to fix one.pound.fifty.pence which 
        # leaves $frac as '500' 
        $val  = sprintf("%d.%02d",$num,substr($frac,0,2));
    } 

    return $val;
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method    =~ s/.*://;   # strip fully-qualified portion
    my $val;
    # nasty override - we should probably have a 
    # generic major or minor currency indicator
    # if we could store and propogate the currency
    # then we could also throw errors at mismatched 
    # units e.g five.pounds.and.fifty.cents
    # but maybe also print out the correct sigil
    # e.g $5.50
    $method = 'pounds' if $method eq 'dollars';
    $method = 'pence'  if $method eq 'cents';

    # dummy methods
    if ($method eq 'and' || $method =~ m!^p!) {
        $val = $self->new(0, $method) 
    } else {
        # bit of a hack here
        my $tmp = ($method eq 'zero')? 0 : words2nums($method);
        # maybe this should die 
        return unless defined $tmp;
        $val = $self->new($tmp, 'num', $method);
    }

    # If we're the first number in the chain 
    # then just return ourselves
    if (!ref $self) {
        return $val;
    } else {
        # Otherwise do the magic 
        return $self->handle($val);
    }
}

=head2 handle <Acme::Numbers>

Handle putting these two objects together

=cut

sub handle {
    my ($self, $val) = @_;
    # If we haven't passed a pounds, pence or point marker
    if ($self->{operator} !~ m!^p!) {
        # If the new object is marker ...
        if ($val->{operator} =~ m!^p!) {
            # ... Just propogate along but make a note
            # A pound should not be overidden by a pence
            $self->{operator} = $val->{operator} unless $self->{operator} =~ m!^pounds?$!;
            return $self;

        # Otherwise ...
        } else {
            my $val = $val->{value};
            # If we're not currently adding and the new more than the old
            # e.g two.hundred then multiply
            if ($self->{value} < $val && $self->{operator} ne 'add') {
                $val *= $self->{value};
            # Otherwise add
            } else {
                $val += $self->{value};
            }
            return $self->new($val, 'num', $self->{operator});
        }
    } else { # point, pound, pence
        # first get the fractional part
        my ($num, $frac) = split /\./, $self->{value};
        #$frac ||= 0;
        # Cope with four.point.zero.four
        if ((defined $frac && $frac>0 && $frac<10) || $val->{value} == 0 || (defined $self->{last_added} and $self->{last_added} eq '0')) {
            $frac .= $val->{value};
        } else {
            $frac += $val->{value};
        }
        # Create the new object
        my $new = $self->new("${num}.${frac}", $self->{operator});
        # We use this to be able to do point.fifty.five and point.five.five
        $new->{last_added} = $val->{value};
        return $new;
    } 
}

=head2 concat <value>

Concatenate two things.

=cut

sub concat {
    my ($self, $new) = @_;
    my $class = shift;
    # If both objects are special numbers handle them
    if (ref($new) && $new->isa(__PACKAGE__)) {
        return $self->handle($new);
    # Otherwise stringify both and concat
    } else {
        return $self->value.$new;
    } 
}

sub _bool {
    my ($self, $new, $op) = @_;
}

use overload '""'       => 'value',
             '+0'       => 'value',
             '.'        => 'concat';
#             'bool'     => 'bool';


sub DESTROY {}

1;
