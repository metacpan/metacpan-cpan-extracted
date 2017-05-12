package Code::Crypt;
{
  $Code::Crypt::VERSION = '0.001000';
}

# ABSTRACT: Encrypt your code

use Moo;

use Crypt::CBC;
use MIME::Base64 'encode_base64';
has code => ( is => 'rw' );

has [qw( key get_key cipher )] => (
   is => 'ro',
   required => 1,
);

sub bootstrap {
sprintf(<<'BOOTSTRAP', $_[0]->get_key, $_[0]->cipher );
use strict;
use warnings;

use Crypt::CBC;
use MIME::Base64 'decode_base64';

my $key = do {%s};

my $cipher = Crypt::CBC->new(
   -key => $key,
   -cipher => '%s',
);

my $ciphertext = decode_base64(<<'DATA');
%%sDATA

my $plain = $cipher->decrypt($ciphertext);
local $@ = undef;
eval($plain);
if ($@) {
   local $_ = $@;
   if ($ENV{SHOW_CODE}) {
      require Data::Dumper::Concise;
      warn "built code was: " . Data::Dumper::Concise::Dumper($plain);
   }
   die "This code was probably meant to run elsewhere:\n\n$_"
}
BOOTSTRAP
}

sub ciphercode {
   my $self = shift;

   my $cipher = Crypt::CBC->new(
      -key => $self->key,
      -cipher => $self->cipher,
   );

   my $code = $self->code;
   return $cipher->encrypt($code)
}

sub final_code { sprintf $_[0]->bootstrap, encode_base64($_[0]->ciphercode) }

1;

__END__

=pod

=head1 NAME

Code::Crypt - Encrypt your code

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

 use Code::Crypt;

 print "#!/usr/bin/env perl\n\n" . Code::Crypt->new(
    code => 'print "hello world!\n"',
    cipher => 'Crypt::Rijndael',
    get_key => q{
    require Sys::Hostname;
    $] . Sys::Hostname::hostname();
 },
    key => $] . 'wanderlust',
 )->final_code;

=head1 DESCRIPTION

C<Code::Crypt> is meant as a menial form of C<DRM> which protects the code from
being run on unauthorized machines.  The idea is illustrated in the
L</SYNOPSIS>: the code is encrypted with L<Crypt::Rijndael> with a key that is
the current perl version and the string "wanderlust".  We specify that the way
the compiled code is to retrieve a key is to get the perl version and the
hostname.  In this way we can ensure that it is somewhat difficult to take code
meant for one customer and widely distribute it.  Of course this is not
completely foolproof; if the customer distributes the code themselves they can
merely hardcode the key.  See L<Code::Crypt::Graveyard> for an even harder to
work around system.

=head1 METHODS

=head2 C<final_code>

 my $code = $cc->final_code;

This method takes no arguments.  It returns the compiled code based on the
L</ATTRIBUTES>.

=head1 ATTRIBUTES

=head2 C<key>

B<required>.  The key used to encrypt the code.

=head2 C<get_key>

B<required>.  The code to be inlined into the final code to get the key.  Could
read a file, prompt the user, or anything else.

=head2 C<cipher>

B<required>.  The cipher used to encrypt the code.  L<Crypt::Rijndael> is
recommended.  See L<Crypt::CBC> for other options.

=head2 C<code>

The code that will be encrypted.

=head1 SEE ALSO

L<Code::Crypt::Graveyard>

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
