package Aut::Backend::Conf;

# $Id: Conf.pm,v 1.8 2004/04/09 13:05:14 cvs Exp $

use strict;
use Config::Frontend;
use Aut::Ticket;
use Digest::MD5 qw(md5_base64);

sub new {
  my $class=shift;
  my $conf=shift;
  my $self;

  $self->{"conf"}=$conf;
  bless $self,$class;

return $self;
}

sub get_keys {
  my $self=shift;
  my $public=$self->{"conf"}->get("aut_keys.public");
  my $private=$self->{"conf"}->get("aut_keys.private");

  if ((not defined $public) or (not defined $private)) {
    return undef;
  }
  else {
    my @K;
    push @K,$public;
    push @K,$private;
    return @K;
  }
}

sub set_keys {
  my $self=shift;
  my $public=shift;
  my $private=shift;

  $self->{"conf"}->set("aut_keys.public",$public);
  $self->{"conf"}->set("aut_keys.private",$private);
}

sub has_accounts {
  my $self=shift;
  my @vars=$self->{"conf"}->variables();
  my $accounts=0;

  for my $a (@vars) {
    my ($pass,$account)=split /[.]/,$a,2;
    if ($pass eq "aut_pass") {
      $accounts+=1;
    }
  }
return $accounts gt 0;
}

sub get_all_accounts {
  my $self=shift;
  my @vars=$self->{"conf"}->variables();
  my @accounts;

  for my $a (@vars) {
    my ($pass,$account)=split /[.]/,$a,2;
    if ($pass eq "aut_pass") {
      push @accounts,$account;
    }
  }
return @accounts;
}

###

sub internal_set {
  my ($self,$account,$val,$type)=@_;
  $self->{"conf"}->set("aut_$type.$account",$val);
}

sub internal_get {
  my ($self,$account,$type)=@_;
  $self->{"conf"}->get("aut_$type.$account");
}

sub internal_del {
  my ($self,$account,$type)=@_;
  $self->{"conf"}->del("aut_$type.$account");
}

###

sub set {
  my ($self,$account,$var,$val)=@_;
  $self->internal_set($account,$val,"config.$var");
}

sub get {
  my ($self,$account,$var)=@_;
  $self->internal_get($account,"config.$var");
}

sub del {
  my ($self,$account,$var)=@_;
  $self->internal_del($account,"config.$var");
}

sub del_bag {
  my ($self,$account)=@_;
  for my $var ($self->{"conf"}->variables()) {
    if ($var=~/^aut_config/ and $var=~/$account$/) {
      $self->{"conf"}->del($var);
    }
  }
}

###

sub set_pass { 
  my ($self,$account,$pass)=@_;
  $pass=md5_base64($pass);
  $self->internal_set($account,$pass,"pass"); 
}

sub set_rsa_pass { internal_set(@_,"rsa_pass"); }
sub set_rights { internal_set(@_,"rights"); }
sub set_seed { internal_set(@_,"seed"); }
sub set_sr_hash{ internal_set(@_,"sr_hash"); }

# There is no get_pass. Passwords are only checked
sub get_rsa_pass { internal_get(@_,"rsa_pass"); }
sub get_rights { internal_get(@_,"rights"); }
sub get_seed { internal_get(@_,"seed"); }
sub get_sr_hash { internal_get(@_,"sr_hash"); }

sub del_pass { internal_del(@_,"pass"); }
sub del_rsa_pass { internal_del(@_,"rsa_pass"); }
sub del_rights { internal_del(@_,"rights"); }
sub del_seed { internal_del(@_,"seed"); }
sub del_sr_hash { internal_del(@_,"sr_hash"); }

sub del_account {
  del_pass(@_);
  del_rsa_pass(@_);
  del_rights(@_);
  del_seed(@_);
  del_sr_hash(@_);
  del_bag(@_);
}

sub pass_ok {
  my ($self,$account,$pass)=@_;
  $pass=md5_base64($pass);
  my $stored_pass=$self->internal_get($account,"pass");
 return ($stored_pass eq $pass);
}

sub exists {
  return (defined internal_get(@_,"pass"));
}

1;
__END__

=head1 NAME

Aut::Backend::Conf - A Config::Frontend backend to Aut.

=head1 SYNOPSIS

    use Aut;
    use Aut::UI::Console;
    use Aut::Backend::Conf;
    use Config::Frontend;
    use Config::Backend::INIREG;

    use strict;

    my $cfg=new Config::Frontend(new Config::Backend::INIREG("Application"));
    my $backend=new Aut::Backend::Conf($cfg);
    my $ui=new Aut::UI::Console();

    my $aut=new Aut( Backend => $backend, 
                     UI => $ui, 
                   );

    (...)


=head1 ABSTRACT

'Aut::Backend::Conf' is part of the 'Aut' authorization framework.
It provides the a Config::Frontend Aut backend for storing and
fetching account related information.

This module can be used as an example module for implementing
Aut backends. As it is, it isn't secure enough to be a real
Aut backend, because if someone wants to do harm, he/she can just
delete e.g. the private key from the configuration file.

A secure backend would be using more secure backends, like implementing
it directly on top of an other account system (passwd, SAM, database
user access tables, etc.).

=head1 DESCRIPTION

=head2 Instantiating

=head3 C<new(Config::Frontend) --E<gt> Aut::Backend::Conf>

=over 1

This method instantiates a new Aut::Backend::Conf object with
given L<Conf::Frontend> object. 

=back

=head2 Querying

=head3 C<get_keys() --E<gt> (list public_key:string private_key:string)>

=over 1

This function returns the currently stored RSA KeyPair in the backend,
or C<undef> if they do not exist.

=back

=head3 C<has_accounts() --E<gt> boolean>

=over 1

Returns true, if there are any accounts stored in the backend, returns
false, otherwise.

=back

=head3 C<get_all_accounts() --E<gt> (list account:string)>

=over 1

Returns all accounts stored in the backend as a list of strings.

=back

=head3 C<pass_ok(account:string, given_pass:string) --E<gt> boolean>

=over 1

Returns true, if the password given for the account is valid.
Returns false, otherwise.

=back

=head3 C<exists(account:string) --E<gt> boolean>

Returns true, if account exists in the backend; false otherwise.

=head2 Retreiving  account information

=head3 C<get_rsa_pass(account:string) --E<gt> rsa_cipher_text>

=over 1

Returns the with RSA public key encrypted password for an account,
or undef if account does not exist.

=back

=head3 C<get_rights(account:string) --E<gt> string>

=over 1

Returns the rights stored for an account,
or undef if account does not exist.

=back

=head3 C<get_seed(account:string) --E<gt> string>

=over 1

Returns the seed stored for an account,
or undef if account does not exist.

=back

=head3 C<get_sr_hash(account:string) --E<gt> string>

=over 1

Returns the stored MD5 hash over the concatenation of
rights and seed, or undef if account does not exist.

=back

=head2 Storing account information

=head3 C<set_keys(public:string,private:string) --E<gt> void>

=over 1

Stores the RSA keypair as given by public and private.

=back

=head3 C<set_rsa_pass( account:string, pass:rsa_cipher_text(string) ) --E<gt> void>

=over 1

Stores the with the RSA public key encrypted password
for account.

=back

=head3 C<set_rights(account:string, rights:string) --E<gt> void>

=over 1

Stores the rights for an account.

=back 

=head3 C<set_seed(account:string, seed:string) --E<gt> void>

=over 1

Stores the seed that is used for keys for an account.

=back

=head3 C<set_sr_hash(account:string, hash:md5_base64(string) ) --E<gt> void>

=over 1

Stores the MD5 hash that has been calculated over the concatenation
of rights and seed.

=back

=head2 Deletion

=head3 C<del_account(account:string) --E<gt> void>

=over 1

Deletes account from the backend.

=back 

=head1 SEE ALSO

L<Aut framework|Aut>, L<Aut::Ticket|Aut::Ticket>

=head1 AUTHOR

Hans Oesterholt-Dijkema <oesterhol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under Artistic license

=cut


