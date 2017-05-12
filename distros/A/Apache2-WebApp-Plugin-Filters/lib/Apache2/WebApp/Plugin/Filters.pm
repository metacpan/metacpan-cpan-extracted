#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::Filters - Plugin providing data filtering methods
#
#  DESCRIPTION
#  Common methods for filtering HTTP request parameters.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::Filters;

use strict;
use base 'Apache2::WebApp::Plugin';
use HTML::StripScripts::Parser;
use Params::Validate qw( :all );

our $VERSION = 0.09;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# encode_url($url)
#
# Encode URL to ASCII.

sub encode_url {
    my ( $self, $url )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    $url =~ s/([\W])/"%" . uc( sprintf("%2.2x", ord($1)) )/eg;
    return $url;
}

#----------------------------------------------------------------------------+
# decode_url($url)
#
# Decode ASCII to URL.

sub decode_url {
    my ( $self, $url ) 
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    $url =~ tr/+/ /;
    $url =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $url =~ s/<!--(.|\n)*-->//g;
    return $url;
}

#----------------------------------------------------------------------------+
# strip_domain_alias($domain)
#
# Remove the subdomain (alias) from a domain name.

sub strip_domain_alias {
    my ( $self, $domain ) 
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    $domain =~ /(?: |\.|\-)([\w-]+?)\.(\w+?) \z/xs;
    return "$1.$2";
}

#----------------------------------------------------------------------------+
# strip_html($markup)
#
# Remove all HTML tags and attributes.

sub strip_html {
    my ( $self, $markup )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    my $hs = HTML::StripScripts::Parser->new({
        Context => 'NoTags',
      });

    my $text = $hs->filter_html($markup);
    $text =~ s/<!--filtered-->//g;
    return $text;
}

#----------------------------------------------------------------------------+
# untaint_html($markup)
#
# Remove restricted HTML tags and attributes.

sub untaint_html {
    my ( $self, $markup ) 
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    my $hs = HTML::StripScripts::Parser->new({
        AllowHref   => 1,
        AllowRelURL => 1,
        AllowSrc    => 1,
        BanAllBut   => [qw(
          a blockquote br dd dl div em font form img input hr h1 h2 h3 h4 h5 h6
          label legend li ol option p pre ul script select small span strong style
          table tbody tfoot thead tr td
        )],
      });

    my $text = $hs->filter_html($markup);
    $text =~ s/<!--filtered-->//g;
    return $text;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# _init(\%params)
#
# Return a reference of $self to the caller.

sub _init {
    my ( $self, $params ) = @_;
    return $self;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Plugin::Filters - Plugin providing data filtering methods

=head1 SYNOPSIS

  my $obj = $c->plugin('Filters')->method( ... );     # Apache2::WebApp::Plugin::Filters->method()

    or

  $c->plugin('Filters')->method( ... );

=head1 DESCRIPTION

Common methods for filtering HTTP request parameters.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  HTML::StripScripts::Parser
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-Filters-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::Filters'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::Filters
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 OBJECT METHODS

=head2 encode_url

Encode URL to ASCII.

  my $ascii = $c->plugin('Filters')->encode_url($url);

=head2 decode_url

Decode ASCII to URL.

  my $url = $c->plugin('Filters')->decode_url($url);

=head2 strip_domain_alias

Remove the subdomain (alias) from a domain name.

  my $result = $c->plugin('Filters')->strip_domain_alias($domain);

=head2 strip_html

Remove all HTML tags and attributes.

  my $result = $c->plugin('Filters')->strip_html($markup);

=head2 untaint_html

Remove restricted HTML tags and attributes.

  my $result = $c->plugin('Filters')->untaint_html($markup);

Supported tags:

  a blockquote br dd dl div em font form img input hr h1 h2 h3 h4 h5 h6
  label legend li ol option p pre ul script select small span strong style
  table tbody tfoot thead tr td

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<HTML::StripScripts::Parser>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
