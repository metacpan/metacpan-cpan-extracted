package Attribute::Args;

our $VERSION = '0.06';

use warnings;
use strict;
use Attribute::Handlers;

=head1 NAME

Attribute::Args - check subroutine param types

=head1 SYNOPSIS

        use Attribute::Args;

	sub foo :ARGS('scalar', 'HASH') {
		my ($scalar, $hashref) = @_;
		# code
	}

	foo(42, { 'key' => 'value' }); # good
	foo(['array', 'elements']); # bad

=head1 OVERVIEW

:ARGS() attribute wraps method and adds runtime type checks for method calls. dies whenever the parameters dont match.

=head1 SUPPORTED TYPES

=head2 any

parameter of any type. useful for defining subs that can accept different types for some parameters.

=head2 scalar

scalar value. can be null. cannot be ref.

=head2 null

does not accept anything except undef.

=head2 list

accepts array. can only be the last param. must have at least one element. can be null. use the 'optional' modifier to declare an array that can be empty.

=head2 hash

same as list, but is also checked for parity. must have at least one key/value pair. can be null.

=head2 any other type

other values are treated as refs. e.g. 'ARRAY', 'HASH', 'Class::Name', etc. for classes also isa() is checked to figure out if the actual parameters class is inherited from the requested one. cannot be null.

=head1 TYPE MODIFIERS

currently the only modifier is the 'optional' modifier. it is denoted by a question mark after the type.

	sub foo :ARGS('scalar', 'scalar?') { ... }

	foo(42, 29); # good
	foo(42); # good

=head1 MANUAL CHECK

for anonymous subs and other special cases manual type check can be used:

	sub foo {
		my ($x, %y) = Attribute::Args::check(['scalar', 'hash?'], \@_);
		# ...
	}

=head1 CAVEATS

in some modules Attribute::Handlers, that is used in Attribute::Args, goes crazy and thinks that all subs are anonymous. you will have to use manual check for them.

Attribute::Args distinguishes between null values and non-existing ones. you cannon pass null for optional param if it does not accept one.

list or hash can only be the last param. whenever is is found it takes all remaining args as it's elements and anything after the list will die as if it wasnt specified.

=cut

sub import {
	my $caller = caller;
	no strict 'refs';
	push @{"${caller}::ISA"}, __PACKAGE__;
}

sub ARGS :ATTR {
	my ($package, $symbol, $ref, $attr, $data, $phase) = @_;
	$data = [ $data || () ] unless 'ARRAY' eq ref $data;
	no warnings;
	if ('ANON' eq $symbol) {
		die sprintf 'trying to wrap anonymous method in %s', $package;
	}
	*$symbol = sub { return Attribute::Args::wrapper($data, $symbol, $ref, @_) };
}

sub wrapper {
	my ($data, $symbol, $original, @p) = @_;
	Attribute::Args::check($data, \@p, *$symbol);
 	return &$original(@p);
}

sub check {
	my ($d, $p, $s) = @_;
	unless ($s) {
		my @caller = caller 1;
		$s = sprintf '*%s::%s', $caller[0], $caller[3];
	}
	die sprintf
		'expected %s(%s), but got %s(%s) instead',
		$s,
		join(', ', @$d),
		$s,
		join(', ', map { defined($_) ? ref || 'scalar' : 'null' } @$p)
		unless Attribute::Args::check_types($p, $d);
	return @$p;
}

sub check_types {
	my ($xargs, $xtypes) = @_;
	my @args = @$xargs;
	my @types = @$xtypes;
	foreach my $type (@types) {
		my $optional = $type =~ s/\?$//;
		if (!@args) {
			if ($optional) {
				next;
			} else {
				return 0;
			}
		}
		my $arg = shift @args;
		if ($type eq 'any') {
		} elsif ($type eq 'scalar') {
			return 0 if ref $arg;
		} elsif ($type eq 'null') {
			return 0 if defined $arg;
		} elsif ($type eq 'list') {
			shift @args while @args;
		} elsif ($type eq 'hash') {
			return 0 unless scalar(@args) % 2;
			shift @args while @args;
		} elsif ($type eq ref $arg) {
		} elsif (UNIVERSAL::isa($arg, $type)) {
		} else {
			return 0;
		}
	}
	return @args ? 0 : 1;
}

1;

=head1 AUTHOR

Alex Alexandrov, C<< <swined at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-attribute-args at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Attribute-Args>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc Attribute::Args

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Attribute-Args>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Attribute-Args>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Attribute-Args>

=item * Search CPAN

L<http://search.cpan.org/dist/Attribute-Args>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Alex Alexandrov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

