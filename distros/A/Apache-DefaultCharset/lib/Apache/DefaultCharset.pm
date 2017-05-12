package Apache::DefaultCharset;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

require DynaLoader;
use base qw(DynaLoader);
__PACKAGE__->bootstrap($VERSION) if $ENV{MOD_PERL};

use overload q("") => sub { _get($_[0]->{r}) };

sub new {
    my($class, $r) = @_;
    bless { r => $r }, $class;
}

sub name {
    my $self = shift;
    if (@_ == 1) {
	_set($self->{r}, @_);
    } else {
	return _get($self->{r});
    }
}

package Apache;

sub add_default_charset_name {
    my $r = shift;
    if (@_ == 1) {
	Apache::DefaultCharset::_set($r, @_);
    } else {
	return Apache::DefaultCharset::_get($r);
    }
}

1;
__END__

=head1 NAME

Apache::DefaultCharset - AddDefaultCharset configuration from mod_perl

=head1 SYNOPSIS

  use Apache::DefaultCharset;

  # This module adds "add_default_charset_name" method
  $charset = $r->add_default_charset_name;
  $r->add_default_charset_name('euc-jp');

  # via Apache::DefaultCharset object
  $charset = Apache::DefaultCharset->new($r);
  print "default_charset_name is ", $charset->name;
  # or print "default charset is $charset"; will do (overload)
  $charset->name('euc-jp');


=head1 DESCRIPTION

Apache::DefaultCharset is an XS wrapper for Apache Core's
C<AddDefaultCharset> configuration.

=head1 EXAMPLES

=head2 Unicode Handling

Suppose you develop multi-language web application, and transparently
decode native encodings into Unicode string inside Perl (5.8 or over
would be better). First you should add

  AddDefaultCharset euc-jp

in your C<httpd.conf>, then leave off C<send_http_header> arguments
just to text/html. Then you can get the current configuration with
this module when you use C<Encode> or C<Text::Iconv> to decode the HTTP
request query into Unicode.

=head2 Modification of DefaultCharset

Suppose you want to add utf-8 for XML files, and Shift_JIS for HTML
files as HTTP charset attribute by default ("By default" means that if
you set C<content_type> explicitly in content-generation phase, that
will be prior to the defalut). This module enables you to write
C<PerlFixupHandler> to configure C<add_default_charset_name> in
run-time.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::DefaultCharset>

mod_perl cookbook at http://www.modperlcookbook.org/

=cut
