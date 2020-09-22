#!/bin/false
# PODNAME: BZ::Client::Bugzilla
# ABSTRACT: Information about the Bugzilla server, i.e. the Bugzilla::Webservices::Bugzilla API

use strict;
use warnings 'all';

package BZ::Client::Bugzilla;
$BZ::Client::Bugzilla::VERSION = '4.4003';

use parent qw( BZ::Client::API );

## functions

sub extensions {
    my($class, $client) = @_;
    $client->log('debug', $class . '::extensions: Asking');
    my $result = $class->api_call($client, 'Bugzilla.extensions');
    $client->log('debug', $class . '::extensions: Got stuff');
    my $extensions = $result->{'extensions'};
    if (!$extensions || 'HASH' ne ref($extensions)) {
        $class->error($client, 'Invalid reply by server, expected hash of extensions.');
    }
    return wantarray ? %$extensions : $extensions
}

sub parameters {
    my($class, $client) = @_;
    $client->log('debug', $class . '::parameters: Asking');
    my $result = $class->api_call($client, 'Bugzilla.parameters');
    $client->log('debug', $class . '::parameters: Got stuff');
    my $parameters = $result->{'parameters'};
    if (!$parameters || 'HASH' ne ref($parameters)) {
        $class->error($client, 'Invalid reply by server, expected hash of parameters.');
    }
    $client->log('debug', $class . '::parameters: Got ' . scalar %$parameters);
    return wantarray ? %$parameters : $parameters
}

sub last_audit_time {
    my($class, $client, $params) = @_;
    $client->log('debug', $class . '::last_audit_time: Asking');
    my $result = $class->api_call($client, 'Bugzilla.last_audit_time', $params);
    $client->log('debug', $class . '::last_audit_time: Got stuff');
    my $last_audit_time = $result->{'last_audit_time'};
    if (!$last_audit_time || ! ref($last_audit_time)) {
        $class->error($client, 'Invalid reply by server, expected last_audit_time dateTime.');
    }
    $client->log('debug', $class . "::parameters: Got $last_audit_time");
    return $last_audit_time
}

sub time {
    my($class, $client) = @_;
    $client->log('debug', $class . '::time: Asking');
    my $time = $class->api_call($client, 'Bugzilla.time');
    $client->log('debug', $class . "::time: Got $time");
    return wantarray ? %$time : $time
}

sub timezone {
    my($class, $client) = @_;
    $client->log('debug', $class . '::timezone: Asking');
    my $result = $class->api_call($client, 'Bugzilla.timezone');
    my $timezone = $result->{'timezone'};
    if (!$timezone || ref($timezone)) {
        $class->error($client, 'Invalid reply by server, expected timezone scalar.');
    }
    $client->log('debug', $class . "::time: Got $timezone");
    return $timezone
}

sub version {
    my($class, $client) = @_;
    $client->log('debug', $class . '::version: Asking');
    my $result = $class->api_call($client, 'Bugzilla.version');
    my $version = $result->{'version'};
    if (!$version || ref($version)) {
        $class->error($client, 'Invalid reply by server, expected version scalar.');
    }
    $client->log('debug', $class . "::version: Got $version");
    return $version
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Bugzilla - Information about the Bugzilla server, i.e. the Bugzilla::Webservices::Bugzilla API

=head1 VERSION

version 4.4003

=head1 SYNOPSIS

This class provides methods for accessing information about the Bugzilla
servers installation.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $extensions = BZ::Client::Bugzilla->extensions( $client );
  my $time = BZ::Client::Bugzilla->time( $client );
  my $version = BZ::Client::Bugzilla->version( $client );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 extensions

 %extensions = BZ::Client::Bugzilla->extensions( $client );
 $extensions = BZ::Client::Bugzilla->extensions( $client );

Returns a hash or hash ref information about the extensions that are currently installed and enabled in this Bugzilla.

=head3 History

Added in Bugzilla 3.2.

As of Bugzilla 3.6, the names of extensions are canonical names that the extensions define themselves. Before 3.6, the names of the extensions depended on the directory they were in on the Bugzilla server.

=head3 Parameters

(none)

=head3 Returns

The hash contains the names of extensions as keys, and the values are a hash.

That hash contains a single key C<version>, which is the version of the extension, or C<0> if the extension hasn't defined a version.

The return value looks something like this:

 {
   Example => {
     version => '3.6',
   },
   BmpConvert => {
     version => '1.0',
   },
 }

=head2 last_audit_time

 $last_audit_time = BZ::Client::Bugzilla->extensions( $client, \%params );

Gets the latest time of the C<audit_log> table.

=head3 History

Added in Bugzilla 4.4.

=head3 Parameters

You can pass the optional parameter L</class> to get the maximum for only the listed classes.

=over 4

=item class

I<class> (array) - An array of strings represetning the class names.

Note: The class names are defined as "Bugzilla::class_name". For the product use Bugzilla::Product.

=back

=head3 Returns

The maximum of the C<at_time> from the C<audit_log>, as a L<DateTime> object.

=head2 parameters

 %parameters = BZ::Client::Bugzilla->parameters( $client );
 $parameters = BZ::Client::Bugzilla->parameters( $client );

Returns a hash or hashref containing the current Bugzilla parameters.

=head3 History

Added in Bugzilla 4.4.

=head3 Parameters

(none)

=head3 Returns

A logged-out user can only access the C<maintainer> and C<requirelogin> parameters.

A logged-in user can access the following parameters (listed alphabetically): C<allowemailchange>, C<attachment_base>, C<commentonchange_resolution>, C<commentonduplicate>, C<cookiepath>, C<defaultopsys>, C<defaultplatform>, C<defaultpriority>, C<defaultseverity>, C<duplicate_or_move_bug_status>, C<emailregexpdesc>, C<emailsuffix>, C<letsubmitterchoosemilestone>, C<letsubmitterchoosepriority>, C<mailfrom>, C<maintainer>, C<maxattachmentsize>, C<maxlocalattachment>, C<musthavemilestoneonaccept>, C<noresolveonopenblockers>, C<password_complexity>, C<rememberlogin>, C<requirelogin>, C<search_allow_no_criteria>, C<urlbase>, C<use_see_also>, C<useclassification>, C<usemenuforusers>, C<useqacontact>, C<usestatuswhiteboard>, C<usetargetmilestone>.

A user in the C<tweakparams> group can access all existing parameters. New parameters can appear or obsolete parameters can disappear depending on the version of Bugzilla and on extensions being installed. The list of parameters returned by this method is not stable and will never be stable.

=head2 time

 %timeinfo = BZ::Client::Bugzilla->time( $client );
 $timeinfo = BZ::Client::Bugzilla->time( $client );

Gets information about what time the Bugzilla server thinks it is, and what timezone it's running in.

=head3 History

Added in Bugzilla 3.4.

Note: As of Bugzilla 3.6, this method returns all data as though the server were in the UTC timezone, instead of returning information in the server's local timezone.

=head3 Parameters

(none)

=head3 Returns

A hash with the following items:

=over 4

=item db_time

I<db_time> (L<DateTime>) -  The current time in UTC, according to the Bugzilla database server.

Note that Bugzilla assumes that the database and the webserver are running in the same time zone. However, if the web server and the database server aren't synchronized for some reason, this is the time that you should rely on for doing searches and other input to the WebService.

=item web_time

I<web_time> (L<DateTime>) -  This is the current time in UTC, according to Bugzilla's web server.

This might be different by a second from L</db_time> since this comes from a different source. If it's any more different than a second, then there is likely some problem with this Bugzilla instance. In this case you should rely on the L</db_time>, not the L</web_time>.

=item web_time_utc

Identical to L</web_time>. (Exists only for backwards-compatibility with versions of Bugzilla before 3.6.)

=item tz_name

I<tz_name> (string) - The literal string C<UTC>. (Exists only for backwards-compatibility with versions of Bugzilla before 3.6.)

=item tz_short_name

tz_short_name (string) - The literal string C<UTC>. (Exists only for backwards-compatibility with versions of Bugzilla before 3.6.)

=item tz_offset

I<tz_offset> (string) - The literal string C<+0000>. (Exists only for backwards-compatibility with versions of Bugzilla before 3.6.)

=back

=head2 timezone

 $timezone = BZ::Client::Bugzilla->timezone( $client );

Returns the Bugzilla servers timezone as a numeric value. This method
is deprecated: Use L</time> instead.

Note: as of Bugzilla 3.6 the timezone is always +0000 (UTC)
Also, Bugzilla has depreceated but not yet removed this API call

=head2 version

 $version = BZ::Client::Bugzilla->version( $client );

Returns the Bugzilla servers version.

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bugzilla.html>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
