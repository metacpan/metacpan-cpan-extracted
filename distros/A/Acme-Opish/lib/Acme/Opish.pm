# $Id: Opish.pm,v 1.2 2003/09/28 08:50:37 gene Exp $

package Acme::Opish;

use vars qw($VERSION);
$VERSION = '0.0601';

use strict;
use Carp;
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT = @EXPORT_OK = qw(
    enop
    has_silent_e
    no_silent_e
);
use File::Basename;

# no_silent_e list {{{
my %OK; @OK{qw(
    adobe
    acme
    acne
    anime
    antistrophe
    apostrophe
    be
    breve
    Brule
    cabriole
    cache
    Calliope
    capote
    Catananche
    catastrophe
    clave
    cliche
    consomme
    coyote
    diastrophe
    epanastrophe
    epitome
    forte
    Giuseppe
    kamikaze
    karate
    me
    misogyne
    Pele
    phlebotome
    progne
    Psyche
    psyche
    Quixote
    recipie
    Sade
    Salome
    saute
    stanze
    supercatastrophe
    Tempe
    tousche
    tsetse
    tonsillectome
    tonsillotome
    tracheotome
    ukulele
    we
    zimbabwe
)} = undef;
# }}}

# Add 'no_silent_e' entries if present and then return the list.
sub no_silent_e {
    $OK{$_} = undef for @_;
    return keys %OK;
}

# Remove'no_silent_e' entries if present and then return the list.
sub has_silent_e {
    delete $OK{$_} for @_;
    return keys %OK;
}

# Prefix vowels not declared in the 'no_silent_e' list.
sub enop {
    my $prefix = 'op';
    # If present, the prefix is given as a named parameter.
    if ($_[0] eq '-opish_prefix') {
        shift;
        $prefix = shift;
    }

    # Process the given text stream.
    my @strings = @_;
        # Given as a known system filename.
    for (@strings) {  # {{{
        if (-f) {
            # Open the file for reading.
            open IN, $_ or carp "Can't read $_: $!\n";

            # Construct a new filename.
            my ($name, $path) = fileparse($_, '');
            $_ = $path . 'opish-' . $name;

            # Open the new file for writing.
            open OUT, ">$_" or carp "Can't write $_: $!\n";

            # Write opish to the file.
            while (my $line = <IN>) {
                print OUT _to_opish($prefix, $line), "\n";
            }

            # Close the files.
            close IN;
            close OUT;
        }  # }}}
        # ..or given as strings on the commandline.
        else {
            $_ = _to_opish($prefix, $_);
        }
    }

    return @strings;
}

# DrMath++ && DrForr++ && Yay!
sub _to_opish {
    my ($prefix, $string) = @_;

    # XXX Oof.  We don't preserve whitespace.  : \
    my @words = split /\s+/, $string;

    # Process each word as a unit.
    for (@words) {
        # Is this word capitalized?
        my $is_capped = /^[A-Z]/ ? 1 : 0;
        # Lowercase the first letter in case we have to prefix it.
        $_ = lcfirst;

        # Okay.  Prefix the sucka.
        # XXX Ack.  How can I simplify this ugliness?
        if (exists $OK{ lc $_ }) {  # {{{
            s/
                (                   # Capture...
                    [aeiouy]+       # consecutive vowels
                    \B              # that do not terminate at a word boundry
                    (?![aeiouy])    # that are not followed by another vowel
                    |               # or
                    [aeiouy]*       # any consecutive vowels
                    [aeiouy]        # with any vowel following
                    \b              # that terminates at a word boundry.
                )                   # ...end capture.
            /$prefix$1/gisx;        # Add 'op' to what we captured.
        }  # }}}
        # Special case 'ye'.
        elsif (lc ($_) eq 'ye') {
            $_ = 'y' . $prefix . substr ($_, -1);
        }  
        # We don't want to prefix a non-vowel y.
        elsif (/^y[aeiouy]/i) {  # {{{
            s/
                (?:^y)?             # Our string starts with y, but we don't
                                    # want to consider it for every match.
                (                   # Capture...
                    [aeiouy]+       # consecutive vowels
                    \B              # that do not terminate at a word boundry
                    (?![aeiouy])    # that are not followed by another vowel
                    |               # or
                    [aeiouy]*       # any consecutive vowels
                    [aiouy]         # with any non-e vowel following
                    \b              # that terminates at a word boundry.
                    |               # or
                    [aeiouy]+       # consecutive vowels
                    [aeiouy]        # with any vowel following
                    \b              # that terminates at a word boundry.
                )                   # ...end capture.
            /$prefix$1/gisx;        # Add 'op' to what we captured.

            $_ = 'y' . $_;
        }  # }}}
        # This regexp captures the "non-solitary, trailing e" vowels.
        else {  # {{{
            s/
                (                   # Capture...
                    [aeiouy]+       # consecutive vowels
                    \B              # that do not terminate at a word boundry
                    (?![aeiouy])    # that are not followed by another vowel
                    |               # or
                    [aeiouy]*       # any consecutive vowels
                    [aiouy]         # with any non-e vowel following
                    \b              # that terminates at a word boundry.
                    |               # or
                    [aeiouy]+       # consecutive vowels
                    [aeiouy]        # with any vowel following
                    \b              # that terminates at a word boundry.
                )                   # ...end capture.
            /$prefix$1/gisx;        # Add 'op' to what we captured.
        }  # }}}

        # The original word was capitalized.
        $_ = ucfirst if $is_capped;
    }

    # Return the words as a single space separated string.
    # XXX Again, oof.  We don't preserve whitespace.  : \
    return join ' ', @words;
}

1;
__END__

=head1 NAME

Acme::Opish - Prefix the audible vowels of words

=head1 SYNOPSIS

  use Acme::Opish;

  print enop('Hello Aeryk!');
  # Hopellopo Opaeropyk! 

  @opped = enop('five', 'yellow', '/literature/Wuthering_Heights.txt');
  # fopive, yopellopow, /literature/opish-Wuthering_Heights.txt

  @opped = enop('xe', 'ze'));       # xe, ze
  @words = no_silent_e('xe', 'ze');
  @opped = enop('xe', 'ze');        # xope, zope
  @words = has_silent_e('xe', 'ze');
  @opped = enop('xe', 'ze');        # xe, ze

  # Okay.  Why not add anything you want, instead of "op"?
  print enop(-opish_prefix => 'ubb', 'Foo bar?');
  # Fubboo bubbar?

=head1 DESCRIPTION

Convert words to Opish, which is similar to "Ubish", but infinitely 
cooler.

More accurately, this means, add an arbitrary prefix to the vowel 
groups of words, except for the "silent e" and "starting, non-vowel 
y's".

Note: This module capitalizes words like you would expect.  Maybe a 
couple examples will elucidate this point:

  enop('Abc') produces 'Opabc'
  enop('abC') produces 'opabC'

Unfortunately, this function, currently converts consecutive spaces 
and newlines into single spaces and newlines.  Yes, this is not a 
feature, but a bug.

* See the eg/ directory for examples.

=head1 EXPORT

=head2 enop [-opish_prefix => STRING,] ARRAY

Convert strings or entire text files to opish.

If a member of the given array is a string, it is converted to opish.
If it is an existing text file, it is opened and converted to opish, 
and then saved as "opish-$filename".

If the first member of the argument list is "-opish_prefix", then the 
next argument is assumed to be the user defined prefix to use in 
place of "op".

=head2 no_silent_e ARRAY

Add the given arguments to the list of words that are to be 
converted without regard for the "silent e".

This function returns the keys in the "not silent e" list.

=head2 has_silent_e ARRAY

Delete the given arguments from the list of words that are to be
converted with regard for the "silent e".

This function returns the keys in the "not silent e" list.

=head1 TO DO

Make this thing preserve contiguous whitespace.

Go in reverse.  That is "deop" text.

Add more "non-silent-e" words to the "OK" list.

=head1 THANK YOU

DrForr (A.K.A. Jeff Goff) and DrMath (A.K.A. Ken Williams)

=head1 DEDICATION

Hopellopo Opaeropyk!

=head1 AUTHOR

Gopene Bopoggs, E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gopene Bopoggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
