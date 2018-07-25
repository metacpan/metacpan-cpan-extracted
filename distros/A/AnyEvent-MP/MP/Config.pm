=head1 NAME

AnyEvent::MP::Config - configuration handling

=head1 SYNOPSIS

   # see the "aemp" command line utility

=head1 DESCRIPTION

Move along please, nothing to see here at the moment.

=cut

package AnyEvent::MP::Config;

use common::sense;

use Carp ();
use AnyEvent ();
use JSON::XS ();

our $VERSION = '2.01';

our $CONFIG_FILE = exists $ENV{PERL_ANYEVENT_MP_RC} ? $ENV{PERL_ANYEVENT_MP_RC}
                   : exists $ENV{HOME}              ? "$ENV{HOME}/.perl-anyevent-mp"
                   :                                  "$ENV{APPDATA}/perl-anyevent-mp";

our %CFG;

sub load {
   if (open my $fh, "<:raw", $CONFIG_FILE) {
      return if eval {
         local $/;
         %CFG = %{ JSON::XS->new->utf8->relaxed->decode (scalar <$fh>) };
         1
      };
   }

   %CFG = (
      version => 1,
   );
}

sub save {
   return unless delete $CFG{dirty};

   open my $fh, ">:raw", "$CONFIG_FILE~new~"
      or Carp::croak "$CONFIG_FILE~new~: $!";

   syswrite $fh, JSON::XS->new->pretty->utf8->encode (\%CFG) . "\n"
      or Carp::croak "$CONFIG_FILE~new~: $!";

   close $fh
      or Carp::croak "$CONFIG_FILE~new~: $!";

   unlink "$CONFIG_FILE~";
   link $CONFIG_FILE, "$CONFIG_FILE~";
   rename "$CONFIG_FILE~new~", $CONFIG_FILE
      or Carp::croak "$CONFIG_FILE: $!";
}

sub config {
   \%CFG
}

sub _find_profile($);
sub _find_profile($) {
   my ($name) = @_;

   if (defined $name) {
      my $profile = $CFG{profile}{$name};
      return _find_profile $profile->{parent}, %$profile;
   } else {
      return %CFG;
   }
}

sub find_profile($;%) {
   my ($name, %kv) = @_;

   my $norc  = delete $kv{norc};
   my $force = delete $kv{force};

   %kv = (
      monitor_timeout  => 30,
      connect_interval => 2,
      framing_format   => [qw(cbor json storable)], # framing types we offer and accept, in order of preference
      auth_offer       => [qw(tls_sha3_512 hmac_sha3_512)], # what we will send
      auth_accept      => [qw(tls_sha3_512 hmac_sha3_512 tls_anon cleartext)], # what we accept
      %kv,
   );

   unless ($norc) {
      if ($force) {
         %kv = (_find_profile $name, %kv);
      } else {
         %kv = (%kv, _find_profile $name);
      }
   }

   \%kv
}

load;
END { save }

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

