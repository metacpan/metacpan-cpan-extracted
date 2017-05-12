# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::Seq::Point;

use 5.008008;
use strict;
use warnings;

use Cv::Seq;

our $VERSION = '0.29';
our @ISA = qw(Cv::Seq);

{ no strict 'refs'; *AUTOLOAD = \&Cv::autoload; }

sub new {
	my $self = shift;
	$self->SUPER::new(@_);
}

sub CreateSeq {
	my $self = shift;
	$self->SUPER::CreateSeq(@_);
}

{ *Get = \&GetSeqElem }
sub GetSeqElem {
	my $self = CORE::shift;
	my $index = CORE::shift;
	my $pt = $self->Unpack($self->SUPER::GetSeqElem($index));
	return undef unless defined $pt;
	wantarray? @$pt : $pt;
}


{ *Set = *set = \&SetSeqElem }
sub SetSeqElem {
	my $self = CORE::shift;
	my $index = CORE::shift;
	$self->SUPER::SetSeqElem($index, $self->Pack(@_));
}


sub Push {
	my $self = CORE::shift;
	$self->SUPER::Push($self->Pack(@$_)) for @_;
	$self;
}


sub Pop {
	my $self = CORE::shift;
	my $pt = $self->Unpack($self->SUPER::Pop);
	return undef unless defined $pt;
	wantarray? @$pt : $pt;
}


sub Shift {
	my $self = CORE::shift;
	my $pt = $self->Unpack($self->SUPER::Shift);
	return undef unless defined $pt;
	wantarray? @$pt : $pt;
}


sub Unshift {
	my $self = CORE::shift;
	$self->SUPER::Unshift($self->Pack(@$_)) for @_;
	$self;
}


sub MakeSeqHeaderForArray {
	ref (my $class = CORE::shift) and Carp::croak 'class name needed';
	$class->SUPER::MakeSeqHeaderForArray(@_);
}


sub Pack {
	my $self = CORE::shift;
	my $t = $self->template;
	CORE::pack($t, map { ref $_ ? @$_ : $_ } @_);
}


sub Unpack {
	my $self = CORE::shift;
	my $t = $self->template;
	return undef unless defined $_[0];
	# no warnings 'uninitialized';
	my @pt = CORE::unpack($t, $_[0]);
	wantarray? @pt : \@pt;
}


sub UnpackMulti {
	my $self = CORE::shift;
	my ($t, $c) = $self->template;
	return undef unless defined $_[1];
	# no warnings 'uninitialized';
	my @data = CORE::unpack("($t)*", $_[1]);
	while (my @elem = CORE::splice(@data, 0, $c)) {
		CORE::push(@{$_[0]}, \@elem);
	}
}

1;
