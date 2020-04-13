#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';

use Getopt::Long qw(:config no_ignore_case);

use Data::Roundtrip;

my $INPUT_STRING = undef;
my $INPUT_FILE = undef;
my $OUTPUT_FILE = undef;
my %params = (
	'dont-bloody-escape-unicode' => 1
);
sub usage { return
	"Usage : $0 [--I 'a-perl-var-as-string' | --i 'afile.pl'] [--o afile.json] [--escape-unicode|-e] [--pretty]\n"
	."\nIt will read a Perl variable as a string from command line (-I), or a file (-i)\n"
	."\nor from STDIN.\n"
	."It will print its JSON equivalent to STDOUT or to a file (--o).\n"
	."It can optionally escape unicode characters (--escape-unicode) and/or do pretty-printing (--pretty).\n"
}
if( ! Getopt::Long::GetOptions(
  'i=s' => \$INPUT_FILE,
  'I=s' => sub { $INPUT_STRING = Encode::decode_utf8($_[1]) },
  'o=s' => \$OUTPUT_FILE,
  'pretty|p' => \$params{'pretty'},
  'escape-unicode|e' => \$params{'escape-unicode'},
) ){ die usage() }

if( defined $INPUT_FILE ){
	$INPUT_STRING = Data::Roundtrip::_read_from_file($INPUT_FILE);
	if( ! defined $INPUT_STRING ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::_read_from_file()'." has failed.\n"; exit(1) }
} elsif( ! defined $INPUT_STRING ){
	# read from STDIN
	$INPUT_STRING = do { local $/; <STDIN> }
}

my $result = Data::Roundtrip::dump2json($INPUT_STRING, \%params);
if( ! defined $result ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::dump2jsonl()'." has failed.\n"; exit(1) }

if( defined $OUTPUT_FILE ){
	if( ! Data::Roundtrip::_write_to_file($OUTPUT_FILE, $result) ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::_write_to_file()'." has failed for '$OUTPUT_FILE'.\n"; exit(1) }
} else {
	print STDOUT $result
}
1;
__END__

### pod follows

=pod

=head1 NAME

Convert a Perl data structure to JSON

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    perl2json.pl -i "perl-data-structure.pl" -o "output.json" --escape-unicode --pretty

=head1 USAGE

C<perl2json.pl>

Options:

=over 4

=item C<--i filename> : specify a filename which contains a Perl
data structure in text representation, not as a (binary) serialised
object, as one would have used in a Perl script.

=item C<--I "string"> : specify a string  which contains a Perl
data structure in text representation, not as a (binary) serialised
object. But exactly as one would have used in a Perl script.

=item C<--o outputfilename> : specify the output filename to write
the result to.

=item C<--escape-unicode> : it will escape all unicode characters, and
convert them to something like "\u0386"

=item C<--pretty> : write this JSON pretty, line breaks, indendations, "the full catastrophe"

=back

Input can be read from an input file (--i), from a string at the
command line (--I) (properly quoted!), from STDIN (which also includes
a file redirection C<< json2json.pl < inputfile.json > outputfile.json >>

For more information see L<Data::Roundtrip>.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> / <andreashad2 at gmail.com> >>

=cut
