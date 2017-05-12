#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::Validate - Plugin providing data validation methods
#
#  DESCRIPTION
#  Common methods used for validating user input.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::Validate;

use strict;
use warnings;
use base 'Apache2::WebApp::Plugin';
use Date::Calc qw( Date_to_Days Today );
use Data::Validate::URI;
use Email::Valid;
use HTTP::BrowserDetect;
use Net::DNS::Check;
use Params::Validate qw( :all );

our $VERSION = 0.08;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# browser()
#
# Check if the request is from a browser.

sub browser {
    my $browser = new HTTP::BrowserDetect;

    if ( $browser->firefox   || $browser->netscape
      || $browser->ie        || $browser->mozilla
      || $browser->safari    || $browser->aol
      || $browser->webtv     || $browser->opera
      || $browser->konqueror ) {
        return 1;
    }
    else {
        return 0;
    }
}

#----------------------------------------------------------------------------+
# currency($total)
#
# Check the currency format (0.00)

sub currency {
    my ( $self, $total )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    if ($total =~ /\A [0-9]{0,8}[\.][0-9]{1,2} \z/xs && length($total) < 10) {
        return 1;
    }
    else {
        return 0;
    }
}

#----------------------------------------------------------------------------+
# date($date)
#
# Check the date format (YYYY-MM-DD)

sub date {
    my ( $self, $date )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    if ($date =~ /\A [0-9]{4}[\/|-][0-9]{1,2}[\/|-][0-9]{1,2} \z/xs ) {
        return 1;
    }
    else {
        return 0;
    }
}

#----------------------------------------------------------------------------+
# date_is_future($date)
#
# Is the date in the future? (YYYY-MM-DD)

sub date_is_future {
    my ( $self, $date )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    my ( $year1, $month1, $day1 ) = split( /\-/, $date );
    my ( $year2, $month2, $day2 ) = Today();

    if (Date_to_Days( $year1, $month1, $day1 ) >=
        Date_to_Days( $year2, $month2, $day2 ))
    {
        return 1;
    }
    return 0;
}

#----------------------------------------------------------------------------+
# date_is_past($date)
#
# Is the date in the past? (YYYY-MM-DD)

sub date_is_past {
    my ( $self, $date )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    my ( $year1, $month1, $day1 ) = split( /\-/, $date );
    my ( $year2, $month2, $day2 ) = Today();

    if (Date_to_Days( $year1, $month1, $day1 ) <=
        Date_to_Days( $year2, $month2, $day2 ))
    {
        return 1;
    }
    return 0;
}

#----------------------------------------------------------------------------+
# domain($name)
#
# Check the domain name format; verify the domain status using a DNS query.

sub domain {
    my ( $self, $name )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    my $dns = new Net::DNS::Check(
        domain => $name,
      );

    return ($dns->check_status() ? 1 : 0);
}

#----------------------------------------------------------------------------+
# email($address)
#
# Check the e-mail address format; verify the domain status using a DNS query.

sub email {
    my ( $self, $address, $mx )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR },
          { type => SCALAR, optional => 1 }
          );

    my $valid = Email::Valid->address(
        -address => $address,
        -mxcheck => ($mx) ? 1 : 0
      ) ? 1 : 0;

    return $valid;
}

#----------------------------------------------------------------------------+
# integer($value)
#
# Check for a integer.

sub integer {
    my ( $self, $value )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    if ($value =~ /^[\d]*$/) {
        return 1;
    }
    else {
        return 0;
    }
}

#----------------------------------------------------------------------------+
# html($markup)
#
# Check for HTML markup.

sub html {
    my ( $self, $markup )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    if ($markup =~ /<\/?\w+((\s+\w+(\s*=\s*(?:"(.|\n)*?"|'(.|\n)*?'|[^'">\s]+))?)+\s*|\s*)\/?>/) {
        return 1;
    }
    else {
        return 0;
    }
}

#----------------------------------------------------------------------------+
# url($string)
#
# Check the URL.

sub url {
    my ( $self, $string )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    my $v = Data::Validate::URI->new();

    if ( $v->is_web_uri($string) ) {
        return 1;
    }
    else {
        return 0;
    }
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

Apache2::WebApp::Plugin::Validate - Plugin providing data validation methods

=head1 SYNOPSIS

  my $result = $c->plugin('Validate')->method( ... );     # Apache2::WebApp::Plugin::Validate->method()

=head1 DESCRIPTION

Common methods used for validating user input.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  Date::Calc
  Data::Validate::URI
  Email::Valid
  HTTP::BrowserDetect
  Net::DNS::Check
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-Validate-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::Validate'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::Validate
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 OBJECT METHODS

=head2 browser

Check if the request is from a browser.

  my $result = $c->plugin('Validate')->browser();

=head2 currency

Check the currency format (0.00)

  my $result = $c->plugin('Validate')->currency($total);

=head2 date

Check the date format (YYYY-MM-DD)

  my $result = $c->plugin('Validate')->date($date);

=head2 date_is_future

Is the date in the future? (YYYY-MM-DD)

  my $result = $c->plugin('Validate')->date_is_future($date);

=head2 date_is_past

Is the date in the past? (YYYY-MM-DD)

  my $result = $c->plugin('Validate')->date_is_past($date);

=head2 domain

Check the domain name format; verify the domain status using a DNS query.

  my $result = $c->plugin('Validate')->domain($name);

=head2 email

Check the e-mail address format; verify the domain status using a DNS query.

  my $result = $c->plugin('Validate')->email( $address, $mx_check );

=head2 integer

Check for a integer.

  my $result = $c->plugin('Validate')->integer($value);

=head2 html

Check for HTML markup.

  my $result = $c->plugin('Validate')->html($markup);

=head2 url

Check the URL.

  my $result = $c->plugin('Validate')->url($string);

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<Data::Validate::URI>, L<Email::Valid>,
L<HTTP::BrowserDetect>, L<Net::DNS::Check>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
