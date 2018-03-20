package CtrlO::Crypt::XkcdPassword;
use strict;
use warnings;

# ABSTRACT: Yet another xkcd style password generator

our $VERSION = '1.004';

use Carp qw(croak);
use Crypt::Rijndael;
use Crypt::URandom;
use Data::Entropy qw(with_entropy_source);
use Data::Entropy::Algorithms qw(rand_int pick_r shuffle_r choose_r);
use Data::Entropy::RawSource::CryptCounter;
use Data::Entropy::Source;
use Data::Handle;
use Module::Runtime qw(use_module);

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(entropy wordlist language _list _pid));


sub new {
    my ( $class, %args ) = @_;

    my %object;

    # init the word list
    my @list;
    if ( $args{wordlist} ) {
        $object{wordlist} = $args{wordlist};
    }
    else {
        my $lang = lc( $args{language} || 'en-GB' );
        $lang =~ s/-/_/g;
        $object{wordlist} = 'CtrlO::Crypt::XkcdPassword::Wordlist::' . $lang;
    }

    if ( -r $object{wordlist} ) {
        open( my $fh, '<:encoding(UTF-8)', $object{wordlist} );
        while ( my $word = <$fh> ) {
            chomp($word);
            $word =~ s/\s//g;
            push( @list, $word );
        }
        $object{_list} = \@list;
    }
    elsif ( $object{wordlist} =~ /::/ ) {
        eval { use_module( $object{wordlist} ); };
        if ($@) {
            croak( "Cannot load word list module " . $object{wordlist} );
        }
        my $pkg = $object{wordlist};
        no strict 'refs';

        # do we have a __DATA__ section, indication a subclass of https://metacpan.org/release/WordList
        my $handle = eval { Data::Handle->new($pkg) };
        if ($handle) {
            $object{_list} = [ map { s/\n//g; chomp; $_ } $handle->getlines ];
        }

        # do we have @Words, indication Crypt::Diceware
        elsif ( @{"${pkg}::Words"} ) {
            $object{_list} = \@{"${pkg}::Words"};
        }
        else {
            croak("Cannot find word list in $pkg");
        }
    }
    else {
        croak(    'Invalid word list: >'
                . $object{wordlist}
                . '<. Has to be either a Perl module or a file' );
    }

    # poor person's lazy_build
    $object{entropy} = $args{entropy} || $class->_build_entropy;
    $object{_pid} = $$;

    return bless \%object, $class;
}

sub _build_entropy {
    my $class = shift;
    return Data::Entropy::Source->new(
        Data::Entropy::RawSource::CryptCounter->new(
            Crypt::Rijndael->new( Crypt::URandom::urandom(32) )
        ),
        "getc"
    );
}


sub xkcd {
    my ( $self, %args ) = @_;
    if ( $self->_pid != $$ ) {
        $self->_reinit_after_fork;
    }

    my $word_count = $args{words} || 4;

    my $words = with_entropy_source(
        $self->entropy,
        sub {
            shuffle_r( choose_r( $word_count, $self->_list ) );
        }
    );

    if ( my $d = $args{digits} ) {
        push(
            @$words,
            sprintf(
                '%0' . $d . 'd',
                with_entropy_source(
                    $self->entropy, sub { rand_int( 10**$d ) }
                )
            )
        );
    }
    return join( '', map {ucfirst} @$words );
}

sub _reinit_after_fork {
    my $self = shift;
    $self->_pid($$);
    $self->entropy( $self->_build_entropy );
}

'correct horse battery staple';

__END__

=pod

=encoding UTF-8

=head1 NAME

CtrlO::Crypt::XkcdPassword - Yet another xkcd style password generator

=head1 VERSION

version 1.004

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<CtrlO::Crypt::XkcdPassword> generates a random password using the
algorithm suggested in L<https://xkcd.com/936/>: It selects 4 words
from a curated list of words and combines them into a hopefully easy
to remember password (actually a passphrase, but we're all trying to
getting things done, so who cares..).

See L<this
explaination|https://www.explainxkcd.com/wiki/index.php/936:_Password_Strength>
for detailed information on the security of passwords generated from a
known word list.

But L<https://xkcd.com/927/> also applies to this module, as there are
already a lot of modules on CPAN implementing
L<https://xkcd.com/936/>. We still wrote a new one, mainly because we
wanted to use a strong source of entropy and a fine-tuned word list.

=head1 METHODS

=head2 new

  my $pw_generator = CtrlO::Crypt::XkcdPassword->new;

Initialize a new object. Uses C<CtrlO::Crypt::XkcdPassword::Wordlist::en_gb>
as a word list per default. The default entropy is based on
C<Crypt::URandom>, i.e. C</dev/urandom> and should be random enough (at
least more random than plain old C<rand()>).

If you want / need to supply another source of entropy, you can do so
by setting up an instance of C<Data::Entropy::Source> and passing it
to C<new> as C<entropy>.

  my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
      entropy => Data::Entropy::Source->new( ... )
  );

To use one of the included language-specific word lists, do:

  my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
      language => 'en-GB',
  );

Available languages are:

=over

=item * en-GB

=back

You can also provide your own custom word list, either in a file:

  my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
      wordlist => '/path/to/file'
  );

Or in a module:

  my $pw_generator = CtrlO::Crypt::XkcdPassword->new(
      wordlist => 'My::Wordlist'
  );

See L<Defining custom word lists> for more info

=head2 xkcd

  my $pw = $pw_generator->xkcd;
  my $pw = $pw_generator->xkcd( words  => 3 );
  my $pw = $pw_generator->xkcd( digits => 2 );

Generate a random, xkcd-style password.

Per default will return 4 randomly chosen words from the word list,
each word's first letter turned to upper case, and concatenated
together into one string:

  $pw_generator->xkcd;
  # CorrectHorseBatteryStaple

You can get a different number of words by passing in C<words>. But
remember that anything smaller than 3 will probably make for rather
poor passwords, and anything bigger than 7 will be hard to remember.

You can also pass in C<digits> to append a random number consisting of
C<digits> digits to the password:

  $pw_generator->xkcd( words => 3, digits => 2 );
  # StapleBatteryCorrect75

=head1 DEFINING CUSTOM WORD LISTS

Please note that C<language> is only supported for the word lists
included in this distribution.

=head2 in a plain file

Put your word list into a plain file, one line per word. Install this
file somewhere on your system. You can now use your word list like
this:

  CtrlO::Crypt::XkcdPassword->new(
    wordlist => '/path/to/wordlist'
  );

=head2 in a Perl module using the Wordlist API

L<Perlancar|https://metacpan.org/author/PERLANCAR> came up with a unified API for various word list modules,
implemented in L<Wordlist|https://metacpan.org/pod/WordList>. Pack
your list into a module adhering to this API, install the module, and
load your word list:

  CtrlO::Crypt::XkcdPassword->new(
    wordlist => 'Your::Cool::Wordlist'
  );

You can check out L<CtrlO::Crypt::XkcdPassword::Wordlist::en_GB> (included in
this distribution) for an example. But it's really quite simple: Just
subclass C<Wordlist> and put your list of words into the C<__DATA__>
section of the module, one line per word.

=head2 in a Perl module using the Crypt::Diceware API

David Golden uses a different API in his L<Crypt::Diceware> module,
which inspired the design of L<CtrlO::Crypt::XkcdPassword>. To use one
of those word lists, use:

  CtrlO::Crypt::XkcdPassword->new(
    wordlist => 'Crypt::Diceware::Wordlist::Common'
  );

(yes, this looks just like when using C<Wordlist>. We inspect the
wordlist module and try to figure out what kind of API you're using)

To create a module using the L<Crypt::Diceware> wordlist API, just
create a package containing a public array C<@Words> containing your
word list.

=head1 WRAPPER SCRIPT

This distributions includes a simple wrapper script, L<pwgen-xkcd.pl>.

=head1 RUNNING FROM GIT

This is B<not> the recommended way to install / use this module. But
it's handy if you want to submit a patch or play around with the code
prior to a proper installation.

=head2 Carton

  git clone git@github.com:domm/CtrlO-Crypt-XkcdPassword.git
  carton install
  carton exec perl -Ilib -MCtrlO::Crypt::XkcdPassword -E 'say CtrlO::Crypt::XkcdPassword->new->xkcd'

=head2 cpanm & local::lib

  git clone git@github.com:domm/CtrlO-Crypt-XkcdPassword.git
  cpanm -L local --installdeps .
  perl -Mlocal::lib=local -Ilib -MCtrlO::Crypt::XkcdPassword -E 'say CtrlO::Crypt::XkcdPassword->new->xkcd'

=head1 SEE ALSO

Inspired by L<https://xkcd.com/936/> and L<https://xkcd.com/927/>

There are a lot of similar modules on CPAN, so we just point you to
L<Neil Bower's comparison of CPAN modules for generating passwords|http://neilb.org/reviews/passwords.html>

=head2 But we did we write yet another module?

=over

=item * Good entropy

Most of the password generating modules just use C<rand()>, which "is
not cryptographically secure" (according to perldoc).
C<CtrlO::Crypt::XkcdPassword> uses L<Crypt::URandom> via
L<Data::Entropy>, which provides good entropy while still being portable.

=item * Good word list

While L<Crypt::Diceware> has good entropy, we did not like its word
lists. Of course we could have just provided a word list better suited
to our needs, but we wanted it to be very easy to generate xkcd-Style
passwords

=item * Easy API

C<< my $pwd = CtrlO::Crypt::XkcdPassword->new->xkcd >> returns 4 words
starting with an uppercase letter as a string, which is our main use
case. But the API also allows for more or less words, or even some digits.

=item * Fork save

=item * L<https://xkcd.com/927/>

=back

=head1 THANKS

=over

=item * Thanks to L<Ctrl O|http://www.ctrlo.com/> for funding the development of this module.

=item * We learned the usage of C<Data::Entropy> from
L<https://metacpan.org/pod/Crypt::Diceware>, which also implements an
algorithm to generate a random passphrase.

=item * L<m_ueberall|https://twitter.com/m_ueberall/status/965263922310909952>
for pointing out
L<https://www.explainxkcd.com/wiki/index.php/936:_Password_Strength>

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
