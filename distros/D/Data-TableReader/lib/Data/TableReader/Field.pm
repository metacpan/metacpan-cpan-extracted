package Data::TableReader::Field;
$Data::TableReader::Field::VERSION = '0.007';
use Moo 2;

# ABSTRACT: Field specification for Data::TableReader


has name     => ( is => 'ro', required => 1 );
has header   => ( is => 'ro' );
has required => ( is => 'ro', default => sub { 1 } );
has trim     => ( is => 'ro', default => sub { 1 } );
has blank    => ( is => 'ro' ); # default is undef
has type     => ( is => 'ro', isa => sub { ref $_[0] eq 'CODE' or $_[0]->can('validate') } );
has array    => ( is => 'ro' );
has follows  => ( is => 'ro' );
sub follows_list { my $f= shift->follows; ref $f? @$f : defined $f? ( $f ) : () }


has header_regex => ( is => 'lazy' );

sub _build_header_regex {
	my $self= shift;
	my $h= $self->header;
	unless (defined $h) {
		$h= $self->name;
		$h =~ s/([[:lower:]])([[:upper:]])/$1 $2/g; # split words on camelCase
		$h =~ s/([[:alpha:]])([[:digit:]])/$1 $2/g; # or digit
		$h =~ s/([[:digit:]])([[:alpha:]])/$1 $2/g;
		$h =~ s/_/ /g;                              # then split on underscore
	}
	return $h if ref($h) eq 'Regexp';
	my $pattern= join "[\\W_]*", map "\Q$_\E", grep { defined && length }
		split /(\n)|\s+|(\W)/, $h; # capture newline or non-word, except for other whitespace
	return qr/^[\W_]*$pattern[\W_]*$/im;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Field - Field specification for Data::TableReader

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This class describes aspects of one of the fields you want to find in your spreadsheet.

=head1 ATTRIBUTES

=head2 name

Required.  Used for the hashref key if you pull records as hashes, and used in diagnostic
messages.

=head2 header

A string or regex describing the column header you want to find in the spreadsheet.
If you specify a regex, it is used directly.  If you specify a string, it becomes the regex
matching any string with the same words (\w+) and non-whitespace (\S+) characters in the same
order, case insensitive, surrounded by any amount of non-alphanumeric garbage (C<[\W_]*>).
When no header is specified, the L</name> is used as a string after first breaking it into
words on underscore or camel-case or numeric boundaries.

This deserves some examples:

  Name           Implied Default Header
  "zipcode"      "zipcode"
  "ZipCode"      "Zip Code"
  "Zip_Code"     "zip Code"
  "zip5"         "zip 5"
  
  Header         Regex                                  Could Match...
  "ZipCode"      /^[\W_]*ZipCode[\W_]*$/i               "zipcode:"
  "zip_code"     /^[\W_]*zip_code[\W_]*$/i              "--ZIP_CODE--"
  "zip code"     /^[\W_]*zip[\W_]*code[\W_]*$/i         "ZIP\nCODE    "
  "zip-code"     /^[\W_]*zip[\W_]*-[\W_]*code[\W_]*$/i  "ZIP-CODE:"
  qr/Zip.*Code/  /Zip.*Code/                            "Post(Zip)Code"

If this default matching doesn't meet your needs or paranoia level, then you should always
specify your own header regexes.

(If your data actually doesn't have any header at all and you want to brazenly assume the
columns match the fields, see reader attribute L<Data::TableReader/header_row_at>)

=head2 required

Whether or not this field must be found in order to detect a table.  Defaults is B<true>.
Note this does B<not> require the field of a row to contain data in order to read a record
from the table; it just requires a column to exist.

=head2 trim

Whether or not to remove prefix/suffix whitespace from each value of the field.
Default is B<true>.

=head2 blank

The value to extract when the spreadsheet cell is empty.  (where "empty" depends on the value
of C<trim>).  Default is C<undef>.  Another common value would be C<"">.

=head2 type

A L<Type::Tiny> type (or any object or class with a C<validate> method) or a coderef which
returns a validation error message (undef if it is valid).

  use Types::Standard;
  ...
     type => Maybe[Int]
  
  # or without Type::Tiny
     type => sub { $_[0] =~ /^\w+/? undef : "word-characters only" },

This is an optional feature and there is no default.
The behavior of a validation failure depends on the options to TableReader.

=head2 array

Boolean of whether this field can be found multiple times in one table.  Default is B<false>.
If true, the value of the field will always be an arrayref (even if only one column matched).

=head2 follows

Name (or arrayref of names) of a field which this field must follow, in a first-to-last
ordering of the columns.  This field must occur immediately after the named field(s), or after
another field which also has a C<follows> restriction and follows the named field(s).

The purpose of this attribute is to resolve ambiguous columns.  Suppose you expect columns with
the following headers:

  Father    |          |      |       | Mother    |          |      |      
  FirstName | LastName | Tel. | Email | FirstName | LastName | Tel. | Email

You can use C<qr/Father\nFirstName/> to identify the first column, but after FirstName the rest
are ambiguous.  But, TableReader can figure it out if you say:

  { name => 'father_first', header => qr/Father\nFirstName/ },
  { name => 'father_last',  header => 'LastName', follows => 'father_first' },
  { name => 'father_tel',   header => 'Tel.',     follows => 'father_first' },
  { name => 'father_email', header => 'Email',    follows => 'father_first' },
  ..

and so on.  Note how C<'father_first'> is used for each as the C<follows> name; this way if any
non-required fields (like maybe C<Tel>) are completely removed from the file, TableReader
will still be able to find C<LastName> and C<Email>.

You can also use this to accumulate an array of columns that lack headers:

  Scores |      |       |      |       |       |       | OtherData
  12%    | 35%  | 42%   | 18%  | 65%   | 99%   | 55%   | xyz

  { name => 'scores', array => 1, trim => 1 },
  { name => 'scores', array => 1, trim => 1, header => '', follows => 'scores' },

The second field definition has an empty header, which would normally make it rather ambiguous
and potentially capture blank-header columns that might not be part of the array.  But, because
it must follow a column named 'scores' there's no ambiguity; you get exactly any column
starting from the header C<'Scores'> until a column of any other header.

=head2 follows_list

Convenience accessor for C<< @{ ->follows } >>.

=head2 header_regex

L</header>, coerced to a regex if it wasn't already

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
