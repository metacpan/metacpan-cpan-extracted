#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

# Tests for the Perl module Config::Perl
# 
# Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Config_Perl_Testlib;

# Note: Run coverage tests via
# $ perl Makefile.PL
# $ make
# $ make test
# $ CONFIG_PERL_AUTHOR_TESTS=1 /opt/perl5.20/bin/cover -test -coverage default,-pod
# $ make distclean
# $ rm -rv cover_db

# These tests are only supposed to increase code coverage.

BEGIN {
	warn "# AUTHOR: Remember to look at code coverage once in a while (Devel::Cover)\n"
		if $AUTHOR_TESTS && !$DEVEL_COVER;
	warn "# Don't forget to enable author tests for Devel::Cover (set \$ENV{CONFIG_PERL_AUTHOR_TESTS})!\n"
		if $DEVEL_COVER && !$AUTHOR_TESTS;
}

use Test::More $AUTHOR_TESTS && $DEVEL_COVER ? (tests=>9)
	: (skip_all=>'only used in author coverage testing');

use Config::Perl;

my $cp = Config::Perl->new;

{
	my $smth = bless {}, 'Something';
	## no critic (RequireCheckingReturnValueOfEval)
	ok !defined eval { $cp->_handle_block    ($smth); 1 }, 'forced error 1';
	ok !defined eval { $cp->_handle_symbol   ($smth); 1 }, 'forced error 2';
	ok !defined eval { $cp->_handle_value    (undef); 1 }, 'forced error 3';
	ok !defined eval { $cp->_handle_list     (undef); 1 }, 'forced error 4';
	ok !defined eval { $cp->_handle_list     ($smth); 1 }, 'forced error 5';
	ok !defined eval { $cp->_handle_assign   ($smth); 1 }, 'forced error 6';
	ok !defined eval { $cp->_handle_struct   ($smth); 1 }, 'forced error 7';
	ok !defined eval { $cp->_handle_subscript($smth); 1 }, 'forced error 8';
	ok !defined eval { $cp->_handle_quote    ($smth); 1 }, 'forced error 9';
}

