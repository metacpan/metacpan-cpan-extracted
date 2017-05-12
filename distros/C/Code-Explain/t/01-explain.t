use strict;
use warnings;
use Test::More;
use Test::Deep;

my %cases = read_cases('t/cases.txt', 20);
my %todo  = read_cases('t/todo.txt',  50);

plan tests => scalar(keys %cases) + scalar(keys %todo) + 2 + 2 +1;

use t::lib::Explain;

require Code::Explain;

foreach my $str (sort keys %cases) {
	my $ce = Code::Explain->new( code => $str );
	is $ce->explain, $cases{$str}, "<$str>";
}

foreach my $str (sort keys %todo) {
	TODO: {
		local $TODO = "$str is not yet handled";
		my $ce = Code::Explain->new( code => $str );
		is $ce->explain, $todo{$str}, $str;
	}
}

{
	my $code = '$_';
	my $ce = Code::Explain->new( code => $code );
	my @dump = $ce->ppi_dump;
	#diag explain @dump;
	my @expected = (
		q(PPI::Document),
		q(  PPI::Statement),
		qq(    PPI::Token::Magic  \t'\$_'),   # why is that tab there?
	);
	is_deeply \@dump, \@expected, 'dump $_';

	my @expected_explain = (
		{
			code => $code,
			text => 'Default variable',
		},
	);
	my @explain = $ce->ppi_explain;
	is_deeply \@explain, \@expected_explain, 'explain $_';
	#diag explain @explain;
	#diag $dump[2] =~ s/\t/TAB/g;
}

{
	my $code = $t::lib::Explain::cases[0]{code};
	my $ce = Code::Explain->new( code => $code );
	my @dump = $ce->ppi_dump;
	#diag explain @dump;
        cmp_deeply \@dump, $t::lib::Explain::cases[0]{expected_ppidump}, "--ppidump $code";

	my @explain = map { "$_->{code}   $_->{text}" } $ce->ppi_explain;
        cmp_deeply \@explain, $t::lib::Explain::cases[0]{expected_ppiexplain}, "--ppiexplain $code";
	#diag explain @explain;
	#diag $dump[2] =~ s/\t/TAB/g;
}


{
	eval { 	my $ce = Code::Explain->new() };
	like $@, qr/Method ->new needs a "code" => \$some_code pair/, 'Code::Explain->new requires code';
}

sub read_cases {
	my ($file, $width) = @_;
	my %c;
	open my $fh, '<', $file or die "Could not open '$file' $!";
	while (my $line = <$fh>) {
		chomp $line;
		my ($code, $text) = unpack("A$width A*", $line);
		$code =~ s/\s+$//;
		$text  =~ s/^\s+|\s+$//g;
		$c{$code} = $text;
	}
	return %c;
}
