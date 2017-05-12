#!/usr/bin/perl


package Data::Thunk::Code;
BEGIN {
  $Data::Thunk::Code::AUTHORITY = 'cpan:NUFFIN';
}
BEGIN {
  $Data::Thunk::Code::VERSION = '0.07';
}

use strict;
use warnings;

use Try::Tiny;
use Data::Swap;
use Scalar::Util qw(reftype blessed);
use Check::ISA;
use Devel::Refcount qw(refcount);
use Carp;

use namespace::clean;

use UNIVERSAL::ref;

BEGIN {
	our $vivify_code = sub {
		bless $_[0], "Data::Thunk::NoOverload";

		my $scalar = reftype($_[0]) eq "REF";
		my $code = $scalar ? ${ $_[0] } : $_[0]->{code};
		my $tmp = $_[0]->$code();

		if ( CORE::ref($tmp) and refcount($tmp) == 1 ) {
			my $ref = \$_[0]; # try doesn't get $_[0]

			try {
				swap $$ref, $tmp;
			} catch {
				# try to figure out where the thunk was defined
				my $lazy_ctx = try {
					require B;
					my $cv = B::svref_2object($_[0]->{code});
					my $file = $cv->FILE;
					my $line = $cv->START->line;
					"in thunk defined at $file line $line";
				} || "at <<unknown>>";

				my $file = __FILE__;
				s/ at \Q$file\E line \d+.\n$/ $lazy_ctx, vivified/; # becomes "vivified at foo line blah"..

				croak($_);
			};

			return $_[0];
		} else {
			unless ( $scalar ) {
				Data::Swap::swap $_[0], do { my $o; \$o };
			}

			# set up the Scalar Value overload thingy
			${ $_[0] } = $tmp;
			bless $_[0], "Data::Thunk::ScalarValue";

			return $tmp;
		}
	};
}

our $vivify_code;

use overload ( fallback => 1, map { $_ => $vivify_code } qw( bool "" 0+ ${} @{} %{} &{} *{} ) );

our $call_method = sub {
	my $method = shift;

	if ( inv($_[0]) ) {
		if ( my $code = $_[0]->can($method) ) {
			goto &$code;
		} else {
			return $_[0]->$method(@_[1 .. $#_]);
		}
	} elsif ( defined $_[0] ) {
		croak qq{Can't call method "$method" without a package or object reference};
	} else {
		croak qq{Can't call method "$method" on an undefined value};
	}
};

our $vivify_and_call = sub {
	$_[1]->$vivify_code();
	goto $call_method;
};

sub ref {
	CORE::ref($_[0]->$vivify_code);
}

foreach my $sym (keys %UNIVERSAL::) {
	no strict 'refs';

	next if $sym eq 'ref::';
	next if defined &$sym;

	local $@;

	eval "sub $sym {
		if ( Scalar::Util::blessed(\$_[0]) ) {
			unshift \@_, '$sym';
			goto \$vivify_and_call;
		} else {
			shift->SUPER::$sym(\@_);
		}
	}; 1" || warn $@;
}

sub AUTOLOAD {
	my ( $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );
	unshift @_, $method;
	goto $vivify_and_call;
}

sub DESTROY {
	# don't create the value just to destroy it
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Data::Thunk::Code

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Yuval Kogman.

This is free software, licensed under:

  The MIT (X11) License

=cut

