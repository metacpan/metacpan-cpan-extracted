#!/usr/bin/perl -w
use 5.006;
use strict;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.07';

=head1 NAME

part - split up a single input file into multiple files according to a column value

=head1 SYNOPSIS

    # Split a comma separated file according to the third column
    # keeping and reproducing one line of headers
    perl -w part.pl example.csv --header-line=1 --column=3 "--separator=,"

    # Split a tab separated file according to the second column
    perl -w part.pl example.tsv --column=2 --separator=009

=head1 OPTIONS

=over 4

=item B<--out> - set the output template

If the output template is not given it is guessed from
the name of the first input file or set to C<part-%s.txt>.
The C<%s> will be replaced by the column value.

=item B<--column> - set the column to part on

This is the zero-based number of the column.
Multiple columns may be given.

=item B<--separator> - set the column separator

This is the separator for the columns. It defaults
to a tab character ("\t").

=item B<--header-line> - output the first line into every file

This defines the line as header line which is output
into every file. If it is given an argument that string
is output as header, otherwise the first line read
will be repeated as the header.

If the value is a number, that many lines will be read from
the file and used as the header. This makes it impossible
to use just a number as the header.

=item B<--verbose> - output the generated filenames

In normal operation, the program will be silent. If you
need to know the generated filenames, the C<--verbose>
option will output them.

=item B<--filename-sep> - set the separator for the filenames

If you prefer a different separator for the filenames
than a newline, this option allows you to set it. If
the separator looks like an octal number (three digits)
it is interpreted as such. Otherwise it will
be taken literally. A common
use is to set the separator to C<000> to separate the
files by the zero character if you suspect that your
filenames might contain newlines.

It defaults to C<012>, a newline.

=item B<--version> - output version information

=back

=head1 CAVEAT

The program loads the whole input into RAM
before writing the output. A future enhancement
might be a C<uniq>-like option that tells the
program to assume that the input will be grouped
according to the parted column so it does not
need to allocate memory.

If your memory is not large enough, the following
C<awk> one-liner might help you:

    # Example of parting on column 3
    awk -F '{ print $0 > $3 }' FILE

=head1 REPOSITORY

The public repository of this program is
L<https://github.com/Corion/app-part>.

=head1 SUPPORT

The public support forum of this program is
L<https://perlmonks.org/>. The homepage is
L<https://perlmonks.org/?node_id=598718> .

=head1 BUG TRACKER

Please report bugs via L<https://perlmonks.org>.

=head1 AUTHOR

Copyright (c) 2007-2019 Max Maischein (C<< corion@cpan.org >>)

=cut

GetOptions(
    'out=s'             => \my $tmpl,
    'column=i'          => \my @col,
    'separator=s'       => \my $sep,
    'verbose'           => \my $verbose,
    'filename-sep=s'    => \my $filename_sep,
    'header-line:s'     => \my $header,
    'help'              => \my $help,
    'version'           => \my $version,
) or pod2usage(2);
pod2usage(1) if $help;
if (defined $version) {
    print "$VERSION\n";
    exit 0;
};
pod2usage("$0: No files given.")  if ((@ARGV == 0) && (-t STDIN));

if (! defined $tmpl) {
    # Let's hope we can guess from the first filename
    my $placeholder = '-%s' x @col;
    ($tmpl = $ARGV[0] || 'part.txt') =~ s/\.(\w+)$/$placeholder.$1/;
};

if (! defined $sep) {
    $sep = "\t";
};

$filename_sep ||= "012";
if ($filename_sep =~ /^\d{3}$/) {
    $filename_sep = chr oct $filename_sep
};

my %lines;
if (defined $header) {
    $header ||= 1;
    if ($header =~ /^\d+$/) {
        my $count = $header;
        $header = "";
        $header .= <>
            while $count--;
    };
};

while (<>) {
    s/\r?\n$//;
    my @c = split /$sep/o;
    my $key = join $sep, @c[ @col ];
    if (not defined $lines{ $key }) {
        $lines{ $key } ||= [];
    };
    push @{ $lines{$key}}, $_
}

for my $key (sort keys %lines) {
    my @vals = split /$sep/o, $key;
    my $name = sprintf $tmpl, @vals;
    open my $fh, ">", $name
        or die "Couldn't create '$name': $!";
    if ($header) {
        print {$fh} $header;
    }
    print "$name$filename_sep"
        if $verbose;
    print {$fh} "$_\n"
        for (@{ $lines{ $key }});
};
