package Carrot::Productivity::Text::Placeholder::Template::File::HTTP
# /type class
# /project_entry ::Productivity::Text::Placeholder
# //parent_classes
#	::Template::File::Plain
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $placeholder_class = '::Productivity::Text::Placeholder');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->superseded(@ARGUMENTS);
	$this->[ATR_HTTP_HEADER] = [[],[]];

	return;
}

sub get_http_header
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_HTTP_HEADER]);
}

my $txt_any_line_break = TXT_ANY_LINE_BREAK;
sub compile
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->superseded($buffer);
	my $header_text = ($this->[ATR_TEXTS][ADX_FIRST_ELEMENT] =~ s{^.*?\015\012\015\012|\n\n}{}sr);

	my $document = [];
	unless ($$buffer_ref =~ s{^([^\n]+)\n(.*?)\n{2}}{}s)
	{
		$invalid_file_format->raise_exception(
			{'key' => $key,
			 'value' => $buffer_ref},
			ERROR_CATEGORY_SETUP);
	}
	my ($status_line, $lines) = ($1, $2);
	push($document, [split(qr{\h+}, $status_line, 2)]);

	my $header_lines = [];
	my $split = [split(qr{(?:\012|\015\012?)}, $lines, PKY_SPLIT_RETURN_FULL_TRAIL)];
	foreach my $line (@$split)
	{
		push($header_lines, [split(qr{:\h+}, $line, 2)]);
	}
	push($document, $header_lines);

	$this->[ATR_HTTP_HEADER] = $document;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.66
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"