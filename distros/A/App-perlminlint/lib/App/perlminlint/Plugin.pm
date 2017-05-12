package App::perlminlint::Plugin; sub MY () {__PACKAGE__}
# -*- coding: utf-8 -*-
use 5.009;
use strict;
use warnings FATAL => 'all';
use Carp;

use App::perlminlint::Object [as_base => qw/^app/];

sub NIMPL {
  my ($pkg, $file, $line, $subname) = caller($_[0] // 1);
  $subname =~ s/^.*?::(\w+)$/$1/;
  croak "Plugin method $subname is not implemented in $pkg";
}

sub priority { 10 }
sub declare_priority {
  my ($myPack, $callpack, $value) = @_;

  $myPack->_declare_constant_in($callpack, priority => $value);
}

sub is_generic { 0 }
sub declare_is_generic {
  my ($myPack, $callpack, $value) = @_;

  $myPack->_declare_constant_in($callpack, is_generic => $value);
}

sub extensions { () }

sub handle_test { NIMPL() }

sub handle_match { NIMPL() }

1;
