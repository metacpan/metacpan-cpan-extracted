package CogBase::Base;
use strict;

use Class::Field qw'field const';
use XXX;

sub import {
    my ($class, $flag) = @_;
    return unless $flag && $flag eq '-base';
    my $package = caller;
    no strict 'refs';
    *{$package . "::$_"} = \&$_
      for qw'field const', qw'WWW XXX YYY ZZZ';
    push @{$package . "::ISA"}, $class;
    return;
}

sub New {
    my $self = bless {}, shift;
    while (@_) {
        my ($key, $value) = splice(@_, 0, 2);
        $self->$key($value);
    }
    $self->_initialize;
    return $self;
}

sub _initialize {}

1;
