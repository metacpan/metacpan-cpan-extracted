package Apache::Throttle::Log;

use strict;
use vars qw( $speeds $DEBUG $Id );

use Apache;
use Apache::Constants qw( :common );
use IPC::Shareable;

BEGIN { eval "use Time::HiRes qw( time );" }

tie $speeds, 'IPC::Shareable', 'ATLX', { create => 1, mode => 0666 };
$speeds = {} unless $speeds;

$DEBUG = 0;
$Id = '$Id: Log.pm,v 1.6 1998/09/15 18:19:47 don Exp $';

sub handler {
    my ($r) = shift;

    start($r);
    return DECLINED;
}

sub start {
    my ($r) = shift;

    my $start_time = time();
    my $id = get_id($r) or return;

    {
        local $^W = 0; # silence warning from (%$speeds > ...)
	my $max = $r->dir_config("MaxUsers");
	if ($max && (%$speeds > $max)) {
	    $r->dir_config("ThrottleDebug") and
		$r->warn("Speed hash reached $max users... cleared.");
	    $speeds = {};
	}
    }

    $speeds->{$id} ||= [];
    return if (@{ $speeds->{$id} } < ($r->dir_config("StoreSpeeds") || 3)) &&
              !$r->dir_config("ContinueChecking");

    $r->notes("START_TIME", $start_time);
    $r->notes("REQUEST_ID", $id);
    $r->post_connection(sub { stop($r); 0; });
    $|++;
}

sub stop {
    my ($r) = shift;

    my $debug = $r->dir_config("ThrottleDebug");
    my $stop_time = time();
    my $id = $r->notes("REQUEST_ID") || get_id($r);

    my $log_types = $r->dir_config("LogTypes");
    if ($log_types && ($r->content_type !~ /$log_types/o)) {
	$debug && $r->warn("Throttle: Can't log... content type " .
                           $r->content_type .
			   " doesn't match regexp $log_types.");
	return;
    }

    my $done;
    if (@{ $speeds->{$id} } < ($r->dir_config("StoreSpeeds") || 3)) {
        $done = sub {
	    $speeds->{$id} = [ (@{ $speeds->{$id} }, shift)];
	};
    } elsif ($r->dir_config("ContinueChecking")) {
        $done = sub {
	    my @o = @{ $speeds->{$id} };
	    shift @o;
	    push @o, shift;
	    $speeds->{$id} = \@o;
	};
    } else {
	return;
    }

    my $start_time = $r->notes("START_TIME") || $r->request_time;
    my $duration = $stop_time - $start_time;

    if ($duration < ($r->dir_config("MinDuration") || .05)) {
	$debug && $r->warn("Throttle: Can't log... request lasted " .
                    sprintf("%.3f", $duration) . ", less than minimum of ".
		    ($r->dir_config("MinDuration") || "default .05"));
	return;
    }

    my $bytes = $r->bytes_sent;
    if ($bytes < ($r->dir_config("MinSize") || (1024 * 64))) {
	$debug && $r->warn("Throttle: Can't log... request was $bytes, " .
                           "smaller than minimum of " .
			   ($r->dir_config("MinSize") || "default 64k"));
	return;
    }
  
    my $speed = int($bytes / $duration);
    (tied $speeds)->shlock;
    $done->($speed);
    (tied $speeds)->shunlock;

    $debug && $r->log_error("Throttle data for $id: speed = $speed " .
                            "[${bytes} bytes/" . sprintf("%.3f", $duration) .
                            "s]");
}

sub get_id {
    my ($r) = shift;

    no strict 'refs';
    my $id_sub = $r->dir_config("IDSub") || \&id_from_ip;
    if ($id_sub =~ /^([a-zA-Z:]+)::[^:]*$/) {
	my $package = $1;
	eval "require $package;";
    }
    $id_sub->($r);
}

sub id_from_ip {
    shift->connection->remote_ip;
}

sub predict_speed {
    my ($r) = shift;

    my $id = get_id($r);

    my $sum = 0;
    my $i = 0;
    foreach my $v (@{ $speeds->{$id} }) {
	$sum += $v;
	$i++;
    }
    $i ? int ($sum / $i) : undef;
}

1;
__END__

=head1 NAME

Apache::Throttle::Log - Apache/Perl module to determine average speed

=head1 SYNOPSIS

    <Location /images>
      PerlSetVar       MaxUsers     100
      PerlSetVar       MinSize      100000
      PerlSetVar       MinDuration  0.1
      PerlSetVar       IDSub        Website::Session::session_id
      PerlTypeHandler  Apache::Throttle::Log
    </Location>

=head1 DESCRIPTION

Apache::Throttle::Log measures the speed that requests are transmitted
at and can calculate the average transmittion speed for a connection.

It isn't particularly accurate yet, but seems to be close enough for
most applications.  If you know of a better way to measure the speed
feel free to send me suggestions, patches, etc.

=head1 OPTIONS

These options can be set with the PerlSetVar operative in one of your
Apache configuration files.

=over 4

=item ThrottleDebug

Prints extra debugging information to the error log.

=item MaxUsers

Clear the speed hash when it reaches the specified number of users.
I'm still looking for a better way of doing this.  If anyone has any
suggestions, feel free to tell me.  This option is strongly recommended.

=item LogTypes

Only log requests with a MIME-type that matches this regular expression.
This is useful for only logging "^image/" if you plan to serve images and
the speeds for other large, compressable files are throwing off your
averages.  It's probably much more efficient to keep all your images under
one directory and just put a <Location> container around the handler
definition though.

=item MinSize

The minimum size in bytes that a request has to be for it to be logged.

=item MinDuration

The minimum time in seconds that a request has to take for it to be logged.

=item StoreSpeeds

The number of speeds to store for each connection.  These are averaged
together to predict the speed of the next request.

=item ContinueChecking

If this is set to a true value, Apache::Throttle::Log will continue
logging requests from a user forever.  If unspecified or set false, 
however, it will only log as many requests as StoreSpeeds is set to,
and then DECLINED requests from the same user.  This should be used
when speeds are fairly constant and Apache::Throttle is putting a
strain on your webserver.

=item IDSub

This specifies the subroutine that Apache::Throttle::Log will get the
hash key from.  The subroutine will be called with one argument:
the Apache request object, and will be expected to return a scalar.
This scalar will be used as the hash key to store the connection
information.  Defaults to the remote IP address for the request.

=back

=head1 AUTHOR

Don Schwarz <dons@xnet.com>

=head1 SEE ALSO

L<Apache::Throttle>, L<mod_perl>

=head1 COPYRIGHT

Copyright (c) 1998 Don Schwarz. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
