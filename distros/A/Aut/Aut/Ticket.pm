package Aut::Ticket;

use strict;

use Aut::Base64;
use Aut::Crypt;

srand(time());

sub new {
    my $class=shift;
    my $account=shift;
    my $pass=shift;

    my $self;

    $self->{"conf"}->{"aut"}="there";

    $self->{"pass"}=$pass;
    $self->{"account"}=$account;
    $self->{"valid"}=1;

    my $s="";
    while (length($s)<32) {
      $s.=rand();
      $s=~s/[^0-9]//g;
    }
    $s=substr($s,0,32);
    $self->{"seed"}=$s;

    bless $self,$class;
return $self;
}

sub invalidate {
  my $self=shift;
  $self->{"valid"}=0;
}

sub valid {
  my $self=shift;
return $self->{"valid"};
}

sub rights {
  my $self=shift;
return $self->{"rights"};
}

sub account {
  my $self=shift;
return $self->{"account"};
}

sub pass {
  my $self=shift;
return $self->{"pass"};
}

sub seed {
  my $self=shift;
return $self->{"seed"};
}


sub set_rights {
  my $self=shift;
  my $rights=shift;
  $self->{"rights"}=$rights;
}

sub set_seed {
  my $self=shift;
  my $seed=shift;
  $self->{"seed"}=$seed;
}

sub set_pass {
  my $self=shift;
  my $pass=shift;
  $self->{"pass"}=$pass;
}

sub gen6 {
  my $r="";

  while (length $r lt 6) {
    $r.=rand();
    $r=~s/[.]//;
    $r=~s/^0//;
  }
  $r=substr($r,0,6);
return $r;
}

sub encrypt {
  my $self=shift;
  my $text=shift;
  my $crypter=new Aut::Crypt($self->seed());
  my $base64=new Aut::Base64();
  my $r=gen6();
return $base64->encode($crypter->encrypt("$r$r".$text));
}

sub decrypt {
  my $self=shift;
  my $text=shift;
  my $dtext;
  my $crypter=new Aut::Crypt($self->seed());
  my $base64=new Aut::Base64();

  $dtext=$crypter->decrypt($base64->decode($text));
  my $r1=substr($dtext,0,6);
  my $r2=substr($dtext,6,6);
  if ($r1 ne $r2) {
    return undef;
  }
  else {
    return substr($dtext,12,length($dtext));
  }
}

sub set {
  my $self=shift;
  my $var=shift;
  my $val=shift;
  $self->{"conf"}->{$var}=$val;
}

sub get {
  my $self=shift;
  my $var=shift;
return  $self->{"conf"}->{$var};
}

1;
__END__

=head1 NAME

Aut::Ticket - Authorization Framework - Tickets

=head1 SYNOPSIS

See L<Aut|Aut>.
=head1 ABSTRACT

'Aut::Ticket' is part of the 'Aut' authorization framework
It provides tickets that are the user's access to services
and application parts. It also provides encryption/decryption
for user data.

=head1 DESCRIPTION

=over 1

=item *

A ticket consists of an account, a password, user's rights and a key value
used for symmetric encryption algorithms. 

=item *

Rights are fully transparant for a ticket. The application context prescribes
the rights that can be used. A ticket's rights value is just a string.

=item *

The key value, called C<seed> in the
Aut::Ticket context, is a (random) value of 32 digits, that is generated when
a new ticket is made and can be set through public  methods.

=item *

A ticket can be valid and invalid. 

=item *

A ticket acts like a bag. You can set and get extra values to and from it.

=back

=head2 Instantiating

=head3 C<new(account,password)> --E<gt> Aut::Ticket

=over 1

This method initializes a ticket with a given account and password and generates
a new seed.

=back 

=head2 Querying

=head3 C<valid() --E<gt> boolean>

=over 1

Returns true, if the ticket is valid, returns False, otherwise.

=back 

=head3 C<rights() --E<gt> string>

=over 1

Returns the currently assigned "rights" value to this ticket.

=back 

=head3 C<account() --E<gt> string>

=over 1

Returns the currently assigned account for this ticket.

=back 

=head3 C<pass() --E<gt> string>

=over 1

Returns the currently assigned password for this ticket.

=back 

=head3 C<seed() --E<gt> string>

=over 1

Returns the seed value of this ticket that is being used for
encryption/decryption.

=back 

=head3 C<get(var) --E<gt> string>

=over 1

Gets value for 'var' from the ticket.

=back

=head2 Setting

=head3 C<invalidate() --E<gt> void>

=over 1

Invalidates a ticket.

=back 

=head3 C<set_rights(_rights) --E<gt> void>

=over 1

Sets the rights value of the ticket to _rights.

=back

=head3 C<set_pass(_pass) --E<gt> void>

=over 1

Sets the password of the ticket to _pass.

=back

=head3 C<set_seed(_seed) --E<gt> void>

=over 1

Sets the seed value of the ticket (the encryption key) to _seed.

=back

=head3 C<set(var,val) --E<gt> void>

=over 1

Sets a variable 'var' in the ticket to value 'val'.

=back


=head2 Encryption/Decryption

=head3 C<encrypt(text) --E<gt> base64 string>

=over 1

Encrypts text using L<Aut::Crypt>, with key C<seed()>; returns
a base64 encoded (with L<Aut::Base64>) encrypted string.

=back

=head3 C<decrypt(ciphertext) --E<gt> string>

=over 1

Decrypts text using L<Aut::Crypt>, after it has been decoded
with L<Aut::Base64>. If the decryption is valid, it returns
the decrypted string, otherwise C<undef> is returned.

=head1 SEE ALSO

L<Aut framework|Aut>, L<Aut::Base64|Aut::Base64>, L<Aut::Crypt|Aut::Crypt>.

=head1 AUTHOR

Hans Oesterholt-Dijkema <oesterhol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under Artistic license.

=cut


