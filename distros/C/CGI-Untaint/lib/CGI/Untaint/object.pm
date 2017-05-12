package CGI::Untaint::object;

=head1 NAME

CGI::Untaint::object - base class for Input Handlers

=head1 SYNOPSIS

  package MyUntaint::foo;

  use base 'CGI::Untaint::object';

  sub _untaint_re {
    return qr/$your_regex/;
  }

  sub is_valid {
    my $self = shift;
    return is_ok($self->value);
  }

  1;

=head1 DESCRIPTION

This is the base class that all Untaint objects should inherit
from. 

=cut

use strict;

sub _new {
	my ($class, $h, $raw) = @_;
	bless {
		_obj   => $h,
		_raw   => $raw,
		_clean => undef,
	} => $class;
}

=head1 METHODS TO SUBCLASS

=head2 is_valid / _untaint_re

Your subclass should either provide a regular expression in _untaint_re
(and yes, I should really make this public), or an entire is_valid method.

=cut

sub is_valid { 1 }

=head1 METHODS TO CALL

=head2 value

This should really have been two methods, but too many other modules
now rely on the fact that this does double duty. As an accessor, this
is the 'raw' value. As a mutator it's the extracted one.

=cut

sub value {
	my $self = shift;
	$self->{_clean} = shift if defined $_[0];
	$self->{_raw};
}

sub _untaint {
	my $self = shift;
	my $re   = $self->_untaint_re;
	die unless $self->value =~ $self->_untaint_re;
	$self->value($1);
	return 1;
}

=head2 re_all / re_none

Regular expressions to match anything, or nothing, untained.  These should
only be used if you have already validated your entry in some way that
means you completely trust the data.

=cut

sub re_all  { qr/(.*)/ }
sub re_none { qr/(?!)/ }

=head2 untainted

Are we clean yet?

=cut

sub untainted { shift->{_clean} }

1;
