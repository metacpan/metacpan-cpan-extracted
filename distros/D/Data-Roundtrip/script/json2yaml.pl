#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

our $VERSION = '0.30';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';

use Getopt::Long qw(:config no_ignore_case);

use Data::Roundtrip;

my $INPUT_STRING = undef;
my $INPUT_FILE = undef;
my $OUTPUT_FILE = undef;
my %params = (
	'escape-unicode' => 0,
	# 'pretty' => 0, # not supported
);

sub usage { return
	"Usage : $0 [--I 'a-json-string' | --i 'afile.json'] [--o afile] [--(no-)escape-unicode|-e]\n"
	."\nIt will read a JSON string from command line (-I), or from a file (-i)\n"
	."\nor from STDIN (beware 4K limit on linux terminal, see CAVEATS for workaround).\n"
	."It will print its contents as YAML to STDOUT or to a file (--o).\n"
	."It can escape/un-escape unicode characters (--escape-unicode). Pretty-printing is not supported.\n"
}
if( ! Getopt::Long::GetOptions(
  'i=s' => \$INPUT_FILE,
  'I=s' => sub { $INPUT_STRING = Encode::decode_utf8($_[1]) },
  'o=s' => \$OUTPUT_FILE,
  'pretty|p!' => sub { warn "--pretty has no effect for converting to YAML and will be ignored.\n" },
  'escape-unicode|e!' => \$params{'escape-unicode'},
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
	if( ! Data::Roundtrip::write_to_file($OUTPUT_FILE, $result) ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::write_to_file()'." has failed for '$OUTPUT_FILE'.\n"; exit(1) }
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

Version 0.30

=head1 SYNOPSIS

    json2yaml.pl -i "input.json" -o "output.yaml" --(no-)escape-unicode

    json2yaml.pl -e < "input.json" > "output.yaml"

    # press CTRL-D when done typing JSON to STDIN
    # input must be less than 4K long!
    json2yaml.pl

    # Read input from clipboard or write output to clipboard
    # Only in: Unix / Linux / OSX                
    # (must have already installed xclip or xsel or pbpaste (on OSX))
    json2json.pl -e < $(xclip -o)
    json2json.pl -e < $(pbaste)
    # write the output to the clipboard for further pasting
    json2json.pl -i input.json | xclip -i
    # clicking mouse's middle-button will paste the result

=head1 USAGE

C<json2yaml.pl>

Options:

=over 4

=item * C<--i filename> : specify a filename which contains a JSON
data structure.

=item * C<--I "string"> : specify a string  which contains a JSON
data structure.

=item * C<--o outputfilename> : specify the output filename to write
the result to, which will be YAML.

=item * C<--escape-unicode> : it will escape all unicode characters, and
convert them to something like "\u0386". This is the default option.

=item * C<--no-escape-unicode> : it will NOT escape unicode characters. Output
will not contain "\u0386" or "\x{386}" but "α" (that's a greek alpha).

=back

Input can be read from an input file (--i), from a string at the
command line (--I) (properly quoted!), from STDIN (which also includes
a file redirection C<< json2yaml.pl < inputfile.json > outputfile.yaml >>

For more information see L<Data::Roundtrip>.

=head1 CAVEATS

Under Unix/Linux,
the maximum number of characters that can be read
on a terminal is 4096. So, in reading-from-STDIN mode
beware how much you type or how much you copy-paste
onto the script. If it complains about malformed input
then this is the case. The workaround is to type/paste
onto a file and operate on that using C<< --i afile >>
or redirection C<< < afile >>.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> / <andreashad2 at gmail.com> >>

=cut
