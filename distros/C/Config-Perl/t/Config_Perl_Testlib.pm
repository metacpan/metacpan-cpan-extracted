#!perl
package Config_Perl_Testlib;
use warnings;
use strict;

=head1 Synopsis

Supporting library for Config::Perl tests.

=head1 Author, Copyright, and License

Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command "C<perldoc perlartistic>" or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use base 'Exporter'; # "parent" pragma wasn't core until 5.10.1
our @EXPORT = qw/ $AUTHOR_TESTS $DEVEL_COVER warns test_ppconf /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{CONFIG_PERL_AUTHOR_TESTS};
our $DEVEL_COVER = exists $INC{'Devel/Cover.pm'};
our $CONFIG_PERL_DEBUG = ! ! $ENV{CONFIG_PERL_DEBUG};

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	return;
}

sub warns (&) {  ## no critic (ProhibitSubroutinePrototypes)
	my $sub = shift;
	my @warns;
	{ local $SIG{__WARN__} = sub { push @warns, shift };
		$sub->() }
	return @warns;
}

use Carp;
use Test::More import=>[qw/ fail is_deeply diag explain /];

my $packname_counter = 1;
sub test_ppconf {
	my $str = shift;
	my $exp_out = shift;
	my $testname = shift||"noname";
	my $opts = shift||{};
	confess "too many args" if @_;
	croak "options must be a hash" unless ref $opts eq 'HASH';
	
	my $pack = 'Config_Perl_Testlib::Testpack'.($packname_counter++);
	my $rv;
	my $code = <<"ENDCODE";
	package $pack;
	no warnings;
	no strict 'vars';
	\$rv = [ do { $str } ];
ENDCODE
	eval "$code; 1"  ## no critic (ProhibitStringyEval)
		or croak "invalid perl \"$str\": $@";
	my $got_syms = _get_syms($pack);
	$$got_syms{_} = $rv if exists $$exp_out{_};
	my $exp_syms = { %{$$opts{add_syms}||{}} };
	for (keys %$exp_out) {
		if (/^\$/) {
			$$exp_syms{$_} = \( $$exp_out{$_} );
		}
		elsif (/^[\@\%](.+)$/) {
			my $vname = $1;
			# an "our @foo" or "our %foo" creates a symbol table entry for $foo as well
			$$exp_syms{"\$$vname"} = \undef unless defined $$exp_syms{"\$$vname"};
			$$exp_syms{$_} = $$exp_out{$_};
		}
		elsif ($_ eq '_') {
			$$exp_syms{$_} = $$exp_out{$_};
		}
		else { croak "unknown expected symbol '$_'" }
	}
	delete $$exp_syms{$_} for @{$$opts{del_syms}||[]};
	
	my $cp = Config::Perl->new(debug=>$CONFIG_PERL_DEBUG);
	my $got_out = $cp->parse_or_undef(\$str);
	if (!defined $got_out) {
		fail "$testname (return value)";
		fail "$testname (symbol table)";
		diag explain "ERROR=",$cp->errstr;
	}
	else {
		is_deeply $got_out, $exp_out, "$testname (return value)"
			or diag explain "GOT_OUT=",$got_out, "EXP_OUT=",$exp_out;
		is_deeply $got_syms, $exp_syms, "$testname (symbol table)"
			or diag explain "GOT_SYMS=",$got_syms, "EXP_SYMS=",$exp_syms;
	}
	return;
}

sub _get_syms {
	my ($pack) = @_;
	my %syms;
	no strict 'refs';  ## no critic (ProhibitNoStrict)
	while ( my ($k,$v) = each %{$pack.'::'} ) {
		if (defined *{$v}{SCALAR}) {
			$syms{"\$$k"} = *{$v}{SCALAR}
				unless $v=~/\bBEGIN$/;
		}
		if (defined *{$v}{ARRAY}) {
			$syms{"\@$k"} = *{$v}{ARRAY};
		}
		if (defined *{$v}{HASH}) {
			$syms{"\%$k"} = *{$v}{HASH};
		}
	}
	return \%syms;
}



1;
