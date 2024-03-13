#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

our $VERSION = '0.10';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';

use Getopt::Long qw(:config no_ignore_case);

use Config::JSON::Enhanced;
use Data::Roundtrip qw/perl2json no-unicode-escape-permanently/;

my $OUTPUT_FILE = undef;
my %params = (
	'commentstyle' => 'custom(</*)(*/>)',
	'tags' => ['<%', '%>'],
);

sub usage { return
	"Usage : $0 [--I inputstring] [--i 'afile.json'] [--o afile] [--c commentstyle] [--tags tags]\n"
	."\nIt will read a JSON string from command line (-I), or from a file (-i)\n"
	."\nor from STDIN (beware 4K limit on linux terminal, see CAVEATS for workaround).\n"
	."It will print its contents as a Perl variable (dump) to STDOUT or to a file (--o).\n"
	."It can escape/un-escape unicode characters (--escape-unicode) and/or --terse and/or --indent.\n"
}
if( ! Getopt::Long::GetOptions(
  'i=s' => \$params{'filename'},
  'I=s' => sub { $params{'string'} = Encode::decode_utf8($_[1]) },
  'o=s' => \$OUTPUT_FILE,
  'commentstyle|c=s' => \$params{'commentstyle'},
  'tags|t=s' => \$params{'tags'},
) ){ die usage() }

if( ! exists($params{'filename'}) && ! exists($params{'string'}) ){
	# read from STDIN
	$params{'string'} = do { local $/; <STDIN> }
}

my $result = Config::JSON::Enhanced::config2perl(\%params);
if( ! defined $result ){ print STDERR "$0 : error, call to ".'Config::JSON::Enhanced::config2perl()'." has failed.\n"; exit(1) }

if( defined $OUTPUT_FILE ){
	my $FH;
	if( ! open($FH, '>', $$OUTPUT_FILE) ){
		print STDERR "$0 : error, failed to open output file '$OUTPUT_FILE', $!\n";
		print STDOUT perl2json($result);
	} else {
		print $FH perl2json($result);
		close $FH;
	}
} else {
	print STDOUT perl2json($result);
}
1;
__END__

### pod follows

=pod

=encoding utf8

=head1 NAME

json2perl.pl : convert JSON data to a Perl variable (dump) which can be parsed or eval'ed by any Perl script.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    json2perl.pl -i "input.json" -o "output.pl" --no-escape-unicode --terse --no-indent

    json2perl.pl -e < "input.json" > "output.pl"

    # press CTRL-D when done typing JSON to STDIN
    # input must be less than 4K long!
    json2perl.pl

    # Read input from clipboard or write output to clipboard
    # Only in: Unix / Linux / OSX
    # (must have already installed xclip or xsel or pbpaste (on OSX))
    json2json.pl -e < $(xclip -o)
    json2json.pl -e < $(pbaste)
    # write the output to the clipboard for further pasting
    json2json.pl -i input.json | xclip -i
    # clicking mouse's middle-button will paste the result

=head1 USAGE

C<json2perl.pl>

Options:

=over 4

=item * C<--i filename> : specify a filename which contains a JSON
data structure.

=item * C<--I "string"> : specify a string  which contains a JSON
data structure.

=item * C<--o outputfilename> : specify the output filename to write
the result to, which will be as a Perl variable, as a dump,
which can be parsed or eval'ed from any Perl script.

=item * C<--escape-unicode> : it will escape all unicode characters, and
convert them to something like "\u0386". This is the default option.

=item * C<--no-escape-unicode> : it will NOT escape unicode characters. Output
will not contain "\u0386" or "\x{386}" but "α" (that's a greek alpha).

=item * C<--terse> / C<--no-terse> : Terse form of output (no $VAR1 for example).
The second is the default option.

=item * C<--indent> / C<--no-indent> : do not use indentation. The first is the default option.

=back

Input can be read from an input file (--i), from a string at the
command line (--I) (properly quoted!), from STDIN (which also includes
a file redirection C<< json2perl.pl < inputfile.json > outputfile.perl >>

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
