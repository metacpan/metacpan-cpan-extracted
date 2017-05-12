# $Id: Rule.pm,v 1.6 2007/08/14 15:45:51 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Rule; {
    use Object::InsideOut;

    # object attributes
    my @code     :Field( Std => 'code',     Type => 'numeric' );
    my @debug    :Field( Std => 'debug',    Type => 'numeric' );
    my @disabled :Field( Std => 'disabled', Type => 'numeric' );
    my @message  :Field( Std => 'message',                    );
    my @score    :Field( Std => 'score',                      );
    my @test     :Field( Std => 'test',     Type => 'CODE'    );
    my @validate :Field( Std => 'validate', Type => 'CODE'    );

    my %init_args :InitArgs = (
        code     => {           Field => \@code,     Type => 'numeric' },
        debug    => { Def => 0, Field => \@debug,    Type => 'numeric' },
        disabled => { Def => 0, Field => \@disabled, Type => 'numeric' },
        message  => {           Field => \@message,                    },
        score    => {           Field => \@score,                      },
        test     => {           Field => \@test,                       },
        validate => {           Field => \@validate, Type => 'CODE'    },
    );
}

1;
__END__

=head1 NAME

Data::Passphrase::Rule - rule for validating passphrases

=head1 SYNOPSIS

    my $rule = Data::Passphrase::Rule->new({
       code     => 450,
       message  => 'is too short',
       test     => 'X' x 15,
       validate => sub { $_[0] / 25 },
    });

=head1 DESCRIPTION

Objects of this class represent individual strength-checking rules
used by L<Data::Passphrase|Data::Passphrase>.

=head1 INTERFACE

There is a constructor, C<new>, which takes a reference to a hash of
initial attribute settings, and accessor methods of the form
C<get_>I<attribute>C<()> and C<set_>I<attribute>C<()>.  See
L</Attributes>.

=head2 Attributes

=over 4

=item code

Numeric status code returned if passphrase fails this rule.

=item message

Textual status message returned if passphrase fails this rule.

=item test

Passphrase(s) used to test this rule specified as a string, an
anoymous array of strings (each of which is tested), or a hash.  The
hash is useful if you want each test phrase to return a different code
and/or message, which is useful if the validation subroutine sets them
to something other than their specification in the rule.  Test
passphrases themselves are specified as the keys of the hash.  The
values of the hash may be strings representing the messages associated
with each test passphrase, or they may be hash references with I<code>
and I<message> attributes.  See L</EXAMPLES>.

A reference to a subroutine that returns any of the above may also be
specified.

=item validate

Reference to a subroutine that does the validation and returns a
score.  This subroutine may override the I<code> and/or I<message>
attributes by setting them excplitly.  See L</EXAMPLES>.

=back

=head1 EXAMPLES

For basic examples, see L<Data::Passphrase> and the included
C<passphrase_rules> file.

Here's a more convoluted example.  The validation subroutine in this
rule sets the I<code> and I<message> attributes explicitly, which is
useful to conditionally apply of certain checks or when an external
application provides the code and/or message.  This example makes use
of Cracklib to test non-passphrases and does no complicated scoring --
passwords receive a score of 0 for failing or 1 for passing.

 # invoke Cracklib
 {
     code     => 470,
     message  => 'rejected by Cracklib',
     test     => sub {
         my ($self) = @_;

         my $username = $self->get_username() or return;

         return {
             "${username}!$%^&*()" => {
                 code    => 472,
                 message => 'may not be based on your username',
             },
             abcdefgh   => 'is too simplistic/systematic',
             password   => 'is based on a dictionary word',
             password1  => 'is based on a dictionary word',
             p455w0rd   => 'is based on a dictionary word',
             k1i988i7   => 'contains a repeating number or symbol',
             'k1i9]]i7' => 'contains a repeating number or symbol',
             179280398  => 'appears to be a Social Security Number',
         };
     },
     validate => sub {
         my ($self) = @_;

         # unpack attributes
         my $passphrase = $self->get_passphrase();
         my $username   = $self->get_username  ();

         # passphrases don't need to pass Cracklib
         return 1
             if length $passphrase >= $MINIMUM_PASSPHRASE_CHARACTERS;

         # use Cracklib to compare against username
         if (Crypt::Cracklib::GTry($username, $passphrase)) {
             $self->set_code   (472                                );
             $self->set_message('may not be based on your username');
             return 0;
         }

         # execute rest of Cracklib ruleset
         my $message = fascist_check $passphrase, $CRACKLIB_DICTIONARY;
         return 1 if $message eq 'ok';

         # normalize message and set the attributes
         $message =~ s/^it //;
         $message =~ s/^'s /is /;
         $self->set_message($message);

         return 0;
     },
 }

The I<validate> subroutine first checks the password length; if it's
longer than a defined minimum, it's passed on to other rules that test
passphrase strength.  Then it tests the password for similary to the
username (we've locally modified L<Crypt::Cracklib|Crypt::Cracklib> to
expose the C<GTry()> routine).  If C<GTry()> sees a similarity, the
I<validate> subroutine returns a special code and message.  Finally,
C<fascist_check()> is called, and if it determines the password to be
too weak, the I<validate> subroutine passes the message along.

Our I<test> routine provides one password to test the C<GTry()> check.
It pads the username with punctuation characters to ensure the minimum
length (enforced by previous rules) is satisfied.  The rest of the
test passwords specify their own messages but inherit the code
specified in the I<code> attribute of the rule.

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Crypt::Cracklib(3), Data::Passphrase(3), Data::Passphrase::Ruleset(3)
