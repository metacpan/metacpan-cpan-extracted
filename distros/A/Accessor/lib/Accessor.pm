package Accessor;

=head1 NAME

Accessor - base class for accessor-pattern classes

=head1 USAGE

	my $h = new Hash(asd => 111);

	warn $h->asd(); 	# get values
	warn $h->asd('ad'); # set values

	package Hash;

	use base 'Accessor';

	sub new {
		my $class = shift;
		return bless {@_}, $class;
	}

=head1 VERSION

0.3

=head1 AUTHOR

All code writen by Ivan Trunaev.

Contacts <ivan@trunaev.ru>

=cut


use strict;
use warnings;

our $VERSION = '0.3';

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;
	my $val  = shift;
	
	my $name = $AUTOLOAD;
	return if $name =~ /^.*::[A-Z]+$/;
	$name =~ s/^.*:://;   # strip fully-qualified portion
	
	my $sub = sub {
		my $self = shift;
		if (scalar @_) {
			my $val = shift;
			$self->{$name} = $val;			
		}
		return $self->{$name};
	};
	
	return unless $self->{$name};
	
	no strict 'refs';
	*{$AUTOLOAD} = $sub;
	
	return $val ? $sub->($self, $val) : $sub->($self);
}

1;
