use warnings;
use strict;

BEGIN {
	eval {
		require Lexical::Sub;
		Lexical::Sub->VERSION(0.004);
	};
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "good Lexical::Sub unavailable");
	}
}

use File::Spec ();
use IO::File ();
use Test::More tests => 5;
use t::LoadXS ();
use t::WriteHeader ();

{
	my $infn = File::Spec->catfile("t", "listquote.xs");
	my $outfn = File::Spec->catfile("t", "leximport.xs");
	END { unlink $outfn if defined $outfn; }
	my $in = IO::File->new($infn, "r") or die "$infn: $!";
	my $out = IO::File->new($outfn, "w") or die "$outfn: $!";
	local $/ = undef;
	my $xs = do { local $/ = undef; $in->getline };
	$xs =~ s/(?<=t::)listquote|listquote(?=_call)/leximport/g;
	$out->printflush($xs) or die "$outfn: $!";
	$out->close or die "$outfn: $!";
}

t::WriteHeader::write_header("callparser0", "t", "leximport");
ok 1;
require_ok "Devel::CallParser";
t::LoadXS::load_xs("leximport", "t",
	[Devel::CallParser::callparser_linkable()]);
ok 1;

use Lexical::Sub foo => sub { [ "aaa", @_, "zzz" ] };
t::leximport::cv_set_call_parser_listquote(\&foo, "xyz");

my $ret;
eval q{$ret = foo:ab cd:;};
is $@, "";
is_deeply $ret, [ "aaa", "xyz", "a", "b", " ", "c", "d", "zzz"  ];

1;
