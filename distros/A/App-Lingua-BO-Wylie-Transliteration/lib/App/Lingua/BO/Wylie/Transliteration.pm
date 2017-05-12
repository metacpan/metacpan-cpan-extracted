package App::Lingua::BO::Wylie::Transliteration;
BEGIN {
  $App::Lingua::BO::Wylie::Transliteration::AUTHORITY = 'cpan:DBR';
}
{
  $App::Lingua::BO::Wylie::Transliteration::VERSION = '0.1.0';
}

use Moo;
use true;
use utf8;
use utf8::all;
use 5.010;
use strict;
use warnings;
use methods-invoker;
use MooX::Options skip_options => [qw<who cares>];
use MooX::Types::MooseLike::Base qw(:all);

no autovivification;

has [qw< SUPERSCRIPT SUBSCRIPT PRESCRIPT SCRIPT SCRIPT_SUBJ POSTSCRIPT1 POSTSCRIPT2 VOWEL > ] => (
    is => 'lazy',
    isa => HashRef,
);

has [qw< SUPERSCRIPT_RX SUBSCRIPT_RX PRESCRIPT_RX SCRIPT_RX SCRIPT_SUBJ_RX POSTSCRIPT1_RX POSTSCRIPT2_RX VOWEL_RX > ] => (
    is => 'lazy',
    isa => RegexpRef,
);

has scheme => (
    is => 'lazy',
    isa => RegexpRef,
);

method _build_PRESCRIPT {+{
    G => "\N{TIBETAN LETTER GA}",
    D => "\N{TIBETAN LETTER DA}",
    P => "\N{TIBETAN LETTER PA}",
    M => "\N{TIBETAN LETTER MA}",
    B => "\N{TIBETAN LETTER BA}",
    "'" => "\N{TIBETAN LETTER -A}",    # special (for later)
}};

method _build_SUPERSCRIPT {+{
    R => "\N{TIBETAN LETTER RA}",
    S => "\N{TIBETAN LETTER SA}",
    L => "\N{TIBETAN LETTER LA}",
}};

method _build_SUBSCRIPT { +{
    R => "\N{TIBETAN SUBJOINED LETTER RA}",
    L => "\N{TIBETAN SUBJOINED LETTER LA}",
    Y => "\N{TIBETAN SUBJOINED LETTER YA}",
    V => "\N{TIBETAN SUBJOINED LETTER WA}",    # can be w aswell
}};

method _build_SCRIPT {+{
    K    => "\N{TIBETAN LETTER KA}",
    KH   => "\N{TIBETAN LETTER KHA}",
    G    => "\N{TIBETAN LETTER GA}",
    GH   => "\N{TIBETAN LETTER GHA}",
    NG   => "\N{TIBETAN LETTER NGA}",
    C    => "\N{TIBETAN LETTER CA}",
    CH   => "\N{TIBETAN LETTER CHA}",
    J    => "\N{TIBETAN LETTER JA}",
    NY   => "\N{TIBETAN LETTER NYA}",
    TT   => "\N{TIBETAN LETTER TTA}",
    TTHA => "\N{TIBETAN LETTER TTHA}",
    DD   => "\N{TIBETAN LETTER DDA}",
    DDHA => "\N{TIBETAN LETTER DDHA}",
    NN   => "\N{TIBETAN LETTER NNA}",
    T    => "\N{TIBETAN LETTER TA}",
    TH   => "\N{TIBETAN LETTER THA}",
    D    => "\N{TIBETAN LETTER DA}",
    DH   => "\N{TIBETAN LETTER DHA}",
    N    => "\N{TIBETAN LETTER NA}",
    P    => "\N{TIBETAN LETTER PA}",
    PH   => "\N{TIBETAN LETTER PHA}",
    B    => "\N{TIBETAN LETTER BA}",
    BH   => "\N{TIBETAN LETTER BHA}",
    M    => "\N{TIBETAN LETTER MA}",
    TS   => "\N{TIBETAN LETTER TSA}",
    TSHA => "\N{TIBETAN LETTER TSHA}",
    DZ   => "\N{TIBETAN LETTER DZA}",
    DZHA => "\N{TIBETAN LETTER DZHA}",
    W    => "\N{TIBETAN LETTER WA}",
    ZH   => "\N{TIBETAN LETTER ZHA}",
    Z    => "\N{TIBETAN LETTER ZA}",
    ''   => "\N{TIBETAN LETTER -A}",
    Y    => "\N{TIBETAN LETTER YA}",
    R    => "\N{TIBETAN LETTER RA}",
    L    => "\N{TIBETAN LETTER LA}",
    SH   => "\N{TIBETAN LETTER SHA}",
    SS   => "\N{TIBETAN LETTER SSA}",
    S    => "\N{TIBETAN LETTER SA}",
    H    => "\N{TIBETAN LETTER HA}",

    KSSA => "\N{TIBETAN LETTER KSSA}",
}};

method _build_SCRIPT_SUBJ {+{
    K    => "\N{TIBETAN SUBJOINED LETTER KA}",
    KH   => "\N{TIBETAN SUBJOINED LETTER KHA}",
    G    => "\N{TIBETAN SUBJOINED LETTER GA}",
    GH   => "\N{TIBETAN SUBJOINED LETTER GHA}",
    NG   => "\N{TIBETAN SUBJOINED LETTER NGA}",
    C    => "\N{TIBETAN SUBJOINED LETTER CA}",
    CH   => "\N{TIBETAN SUBJOINED LETTER CHA}",
    J    => "\N{TIBETAN SUBJOINED LETTER JA}",
    NY   => "\N{TIBETAN SUBJOINED LETTER NYA}",
    TT   => "\N{TIBETAN SUBJOINED LETTER TTA}",
    TTHA => "\N{TIBETAN SUBJOINED LETTER TTHA}",
    DD   => "\N{TIBETAN SUBJOINED LETTER DDA}",
    DDHA => "\N{TIBETAN SUBJOINED LETTER DDHA}",
    NN   => "\N{TIBETAN SUBJOINED LETTER NNA}",
    T    => "\N{TIBETAN SUBJOINED LETTER TA}",
    TH   => "\N{TIBETAN SUBJOINED LETTER THA}",
    D    => "\N{TIBETAN SUBJOINED LETTER DA}",
    DH   => "\N{TIBETAN SUBJOINED LETTER DHA}",
    N    => "\N{TIBETAN SUBJOINED LETTER NA}",
    P    => "\N{TIBETAN SUBJOINED LETTER PA}",
    PH   => "\N{TIBETAN SUBJOINED LETTER PHA}",
    B    => "\N{TIBETAN SUBJOINED LETTER BA}",
    BH   => "\N{TIBETAN SUBJOINED LETTER BHA}",
    M    => "\N{TIBETAN SUBJOINED LETTER MA}",
    TS   => "\N{TIBETAN SUBJOINED LETTER TSA}",
    TSHA => "\N{TIBETAN SUBJOINED LETTER TSHA}",
    DZ   => "\N{TIBETAN SUBJOINED LETTER DZA}",
    DZHA => "\N{TIBETAN SUBJOINED LETTER DZHA}",
    W    => "\N{TIBETAN SUBJOINED LETTER WA}",
    ZH   => "\N{TIBETAN SUBJOINED LETTER ZHA}",
    Z    => "\N{TIBETAN SUBJOINED LETTER ZA}",
    # -A   => \N{TIBETAN LETTER -A}",
    Y    => "\N{TIBETAN LETTER YA}",
    R    => "\N{TIBETAN LETTER RA}",
    L    => "\N{TIBETAN LETTER LA}",
    SH   => "\N{TIBETAN LETTER SHA}",
    SS   => "\N{TIBETAN LETTER SSA}",
    S    => "\N{TIBETAN LETTER SA}",
    H    => "\N{TIBETAN LETTER HA}",
    #      => "\N{TIBETAN LETTER A}",
    KSSA => "\N{TIBETAN LETTER KSSA}",
     # => TIBETAN LETTER FIXED-FORM RA,
     # => TIBETAN LETTER KKA,
     # => TIBETAN LETTER RRA,
}};

method _build_POSTSCRIPT1 {+{
    G    => "\N{TIBETAN LETTER GA}",
    NG   => "\N{TIBETAN LETTER NGA}",
    D    => "\N{TIBETAN LETTER DA}",
    N    => "\N{TIBETAN LETTER NA}",
    B    => "\N{TIBETAN LETTER BA}",
    M    => "\N{TIBETAN LETTER MA}",
    W    => "\N{TIBETAN LETTER WA}",
    R    => "\N{TIBETAN LETTER RA}",
    L    => "\N{TIBETAN LETTER LA}",
    S    => "\N{TIBETAN LETTER SA}",

}};

method _build_POSTSCRIPT2 {+{
      G    => "\N{TIBETAN LETTER GA}",
      NG   => "\N{TIBETAN LETTER NGA}",
      D    => "\N{TIBETAN LETTER DA}",
      N    => "\N{TIBETAN LETTER NA}",
      B    => "\N{TIBETAN LETTER BA}",
      M    => "\N{TIBETAN LETTER MA}",
      W    => "\N{TIBETAN LETTER WA}",
      R    => "\N{TIBETAN LETTER RA}",
      L    => "\N{TIBETAN LETTER LA}",
      S    => "\N{TIBETAN LETTER SA}",
}};

method _build_VOWEL {+{
    A => "\N{TIBETAN VOWEL SIGN AA}",
    E => "\N{TIBETAN VOWEL SIGN E}",
    I => "\N{TIBETAN VOWEL SIGN I}",
    O => "\N{TIBETAN VOWEL SIGN O}",
    U => "\N{TIBETAN VOWEL SIGN U}",
}};


sub make_rx {
    my $hash = shift;
    $_ = join '|',
         sort  { length $b <=> length $a }
         keys %{ $hash };
    $_ = '(?:' . $_ . ')';
    return qr{$_}ix;
}

method _build_SUPERSCRIPT_RX { make_rx( $self->SUPERSCRIPT ) };
method _build_SUBSCRIPT_RX   { make_rx( $self->SUBSCRIPT   ) };
method _build_PRESCRIPT_RX   { make_rx( $self->PRESCRIPT   ) };
method _build_SCRIPT_RX      { make_rx( $self->SCRIPT      ) };
method _build_SCRIPT_SUBJ_RX { make_rx( $self->SCRIPT      ) };
method _build_POSTSCRIPT1_RX { make_rx( $self->POSTSCRIPT1 ) };
method _build_POSTSCRIPT2_RX { make_rx( $self->POSTSCRIPT2 ) };
method _build_VOWEL_RX       { make_rx( $self->VOWEL       ) };

method _build_scheme {
    qr"
      (?:

        (?<script> @{[ $self->SCRIPT_RX      ]}   )
        (?<sub>    @{[ $self->SUBSCRIPT_RX   ]} ? )
        (?<vowel>  @{[ $self->VOWEL_RX       ]}   )
        (?<post1>  @{[ $self->POSTSCRIPT1_RX ]} ? )
        (?<post2>  @{[ $self->POSTSCRIPT2_RX ]} ? )
      |
        (?<pre>    @{[ $self->PRESCRIPT_RX   ]} ? )
        (?<script> @{[ $self->SCRIPT_RX      ]}   )
        (?<sub>    @{[ $self->SUBSCRIPT_RX   ]} ? )
        (?<vowel>  @{[ $self->VOWEL_RX       ]}   )
        (?<post1>  @{[ $self->POSTSCRIPT1_RX ]} ? )
        (?<post2>  @{[ $self->POSTSCRIPT2_RX ]} ? )
      |
        (?<super>  @{[ $self->SUPERSCRIPT_RX ]} ? )
        (?<script> @{[ $self->SCRIPT_RX      ]}   )
        (?<sub>    @{[ $self->SUBSCRIPT_RX   ]} ? )
        (?<vowel>  @{[ $self->VOWEL_RX       ]}   )
        (?<post1>  @{[ $self->POSTSCRIPT1_RX ]} ? )
        (?<post2>  @{[ $self->POSTSCRIPT2_RX ]} ? )
      |
        (?<pre>    @{[ $self->PRESCRIPT_RX   ]} ? )
        (?<super>  @{[ $self->SUPERSCRIPT_RX ]} ? )
        (?<script> @{[ $self->SCRIPT_RX      ]}   )
        (?<sub>    @{[ $self->SUBSCRIPT_RX   ]} ? )
        (?<vowel>  @{[ $self->VOWEL_RX       ]}   )
        (?<post1>  @{[ $self->POSTSCRIPT1_RX ]} ? )
        (?<post2>  @{[ $self->POSTSCRIPT2_RX ]} ? )
      )
    "ix
};

method transliterate($word) {
    no strict;
    no warnings;
    my $output =
    $word =~ s( @{[$self->scheme]} )[
        my $o;
        my $pre    //= $+{pre    };
        my $super  //= $+{super  };
        my $sub    //= $+{sub    };
        my $script //= $+{script };
        my $vowel  //= $+{vowel  };
        my $post1  //= $+{post1  };
        my $post2  //= $+{post2  };

        # say "word  : $word  ";
        # say "pre   : $pre   ";
        # say "super : $super ";
        # say "script: $script";
        # say "sub   : $sub   ";
        # say "vowel : $vowel ";
        # say "post1 : $post1 ";
        # say "post2 : $post2 ";

        $o .= $self->PRESCRIPT   -> {uc $pre}     if defined $pre;
        $o .= $self->SUPERSCRIPT -> {uc $super}   if defined $super;
        $o .= $self->SCRIPT_SUBJ -> {uc $script}  if defined $script and     defined $super;
        $o .= $self->SCRIPT      -> {uc $script}  if defined $script and $super eq '';
        $o .= $self->SUBSCRIPT   -> {uc $sub}     if defined $sub;
        $o .= $self->VOWEL       -> {uc $vowel}   if defined $vowel and not uc($vowel) eq 'A';
        $o .= $self->POSTSCRIPT1 -> {uc $post1}   if defined $post1;
        $o .= $self->POSTSCRIPT2 -> {uc $post2}   if defined $post2;
      return $o;
    ]giex;

    return $output;
}

no Moo;

__END__

=pod

=head1 NAME

App::Lingua::BO::Wylie::Transliteration

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

Wylie transliterate can be used to transliterate words from Wylie Transliteration to (Classical) Tibetan (dbu med)

=for Pod::Coverage make_rx

=head1 BACKGROUND

When you have one (foreign) alphabet and would like to display it in a
different alphabet (example: Russian to Latin alphabet), you will
want to use a certain B<transliteration scheme>.

Just compare all the different names you can find "Dostojevski" transliterated
to, to see what enourmous differences there will be.

Now for the Classical Tibetan "dbu med" alphabet there exist two main
transliteration schemes:

=over

=item *

Library of Congress Transliteration

=item *

Wylie Transliteration

=back

Classical Tibetan alphabet itself works in a really interesting way.

First, let's have a look at the table of the individual "characters"
with their Wylie transliterations:

E<lt>http:E<sol>E<sol>en.wikipedia.orgE<sol>wikiE<sol>Tibetan_alphabetE<gt>

A few key observations:

=over

=item *

(Almost) all letters represent a consonant, carrying an B<inherent> vocal: "a"

=item *

These lettersE<sol>syllables are sorted according to tonality and aspiration (in pronunciation)

=item *

Other vocals will be achieved by adding certain vocal-symbols in the proper places:

=back

   * i.e. you can build the following syllables by adding a vowel sign:
     * ka -> ko
     * ka -> ku
     * ka -> ki
     * ka -> ke

The latter is a process of B<merging> symbols to form new symbols (with the
merging taking place in the proper places -- 'e' is on top, 'u' will be inserted
at the bottom)

This merging process can be seen as building "ligatures", of which even more exist.

As we have seen, the vocal symbols (for all vocals except 'a', which is inherent)
need to be added in the proper places.

For the rest of the symbols that can be added, the scheme looks the following:

         b  s  g   r   u   b  s
         |  |  |   |   |   |  |
         1  2  3   4   5   6  7

With the places being the following:

1) Prescript
2) Superscript
3) The Center piece (carriyng the inherent vocal, mandatory)
4) Subscript
5) The vocal sign
6) Postscript1
7) Postscript2

Note: Except from the Center piece (3), all other signs are optional.

Note: Optional character B<can> form B<ligatures> with the character they are combined with.

=head1 TECHNICAL BACKGROUND (UNICODE)

The Unicode consortium had to decide what they want their code points to look like:

a) either each altered base syllable is represented (i.e. ka, ko, ke, ki, ku) as a separate character (code point)
b) the base syllables are represented and the altered syllables will be merged

Since it was chosen for the latter, this has a few consequences:

=over

=item *

The graphical representation will depend on building B<ligatures> and thus on the font you are using.

=back

=over

=item *

That means you have to make sure you have appropriate fonts to display the signs correctly.

=back

Even if you find the ligatures not mixed together well (e.g. on your shell),
you can still copy-paste the results somewhere else where you have a proper
font available. Since only the code points are represented and it is up to the font
to build the ligatures you will find the copy-pasted result come out very well with
a proper font having the ligatures available.

Copy-pasting your results L<here>(http:E<sol>E<sol>www.thlib.orgE<sol>referenceE<sol>transliterationE<sol>wyconverter.php) might help should the tibetan signs not be rendered correctly on your shell

=head1 USAGE

     echo bsgrubs | wylie-transliterate

or

   wylie-transliterate <FILE>

=head1 MOTIVATION

"Nobody needs such a module!" -- you might say. I agree. But the B<one> person
who might need it will be more than happy to have. (Given heE<sol>she finds it in the webz).

Still though, let me just say:

=over

=item *

I do it because I can

=item *

in my studies I visited a course "Classical Tibetan I"

=back

Really, I didn't learn too much about this interesting language, but a few things
just stuck with me, such as the composition of characters to build words.

=head1 RESPONSIBILITIES E<sol> FEEDBACK

I am in B<no way> any expert in Classical Tibetan. I can't even read one sentence.

But I can decipher one word!

This module was written in the spirit of my fascination with the interesting
system of this language and I would love to learn it for real some day.

Please, if you are an expert and you find any errors, fixes, whatever -- I call
it B<your reponsibility> to let me know!

Please shoot me an email at: dbr @at@ cpan . org, thank you!

=head1 AUTHOR

DBR <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by DBR.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
