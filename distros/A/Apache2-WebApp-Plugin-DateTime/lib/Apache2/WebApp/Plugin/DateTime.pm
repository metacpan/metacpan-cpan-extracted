#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::DateTime - Plugin providing Date/Time methods
#
#  DESCRIPTION
#  Common methods for dealing with Date/Time.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::DateTime;

use strict;
use base 'Apache2::WebApp::Plugin';
use Date::Calc qw( Date_to_Days Delta_Days Today );
use Date::Manip;
use Params::Validate qw( :all );
use POSIX qw( strftime );
use Time::ParseDate;

our $VERSION = 0.07;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# days_between_dates( $date1, $date2 )
#
# Return the total days between dates.

sub days_between_dates {
    my ( $self, $date1, $date2 )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR },
          { type => SCALAR }
          );

    my $epoch1 = parsedate($date1);
    my $epoch2 = parsedate($date2);

    my @date_to   = split(/\s+/, strftime( '%Y %m %e', localtime($epoch1) ) );
    my @date_from = split(/\s+/, strftime( '%Y %m %e', localtime($epoch2) ) );

    return Delta_Days( @date_to, @date_from );
}

#----------------------------------------------------------------------------+
# format_time( $unix_time, $format )
#
# Convert seconds-since-epoch to a human readable format.

sub format_time {
    my ( $self, $unix_time, $format )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR },
          { type => SCALAR }
          );

    require Date::Format;     # since POSIX imports similiar methods

    return Date::Format::time2str($format, $unix_time, undef);
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

Apache2::WebApp::Plugin::DateTime - Plugin providing Date/Time methods

=head1 SYNOPSIS

  my $obj = $c->plugin('DateTime')->method( ... );     # Apache2::WebApp::Plugin::DateTime->method()

    or

  $c->plugin('DateTime')->method( ... );

=head1 DESCRIPTION

Common methods for dealing with Date/Time.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  Date::Calc
  Date::Format
  Date::Manip
  Params::Validate
  Time::ParseDate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-DateTime-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::DateTime'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::DateTime
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 OBJECT METHODS

=head2 days_between_dates

Return the total days between dates.

  my $date1 = 'Sun Oct 18 15:14:48 2009';     # then and
  my $date2 = localtime(time);                # now

  my $delta = $c->plugin('DateTime')->days_between_dates( $date1, $date2 );

=head2 format_time

Convert seconds-since-epoch to a human readable format.

  my $date = $c->plugin('DateTime')->format_time( $unix_time, '%a %b %d %T %Y' );

See L<Date::Format> for character conversion specification.

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<Date::Calc>, L<Date::Format>,
L<Date::Manip>, L<Params::Validate>, L<Time::ParseDate>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
