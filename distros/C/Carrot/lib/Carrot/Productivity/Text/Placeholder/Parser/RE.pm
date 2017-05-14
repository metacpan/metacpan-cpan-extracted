package Carrot::Productivity::Text::Placeholder::Parser::RE
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

my $default_re = qr{^(.*?)\[=(.+?)=\]}s;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this, $re) = @ARGUMENTS;
	$re //= $default_re;

	$this->[ATR_RE] = $re;

	return;
}

sub split_text
# /type method
# /effect ""
# //parameters
#	format
# //returns
#	?
{
	my ($this, $format) = @ARGUMENTS;

	my $re = $this->[ATR_RE];
	my $text = [];
	while ($format =~ s{$re}{})
	{
		push($text, [$1, $2]);
	}
	push($text, [$format, '']);

	return($text);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}

__END__

	my $expressiveness = Carrot::individuality;
$expressiveness->provide(
	my $code_evaluation = '::Individuality::Singular::Execution::Code_Evaluation');

sub build_parser($)
# /type function
# /effect ""
# //parameters
#	placeholder_re
# //returns
#	?
{
	my $placeholder_re = $_[SPX_PLACEHOLDER_RE];
	$placeholder_re =~ s/\}/\\}/sg;
	$placeholder_re =~ s/\{/\\{/sg;

	my $parser = "sub {
		return unless (\$_[0] =~ s{$placeholder_re}{}s);
		return(\$1, \$2);
	};";
	$code_evaluation->provide_fatally($parser);
	return($parser);
}
# //revision_control
#	version 1.1.52
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"