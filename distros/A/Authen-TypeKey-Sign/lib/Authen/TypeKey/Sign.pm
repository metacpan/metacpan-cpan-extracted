# Copyright (c) 2004 Timothy Appnel (tima@cpan.org)
# http://www.timaoutloud.org/
# This code is released under the Artistic License.

package Authen::TypeKey::Sign;
use strict;
use base qw( Class::ErrorHandler );

use Crypt::DSA;
use Crypt::DSA::Key;
use Crypt::DSA::Signature;
use MIME::Base64 qw( encode_base64 );
use Math::Pari;

use vars qw( $VERSION );
$VERSION = '0.07';

sub new {
    my $class = shift;
    my $tk = bless {}, $class;
    $tk->hide_email(1);
    $tk->version(1.1);
    $tk->token('');
    $tk;
}

sub hide_email { shift->stash('hide_email', @_) }
sub version    { shift->stash('version',    @_) }
sub token      { shift->stash('token',      @_) }

sub key {
    my ($tk, $in) = @_;
    return $tk->stash('key') if $tk->stash('key');
    my $key;
    unless (ref($in)) {    # read from file
        open my $fh, $in
          or return $tk->error("Can't open $in: $!");
        my $data = do { local $/; <$fh> };
        close $fh;
        $key = Crypt::DSA::Key->new;
        for my $f (split /\s+/, $data) {
            my ($k, $v) = split /=/, $f, 2;
            $key->$k($v);
        }
    } else {
        if (ref($in) eq 'HASH') {    # from hash
            $key = Crypt::DSA::Key->new();
            map { $key->$_($in->{$_}) } keys %$in;
        } elsif (ref($key) ne 'Crypt::DSA::Key') {
            return $tk->error(
                         ref($key) . ' is unsupported by ' . 'the key method.');
        } else {
            $key = $in;
        }    # is DSA key
    }
    $tk->stash('key', $key);
    $key;
}

sub sign {
    my ($tk, $in) = @_;
    if (ref($in) ne 'HASH') {
        return $tk->error(ref($in) . ' cannot param.')
          unless ($in->can('param'));
        my %in;
        map { $in{$_} = $in->param($_) } qw( name nick email );
        $in = \%in;
    }

    # tbd: more validation?
    $in->{nick} = substr($in->{nick}, 0, 50);
    $in->{ts} = time;
    if ($tk->hide_email) {
        require Digest::SHA1;
        my $sha1 = Digest::SHA1->new;
        $sha1->add('mailto:' . $in->{email});
        $in->{email} = $sha1->hexdigest();
    }
    my $msg =
      $in->{email} . '::' . $in->{name} . '::' . $in->{nick} . '::' . $in->{ts};
    $msg .= '::' . $tk->token if ($tk->version > 1);
    my $key = $tk->key;
    my $dsa = Crypt::DSA->new;
    my $sig = $dsa->sign(Message => $msg, Key => $key);
    require MIME::Base64;
    my $r = MIME::Base64::encode_base64(mp2bin($sig->r()), '');
    my $s = MIME::Base64::encode_base64(mp2bin($sig->s()), '');
    $in->{sig} = "$r:$s";
    my @qs = map { "$_=" . encode_url($in->{$_} || '') } qw( name nick );
    push(@qs,
         map    { "$_=" . encode_url($in->{$_}) }
           grep { defined($in->{$_}) } qw( email ts token sig ));
    join('&', @qs);
}

#--- utility methods

sub stash {
    $_[0]->{$_[1]} = $_[2] if defined $_[2];
    $_[0]->{$_[1]};
}

sub mp2bin {
    my ($p) = @_;
    $p = PARI($p);
    my $base = PARI(1) << PARI(4 * 8);
    my $res  = '';
    while ($p != 0) {
        my $r = $p % $base;
        $p = ($p - $r) / $base;
        my $buf = pack 'N', $r;
        if ($p == 0) {
            $buf =
                $r >= 16777216 ? $buf
              : $r >= 65536 ? substr($buf, -3, 3)
              : $r >= 256   ? substr($buf, -2, 2)
              : substr($buf, -1, 1);
        }
        $res = $buf . $res;
    }
    $res;
}

sub encode_url {
    (my $str = $_[0]) =~ s!([^a-zA-Z0-9_.-])!uc sprintf "%%%02x", ord($1)!eg;
    $str;
}

1;

__END__

=head1 NAME

Authen::TypeKey::Sign - TypeKey authentication signature generation

=head1 SYNOPSIS

    use Authen::TypeKey::Sign;
    my $tk = Authen::TypeKey::Sign->new;
    $tk->token('typekey-token');
    $tk->key('./TYPEKEYS');
    my $user = { name=>'foo', nick=>'Dr. Foo', 
        email=>'drfoo@spectre.evilorg' };
    my $querystring = $tk->sign($user) or die $tk->errstr;

=head1 DESCRIPTION

I<Authen::TypeKey::Sign> is an implementation of the TypeKey 
authentication signature process. For information on the TypeKey
protocol and using TypeKey in other applications, see
I<http://www.movabletype.org/docs/tk-apps.html>.

=head1 USAGE

=head2 Authen::TypeKey::Sign->new

Create a new I<Authen::TypeKey::Sign> object.

=head2 $tk->token([ $typekey_token ])

Get/set the TypeKey token used when creating the original sign-in
link. This is required to successfully validate the signature in
TypeKey 1.1 and higher, which includes the token in the plaintext.

This must be set B<before> calling C<sign>.

=head2 $tk->key( [$keyfile|\%key|$dsa_key_obj] )

Gets/sets the DSA key. If no parameter is passed it returns the key 
as a L<Crypt::DSA::Key> object. With a parameter it also sets the key.
The parameter may be one of the following:

=over 4

=item * Crypt::DSA::Key object

A reference to a populated L<Crypt::DSA::Key> object.

=item * HASH reference

A HASH reference containing keys of p, g, q, pub_key, and priv_key
carrying the applicable values as per DSA key generation standard.

=item * Filename

A SCALAR containing the full path and filename of a text
file containing the DSA keys including the private key. The format
consists of five keys (p, g, q, pub_key, and priv_key) and their
applicable values as per the DSA key generation standard. One per
line. Keys and values are delimited by an equal sign.

 p=someDSAkeyvalue
 g=someDSAkeyvalue
 q=someDSAkeyvalue
 pub_key=someDSAkeyvalue
 priv_key=someDSAkeyvalue
 
You can use the L<typekeygen> utility script to generate this file.

This must be set B<before> calling C<sign>.

=back

=head2 $tk->sign(\%user|$param_object)

Generates a TypeKey signature and returns a HTTP query string on
success that can be used in its response to a TypeKey-enabled
client. The method takes a required parameter of either a HASH
reference or an object that supports a param method such as L<CGI>
or L<Apache::Request>. The following hash keys are recognized:

=over 4

=item * name

The unique username of the TypeKey user. Required.

=item * nick

The user's display name. Required.

=item * email

The user's email address. Required. If C<hide_email> is set to true, 
C<sign> will automatically encode the email address as a SHA-1 hash of 
the string C<mailto:E<lt>emailE<gt>>. 

=back

Elements for I<ts> (timestamp) and I<token> will be handled by the
C<sign> method. I<ts> will be set to the current time (seconds
since epoch). If using TypeKey Protocol version 1.1 or higher,
I<token> will be the value set using the C<token> method.

If generation is unsuccessful, I<sign> will return C<undef>, and
the error message can be found in C<$tk-E<gt>errstr>.

=head2 $tk->version([ $version ])

Get/set the version of the TypeKey protocol to use. The default version
if C<1.1>.

=head2 $tk->hide_email([0|1])

Get/set whether the TypeKey signature should "hide" the email address by
encoding the value as a SHA-1 hash. Default is true (1).

=head1 SEE ALSO

http://www.movabletype.org/docs/tk-apps.html

http://www.typekey.com/
 
L<Authen::TypeKey>, L<Apache::AuthTypeKey>, L<typekeygen>

=head1 DEPENDENCIES

L<Crypt::DSA>
L<Crypt::DSA::Key>
L<Crypt::DSA::Signature>
L<MIME::Base64>
L<Getopt::Long> 2.33+
L<Pod::Usage>

=head1 LICENSE

The software is released under the Artistic License. The terms of
the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

TypeKey is a trademark of Six Apart Ltd. TypeKey Authentication Protocol 
is Copyright 2004 Six Apart Ltd, cpan@sixapart.com. All rights reserved.

Except where otherwise noted, L<Authen::TypeKey::Sign> is 
Copyright 2004, Timothy Appnel, cpan@timaoutloud.org. All rights 
reserved.

=cut

=end
