=head1 NAME

Data::Pond - Perl-based open notation for data

=head1 SYNOPSIS

	use Data::Pond qw($pond_datum_rx);

	if($expr =~ /\A$pond_datum_rx\z/o) { ...
	# and other regular expressions

	use Data::Pond qw(pond_read_datum pond_write_datum);

	$datum = pond_read_datum($text);
	$text = pond_write_datum($datum);
	$text = pond_write_datum($datum, { indent => 0 });

=head1 DESCRIPTION

This module is concerned with representing data structures in a textual
notation known as "Pond" (I<P>erl-based I<o>pen I<n>otation for I<d>ata).
The notation is a strict subset of Perl expression syntax, but is intended
to have language-independent use.  It is similar in spirit to JSON, which
is based on JavaScript, but Pond represents fewer data types directly.

The data that can be represented in Pond consist of strings (of
characters), arrays, and string-keyed hashes.  Arrays and hashes can
recursively (but not cyclically) contain any of these kinds of data.
This does not cover the full range of data types that Perl or other
languages can handle, but is intended to be a limited, fixed repertoire
of data types that many languages can readily process.  It is intended
that more complex data can be represented using these basic types.
The arrays and hashes provide structuring facilities (ordered and
unordered collections, respectively), and strings are a convenient way
to represent atomic data.

The Pond syntax is a subset of Perl expression syntax, consisting of
string literals and constructors for arrays and hashes.  Strings may
be single-quoted or double-quoted, or may be decimal integer literals.
Double-quoted strings are restricted in which backslash sequences they
can use: the permitted ones are the single-character ones (such as C<\n>),
C<\x> sequences (such as C<\xe3> and C<\x{e3}>), and octal digit sequences
(such as C<\010>).  Non-ASCII characters are acceptable in quoted strings.
Strings may also appear as pure-ASCII barewords, when they directly
precede C<< => >> in an array or hash constructor.  Array (C<[]>) and hash
(C<{}>) constructors must contain data items separated by C<,> and C<<
=> >> commas, and can have a trailing comma but not adjacent commas.
Whitespace is permitted where Perl allows it.  Control characters are
not permitted, except for whitespace outside strings.

A Pond expression can be C<eval>ed by Perl to yield the data item
that it represents, but this is not the recommended way to do it.
Any use of C<eval> on data opens up security issues.  Instead use the
L</pond_read_datum> function of this module, which does not use Perl's
parser but directly parses the restricted Pond syntax.

This module is implemented in XS, with a pure Perl backup version for
systems that can't handle XS.

=cut

package Data::Pond;

{ use 5.008; }
use warnings;
use strict;

our $VERSION = '0.006';

use parent "Exporter";
our @EXPORT_OK = qw(
	$pond_string_rx $pond_ascii_string_rx
	$pond_array_rx $pond_ascii_array_rx
	$pond_hash_rx $pond_ascii_hash_rx
	$pond_datum_rx $pond_ascii_datum_rx
	pond_read_datum pond_write_datum
);

=head1 REGULAR EXPRESSIONS

Each of these regular expressions corresponds precisely to part of
Pond syntax.  The regular expressions do not include any anchors, so to
check whether an entire string matches a production you must supply the
anchors yourself.

The regular expressions with C<_ascii_> in the name match the subset
of the grammar that uses only ASCII characters.  All Pond data can be
expressed using only ASCII characters.

=over

=item $pond_string_rx

=item $pond_ascii_string_rx

A string literal.  This may be a double-quoted string, a single-quoted
string, or a decimal integer literal.  It does not accept barewords.

=cut

my $pond_optwsp_rx = qr/[\t\n\f\r ]*/;

my $pond_dqstringchar_rx = qr/[\ -\!\#\%-\?A-\[\]-\~\x{a1}-\x{7fffffff}]/;
my $pond_dqstring_rx = qr/(?>"(?:
	$pond_dqstringchar_rx+
	|\\(?:[\ -befnrt\{-\~\x{a1}-\x{7fffffff}]
	     |x(?:[0-9a-fA-F]|\{[0-9a-fA-F]+\}))
)*")/x;
my $pond_ascii_dqstring_rx = qr/(?>"(?:
	[\ -\!\#\%-\?A-\[\]-\~]+
	|\\(?:[\ -befnrt\{-\~]
	     |x(?:[0-9a-fA-F]|\{[0-9a-fA-F]+\}))
)*")/x;

my $pond_sqstringchar_rx = qr/[\ -\&\(-\[\]-\~\x{a1}-\x{7fffffff}]/;
my $pond_sqstring_rx = qr/(?>'(?:
	$pond_sqstringchar_rx+
	|\\[\ -\~\x{a1}-\x{7fffffff}]
)*')/x;
my $pond_ascii_sqstring_rx = qr/(?>'(?:
	[\ -\&\(-\[\]-\~]+
	|\\[\ -\~]
)*')/x;

my $pond_number_rx = qr/0|[1-9][0-9]*/;

our $pond_string_rx = qr/$pond_dqstring_rx
			|$pond_sqstring_rx
			|$pond_number_rx/xo;
our $pond_ascii_string_rx = qr/$pond_ascii_dqstring_rx
			      |$pond_ascii_sqstring_rx
			      |$pond_number_rx/xo;

my $pond_bareword_rx = qr/(?>[A-Za-z_][0-9A-Za-z_]*(?=$pond_optwsp_rx=>))/o;

my $pond_interior_string_rx = qr/$pond_bareword_rx|$pond_string_rx/o;
my $pond_ascii_interior_string_rx =
	qr/$pond_bareword_rx|$pond_ascii_string_rx/o;

=item $pond_array_rx

=item $pond_ascii_array_rx

An array C<[]> constructor.

=cut

my $pond_interior_datum_rx = do { use re "eval";
	qr/$pond_bareword_rx|(??{$Data::Pond::pond_datum_rx})/o
};
my $pond_ascii_interior_datum_rx = do { use re "eval";
	qr/$pond_bareword_rx|(??{$Data::Pond::pond_ascii_datum_rx})/o
};

my $pond_comma_rx = qr/,|=>/;

our $pond_array_rx = qr/(?>\[$pond_optwsp_rx
	(?>$pond_interior_datum_rx$pond_optwsp_rx
	   $pond_comma_rx$pond_optwsp_rx)*
	(?:$pond_interior_datum_rx$pond_optwsp_rx)?
\])/xo;
our $pond_ascii_array_rx = qr/(?>\[$pond_optwsp_rx
	(?>$pond_ascii_interior_datum_rx$pond_optwsp_rx
	   $pond_comma_rx$pond_optwsp_rx)*
	(?:$pond_ascii_interior_datum_rx$pond_optwsp_rx)?
\])/xo;

=item $pond_hash_rx

=item $pond_ascii_hash_rx

A hash C<{}> constructor.

=cut

my $pond_hashelem_rx = qr/
	$pond_interior_string_rx$pond_optwsp_rx
	$pond_comma_rx$pond_optwsp_rx$pond_interior_datum_rx
/xo;
my $pond_ascii_hashelem_rx = qr/
	$pond_ascii_interior_string_rx$pond_optwsp_rx
	$pond_comma_rx$pond_optwsp_rx$pond_ascii_interior_datum_rx
/xo;

our $pond_hash_rx = qr/(?>\{$pond_optwsp_rx
	(?>$pond_hashelem_rx$pond_optwsp_rx$pond_comma_rx$pond_optwsp_rx)*
	(?:$pond_hashelem_rx$pond_optwsp_rx)?
\})/xo;
our $pond_ascii_hash_rx = qr/(?>\{$pond_optwsp_rx
	(?>$pond_ascii_hashelem_rx$pond_optwsp_rx$pond_comma_rx$pond_optwsp_rx)*
	(?:$pond_ascii_hashelem_rx$pond_optwsp_rx)?
\})/xo;

=item $pond_datum_rx

=item $pond_ascii_datum_rx

Any permitted expression.  This may be a string literal, array
constructor, or hash constructor.

=cut

our $pond_datum_rx = qr/$pond_string_rx
		       |$pond_array_rx
		       |$pond_hash_rx/xo;
our $pond_ascii_datum_rx = qr/$pond_ascii_string_rx
			     |$pond_ascii_array_rx
			     |$pond_ascii_hash_rx/xo;

=back

=cut

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
};

if($@ eq "") {
	close(DATA);
} else {
	(my $filename = __FILE__) =~ tr# -~##cd;
	local $/ = undef;
	my $pp_code = "#line 223 \"$filename\"\n".<DATA>;
	close(DATA);
	{
		local $SIG{__DIE__};
		eval $pp_code;
	}
	die $@ if $@ ne "";
}

1;

__DATA__

use Params::Classify 0.000 qw(is_undef is_string is_ref);

=head1 FUNCTIONS

=over

=item pond_read_datum(TEXT)

I<TEXT> is a character string.  This function parses it as a Pond-encoded
datum, with optional surrounding whitespace, returning the represented
item as a Perl native datum.  C<die>s if a malformed item is encountered.

=cut

my %str_decode = (
	"a" => "\a",
	"b" => "\b",
	"t" => "\t",
	"n" => "\n",
	"f" => "\f",
	"r" => "\r",
	"e" => "\e",
);

sub _subexpr_skip_ws($) {
	my($exprref) = @_;
	$$exprref =~ /\G[\t\n\f\r ]+/gc;
}

sub _subexpr_datum($);
sub _subexpr_datum($) {
	my($exprref) = @_;
	if($$exprref =~ /\G([A-Za-z_][0-9A-Za-z_]*)(?=[\t\n\f\r ]*=>)/gc) {
		return $1;
	} elsif($$exprref =~ /\G\"/gc) {
		my $datum = "";
		until($$exprref =~ /\G\"/gc) {
			if($$exprref =~ /\G\\([0-7]{1,3})/gc) {
				$datum .= chr(oct($1));
			} elsif($$exprref =~ /\G\\x([0-9a-fA-F]{1,2})/gc) {
				$datum .= chr(hex($1));
			} elsif($$exprref =~ /\G\\x\{([0-9a-fA-F]+)\}/gc) {
				my $hexval = $1;
				unless($hexval =~ /\A0*(?:0
					|[1-7][0-9a-fA-F]{0,7}
					|[8-9a-fA-F][0-9a-fA-F]{0,6}
				)\z/x) {
					die "Pond constraint error: ".
						"invalid character\n";
				}
				$datum .= chr(hex($hexval));
			} elsif($$exprref =~ /\G\\([a-zA-Z])/gc) {
				my $c = $str_decode{$1};
				die "Pond syntax error\n" unless defined $c;
				$datum .= $c;
			} elsif($$exprref =~
				/\G\\([\ -\~\x{a1}-\x{7fffffff}])/gc) {
				$datum .= $1;
			} elsif($$exprref =~ /\G($pond_dqstringchar_rx+)/ogc) {
				$datum .= $1;
			} else { die "Pond syntax error\n" }
		}
		return $datum;
	} elsif($$exprref =~ /\G\'/gc) {
		my $datum = "";
		until($$exprref =~ /\G\'/gc) {
			if($$exprref =~ /\G\\([\'\\])/gc) {
				$datum .= $1;
			} elsif($$exprref =~
					/\G(\\|$pond_sqstringchar_rx+)/ogc) {
				$datum .= $1;
			} else { die "Pond syntax error\n" }
		}
		return $datum;
	} elsif($$exprref =~ /\G(0|[1-9][0-9]*)/gc) {
		return $1;
	} elsif($$exprref =~ /\G([\[\{])/gc) {
		my $type = $1 eq "[" ? "ARRAY" : "HASH";
		my $close = $1 eq "[" ? qr/\]/ : qr/\}/;
		my @data;
		while(1) {
			_subexpr_skip_ws($exprref);
			last if $$exprref =~ /\G$close/gc;
			push @data, _subexpr_datum($exprref);
			_subexpr_skip_ws($exprref);
			last if $$exprref =~ /\G$close/gc;
			die "Pond syntax error\n"
				unless $$exprref =~ /\G(?:,|=>)/gc;
		}
		return \@data if $type eq "ARRAY";
		die "Pond constraint error: ".
				"odd number of elements in hash constructor\n"
			if scalar(@data) & 1;
		for(my $i = @data; $i; ) {
			$i -= 2;
			die "Pond constraint error: non-string hash key\n"
				unless is_string($data[$i]);
		}
		return {@data};
	} else { die "Pond syntax error\n" }
}

sub pond_read_datum($) {
	my($text) = @_;
	die "Pond data error: text isn't a string\n" unless is_string($text);
	_subexpr_skip_ws(\$text);
	my $datum = _subexpr_datum(\$text);
	_subexpr_skip_ws(\$text);
	die "Pond syntax error\n" unless $text =~ /\G\z/gc;
	return $datum;
}

=item pond_write_datum(DATUM[, OPTIONS])

I<DATUM> is a Perl native datum.  This function serialises it as a
character string using Pond encoding.  The data to be serialised can
recursively contain Perl strings, arrays, and hashes.  Numbers are
implicitly stringified, and C<undef> is treated as the empty string.
C<die>s if an unserialisable datum is encountered.

I<OPTIONS>, if present, must be a reference to a hash, containing options
that control the serialisation process.  The recognised options are:

=over

=item B<indent>

If C<undef> (which is the default), no optional whitespace will be added.
Otherwise it must be a non-negative integer, and the datum will be laid
out with whitespace (where it is optional) to illustrate the structure by
indentation.  The number given must be the number of leading spaces on
the line on which the resulting element will be placed.  If whitespace
is added, the element will be arranged to end on a line of the same
indentation, and all intermediate lines will have greater indentation.

=item B<undef_is_empty>

If false (the default), C<undef> will be treated as invalid data.
If true, C<undef> will be serialised as an empty string.

=item B<unicode>

If false (the default), the datum will be expressed using only ASCII
characters.  If true, non-ASCII characters may be used in string literals.

=back

=cut

my %str_encode = (
	"\t" => "\\t",
	"\n" => "\\n",
	"\"" => "\\\"",
	"\$" => "\\\$",
	"\@" => "\\\@",
	"\\" => "\\\\",
);
foreach(0x00..0x1f, 0x7f..0xa0) {
	my $c = chr($_);
	$str_encode{$c} = sprintf("\\x%02x", $_) unless exists $str_encode{$c};
}

sub _strdatum_to_string($$) {
	my($str, $options) = @_;
	return $str if $str =~ /\A(?:0|[1-9][0-9]{0,8})\z/;
	die "Pond data error: invalid character\n"
		unless $str =~ /\A[\x{0}-\x{7fffffff}]*\z/;
	$str =~ s/([\x00-\x1f\"\$\@\\\x7f-\xa0])/$str_encode{$1}/eg;
	$str =~ s/([^\x00-\x7f])/sprintf("\\x{%02x}", ord($1))/eg
		unless $options->{unicode};
	return "\"$str\"";
}

sub _strdatum_to_bareword($$) {
	return $_[0] =~ /\A[A-Za-z_][0-9A-Za-z_]*\z/ ? $_[0] :
		&_strdatum_to_string;
}

sub pond_write_datum($;$);
sub pond_write_datum($;$) {
	my($datum, $options) = @_;
	$options = {} unless defined $options;
	if(is_undef($datum) && $options->{undef_is_empty}) {
		return '""';
	} elsif(is_string($datum)) {
		return _strdatum_to_string($datum, $options);
	} elsif(is_ref($datum, "ARRAY")) {
		return "[]" if @$datum == 0;
		if(defined $options->{indent}) {
			my $indent = $options->{indent};
			my $subindent = $indent + 4;
			my $indent_str = "\n"." "x$indent;
			my $subindent_str = "\n"." "x$subindent;
			my $suboptions = { %$options, indent => $subindent };
			return join("", "[", (map { (
				$subindent_str,
				pond_write_datum($_, $suboptions),
				",",
			) } @$datum), $indent_str, "]");
		} else {
			return "[".join(",", map {
				pond_write_datum($_, $options)
			} @$datum)."]";
		}
	} elsif(is_ref($datum, "HASH")) {
		return "{}" if keys(%$datum) == 0;
		if(defined $options->{indent}) {
			my $indent = $options->{indent};
			my $subindent = $indent + 4;
			my $indent_str = "\n"." "x$indent;
			my $subindent_str = "\n"." "x$subindent;
			my $suboptions = { %$options, indent => $subindent };
			return join("", "{", (map { (
				$subindent_str,
				_strdatum_to_bareword($_, $options),
				" => ",
				pond_write_datum($datum->{$_}, $suboptions),
				",",
			) } sort keys %$datum), $indent_str, "}");
		} else {
			return "{".join(",", map {
				_strdatum_to_bareword($_, $options)."=>".
				pond_write_datum($datum->{$_}, $options)
			} sort keys %$datum)."}";
		}
	} else {
		die "Pond data error: unsupported data type\n";
	}
}

=back

=head1 SEE ALSO

L<Data::Dumper>,
L<JSON::XS>,
L<perlfunc/eval>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009 PhotoBox Ltd

Copyright (C) 2010, 2012, 2017 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
