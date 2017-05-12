#!/usr/bin/perl
#
# deparse.t
#
# Use B::Deparse to deparse Rlist.pm, quote the whole text and let read it as
# Rlist.  Write as outlined text, which will use here-docs (heavy ones, in this
# case).
#
# BUGS DISCOVERED IN PERL
#
#	This is perl, v5.8.7 built for cygwin-thread-multi-64int
#	This is perl, v5.8.4 built for sun4-solaris
#
# Deparsing of \&Data::Rlist::lex fails:
#
#	Can't call method "name" on an undefined value at
#	/usr/local/lib/perl5/5.8.4/sun4-solaris/B/Deparse.pm line 948.
#
# $Writestamp: 2008-07-21 17:07:19 andreas$
# $Compile: perl -M'constant standalone => 1' deparse.t$

use warnings;
use strict;
use constant;
use Test;
BEGIN { plan tests => 5 }
BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use Data::Rlist qw/:options/;
use B::Deparse;

our $tempfile = "$0.tmp";

#########################

{
	no strict;
	my $deparser = B::Deparse->new(qw/-p -sC/);
	my %bodies = 
	map {
		my $fun = "Data::Rlist::$_";
		my $funref = eval { \&$fun };
		$fun => $deparser->coderef2text($funref)."\n" # add final newline so
                                                      # that string qualifies
                                                      # as here-doc
	}
	qw/new set get have require comptab compval escape7 unescape7
	   open_input read write
	   compile compile1 compile2
	   compile_fast compile_fast1
	   compile_perl compile_Perl1
	   synthesize_pathname deep_compare/;

	ok(complete_options()->{here_docs}); # ...shall be enabled by default

	$Data::Rlist::MaxDepth = 10;

	# Warning: when 0..1 (i.e. here-docs disabled) perl 5.8.8 exits abnormally.
	# I had this bug earlier when applying regexes to large strings.  It
	# happens in Data::Rlist::lex().

	for my $here_docs (1..1) {
		for my $auto_quote (0..1) {
			my $obj = new Data::Rlist(-data => \%bodies,
									  -input => $tempfile,
									  -output => $tempfile,
									  -options => { auto_quote => $auto_quote, here_docs => $here_docs });
			die unless ok($obj->write);
			die unless ok(not CompareData(\%bodies, $obj->read));
		}
	}

	unlink $tempfile;
}

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
