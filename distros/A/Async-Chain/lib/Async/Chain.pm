package Async::Chain;

use 5.006;
use warnings FATAL => 'all';
use overload ('&{}' => \&_to_code, fallback => 1);
use Carp;

=head1 NAME

Async::Chain - The right way to convert nested callback in plain struct
or just the syntax sugar for guy who do not like deep indent.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

Every subroutine in the chain receive callable object as first argument followed
by arguments of object call. You can break chain in every sub, just do not call
C<$next>.

You can skip some subroutins using C<skip> or C<jump> method.

    use Async::Chain;

    # with chain call

    chain
        sub {
            my next = shift;
            AnyEvent::HTTP::http_get('http://perldoc.perl.org/', $next);
        },
        sub {
            my next = shift;
            return $next->jump('log')->(0, "not a 200 response");
            ...
            $db->async_insert(..., cb => $next);
        },
        sub {
            my next = shift;
            ...
            $next->($status, $message);
        },
        log => sub {
            my next = shift;
            my ($status, $message) = @_;
            ...
            log(...);
        };

=head1 RATIONALE

A asynchronous code often have deep nested callbacks, therefore it is tangled
and hard to change. This module help to converta a code like following to some
more readable form. Also, with C<chain> you can easily skip some unneeded steps
in this thread. For example jump to log step after the first failed query in
the chain.

without chain:

    sub f {
        ...
        some_anync_call @args, cb => sub {
            ...
            some_other_anync_call @args, cb => sub {
            ...
                ...
                    ...
                        yet_another_anync_call @args, cb => sub {
                            ...
                        }
            }
        }
    }

using chain:

    chain
        sub {
            my next = shift;
            ...
            some_anync_call @args, cb => sub { $next->(@arg) }
        },
        sub {
            my next = shift;
            ...
            some_other_anync_call @args, cb => sub { $next->(@arg) }
        },
        sub {
            my next = shift;
            ...
        },
        ...
        sub {
            ...
            yet_another_anync_call @args, cb => sub { $next->(@arg) }
        },
        sub {
            ...
        };

If you don't need to skip or hitch links, you can use 'kseq' function from CPS
module, that slightly faster.

=head1 SUBROUTINES/METHODS

=cut

# Internal method called by use function
sub import {
	$caller = (caller())[0];
	*{$caller . "::chain"} = \&chain;
}

# Internal method used for reduction to code.
sub _to_code {
	my $self = shift;
	return sub {
		my $cb = shift @{$self} or
			return sub { };
		$cb->[1]->($self, @_);
		();
	}
}

=head2 new

The Asyn::Chain object constructor. Arguments are list of subroutine optionaly
leaded by mark.

=cut

sub new {
	my $class = shift; $class = ref $class ? ref $class : $class;
	my $self = [ ];
	# FIXME: check args type
	while (scalar @_) {
		if (ref $_[0]) {
			push @$self, [ '', shift ];
		} else {
			push @$self, [ shift, shift ];
		}
	}
	bless $self, $class;
}

=head2 chain

Only one exported subroutine. Create and call Anync::Chain object. Return empty
list.

=cut

sub chain(@) {
	my $self = __PACKAGE__->new(@_);
	$self->();
	();
}

=head2 skip

Skip one or more subroutine. Skipe one if no argument given. Return
Anync::Chain object.

=cut

sub skip {
	my ($self, $skip) = @_;
	$skip = ($skip and $skip > 0) ? $skip : 1;
	while($skip) {
		shift @{$self}; --$skip;
	}
	$self;
}

=head2 jump

Skip subroutines for first entry of named mark. Return Anync::Chain object.

=cut

sub jump {
	my ($self, $mark) = @_;
	while(scalar @{$self} and ${self}->[0]->[0] ne $mark) {
		shift @{$self};
	}
	$self;
};

=head2 hitch

Move named link to beginning of the chain. When link with given name not exists
or first in chain, method has no effect. Return Anync::Chain object.

=cut

sub hitch {
	my ($self, $mark) = @_;
	my ($index, $link) = (0, undef);

	unless ($mark) {
		croak "hitch called with empty mark";
		return $self;
	}

	for (@$self) {
		if ($_->[0] eq $mark) {
			$link = splice (@$self, $index, 1) if ($index);
			last;
		}
		$index++;
	}

	unshift (@$self, $link) if ($link);
	$self;
}

=head1 AUTHOR

Anton Reznikov, C<< <anton.n.reznikov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests, or through GitHub web interface at
L<https://github.com/17e/Async-Chain>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Async::Chain

=head1 ACKNOWLEDGEMENTS

    Mons Anderson    - The original idia of chain and it first implementation.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Anton Reznikov.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA


=cut

1; # End of Async::Chain
