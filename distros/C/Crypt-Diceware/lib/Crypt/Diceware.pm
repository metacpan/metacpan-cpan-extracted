use 5.008001;
use strict;
use warnings;

package Crypt::Diceware;
# ABSTRACT: Random passphrase generator loosely based on the Diceware algorithm
our $VERSION = '0.005'; # VERSION

use Class::Load qw/load_class/;
use Crypt::Rijndael;
use Crypt::URandom;
use Data::Entropy qw/with_entropy_source/;
use Data::Entropy::Algorithms qw/pick_r/;
use Data::Entropy::RawSource::CryptCounter;
use Data::Entropy::Source;

use Sub::Exporter -setup => {
    exports => [ words   => \'_build_words' ],
    groups  => { default => [qw/words/] },
};

my $ENTROPY = Data::Entropy::Source->new(
    Data::Entropy::RawSource::CryptCounter->new(
        Crypt::Rijndael->new( Crypt::URandom::urandom(32) )
    ),
    "getc"
);

sub _build_words {
    my ( $class, $name, $arg ) = @_;
    $arg ||= {};
    my $list;
    my $entropy = $arg->{entropy} || $ENTROPY;
    if ( exists $arg->{file} ) {
        my @list = do { local (@ARGV) = $arg->{file}; <> };
        chomp(@list);
        $list = \@list;
    }
    else {
        my $word_class = $arg->{wordlist} || 'Common';
        unless ( $word_class =~ /::/ ) {
            $word_class = "Crypt::Diceware::Wordlist::$word_class";
        }
        load_class($word_class);
        $list = do {
            no strict 'refs';
            \@{"${word_class}::Words"};
        };
    }
    return sub {
        my ($n) = @_;
        return unless $n && $n > 0;
        my @w = with_entropy_source(
            $entropy,
            sub {
                map { pick_r($list) } 1 .. int($n);
            }
        );
        return wantarray ? @w : join( ' ', @w );
    };
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Diceware - Random passphrase generator loosely based on the Diceware algorithm

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Crypt::Diceware;
  my @phrase = words(4); # qw/starker call recur outlaw/

  # with alternate word lists
  use Crypt::Diceware words => { wordlist => 'Original' };
  use Crypt::Diceware words => { wordlist => 'Beale' };

=head1 DESCRIPTION

This module generates a random passphrase of words based loosely on the
L<Diceware|http://world.std.com/~reinhold/diceware.html> algorithm by Arnold G.
Reinhold.

A Diceware passphrase consists of randomly selected words chosen from a list
of over seven thousand words.  A passphrase of four or five words is likely to
be stronger than typical human-generated passwords, which tend to be
too-short and over-sample common letters ("e") and numbers ("1").

Words are randomly selected using L<Data::Entropy> in AES counter mode,
seeded with L<Crypt::URandom>, which is reasonably cryptographically strong.

=head1 USAGE

By default, this module exports a single subroutine, C<words>, which uses the
L<Crypt::Diceware::Wordlist::Common> word list.

An alternate wordlist may be specified:

  use Crypt::Diceware words => { wordlist => 'Original' };

This loads the wordlist provided by
L<Crypt::Diceware::Wordlist::Original>. If the name of the wordlist
contains I<::> the name of the wordlist is not prefixed by
I<Crypt::Diceware::Wordlist>.

It is also possible to load a wordlist from a file via:

  use Crypt::Diceware words => { file => 'diceware-german.txt' };

The supplied file should contain one word per line.

You can also replace the entropy source with another L<Data::Entropy::Source>
object:

  use Crypt::Diceware words => { entropy => $entropy_source };

Exporting is done via L<Sub::Exporter> so any of its features may be used:

  use Crypt::Diceware words => { -as => 'passphrase' };
  my @phrase = passphrase(4);

=head2 words

  my @phrase = words(4);

Takes a positive numeric argument and returns a passphrase of that many
randomly-selected words. In a list context it will return a list of words, as above.
In a scalar context it will return a string with the words separated with a single space character:

  my $phrase = words(4);

Returns the empty list / string if the argument is missing or not a positive number.

=for Pod::Coverage method_names_here

=head1 SEE ALSO

Diceware and Crypt::Diceware related:

=over 4

=item *

L<Diceware|http://world.std.com/~reinhold/diceware.html>

=item *

L<Crypt::Diceware::Wordlist::Common>

=item *

L<Crypt::Diceware::Wordlist::Original>

=item *

L<Crypt::Diceware::Wordlist::Beale>

=back

Other CPAN passphrase generators:

=over 4

=item *

L<Crypt::PW44>

=item *

L<Crypt::XkcdPassword>

=item *

L<Review of CPAN password/phrase generators|http://neilb.org/reviews/passwords.html>

=back

About password strength in general:

=over 4

=item *

L<Password Strength (XKCD)|http://xkcd.com/936/>

=item *

L<Password Strength (Wikipedia)|http://en.wikipedia.org/wiki/Password_strength>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Crypt-Diceware/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Crypt-Diceware>

  git clone https://github.com/dagolden/Crypt-Diceware.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

Mario Domgoergen <mdom@taz.de>

=item *

Neil Bowers <neil@bowers.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
