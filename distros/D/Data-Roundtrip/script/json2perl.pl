#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

our $VERSION = '0.05';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';

use Getopt::Long qw(:config no_ignore_case);

use Data::Roundtrip;

my $INPUT_STRING = undef;
my $INPUT_FILE = undef;
my $OUTPUT_FILE = undef;
my %params = (
	'dont-bloody-escape-unicode' => 1,
	'terse' => 0,
	'indent' => 1,
);

sub usage { return
	"Usage : $0 [--I 'a-json-string' | --i 'afile.json'] [--o afile] [--escape-unicode|-e] [--pretty] [--terse] [--no-indent]\n"
	."\nIt will read a JSON string from command line (-I), or from a file (-i)\n"
	."\nor from STDIN.\n"
	."It will print its contents as a Perl variable (dump) to STDOUT or to a file (--o).\n"
	."It can escape/un-escape unicode characters (--escape-unicode) and/or --terse and --no-indent.\n"
}
if( ! Getopt::Long::GetOptions(
  'i=s' => \$INPUT_FILE,
  'I=s' => sub { $INPUT_STRING = Encode::decode_utf8($_[1]) },
  'o=s' => \$OUTPUT_FILE,
  'terse|t!' => \$params{'terse'},
  'indent|t!' => \$params{'indent'},
  'escape-unicode|e!' => \$params{'dont-bloody-escape-unicode'},
) ){ die usage() }

if( defined $INPUT_FILE ){
	$INPUT_STRING = Data::Roundtrip::read_from_file($INPUT_FILE);
	if( ! defined $INPUT_STRING ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::read_from_file()'." has failed.\n"; exit(1) }
} elsif( ! defined $INPUT_STRING ){
	# read from STDIN
	$INPUT_STRING = do { local $/; <STDIN> }
}

my $result = Data::Roundtrip::json2dump($INPUT_STRING, \%params);
if( ! defined $result ){ print STDERR "$0 : error, call to ".'Data::Roundtrip::json2dump()'." has failed.\n"; exit(1) }

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

json2perl.pl : convert JSON data to a Perl variable (dump) which can be parsed or eval'ed by any Perl script.

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    json2perl.pl -i "input.json" -o "output.perl" --no-escape-unicode --terse --no-indent

=head1 USAGE

C<json2perl.pl>

Options:

=over 4

=item C<--i filename> : specify a filename which contains a JSON
data structure.

=item C<--I "string"> : specify a string  which contains a JSON
data structure.

=item C<--o outputfilename> : specify the output filename to write
the result to, which will be as a Perl variable, as a dump,
which can be parsed or eval'ed from any Perl script.

=item C<--escape-unicode> : it will escape all unicode characters, and
convert them to something like "\u0386"

=item C<--terse> : Terse form of output (no $VAR1)

=item C<--no-indent> : do not use indentation

=back

Input can be read from an input file (--i), from a string at the
command line (--I) (properly quoted!), from STDIN (which also includes
a file redirection C<< json2perl.pl < inputfile.json > outputfile.perl >>

For more information see L<Data::Roundtrip>.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> / <andreashad2 at gmail.com> >>

=cut
