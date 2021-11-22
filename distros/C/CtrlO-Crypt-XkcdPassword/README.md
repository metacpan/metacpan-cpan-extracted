# NAME

CtrlO::Crypt::XkcdPassword - Yet another xkcd style password generator

# VERSION

version 1.011

# SYNOPSIS

    use CtrlO::Crypt::XkcdPassword;
    my $password_generator = CtrlO::Crypt::XkcdPassword->new;

    say $password_generator->xkcd;
    # LimousineAllegeClergymanEconomic

    say $password_generator->xkcd( words => 3 );
    # ObservantFiresideMacho

    say $password_generator->xkcd( words => 3, digits => 3 );
    # PowerfulSpreadScarf645

    # Use custom word list
    CtrlO::Crypt::XkcdPassword->new(
      wordlist => '/path/to/wordlist'
    );
    CtrlO::Crypt::XkcdPassword->new(
      wordlist => 'Some::Wordlist::From::CPAN'
    );

    # Use another source of randomness (aka entropy)
    CtrlO::Crypt::XkcdPassword->new(
      entropy => Data::Entropy::Source->new( ... );
    );

# DESCRIPTION

`CtrlO::Crypt::XkcdPassword` generates a random password using the
algorithm suggested in [https://xkcd.com/936/](https://xkcd.com/936/): It selects 4 words
from a curated list of words and combines them into a hopefully easy
to remember password (actually a passphrase, but we're all trying to
get things done, so who cares..).

See [this
explaination](https://www.explainxkcd.com/wiki/index.php/936:_Password_Strength)
for detailed information on the security of passwords generated from a
known word list.

But [https://xkcd.com/927/](https://xkcd.com/927/) also applies to this module, as there are
already a lot of modules on CPAN implementing
[https://xkcd.com/936/](https://xkcd.com/936/). We still wrote a new one, mainly because we
wanted to use a strong source of entropy and a fine-tuned word list.

# METHODS

## new

    my $pw_generator = CtrlO::Crypt::XkcdPassword->new;

Initialize a new object. Uses `CtrlO::Crypt::XkcdPassword::Wordlist::en_gb`
as a word list per default. The default entropy is based on
`Crypt::URandom`, i.e. `/dev/urandom` and should be random enough (at
least more random than plain old `rand()`).

If you want / need to supply another source of entropy, you can do so
by setting up an instance of `Data::Entropy::Source` and passing it
to `new` as `entropy`.

    my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
        entropy => Data::Entropy::Source->new( ... )
    );

To use one of the included language-specific word lists, do:

    my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
        language => 'en-GB',
    );

Available languages are:

- en-GB

You can also provide your own custom word list, either in a file:

    my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
        wordlist => '/path/to/file'
    );

Or in a module:

    my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
        wordlist => 'My::Wordlist'
    );

See ["DEFINING CUSTOM WORD LISTS"](#defining-custom-word-lists) for more info.

## xkcd

    my $pw = $pw_generator->xkcd;
    my $pw = $pw_generator->xkcd( words  => 3 );
    my $pw = $pw_generator->xkcd( digits => 2 );

Generate a random, xkcd-style password.

Per default will return 4 randomly chosen words from the word list,
each word's first letter turned to upper case, and concatenated
together into one string:

    $pw_generator->xkcd;
    # CorrectHorseBatteryStaple

You can get a different number of words by passing in `words`. But
remember that anything smaller than 3 will probably make for rather
poor passwords, and anything bigger than 7 will be hard to remember.

You can also pass in `digits` to append a random number consisting of
`digits` digits to the password:

    $pw_generator->xkcd( words => 3, digits => 2 );
    # StapleBatteryCorrect75

# DEFINING CUSTOM WORD LISTS

Please note that `language` is only supported for the default word list
included in this distribution.

## in a plain file

Put your word list into a plain file, one line per word. Install this
file somewhere on your system. You can now use your word list like
this:

    CtrlO::Crypt::XkcdPassword->new(
      wordlist => '/path/to/wordlist'
    );

## in a Perl module using the Wordlist API

[Perlancar](https://metacpan.org/author/PERLANCAR) came up with a unified API for various word list modules,
implemented in [Wordlist](https://metacpan.org/pod/WordList). Pack
your list into a module adhering to this API, install the module, and
load your word list:

    CtrlO::Crypt::XkcdPassword->new(
      wordlist => 'Your::Cool::Wordlist'
    );

You can check out [CtrlO::Crypt::XkcdPassword::Wordlist::en\_gb](https://metacpan.org/pod/CtrlO%3A%3ACrypt%3A%3AXkcdPassword%3A%3AWordlist%3A%3Aen_gb) (included in
this distribution) for an example. But it's really quite simple: Just
subclass `Wordlist` and put your list of words into the `__DATA__`
section of the module, one line per word.

## in a Perl module using the Crypt::Diceware API

David Golden uses a different API in his [Crypt::Diceware](https://metacpan.org/pod/Crypt%3A%3ADiceware) module,
which inspired the design of [CtrlO::Crypt::XkcdPassword](https://metacpan.org/pod/CtrlO%3A%3ACrypt%3A%3AXkcdPassword). To use one
of those word lists, use:

    CtrlO::Crypt::XkcdPassword->new(
      wordlist => 'Crypt::Diceware::Wordlist::Common'
    );

(yes, this looks just like when using `Wordlist`. We inspect the
wordlist module and try to figure out what kind of API you're using)

To create a module using the [Crypt::Diceware](https://metacpan.org/pod/Crypt%3A%3ADiceware) wordlist API, just
create a package containing a public array `@Words` containing your
word list.

# INCLUDED WORD LISTS

This distribution comes with a hand-crafted word list
[CtrlO::Crypt::XkcdPassword::Wordlist::en\_gb](https://metacpan.org/pod/CtrlO%3A%3ACrypt%3A%3AXkcdPassword%3A%3AWordlist%3A%3Aen_gb) and three word lists
provided by
[EFF](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases):
[CtrlO::Crypt::XkcdPassword::Wordlist::eff\_large](https://metacpan.org/pod/CtrlO%3A%3ACrypt%3A%3AXkcdPassword%3A%3AWordlist%3A%3Aeff_large),
[CtrlO::Crypt::XkcdPassword::Wordlist::eff\_short\_1](https://metacpan.org/pod/CtrlO%3A%3ACrypt%3A%3AXkcdPassword%3A%3AWordlist%3A%3Aeff_short_1) and
[CtrlO::Crypt::XkcdPassword::Wordlist::eff\_short\_2\_0](https://metacpan.org/pod/CtrlO%3A%3ACrypt%3A%3AXkcdPassword%3A%3AWordlist%3A%3Aeff_short_2_0).

# WRAPPER SCRIPT

This distributions includes a simple wrapper script, [pwgen-xkcd.pl](https://metacpan.org/pod/pwgen-xkcd.pl).

# RUNNING FROM GIT

This is **not** the recommended way to install / use this module. But
it's handy if you want to submit a patch or play around with the code
prior to a proper installation.

## Carton

    git clone git@github.com:domm/CtrlO-Crypt-XkcdPassword.git
    carton install
    carton exec perl -Ilib -MCtrlO::Crypt::XkcdPassword -E 'say CtrlO::Crypt::XkcdPassword->new->xkcd'

## cpanm & local::lib

    git clone git@github.com:domm/CtrlO-Crypt-XkcdPassword.git
    cpanm -L local --installdeps .
    perl -Mlocal::lib=local -Ilib -MCtrlO::Crypt::XkcdPassword -E 'say CtrlO::Crypt::XkcdPassword->new->xkcd'

# SEE ALSO

Inspired by [https://xkcd.com/936/](https://xkcd.com/936/) and [https://xkcd.com/927/](https://xkcd.com/927/).

There are a lot of similar modules on CPAN, so we just point you to
[Neil Bower's comparison of CPAN modules for generating passwords](http://neilb.org/reviews/passwords.html).

## But why did we write yet another module?

- Good entropy

    Most of the password generating modules just use `rand()`, which "is
    not cryptographically secure" (according to perldoc).
    `CtrlO::Crypt::XkcdPassword` uses [Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom) via
    [Data::Entropy](https://metacpan.org/pod/Data%3A%3AEntropy), which provides good entropy while still being portable.

- Good word list

    While [Crypt::Diceware](https://metacpan.org/pod/Crypt%3A%3ADiceware) has good entropy, we did not like its word
    lists. Of course we could have just provided a word list better suited
    to our needs, but we wanted it to be very easy to generate xkcd-style
    passwords.

- Easy API

    `my $pwd = CtrlO::Crypt::XkcdPassword->new->xkcd` returns 4 words
    starting with an uppercase letter as a string, which is our main use
    case. Nevertheless, the API also allows for more or fewer words, or
    even some digits.

- Fork save
- [https://xkcd.com/927/](https://xkcd.com/927/)

# THANKS

- Thanks to [Ctrl O](http://www.ctrlo.com/) for funding the development of this module.
- We learned the usage of `Data::Entropy` from
[https://metacpan.org/pod/Crypt::Diceware](https://metacpan.org/pod/Crypt::Diceware), which also implements an
algorithm to generate a random passphrase.
- [m\_ueberall](https://twitter.com/m_ueberall/status/965263922310909952)
for pointing out
[https://www.explainxkcd.com/wiki/index.php/936:\_Password\_Strength](https://www.explainxkcd.com/wiki/index.php/936:_Password_Strength)

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
