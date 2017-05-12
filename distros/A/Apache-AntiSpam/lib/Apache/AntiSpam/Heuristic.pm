package Apache::AntiSpam::Heuristic;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Apache::AntiSpam;
use base qw(Apache::AntiSpam);

sub antispamize {
    my($class, $email, $orig) = @_;
    $orig =~ s/\@/ at /g;
    $orig =~ s/\./ dot /g;
    $orig =~ s/  */ /g;
    return $orig;
}    

1;
__END__

=head1 NAME

Apache::AntiSpam::Heuristic - Filters E-mail address to heuristic one

=head1 SYNOPSIS

  # in httpd.conf
  <Location /antispam>
  SetHandler perl-script
  PerlHandler Apache::AntiSpam::Heuristic
  </Location>

  # filter aware
  PerlModule Apache::Filter
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::RegistryFilter Apache::AntiSpam::Heuristic Apache::Compress

=head1 DESCRIPTION

Apache::AntiSpam::Heuristic is a subclass of Apache::AntiSpam, filter
module to prevent e-mail addresses exposed as is on web pages. This
module filters e-mail addresses to heuristic ones.

For example, C<miyagawa@cpan.org> will be filtered to C<miyagawa at
cpan dot org>.

This module is Filter aware, meaning that it can work within
Apache::Filter framework without modification.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::AntiSpam>

=cut
