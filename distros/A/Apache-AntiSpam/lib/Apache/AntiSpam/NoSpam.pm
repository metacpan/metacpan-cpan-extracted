package Apache::AntiSpam::NoSpam;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Apache::AntiSpam;
use base qw(Apache::AntiSpam);

sub antispamize {
    my($class, $email, $orig) = @_;
    $orig =~ s/\@/-nospam\@/;
    return $orig;
}    

1;
__END__

=head1 NAME

Apache::AntiSpam::NoSpam - Add suffix to local-part in Email

=head1 SYNOPSIS

  # in httpd.conf
  <Location /antispam>
  SetHandler perl-script
  PerlHandler Apache::AntiSpam::NoSpam
  </Location>

  # filter aware
  PerlModule Apache::Filter
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::RegistryFilter Apache::AntiSpam::NoSpam Apache::Compress

=head1 DESCRIPTION

Apache::AntiSpam::NoSpam is a subclass of Apache::AntiSpam, filter
module to prevent e-mail addresses exposed as is on web pages. This
module adds B<-nospam> suffix to local-part of e-mail addresses.

For example, C<miyagawa@cpan.org> will be filtered to
C<miyagawa-nospam@cpan.org>.

This module is Filter aware, meaning that it can work within
Apache::Filter framework without modification.

=head1 TODO

=over 4

=item *

should make -nospam suffix be configured.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::AntiSpam>

=cut
