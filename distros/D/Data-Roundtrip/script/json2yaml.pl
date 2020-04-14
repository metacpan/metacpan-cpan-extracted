#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

our $VERSION = '0.03';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';

use Getopt::Long qw(:config no_ignore_case);

use Data::Roundtrip;

my $INPUT_STRING = undef;
my $INPUT_FILE = undef;
my $OUTPUT_FILE = undef;
my %params = (
	'escape-unicode' => 0
);

sub usage { return
	"Usage : $0 [--I 'a-json-string' | --i 'afile.json'] [--o afile] [--escape-unicode|-e] [--pretty]\n"
	."\nIt will read a JSON string from command line (-I), or from a file (-i)\n"
	."\nor from STDIN.\n"
	."It will print its contents as YAML to STDOUT or to a file (--o).\n"
	."It can escape/un-escape unicode characters (--escape-unicode) and/or do pretty-printing (--pretty).\n"
}
if( ! Getopt::Long::GetOptions(
  'i=s' => \$INPUT_FILE,
  'I=s' => sub { $INPUT_STRING = Encode::decode_utf8($_[1]) },
  'o=s' => \$OUTPUT_FILE,
  'pretty|p' => \$params{'pretty'},
  'escape-unicode|e' => \$params{'escape-unicode'},
) ){ die usage() }

if( defined $INPUT_FILE ){
	$INPUT_STRING = Data::Roundtrip::read_from_file($INPUT_FILE);
	if( ! defined $INPUT_STRING ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::read_from_file()'." has failed.\n"; exit(1) }
} elsif( ! defined $INPUT_STRING ){
	# read from STDIN
	$INPUT_STRING = do { local $/; <STDIN> }
}

my $result = Data::Roundtrip::json2yaml($INPUT_STRING, \%params);
if( ! defined $result ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::json2yaml()'." has failed.\n"; exit(1) }

if( defined $OUTPUT_FILE ){
	if( ! Data::Roundtrip::_write_to_file($OUTPUT_FILE, $result) ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::_write_to_file()'." has failed for '$OUTPUT_FILE'.\n"; exit(1) }
} else {
	print STDOUT $result
}
1;
__END__

### pod follows

=pod

=encoding utf8

=head1 NAME

json2yaml.pl : convert JSON to YAML with formatting options.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    json2yaml.pl -i "input.json" -o "output.yaml" --escape-unicode --pretty

=head1 USAGE

C<json2yaml.pl>

Options:

=over 4

=item C<--i filename> : specify a filename which contains a JSON
data structure.

=item C<--I "string"> : specify a string  which contains a JSON
data structure.

=item C<--o outputfilename> : specify the output filename to write
the result to, which will be YAML.

=item C<--escape-unicode> : it will escape all unicode characters, and
convert them to something like "\u0386"

=back

Input can be read from an input file (--i), from a string at the
command line (--I) (properly quoted!), from STDIN (which also includes
a file redirection C<< json2yaml.pl < inputfile.json > outputfile.yaml >>

For more information see L<Data::Roundtrip>.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> / <andreashad2 at gmail.com> >>

=cut
