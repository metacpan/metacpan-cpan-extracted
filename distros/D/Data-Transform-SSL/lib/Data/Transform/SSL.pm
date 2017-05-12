package Data::Transform::SSL;
use strict;
use warnings;

=head1 NAME

Data::Transform::SSL - SSL in a filter

=head1 DESCRIPTION

=head1 PUBLIC API

Data::Transform::SSL implements the L<Data::Transform> API. Only
differences and additions are documented here.

=cut

use base qw(Data::Transform);

our $VERSION = '0.03';

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Net::SSLeay qw(die_now);
Net::SSLeay::load_error_strings();
Net::SSLeay::ERR_load_crypto_strings;
Net::SSLeay::SSLeay_add_ssl_algorithms();
Net::SSLeay::randomize();

sub BUF    () {  0 }
sub CTX    () {  1 }
sub SSL    () {  2 }
sub RB     () {  3 }
sub WB     () {  4 }
sub STATE  () {  5 }
sub KEY    () {  6 }
sub CERT   () {  7 }
sub TYPE   () {  8 }
sub OUTBUF () {  9 }
sub FLAGS  () { 10 }

sub STATE_DISC ()     { 0 }
sub STATE_CONN ()     { 1 }
sub STATE_SHUTDOWN () { 2 }

sub TYPE_SERVER () { 0 }
sub TYPE_CLIENT () { 1 }

# from IO::Socket::SSL
# from openssl/ssl.h, should be better in Net::SSLeay
sub SSL_SENT_SHUTDOWN     () { 1 }
sub SSL_RECEIVED_SHUTDOWN () { 2 }

# from openssl/x509_vfy.h
sub X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT () { 18 }

sub FLAGS_ALLOW_SELFSIGNED () { 0x00000001 }

sub _init {
   my ($self) = @_;

   my %args = ();
   if ($self->[TYPE] == TYPE_CLIENT) {
      # don't reference $self, so there isn't an extra reference keeping
      # it alive too long
      my $flags = $self->[FLAGS];
      $args{SSL_verify_callback} = sub {
         my ($ok, $ctx_store) = @_;
            my $cert = Net::SSLeay::X509_STORE_CTX_get_current_cert($ctx_store);
	    my $error = Net::SSLeay::X509_STORE_CTX_get_error($ctx_store);
            warn Net::SSLeay::X509_verify_cert_error_string($error);
            my $issuer = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($cert)); 
            my $subject = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($cert));
            return 1
               if ($error == X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT and $flags & FLAGS_ALLOW_SELFSIGNED);
         return $ok;
      };
   }
   my $ctx = Net::SSLeay::CTX_new
      or die_now("Failed to create SSL_CTX $!");
   Net::SSLeay::CTX_set_options($ctx, Net::SSLeay::OP_ALL())
      and die_if_ssl_error("Failed to set compatibility options");

   if ($self->[TYPE] == TYPE_SERVER) {
      Net::SSLeay::CTX_set_cipher_list($ctx, 'ALL');
      Net::SSLeay::set_cert_and_key($ctx,
            $self->[CERT],
            $self->[KEY],
         ) or die "key $!";
   } else {
      Net::SSLeay::CTX_load_verify_locations($ctx, '', '/etc/ssl/certs/');
      Net::SSLeay::CTX_set_verify($ctx, Net::SSLeay::VERIFY_PEER(), $args{SSL_verify_callback});
   }
   # enable revocation checking
   # FIXME figure out how to do this only when we have a CRL because
   # certificate verifying returns an error if there isn't one.
#   my $store = Net::SSLeay::CTX_get_cert_store($ctx);
#   my $flag = Net::SSLeay::X509_V_FLAG_CRL_CHECK();
#   Net::SSLeay::X509_STORE_set_flags(
#     Net::SSLeay::CTX_get_cert_store($ctx),
#     Net::SSLeay::X509_V_FLAG_CRL_CHECK(),
#   );
   my $ssl = Net::SSLeay::new($ctx)
      or die_now("Failed to create SSL $!");
   if ($self->[TYPE] == TYPE_SERVER) {
      Net::SSLeay::set_cipher_list($ssl, 'ALL')
         or die_now("Failed to set cipher list $!");
   }
   my $rb = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem())
      or die_now("Could not create memory BIO $!");
   my $wb = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem())
      or die_now("Could not create memory BIO $!");
   Net::SSLeay::set_bio($ssl, $rb, $wb);

   @{$self}[CTX..STATE] = ($ctx, $ssl, $rb, $wb, STATE_DISC);
   return $self;
}

=head1 new

Accepts the following parameters:

=over 2

=item type

If set to 'Server', the filter will act like a server-side ssl filter,
otherwise it will act like a client-side one. If the filter is a
server-side one, the 'cert' and 'key' parameters are required.

=item cert

The filename of the cert to use.

=item key

The filename of the key to use.

=back

=cut

sub new {
   my $class = shift;
   my %opts = @_;

   my $self = bless [], $class;

   croak "You must either supply both key and cert, or neither"
      if (defined ($opts{key}) xor defined ($opts{cert}));
   if (defined $opts{key}) {
      $self->[KEY] = $opts{key};
      $self->[CERT] = $opts{cert};
   }

   $self->[TYPE] = (defined $opts{type} and $opts{type} eq 'Server') ? TYPE_SERVER : TYPE_CLIENT;
   croak "A server-side filter requires a cert and key"
      if ($self->[TYPE] == TYPE_SERVER and not defined $self->[KEY]);

   $self->[BUF] = [];
   $self->[FLAGS] = $opts{flags} ? $opts{flags} : 0;

   return $self->_init;
}

sub clone {
   my $self = shift;

   my $new_self = bless [], ref($self);
   $new_self->[TYPE] = $self->[TYPE];
   $new_self->[BUF] = [ ];
   $new_self->[CERT] = $self->[CERT];
   $new_self->[KEY] = $self->[KEY];
   $new_self->[FLAGS] = $self->[FLAGS];
   return $new_self->_init;
}

sub _try_connection {
      my $self = shift;

      my $rv;
      if ($self->[TYPE] == TYPE_SERVER) {
         $rv = Net::SSLeay::accept($self->[SSL]);
      } else {
         $rv = Net::SSLeay::connect($self->[SSL]);
      }

      if ($rv < 0) {
         my $err = Net::SSLeay::get_error($self->[SSL], $rv);
         if ($err == Net::SSLeay::ERROR_WANT_READ()) {
	    my $data = Net::SSLeay::BIO_read($self->[WB]);
            return $data;
         } else {
	    # uh oh, something went wrong
	    # theoretically, this could be ERROR_WANT_WRITE but
	    # I think that will not happen since we write to a
	    # memory buffer, which should always work. So assume
            # it is an actual error and return its description
            # FIXME probably check for ERROR_WANT_WRITE anyway
            my $str;
            while (my $e = Net::SSLeay::ERR_get_error) {
               $str .= Net::SSLeay::ERR_error_string($e) . "\n";
            }
            my $ret = Data::Transform::Meta::Error->new($str);
            return $ret;
         }
      } elsif ($rv == 1) {
         $self->[STATE] = STATE_CONN;

         # SSL handshake done. send out any data already
         # received from the client.
         if (defined $self->[OUTBUF]) {
	    my $data = join ('', @{delete $self->[OUTBUF]});
	    Net::SSLeay::write($self->[SSL], $data);
         }
         return Net::SSLeay::BIO_read($self->[WB]);
      }
   return;
}

sub _handle_get_data {
   my ($self, $newdata) = @_;

   if (defined $newdata) {
      Net::SSLeay::BIO_write($self->[RB], $newdata);
   }

   return unless (Net::SSLeay::BIO_pending($self->[RB]) or $self->[STATE] == STATE_DISC);

   if ($self->[STATE] == STATE_DISC) {
      if (my $data = $self->_try_connection) {
         if (blessed $data and $data->isa('Data::Transform::Meta::Error')) {
            return $data;
         } else {
            my $ret = Data::Transform::Meta::SENDBACK->new($data);
            return $ret;
         }
      }
   } elsif ($self->[STATE] == STATE_CONN) {
      my $got = Net::SSLeay::read($self->[SSL]);
      my $shutdown = Net::SSLeay::get_shutdown($self->[SSL]);
      if ($shutdown == SSL_RECEIVED_SHUTDOWN()) {
         Net::SSLeay::shutdown($self->[SSL]);
         my $notify = Net::SSLeay::BIO_read($self->[WB]);
         my $ret = Data::Transform::Meta::SENDBACK->new($notify);
         $self->[STATE] = STATE_SHUTDOWN;
         return $ret;
      }
      return $got if (defined $got);
   } elsif ($self->[STATE] == STATE_SHUTDOWN) {
      #my $ret Data::Transform::Meta::EOF->new;
      #return $ret;
   }
   return;
}

sub _handle_put_meta {
   my ($self, $meta) = @_;

   if ($meta->isa('Data::Transform::Meta::EOF')) {
      my $rv = Net::SSLeay::shutdown($self->[SSL]);
      my $shutdown = Net::SSLeay::get_shutdown($self->[SSL]);
      if ($shutdown == SSL_SENT_SHUTDOWN()) {
      }
      my $notify = Net::SSLeay::BIO_read($self->[WB]);
      $self->[STATE] = STATE_SHUTDOWN;
      return $notify, $meta;
   }
   return $meta;
}

sub _handle_put_data {
   my ($self, $stream) = @_;

   if ($self->[STATE] == STATE_DISC) {
      # In SSL, the client starts the handshake. Since this is a 
      # filter, there's no way to trigger on some on_connect event
      # so we do it once we receive the first data from the user.
      # Store that data until the handshake is done.
      push (@{$self->[OUTBUF]}, $stream);

      return $self->_try_connection;
   } else {
      Net::SSLeay::write($self->[SSL], $stream);
      my $ret = Net::SSLeay::BIO_read($self->[WB]);
      return $ret if $ret;
   }
   return;
}

sub DESTROY {
  my $self = shift;

  Net::SSLeay::free ($self->[SSL]);
  Net::SSLeay::CTX_free ($self->[CTX]);
}

1;

__END__

=head1 SEE ALSO

L<Data::Transform>, L<Net::SSLeay>

=head1 AUTHOR

Martijn van Beers  <martijn@cpan.org>

=head1 LICENSE

Data::Transform::SSL is released under the GPL version 2.0 or higher.
See the file LICENSE for details.

=cut

