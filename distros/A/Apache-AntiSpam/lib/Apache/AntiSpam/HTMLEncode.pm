package Apache::AntiSpam::HTMLEncode;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Apache::AntiSpam;
use base qw(Apache::AntiSpam);
use HTML::Entities;

sub antispamize {
    my($class, $email, $orig) = @_;
    return encode_entities($orig, '\x00-\xff');
}    

1;
__END__

=head1 NAME

Apache::AntiSpam::HTMLEncode - Encodes E-mail addresses with HTML

=head1 SYNOPSIS

  # in httpd.conf
  <Location /antispam>
  SetHandler perl-script
  PerlHandler Apache::AntiSpam::HTMLEncode
  </Location>

  # filter aware
  PerlModule Apache::Filter
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::RegistryFilter Apache::AntiSpam::HTMLEncode Apache::Compress

=head1 DESCRIPTION

Apache::AntiSpam::HTMLEncode is a subclass of Apache::AntiSpam, filter
module to prevent e-mail addresses exposed as is on web pages. This
module encodes e-mail addresses with HTML.

For example, C<miyagawa@cpan.org> will be filtered to
C<&#109;&#105;&#121;&#97;&#103;&#97;&#119;&#97;&#64;&#99;&#112;&#97;&#110;&#46;&#111;&#114;&#103>.

This won't affect anything on your favourite browsers, but spammers
with crawling-robot plus pattern matching technique won't be able to
extract addresses from this kind of format.

This module is Filter aware, meaning that it can work within
Apache::Filter framework without modification.

=head1 ACKNOWLEDGEMENT

The idea to encode E-mail address with HTML is stolen from
http://perlmonks.org/?node_id=89810

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::AntiSpam>

=cut
