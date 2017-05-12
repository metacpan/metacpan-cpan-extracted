package Apache::AntiSpam::SpamTrap;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Apache::AntiSpam;
use Apache::Constants qw(:common);
use base qw(Apache::AntiSpam);
use Crypt::Blowfish;

sub antispamize {
    my($class, $email, $orig) = @_;
    # this seems not very efficient
    my $r = Apache->request();
    # better error handling?
    my $key = $r->dir_config('Key') || return SERVER_ERROR;
    my $ip = $r->get_remote_host || return SERVER_ERROR;
    my $time = time;
    my $string = spamtrap_encode($ip, $time, $key);
    $orig =~ s/\@/-$string\@/;
    return $orig;
}

sub spamtrap_encode
  {
    my ($ip, $time, $key) = @_;
    return unless $key;
    return unless $time > 0;
    return unless $ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/o;
    my $inkey = pack("H16", $key);
    my $plaintext = join("", map { chr } split (/\./, $ip)) . pack("L", $time);
    my $cipher = new Crypt::Blowfish $inkey;
    my $string = unpack("H*", $cipher->encrypt($plaintext));
    return $string;
  }


1;
__END__

=head1 NAME

Apache::AntiSpam::SpamTrap - Add SpamTrap suffix to local-part in Email

=head1 SYNOPSIS

  # in httpd.conf
  <Location /antispam>
  SetHandler perl-script
  PerlAddVar Key 0123456789ABCDEF
  PerlHandler Apache::AntiSpam::SpamTrap
  </Location>

  # filter aware
  PerlModule Apache::Filter
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::RegistryFilter Apache::AntiSpam::SpamTrap Apache::Compress

=head1 DESCRIPTION

Apache::AntiSpam::SpamTrap is a subclass of Apache::AntiSpam, filter
module to prevent e-mail addresses exposed as is on web pages. This
module adds a Blowfish encrypted string suffix to the local-part of 
e-mail addresses. This string contains a timestamp and the IP address
of the remote host. This enables you to identify a spammer's address
harvester by its IP address and take steps to prosecute him.

The encryption prevents faking and may help in a prosecuting attemp.

For example, C<apleiner@cpan.org> will be filtered to
C<apleiner-78c1ed6da0322b3a@cpan.org>.

This module is Filter aware, meaning that it can work within
Apache::Filter framework without modification.

You need to give the Blowfish key in your Apache configuration file.

To decode a received mail's SpamTrap string use the following function:

  sub spamtrap_decode
    {
      my ($string, $key) = @_;
      return unless $key;
      return unless $string =~ /[0-9a-f]{16}/o;
      my $inkey = pack("H16", $key);
      use Crypt::Blowfish;
      my $cipher = new Crypt::Blowfish $inkey;
      my $plaintext = $cipher->decrypt(pack("H*", $string));
      my $time = unpack("L", substr($plaintext, 4, 4));
      my $ip = join(".", map { ord } split //, substr($plaintext, 0, 4));
      return wantarray ? ($ip, $time) : "$ip $time";
    }


=head1 TODO

=over 4

=item *

should make local address part be configured.

=back

=head1 AUTHOR

Alex Pleiner <alex@zeitform.de> - zeitform Internet Dienste 2003

This work is based on the Apache::AntiSpam::* modules provided by
Tatsuhiko Miyagawa <miyagawa@bulknews.net>. The idea is taken from
Daniel A. Rehbein (http://daniel.rehbein.net/).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::AntiSpam>

=cut



