package Business::OnlinePayment::Multiplex;

use 5.008004;
use strict;
use warnings;
use Carp;
use Business::OnlinePayment;

our @ISA = qw(Business::OnlinePayment);

our @EXPORT_OK = ();

our @EXPORT = ();

our $VERSION = '0.01';


sub submit {
    my $self = shift;
    my %content = $self->content();
    &{$content{submit}}($self);
}

1;
__END__

=head1 NAME

Business::OnlinePayment::Multiplex - Perl extension using the 
Business::OnlinePayment interface to add a callback to the content hash

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $submit = sub {
    my $self = shift;
    my %content = $self->content;
    undef $content{submit};
    my $tx = new Business::OnlinePayment('StoredTransaction');
    $tx->content(
        %content
    );
    my $submit = $tx->submit;
    $self->is_success($tx->is_success);
    $self->authorization($tx->authorization);
    $self->error_message($tx->error_message);
    $self->result_code($tx->result_code);
    return $submit;
  };


  my $tx = new Business::OnlinePayment('Multiplex');
  $tx->content( submit => $submit,
                type => 'Visa',
                amount => '1.00',
                cardnumber => '1234123412341238',
                expiration => '0100',
                action => 'normal authorization',
                name => 'John Doe',
                password => '-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAOoKKH0CZm6sWHGg4SygikvvAecDS+Lx6ilUZ8mIVJeV2d6YjEJRjy12
TSFdJTC0SiBDbJ4UHz5ayXhLShK0VvaQY+sfZwMX1SNZNYUyO8T7gY7QCzOrcSTS
CcBBrNWzz0CMWUO5oOIIYevKEimtsDvBtlVaYJArJdwJq9KB/RjRAgMA//8=
-----END RSA PUBLIC KEY-----' );

  $tx->submit();
  if ($tx->is_success()) {
      my $auth = $tx->authorization();
      open FH, '>> /some/file' # don't do this it's stupid
      print FH $auth;
  }
  else {
      warn $tx->error_message();
  }


=head1 DESCRIPTION

  Adds a submit key to the content hash.  This key should have a coderef as
  a value.  It should set error_message, is_success and suchlike if it wants
  to be successful.  This is possibly the stupidest module I've ever made
  (functionally it is about 5 lines of code) however I've found it very
  useful for mangling other peoples BOP modules and mashing them together in
  odd ways.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Business::OnlinePayment

=head1 AUTHOR

mock, E<lt>mock@obscurity.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by mock 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
