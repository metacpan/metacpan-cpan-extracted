#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2025, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.020000;

BEGIN { our $VERSION = q{v0.0.2}; }

use Convert::ModHex qw(hex2modhex);
use English         qw( -no_match_vars );
use File::Basename;

use Getopt::Long;
use HTTP::Status qw(HTTP_OK);
use HTTP::Tiny;
use Lingua::EN::Inflexion qw(inflect);
use List::Uniq            qw(uniq);
use Log::Log4perl         qw(:easy get_logger);
use Math::Base::Convert   qw(basemap cnv hex);
use Pod::Usage::CommandLine;
use Pod::Usage;
use Readonly;
use String::Pad qw(pad);
use Text::Hunspell;

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY    => q{};
Readonly::Scalar my $SPACE    => q{ };
Readonly::Scalar my $NL       => qq{\n};
Readonly::Scalar my $PAD_LEFT => q{left};

Readonly::Scalar my $DICE_SIDES     => 6;
Readonly::Scalar my $DICEWARE_ROLLS => 5;
Readonly::Scalar my $REQUIRED_WORDS => $DICE_SIDES**$DICEWARE_ROLLS;

Readonly::Scalar my $COIN_SIDES         => 2;
Readonly::Scalar my $DICEWARE_COINFLIPS => 13;
Readonly::Scalar my $REQUIRED_WORDS_8K  => $COIN_SIDES**$DICEWARE_COINFLIPS;

Readonly::Scalar my $DEFAULT_MIN_LENGTH => 5;
Readonly::Scalar my $DEFAULT_MAX_LENGTH => 10;

Readonly::Scalar my $MODHEX => Convert::ModHex::hex2modhex( join $EMPTY,
    sort uniq map { lc } keys %{ basemap(hex) },
);

Readonly::Scalar my $FILE => $FindBin::Bin
  . q{../lib/Crypt/Diceware/Wordlist/TR/ModHex.pm};
Readonly::Scalar my $HUNSPELL_AFFIX_PATTERN => q{/usr/share/hunspell/%s.aff};
Readonly::Scalar my $HUNSPELL_DICTIONARY_PATTERN =>
  q{/usr/share/hunspell/%s.dic};
Readonly::Scalar my $URL_PATTERN =>
  q{https://raw.githubusercontent.com/hermitdave/FrequencyWords/refs/heads/}
## no critic (RequireInterpolationOfMetachars)
  . q{master/content/2016/%1$s/%1$s_full.txt};

Readonly::Hash my %BC => (
    'DICE' => Math::Base::Convert->new( ( 10, [ 1 .. 6 ] ) ),
    'COIN' => Math::Base::Convert->new( ( 10, [ 0 .. 1 ] ) ),
);

Readonly::Scalar my $LOG_CONF => q{diceware_modhex_wordlist_log.conf};
Readonly::Array my @DEBUG_LEVELS => ( $FATAL, $INFO, $WARN, $DEBUG );

Readonly::Hash my %LOG => (
    'SHORT_LIST' =>
      q{Only <#:%i> <N:words> could be generated, this is not enough for a }
      . q{wordlist that needs <#:%i> <N:words>},
    'NO_SPELLER' => q{Could not create a spell checker. Is hunspell installed?},
    'NO_SPELLER_FILES' =>
q{Could not create a spell checker using "%s" as affix and "%s" as dictionary},
    'NO_PRINT' => q{Could not print},
);

Readonly::Array my @GETOPTIONS => (
    q{verbose|v+},       q{language|l=s},
    q{machine-friendly}, q{min:i},
    q{max:i},            q{no-rolls},
    q{shorter},          q{update}
);
Readonly::Array my @GETOPT_CONFIG =>
  qw(no_ignore_case bundling auto_version auto_help);
Readonly::Hash my %OPTS_DEFAULT => (
    'language' => q{tr_TR},
    'min'      => $DEFAULT_MIN_LENGTH,
    'max'      => $DEFAULT_MAX_LENGTH,
);
## use critic
Getopt::Long::Configure(@GETOPT_CONFIG);
my %opts = %OPTS_DEFAULT;
Getopt::Long::GetOptions( \%opts, @GETOPTIONS ) or Pod::Usage::pod2usage(2);

if ( -r $LOG_CONF ) {
## no critic qw(ProhibitCallsToUnexportedSubs)
    Log::Log4perl::init_and_watch($LOG_CONF);
## use critic
}
else {
## no critic qw(ProhibitCallsToUnexportedSubs)
    Log::Log4perl::easy_init($ERROR);
## use critic
}
my $log = Log::Log4perl->get_logger( File::Basename::basename $PROGRAM_NAME );
$log->level(
    $DEBUG_LEVELS[
      (
          ( $opts{'verbose'} || 0 ) > $#DEBUG_LEVELS
          ? $#DEBUG_LEVELS
          : $opts{'verbose'}
      )
      || 0
    ],
);
## use critic

sub _logdie {
    return $log->logdie( inflect(shift) );
}

my $affix      = sprintf $HUNSPELL_AFFIX_PATTERN,      $opts{'language'};
my $dictionary = sprintf $HUNSPELL_DICTIONARY_PATTERN, $opts{'language'};
my $speller;
if ( -r $affix && -r $dictionary ) {
    $speller = Text::Hunspell->new( $affix, $dictionary )
      // _logdie( sprintf $LOG{'NO_SPELLER'} );
}
else {
    _logdie( sprintf $LOG{'NO_SPELLER_FILES'}, $affix, $dictionary );
}

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $MODHEX_WORD =>
## use critic
  qr{\b(?<modhex_word>[$MODHEX]{$opts{'min'},$opts{'max'}})\b}imsx;
my $required_words =
  $opts{'machine-friendly'} ? $REQUIRED_WORDS_8K : $REQUIRED_WORDS;
my %words = ();
my $response;

sub need_more_words {
## no critic (ProhibitParensWithBuiltins)
    return $opts{'shorter'} || scalar keys %{ shift() } < $required_words;
## use critic
}

sub cf_handle_chunk {
    my $resp = shift;
    return sub {
        my ( $chunk, $hr_response ) = @_;
        if ( need_more_words( \%words )
            && ${$hr_response}{'status'} == HTTP::Status::HTTP_OK )
        {
            while (
                need_more_words( \%words )
## no critic (:ProhibitUselessRegexModifiers)
                && $chunk =~ /$MODHEX_WORD/gmsx
              )
## use critic
            {
                my $word = $LAST_PAREN_MATCH{'modhex_word'};
                if (
                    ## no critic (ProhibitAccessOfPrivateData)
                    $speller->check($word)
                    ## use critic
                    && !exists $words{$word}
                  )
                {
                    $words{$word} = $word;
                }
            }
        }
        else {
            $resp = undef;
        }
        return;
    };
}

sub short_language {
    my $lang = substr shift, 0, 2;
    if ( q{nn} eq $lang ) {
        $lang = q{no};
    }
    return $lang;
}

sub get_url {
    return sprintf $URL_PATTERN, short_language(shift);
}

sub index2rolls {
    my $index = shift;
    my $mode  = q{DICE};
    my $size  = $DICEWARE_ROLLS;
    if ( $opts{'machine-friendly'} ) {
        $mode = q{COIN};
        $size = $DICEWARE_COINFLIPS;
    }
    return pad( int $BC{$mode}->cnv($index),
        $size, $PAD_LEFT, int $BC{$mode}->cnv(0) );
}

$response = HTTP::Tiny->new()->get(
    get_url( $opts{'language'} ),
    {
        'data_callback' => cf_handle_chunk($response),
    },
);

if ( my $amount = keys %words < $required_words ) {
    _logdie( sprintf $LOG{'SHORT_LIST'}, $amount, $required_words );
}

my $sum = 0;
my $min = q{Inf};
my $max = q{-Inf};

sub report {
    my $word = shift;
    my $len  = length $word;
    $sum += $len;
    $len < $min && ( $min = $len );
    $len > $max && ( $max = $len );
    return $word;
}

my @words =
  map { report $_ } sort grep { state $c; $c++ < $required_words } sort {
    $opts{'shorter'}
      ? ( length $a <=> length $b ) || ( $a cmp $b )
      : ( $a cmp $b )
  } values %words;
my $avg = $sum / @words;

my $module   = $EMPTY;
my $wordlist = $EMPTY;
if ( $opts{'update'} ) {
    unshift @ARGV, $FILE;
    while ( my $line = <> ) {
        $module .= $line;
    }
}
while ( my ( $i, $word ) = each @words ) {
    if ( 0 == $i ) {
        my $header = $EMPTY;
        while (<DATA>) {
            $header .= $_;
        }
        my $banner = sprintf $header, ${$response}{'url'},
          $opts{'language'}, scalar @words, $min, $max, $avg;
        if ( $opts{'update'} ) {
            $wordlist .= $banner;
        }
        else {
            print $banner or _logdie( $LOG{'NO_PRINT'} );
        }
    }
    my $roll = $opts{'no-rolls'} ? $EMPTY : ( index2rolls( $i++ ) . $SPACE );
    if ( $opts{'update'} ) {
        $wordlist .= $roll . $word . $NL;
    }
    else {
        say $roll . $word or _logdie( $LOG{'NO_PRINT'} );
    }
}
if ( $opts{'update'} ) {
    $module =~ s{(.*__DATA__\s*).*}{$1$wordlist}gimsx;
    binmode STDOUT, ':encoding(UTF-8)';
    my $fh;
    open $fh, '>', $FILE;
    print {$fh} $module
## no critic (RequireUseOfExceptions)
      or die "can't print to file, $ERRNO\n";
## use critic
    close $fh;
}

## no critic (RequirePodAtEnd)

=pod

=head1 NAME

diceware_modhex_wordlist.pl

=head1 DESCRIPTION

Generates a list of words for Diceware using only ModHex characters.

=head1 USAGE

diceware_modhex_wordlist.pl [--language|-l tr_TR] [--machine-friendly]
[--no-rolls] [--min 5] [--max 10] [--shorter] [--update|u]
[--version] [--verbose|-v] [--help]

=head1 REQUIRED ARGUMENTS

None.

=head1 OPTIONS

=over 4

=item * --language -l

The language of the words in the wordlist as an ICU locale like C<da_DK>. The
chosen language should have a word frequency list on
L<https://github.com/hermitdave/FrequencyWords> and have support in Hunspell
installed. Default is C<tr_TR> because C<en_US> doesn't yield enough words for a
complete list.

=item * --machine-friendly

Generate a list of 8192 words instead of 7776 words. Diceware uses 7776 words to
map the result of a roll with five 6-sided dice - 6^5 = 7776 - to a word, but if
no dice are used a computer could use a list of 2^13 = 8192 words. This is also
how a word could be selected using 13 coinflips per word so the roll is then
shown as the result of 13 coinflips. Default it tries to generate 7776 words in
a list for use with five dice.

=item * --no-rolls

Do not prepend the words with the set of dice rolls or coin flips. When the list
is not used to manually map the rolls to words they might be omitted if software
using the list only handles the words. Default the rolls are included.

=item * --min

The minimum length of the words selected for the list. Short words in a list
could weaken a passphrase when a combination of short words lead to a short
passphrase that can be cracked more easily than the used entropy of the Diceware
method to generate the passphrase suggests. Default 5.

=item * --max

The maximum length of the words added to the list. Longer words are more
cumbersome to use in a passphrase but to get enough words in the list we have to
accept them up to some limit. Default 10.

=item * --shorter

Prefer shorter words over more frequently used words.

=item * --update

Update the wordlist used in the module instead of printing to standard output.

=item * --version

Print the version of this script.

=item * --verbose

Be more verbose.

=item * --help

Show help.

=back

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

To check if a word on a list is valid for the selected language it is checked by
the Hunspell spellchecker that must be installed on the system and have support
for the selected language installed.

=head1 DEPENDENCIES

L<Convert::ModHex>, L<English>, L<File::Basename>, L<Getopt::Long>,
L<HTTP::Status>, L<HTTP::Tiny>, L<Lingua::EN::Inflexion>, L<List::Uniq>,
L<Log::Log4perl>, L<Math::Base::Convert>, L<Pod::Usage::CommandLine>,
L<Pod::Usage>, L<Readonly>, L<String::Pad>, L<Text::Hunspell>

=head1 INCOMPATIBILITIES

Currently only the languages Danish (da_DK), Hungarian (hu_HU), Dutch (nl_NL),
Turkish (tr_TR) and their regional variants provide enough words containing only
ModHex characters to generate a list with enough words. Danish and Dutch require
a maximum length of 10 to provide enough words, Hungarian and Turkish require
only a maximum length of 9.

=head1 BUGS AND LIMITATIONS

Because the ModHex requirement already limits the number of allowed words
significantly it usually isn't possible to limit the list further to words that
aren't composites of each other and still get a list of 7776 words as a result.
Therefore the words in these wordlists require the use of spaces between the
words in a passphrase to avoid weakening the passphrase.

=head1 AUTHOR

Roland van Ipenburg <roland@rolandvanipenburg.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2025 Roland van Ipenburg.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

The wordlists generated by this program are based on FrequencyWords content
Copyright (c) 2016 Hermit Dave L<https://github.com/hermitdave/FrequencyWords>
CC-by-sa-4.0 L<https://creativecommons.org/licenses/by-sa/4.0/deed.en>

=cut

__DATA__
# Diceware ModHex wordlist generated by diceware_modhex_wordlist.pl by Roland van Ipenburg
# Wordlist content based on FrequencyWords content language resource
# %s
# Copyright (c) 2016 Hermit Dave
# CC-by-sa-4.0 https://creativecommons.org/licenses/by-sa/4.0/deed.en
# Language: %s; Words: %d; Min. length: %d; Max. length: %d; Avg. length: %.2f
