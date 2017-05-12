package App::Bernard;

use 5.005;
use strict;
use warnings;

use Lingua::EN::Alphabet::Shaw;

use Getopt::Long;

our $VERSION = 0.01;

################################################################

my %settings = (
    output => undef,
    script => 'shaw',
    inplace => 0,
    names => undef,
    input => undef,
    help => 0,
    check => 0,
    magic => 'single',
    expression => [],
    # "underscore" doesn't have an
    # associated command-line option
    underscore => 0,
    definelist => [],
    defines => {},
    );

sub parse_command_line {
    GetOptions(
	'o|output=s'      => \$settings{'output'},
	's|script=s'      => \$settings{'script'},
	'i|in-place'      => \$settings{'inplace'},
	'n|names=s'       => \$settings{'names'},
	'h|?|help'        => \$settings{'help'},
	'c|check'         => \$settings{'check'},
	'm|magic=s'       => \$settings{'magic'},
	'e|expression=s@' => \$settings{'expression'},
	);

    if (scalar(@ARGV)==0) {
	$settings{'help'} = 1 unless $settings{'expression'};
    } elsif (scalar(@ARGV)>1) {
	die "Can work on at most one file at once\n";
    } else {
	$settings{'input'} = $ARGV[0];
    }

    if ($settings{'inplace'}) {
	die "--in-place cannot be used with --output\n"
	    if $settings{'output'};
	
	die "--in-place cannot be used with standard input\n"
	    unless $settings{'input'};

	$settings{'output'} = $settings{'input'}.'.'.rand();
    }

    my %known_alphabets = ( latn=>1, shaw=>1 );
    $settings{'script'} = lc $settings{'script'};

    die "Alphabet $settings{'script'} is unknown\n"
	unless defined $known_alphabets{$settings{'script'}};

    die "Can't check standard output\n"
	if $settings{'check'} && !defined($settings{'output'});

    if ($settings{'help'}) {
	if (system("man bernard")!=0) {
	    print "Sorry, I can't launch the help program.\n";
	}
	exit;
    }
}

################################################################

sub print_expressions {
    for my $expression (@{$settings{'expression'}}) {
	print $settings{'transliterate'}->($expression), "\n";
    }

    exit if scalar(@ARGV)==0;
}

################################################################


sub execute {

    binmode STDOUT, ":utf8";

    parse_command_line();

    if ($settings{'script'} eq 'latn') {
	$settings{'transliterate'} = sub {
	    my ($text) = @_;
	    return $text;
	};
    } else {
	my $leas = Lingua::EN::Alphabet::Shaw->new();

	$settings{'transliterate'} = sub {
	    my ($text) = @_;

	    $settings{'underscore'} = 0 if $text =~ /%\(/;

	    if ($settings{'underscore'}) {
		$text =~ s/_/_ /g;
		$text =~ s/([a-z]+)_ ([a-z]+)/_ $1$2/gi;
	    }

	    for my $lhs (keys(%{$settings{'defines'}})) {
		my $rhs = $settings{'defines'}->{$lhs};
		$text =~ s/\b$lhs\b/$rhs/gi;
	    }

	    # split out Python interpolation
	    my @text = split /(%\([^)]*\)[^a-z]*[a-z])/, $text;

	    $text = $leas->transliterate(@text);

	    if ($settings{'underscore'}) {
		$text =~ s/_ /_/g;
	    }

            return $text;
        };
    }

    print_expressions();

    # now do the magic

    my $magic = undef;
    my $m = lc $settings{'magic'};
    my $pkg = "App::Bernard::Magic::\u$m";

    eval {
	my $filename = $pkg;
	$filename =~ s!::!/!g;
	require "$filename.pm";

	$magic = $pkg->new();
    };

    if ($@) {
       die "Magic $settings{'magic'} is not known\n"
	   if $@ =~ /Can't locate/;
       die "Error in loading magic $settings{'magic'}: $@\n";
    }

    $magic->handle(\%settings)
	if $magic;
}

1;

=head1 NAME

bernard - alphabet remix

=head1 AUTHOR

Thomas Thurman <thomas@thurman.org.uk>

=head1 SYNOPSIS

  bernard <source> -o <target>

=head1 DESCRIPTION

bernard takes files written in the conventional alphabet and
returns them written in some other alphabet.

At present, only the Shavian alphabet is supported.

=head1 SWITCHES

=head2 -o <filename>, --output <filename>

Select output file.  If this is not specified,
the output is written to the standard output.

=head2 -s <alphabet>, --script <alphabet>

Select alphabet.  Use the ISO 15924 code.
This is not case-sensitive.
The only arguments currently accepted are "Shaw",
which represents the Shavian alphabet, and
"Latn", which causes no transformation to
the input text.

=head2 -S <alphabet>, --source <alphabet>

Specifies the alphabet of the source document.
The default is C<"Latn">.  This is not automatically
detected, because the use-cases are so different.
This is not case-sensitive.
The only two values allowed are C<"Latn"> and C<"Shaw">.
Selecting C<"Shaw"> will allow you to transliterate
a document in Shavian into, for example, Deseret.

If C<"Shaw"> is selected, this has the additional
effect of causing I<every> stanza in a .po file
to be transliterated, not only the fuzzy and empty
ones.  It also disables the C<--in-place> switch.

Selecting the same source and target alphabet is
a valid choice, but means that there will be
no change between input and output.

It is currently an error to select C<"Shaw"> as
the source alphabet and C<"Latn"> as the target
alphabet.  In other words, you can't yet undo
a transliteration into Shavian.  This may be
added one day.

This entire option is not yet implemented.

=head2 -n <file>, --names <file>

This switch only makes sense with gettext .po files.
It means that the msgids in the file are not English
strings, but identifiers, and that the English strings
are in the .po file whose name is supplied.  This is
often found in Nokia catalogues.

This is not yet implemented.

=head2 -c, --check

Runs the resulting file through C<"msgfmt -c"> to check
its validity.

=head2 -i, --in-place

This writes the output file over the top of the
input file.

This switch is only useful with gettext .po files.
It is disabled for other filetypes because it would
be dangerous: you would lose the original text.

=head2 -a, --armour

This replaces Shavian letters with their traditional
ASCII equivalents.  It is disabled for other alphabets.
This will cause obvious difficulties if the output
would ordinarily contain Latin-alphabet letters.
Latin-alphabet letters discovered in the text will be
retained.

This is not currently implemented.

The inverse operation is obtained by using
C<-m unarmour>.

=head2 -D, --shift-down

This is a nasty hack.  It shifts the letters of the
output alphabet down so that they begin at codepoint
128.  This is needed because of shortcomings in
the UTF-8 decoding of some programs, and when you
may be unable to use C<-a> because you need to include
characters from both alphabets.  You will, of
course, need a special font with the relevant glyphs
at these non-standard positions.

This is not currently implemented.

=head2 -e <text>, --expression <text>

Transliterates the given expression.  This is
output before any other file.

=head2 -U, --update

Checks to see whether there's an updated version
of the Shavian set used for transliteration, and
downloads it if there is.

This is not currently implemented.

=head2 -m <magic>, --magic <magic>

Selects an alternative mode of operation.  The
defalt is C<single>, which behaves as described
above.  Other values have other effects,
described in "Magic modes", below.

=head2 -p, --apostrophe

George Bernard Shaw believed that apostrophes,
which he called "uncouth bacilli", were redundant.
In honour of this opinion, the C<-p> option
strips apostrophes from the transliterated
output where they occur within words.  The rare
apostrophes at the beginnings or endings of words
(as in C<'tis>) will not be stripped, in case
you use them for quotation marks.

This is not currently implemented.

=head2 -D, --define

This allows you to define the Shavian spelling of
a word temporarily.  Its argument is the
Latin-alphabet spelling, followed by an equals sign,
followed by the Shavian spelling.  In case
you cannot type Shavian letters, you may use the
standard ASCII-armouring.  For example, to cause
the word "of" to be written out in full, rather
than as a single-letter abbreviation, use C<-Dof=ov>.

This is not currently implemented.


=head1 MAGIC MODES

These are selected using the C<-m> or C<--magic>
switch.

=head2 single

This is the default, and behaves as described above.

=head2 gnome

In this mode, the sole non-option argument should be
the name of a Shavian .po file.  The master template
for that package will be downloaded and merged with
the .po file, the transliterations will be updated,
and then run through C<msgfmt -c> to check them.

Alternatively, the non-option argument may be the
name of a directory.  Each subdirectory of this
directory should contain a GNOME package, which
contains a file C<po/en@shaw.po>.  Each of these
files will be acted on as described in the previous
paragraph.

=head2 unarmour

This undoes the effect of the C<-a> or C<--armour>
switch.  The single non-option argument is a file,
which is output verbatim except that characters from
the Latin alphabet will be replaced with their
corresponding values in the old Shavian-to-Latin
mapping.

This is not currently implemented.

=head1 BUGS

Probably many.

Code to update the Shavian transliteration of Firefox
exists, but has not yet been merged into C<bernard>.
It will be merged at some point.

It will also be possible later to translate
Qt's C<.ts> files.

Code to handle C<.srt> subtitle files exists,
but has not yet been merged.

It doesn't handle any other alphabets than Shavian
and the conventional alphabet.  At least Deseret
will be added.

There are several other planned features which are
as yet unimplemented.

=head1 COPYRIGHT

This Perl module is copyright (C) Thomas Thurman, 2010.
This is free software, and can be used/modified under the same terms as
Perl itself.

