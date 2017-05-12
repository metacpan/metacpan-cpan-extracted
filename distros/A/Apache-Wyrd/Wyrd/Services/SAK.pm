use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::SAK;
use Carp;
use Exporter;
use Apache::Util;
use HTML::Entities;
use Encode qw(from_to _utf8_off);

=pod

=head1 NAME

Apache::Wyrd::Services::SAK - Swiss Army Knife of common subs

=head1 SYNOPSIS

	use Apache::Wyrd::Services::SAK qw(:hashes spit_file);

=head1 DESCRIPTION

"Swiss Army Knife" of functions used in Apache::Wyrd.  These are mostly
internal to the base classes of Wyrds, and are probably better implemented
elsewhere in CPAN, but reducing the number of external modules was a goal of
the Apache::Wyrd project.

I<(format: (returns) C<name> (arguments))> for regular functions.

I<(format: (returns) C<$wyrd-E<gt>name> (arguments))> for methods


=cut

our $VERSION = '0.98';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	array_4_get
	attopts_template
	cgi_query
	commify
	data_clean
	_exists_in_table
	do_query
	env_4_get
	file_attribute
	lc_hash
	normalize_href
	send_mail
	set_clause
	slurp_file
	sort_by_ikey
	sort_by_key
	spit_file
	strip_html
	token_hash
	token_parse
	uri_escape
	uniquify_by_key
	uniquify_by_ikey
	utf8_force
	utf8_to_entities
);

our %EXPORT_TAGS = (
	all			=>	\@EXPORT_OK,
	db			=>	[qw(cgi_query do_query set_clause _exists_in_table)],
	file		=>	[qw(file_attribute slurp_file spit_file)],
	hash		=>	[qw(array_4_get data_clean env_4_get lc_hash sort_by_ikey sort_by_key token_hash token_parse uniquify_by_ikey uniquify_by_key)],
	mail		=>	[qw(send_mail)],
	string		=>	[qw(commify strip_html utf8_force utf8_to_entities)],
	tag			=>	[qw(attopts_template)],
	uri			=>	[qw(normalize_href uri_escape)],
);

=pod

=head2 DATABASE (:db)

Functions for working with databases.  Designed for use with a
combination of C<Apache::Wyrd::Interfaces::Setter> and the DBI-compatible
database stored in C<Apache::Wyrd::DBL>.

=over

=item (scalarref) C<$wyrd-E<gt>cgi_query>(scalar)

For turning strings with conditional variables into
queries parseable by the SQL interpreter.  First sets all conditional variables
in the query that are known, then set all unknown variables to NULL.  The query
is then executes and the DBI handle to the query is returned.

     $sh = $wyrd->cgi_query(
       'select names from people where name=$:name'
     );

	$wyrd->cgi_query('delete from people where id=$:id');

=cut

sub cgi_query {
	my ($self, $query) = @_;
	$self->_raise_exception("Wyrd must be a Setter before you can use cgi_query.  Include Apache::Wyrd::Interfaces::Setter in your use base declaration.")
		unless (UNIVERSAL::isa($self, 'Apache::Wyrd::Interfaces::Setter'));
	$query=Apache::Wyrd::Interfaces::Setter::_cgi_quote_set($self, $query);
	#replace unknown variables with null
	$query =~ s/\$:[a-zA-Z_0-9]+/NULL/g;
	my $sh = $self->dbl->dbh->prepare($query);
	$self->_info("Executing $query");
	$sh->execute;
	my $err = $sh->errstr;
	$self->_error("DB Error: $err") if ($err);
	return $sh;
}

=pod

=item (scalarref) C<$wyrd-E<gt>do_query>(scalar, [hashref])

Shorthand for creating and executing a DBI statement handle, returning the
handle.  If the optional hashref is supplied, it will perform a substitution in
the manner of C<Apache::Wyrd::Interfaces::Setter>. Unknown variables will be
made NULL for the query.  The query is then executes and the DBI handle to the
query is returned.

    $sh = $wyrd->do_query(
      'select names from people where name=$:name', {name => $name}
    );

    $wyrd->do_query('delete from people');

=cut

sub do_query {
	my ($self, $query, $hash) = @_;
	$self->_raise_exception("Wyrd must be a Setter before you can use do_query.  Include Apache::Wyrd::Interfaces::Setter in your use base declaration.")
		unless (UNIVERSAL::isa($self, 'Apache::Wyrd::Interfaces::Setter'));
	$query = Apache::Wyrd::Interfaces::Setter::_quote_set($self, $hash, $query) if (ref($hash) eq 'HASH');
	my $sh = $self->dbl->dbh->prepare($query);
	$self->_info("Executing $query");
	$sh->execute;
	my $err = $sh->errstr;
	$self->_error("DB Error: $err") if ($err);
	return $sh;
}

=pod

=item (scalar) _exists_in_table (hashref)

Determines if there exists in a table an entry with a given value in a
given column.  Accepts a hashref with the keys "table", "column", and
"value".  These should all be scalar string values.  Returns the number
of matching cases.

=cut

sub _exists_in_table {
	my ($self, $spec) = @_;
	if (ref($spec) eq 'HASH') {
		my $table = $spec->{'table'};
		my $column = $spec->{'column'};
		my $value = $spec->{'value'};
		my $count = 0;
		if ($table and $column and $value) {
			$value = $self->dbl->dbh->quote($value);
			($count) = $self->_dbh->selectrow_array("select count(*) from $table where $column=$value")
				|| $self->_error("DBH error: " . $self->_dbh->errstr);
		}
		return $count;
	}
	$self->_error("_exists_in_table requires a hashref with keys table, column, and value");
	return;
}

=pod

=item (scalar) set_clause(array)

Shorthand for setting up a query to be settable per
C<Apache::Wyrd::Interfaces::Setter> when given an array of column names.

=cut

sub set_clause {
	my @items = @_;
	@items = map {$_ . '=$:' . $_} @items;
	return join(", ", @items);
}

=pod

=back

=head2 FILES (:file)

Old-style file routines and file-related methods.

=over

=item (scalarref) C<file_attribute>(scalar, scalar, scalar)

Convert and check a file attribute based on tests.  The tests are 'r'
for read, 'w' for write, 'f' for exists (file) and 'd' for exists
(directory), similar to the builtin -E<lt>fooE<gt> tests of the same
name.  If the file does not exist, but the test is w and not f or d,
this method will check if the item is in a writeable directory.

If the file path under the attribute is not absolute, the relative path
will be calculated first from the current location (of the file in which
the wyrd is located) or from the document root, in that order.

The method returns C<undef> on failure and the resolved path on success,
leaving the attribute intact.

=cut

sub file_attribute {
	my ($self, $attr, $tests) = @_;
	$self->_error("file_attribute() accepts only the r, w,d , and f tests") if ($tests =~ /[^rwdf]/);
	#warn "File is " . $self->{$attr};
	my @paths = ($self->{$attr});
	#warn "File is $paths[0]";
	unless (-e $paths[0]) {
		$paths[0] =~ s#^/##;
		my ($curdir) = ($self->dbl->file_path =~ m#(.+)/([^/]+)#);
		push @paths, "$curdir/$paths[0]";
		my ($rootdir) = ($self->dbl->req->document_root);
		push @paths, "$rootdir/$paths[0]";
	}
	foreach my $path (@paths) {
		#warn "testing $path";
		my $result = 1;
		foreach my $test (split '', $tests) {
			my $write_ok = (-w $path);
			$result = 0 if ($test eq 'w' and not ($write_ok));
			$result = 0 if ($test eq 'r' and not (-r _));
			$result = 0 if ($test eq 'd' and not (-d _));
			$result = 0 if ($test eq 'f' and not (-f _));
		}
		($path) = $path =~ /(.+)/;#untaint
		return $path if ($result);
	}
	#at this point, the tests have failed for all paths.
	#test the special case of a file for writing that does
	#not yet exist
	if (($tests =~ /w/) and ($tests !~ /d|f/)) {
		foreach my $path (@paths) {
			($path) = $path =~ /(.+)/;#untaint
			my ($testdir, @null) = ($path =~ m#(.+)/([^/]+)#);
			if ($tests =~ /r/) {
				return $path if (-d $testdir and -w _ and -r _)
			} else {
				return $path if (-d $testdir and -w _)
			}
		}
	}
	return;
}

=pod

=item (scalarref) C<slurp_file>(scalar)

get whole contents of a file.  The only argument is the whole path and
filename.  A scalarref to the contents of the file is returned.

=cut

sub slurp_file {
	my $file = shift;
	$file = open (FILE, $file);
	if ($file) {
		local $/;
		$file = <FILE>;
		close (FILE);
	}
	return \$file;
}

=pod

=item (scalar) C<spit_file>(scalar, scalar)

Opposite of C<slurp_file>.  The second argument is the contents of the file.
A positive response means the file was successfully written.

=cut

sub spit_file {
	my ($file, $contents) = @_;
	my $success = open (FILE, '>', $file);
	if ($success) {
		print FILE $contents;
		close (FILE);
	}
	return $success;
}

=pod

=back

=head2 HASHES (:hash)

Helpful routines for handling hashes.

=over

=item (scalar) C<array_4_get> (array)

create the query portion of a URL as a get request out of the current
CGI environment values for those elements.  When multiple values of an
element exist, they are appended.

=cut

sub array_4_get {
	my ($self, @array) = @_;
	my @param = ();
	foreach my $param (@array) {
		my @values = $self->dbl->param($param);
		foreach my $value (@values) {
			push @param, Apache::Wyrd::Services::SAK::uri_escape("$param=" . $value);
		}
	}
	return join('&', @param);
}

=pod

=item (scalar) C<data_clean>(scalar)

Shorthand for turning a string into "all lower case with underlines for
whitespace".

=cut

sub data_clean {
	my $data = shift;
	$data = lc($data);
	$data =~ s/\s+/_/gm;
	$data = Apache::Util::escape_uri($data);
	return $data;
}

=pod

=item (scalar) C<env_4_get>([array/hashref])

attempt to re-create the current CGI environment as the query portion of a GET
request.  Either a hash or an array of variables to ignore can be supplied.

=cut

sub env_4_get {
	my ($self, $ignore, @ignore) = @_;
	my %drop = ();
	my $out = undef;
	my @params = ();
	unless (ref($ignore) eq 'HASH') {
		foreach my $i ($ignore, @ignore) {
			$drop{$i} = 1;
		}
	} else {
		%drop = %$ignore;
	}
	foreach my $i ($self->dbl->param) {
		next if (exists($drop{$i}));
		push @params, Apache::Wyrd::Services::SAK::uri_escape("$i=" . $self->dbl->param($i));
	}
	return join('&', @params);
}

=pod

=item (hashref) C<data_clean>(hashref)

Shorthand for turning a hashref into a lower-case version of itself.  Will
randomly destroy one value of any key for which multiple keys of different case
are given.

=cut

sub lc_hash {
	my $hashref = shift;
	return {} if (ref($hashref) ne 'HASH');
	my %temp = ();
	foreach my $i (keys %$hashref) {
		$temp{lc($i)} = $$hashref{$i};
	}
	$hashref = \%temp;
	return $hashref;
}

=pod

=item (scalar, scalar) C<sort_by_ikey>(a_hashref, b_hashref, array of keys)

Sort hashes by key.  To be used in conjunction with the sort function:

    sort {sort_by_ikey($a, $b, 'lastname', 'firstname')} @array

=cut

sub sort_by_ikey {
	my $first = shift;
	my $last = shift;
	my $key = shift;
	return 0 unless ($key);
	if ($key =~ s/^-//) {#reverse for this key if it is preceeded by a minus sign
		($first, $last) = ($last, $first);
	}
	no warnings q/numeric/;
	return ((lc($first->{$key}) cmp lc($last->{$key})) || ($first->{$key} <=> $last->{$key}) || (sort_by_ikey($first, $last, @_)));
}

=pod

=item (scalar, scalar) C<sort_by_key>(a_hashref, b_hashref, array of keys)

Case-insensitive version of C<sort_by_ikey>

    sort {sort_by_key($a, $b, 'lastname', 'firstname')} @array

=cut

sub sort_by_key {
	my $first = shift;
	my $last = shift;
	my $key = shift;
	return 0 unless ($key);
	if ($key =~ s/^-//) {#reverse for this key if it is preceeded by a minus sign
		($first, $last) = ($last, $first);
	}
	no warnings q/numeric/;
	return (($first->{$key} cmp $last->{$key}) || ($first->{$key} <=> $last->{$key}) || (sort_by_ikey($first, $last, @_)));
}

=pod

=item (hashref) C<token_hash>(scalar, [scalar])

Shorthand for performing C<token_hash> on a string and returning a hash with
positive values for every token.  Useful for making a hash that can be easily
used to check against the existence of a token in a string.

=cut

sub token_hash {
	my ($text, $token_regexp) = @_;
	my @parts = token_parse($text, $token_regexp);
	my %hash = ();
	foreach my $part (@parts) {
		$hash{$part} = 1;
	}
	return \%hash;
}

=pod

=item (array) C<token_parse>(scalar, [regexp])

given a string made up of tokens it will split the tokens into an array
of these tokens separated.  It defaults to separating by commas, or if
there are no commas, by whitespace.  The optional regexp overrides the
normal behavior.


	token_parse('each peach, pear, plum')

returns

	(q/each peach/, q/pear/, q/plum/)

and

	token_parse('every good boy does fine')

returns

	qw(every good boy does fine)

=cut

sub token_parse {
	my ($text, $token_regexp) = @_;
	if ($token_regexp) {
		return split(/$token_regexp/, $text);
	} else {
		if ($text =~ /,/) {
			return split /\s*,\s*/, $text;
		} else {
			return split /\s+/, $text;
		}
	}
}

=pod

=item (array of hashrefs) C<uniquify_by_ikey>(scalar, array of hashrefs)

given a key and an array of hashrefs, returns an array in the same order,
dropping any hashrefs with duplicate values in the given key.  Items are
evaluated in a case-insensitive manner.

=cut

sub uniquify_by_ikey {
	my ($key, @array) = @_;
	my %counts =();
	return grep {$counts{lc($_->{$key})}++ == 0} @array;
}

=pod

=item (array of hashrefs) C<uniquify_by_key>(scalar, array of hashrefs)

case sensitive version of C<uniquify_by_ikey>.

=cut

sub uniquify_by_key {
	my ($key, @array) = @_;
	my %counts =();
	return grep {$counts{$_->{$key}}++ == 0} @array;
}

=pod

=item (array of hashrefs) C<uri_escape>(scalar, array of hashrefs)

Quick and dirty shorthand for encoding a get request within a get request.

=cut

sub uri_escape {
	my $value = shift;
	$value = Apache::Util::escape_uri($value);
	$value =~ s/\&/%26/g;
	$value =~ s/\?/%3f/g;
	$value =~ s/\#/%23/g;
	return $value;
}

=pod

=item (scalar) C<normalize_href>(objectref DBL, scalar href)

Given a href-style URL, returns the full URL that is implied from the fragment.

=cut

sub normalize_href {
	my ($dbl, $fragment) = @_;
	my $req = $dbl->req;

	my $default_scheme = ($ENV{'HTTPS'} eq 'on') ? 'https' : 'http';
	my $default_hostinfo = $req->hostname;
	my $default_path = $dbl->self_path;

	my $uri =$req->parsed_uri;
	my $scheme = $uri->scheme || $default_scheme;
	my $hostinfo = $uri->hostinfo || $default_hostinfo;
	my $path = $uri->rpath || $default_path;
	$path =~ s{[^/]+$}{};

	if ($fragment =~ /^https?:/) {
		return $fragment;
	}
	elsif ($fragment =~ m#^/#) {
		return "$scheme://$hostinfo$fragment";
	} else {
		use Apache::URI;
		my $uri=$req->parsed_uri;
		return "$scheme://$hostinfo$path$fragment";
	}
}

=pod

=back

=head2 MAIL (:mail)

Quick and dirty interfaces to sendmail

=over

=item (null) C<send_mail> (hashref)

Send an email.  Assumes that the apache process is a trusted user (see
sendmail documentation).  The hash should have the following keys: to,
from, subject, and body.  Unless sendmail is in /usr/sbin, the path key
should also be set.

=cut

sub send_mail {
	my $mail = shift;
	$mail = lc_hash($mail);
	my $path = ($$mail{'path'} || '/usr/sbin');
	open (OUT, '|-', "$path/sendmail -t") || croak("Mail Failed: sendmail could not be used to send mail");
	print OUT <<__mail_end__;
From: $$mail{from}
To: $$mail{to}
Subject: $$mail{subject}

$$mail{body}

__mail_end__
	close OUT;
}

=pod

=back

=head2 Strings (:string)

String manipulations.

=over

=item (scalar) C<commify> (array)

Add commas to numbers, thanks to the perlfaq.

=cut

sub commify {
	my $number = shift;
	1 while ($number =~ s/^([-+]?\d+)(\d{3})/$1,$2/);
	return $number;
}

=pod

=item (scalar) C<strip_html>(scalar)

Escape out entities and strip tags from a given string.

=cut

sub strip_html {
	my ($data) = @_;
	$data = decode_entities($data);
	$data =~ s/<>//g; # Strip out all empty tags
	$data =~ s/<--.*?-->/ /g; # Strip out all comments
	$data =~ s/<[^>]*?>/ /g; # Strip out all HTML tags
	return $data;
}

=pod

=item (scalar) C<utf8_force>(scalar)

Attempt to decode the text into UTF-8 by trying different common encodings
until one returns valid UTF-8.

=cut

sub utf8_force {
	my ($text) = @_;
	my $success = 0;
	if (utf8::valid($text)) {
		utf8::upgrade($text);
		return $text;
	}
	for my $encoding (qw(windows-1252 MacRoman Latin-1 Latin-9)) {
		my $trial_data = $text;
		eval {
			from_to($encoding, 'utf8', $trial_data, Encode::FB_HTMLCREF);
		};
		if (not($@) && utf8::valid($trial_data)) {
			$text = $trial_data;
			$success = 1;
			last;
		}
	}
	unless ($success) {
		carp "Unable to encode as UTF8";
	}
	return $text;
}

=pod

=item (scalar) C<utf8_to_entities>(scalar)

Seek through the given text for Unicode byte sequences and replace them with
numbered entities for that unicode character.  Assumes the text is properly-
formatted UTF8.

=cut


sub utf8_to_entities {
	my ($text) = @_;
	use Encode qw(_utf8_off);
	_utf8_off($text);
	while ($text =~ /(([\xC0-\xFF])([\x80-\xFF]{1,5}))/) {

		#store the sequence for later;
		my $unicode_sequence = $1;

		#separate the first byte from the others
		my ($first, $second) = ($2, $3);

		#split remaining bytes and count them
		my @parts = split '', $second;
		my $count = @parts;

		#remove the appropriate number of bits from the high end of the first
		#byte (3 for 2 bytes, 4 for 3, etc) and use that for the first part of
		#the 32-bit binary number
		$first = substr(sprintf("%b", ord($first)), $count + 2, 6 - $count);
		my $full = $first;

		#Remove the two highest bits from the remaining bytes and concatenate
		#the result with the first part
		foreach my $part (@parts) {
			$part = substr(sprintf("%b", ord($part)),2,6);
			$full .= $part;
		}

		#Left-fill with zeroes to make a full 32 bit binary number
		$full =  substr(0 x 32 . $full, -32);

		#Turn the binary number into a 32-bit unsigned integer value
		my $hex_number = sprintf('%04X', unpack("N", pack("B32", $full)));

		#Replace all instances of that byte sequence found in the text with a
		#numbered entity sequence
		$text =~ s/$unicode_sequence/&#x$hex_number;/g;
	}
	return $text;
}

=pod

=back

=head2 TAGS (:tag)

Tag-generation tools.

=over

=item (scalar) C<attopts_template> (array)

Creates a template of attribute options, given an array of the attributes.

=cut

sub attopts_template {
	my @opts = @_;
	my $string = '';
	foreach my $opt (@opts) {
		$string .= '?:' . $opt . '{ $:' . $opt . '}';
	}
}

=pod

=back

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;