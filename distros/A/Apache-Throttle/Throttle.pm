
package Apache::Throttle;

use strict;
use vars qw( $VERSION $CacheData $Id );

use Apache;
use Apache::Constants qw( :common );
use Apache::URI;

$VERSION = 0.03;
$Id = '$Id: Throttle.pm,v 1.5 1998/09/15 18:20:01 don Exp $';

# Caching is experimental.  Assuming that your document root is writable
# by mod_perl this should work, but I can't promise that it will speed
# anything up and .throttle.cache files never get stale.  On the plus
# side, that means you can tweak them.
$CacheData = 0;

sub handler {
    my ($r) = shift;

    my $uri = $r->parsed_uri;
    my $filename = $r->document_root . $uri->path;

    return DECLINED unless -d $filename;
#    return DECLINED if $filename =~ m|/$|;
    return DECLINED if (rindex($filename, "/") == (length($filename) - 1));
    return DECLINED unless -f "$filename/.throttle";

    my @speeds = ();
    if ($CacheData && (-f "$filename/.throttle.cache")) {
        eval {
	    open (TCACHE, "$filename/.throttle.cache") || die $!;
            flock (TCACHE, 2);
	    @speeds = map { [ split /:/ ] } <TCACHE>;
	    close TCACHE;
        };
        $r->warn($@) if $@;
    }
    unless (@speeds) {
	open(T, "$filename/.throttle") || return DECLINED;
	my $time = <T>;
	close T;

        $r->warn("$filename/.throttle does not contain a time") unless $time;
	$time ||= 1.0;	

	opendir(DIR, $filename) || return DECLINED;
	foreach my $f (readdir(DIR)) {
	    next if (index($f, ".") == 0);
	    push (@speeds, [$f, (-s "$filename/$f") / $time]);
	}
	closedir DIR;
	
	@speeds = sort { $a->[1] <=> $b->[1] } @speeds;

	if ($CacheData) {
            eval {
		open(TCACHE, "> $filename/.throttle.cache") || die $!;
		flock (TCACHE, 8);
		seek (TCACHE, 0, 0);
		print TCACHE map { join(":", @$_) } @speeds;
		close TCACHE;
	    };
	    $r->warn($@) if $@;
	}
    }

    my $speed = predict_speed($r);

    my $i = -1;
    if ($speed) {
        $i = 0;
	foreach my $z (@speeds) {
	    last if $speed <= $z->[1];
            $i++;
	}
	$i-- if $i;
    }

    if ($r->dir_config("ThrottleDebug")) {
	$r->log_error("Throttled: " . $filename . " => " . $speeds[$i][0] .
                      " (" . int($speeds[$i][1]) . "/" . ($speed || "?"). ")");
    }
    $filename = "$filename/" . $speeds[$i][0];
    $r->filename($filename);
    return OK;
}

sub predict_speed {
    my ($r) = @_;

    no strict 'refs';
    my $predict_sub = $r->dir_config("PredictSub") ||
                      "Apache::Throttle::Log::predict_speed";

    if ($predict_sub =~ /^([a-zA-Z:]+)::[^:]*$/) {
	my $package = $1;
	eval "require $package;";
    }
    $predict_sub->($r);
}

1;
__END__

=head1 NAME

Apache::Throttle - Apache/Perl module for speed-based content negotiation

=head1 SYNOPSIS

    PerlTransHandler   Apache::Throttle

    # See the Apache::Throttle::Log manpage for options...
    PerlFixUpHandler   Apache::Throttle::Log

=head1 DESCRIPTION

Apache::Throttle is made up of two separate modules.

Apache::Throttle is responsible for negotiating the content of certain
requests based on the speed of the connection.  It does this by
checking each request to see if it passes the following criteria:

=over 4

=item *
it is a directory,

=item *
it does not end in a /,

=item *
and it contains a file named .throttle.

=back

If the request passes, Apache::Throttle will open the .throttle file
and read a number from it.  This is the time (in seconds) that the
requested file should take to send, ideally.  It then takes the sizes
of each of the files in the directory (ignoring any that start with
a period) and calculates the speed required to send the file to the
client in under the specified number of seconds.  Finally, it
predicts the speed of the current connection and maps the request
to point to the largest file that can still be sent in the ideal time.

This implementation allows you to create a virtual copy of a file
simply by dropping the different versions of the file into a directory
in your HTML tree with same name that you want the file to have.
These files can be named anything you want, although they should end
in the same extension for MIME-type mapping to work properly.
A script, L<throttleimg>, is provided which automatically sets up
this directory structure from an existing GIF or JPEG image.

Apache::Throttle::Log is responsible for measuring the speed that other
requests are transmitted at and calculating the average transmittion
speed for each connection.  This information is used by Apache::Throttle
by default, but it can also be accessed by other modules.
See L<Apache::Throttle::Log> for more information.

=head1 OPTIONS

This option can be set with the PerlSetVar operative in one of your
Apache configuration files.

=over 4

=item ThrottleDebug

Prints extra debugging information to the error log.

=item PredictSub

Sets the subroutine called to predict a connection's speed.
This defaults to Apache::Throttle::Log::predict_speed.  If the package
that the specified subroutine is in can be determined, it will be
required automatically.

=back

=head1 IDEAS

This doesn't only work with images.  It can also be used to send
different quality audio files, animations, etc.  You can even
use a directory named index.html if you want, with two different
HTML pages for high- and low-bandwidth users.  The possibilities
are endless.  If you think you've used this is a way no one has
though of before, mail me.  I'd love to hear about it.

=head1 AUTHOR

Don Schwarz <dons@xnet.com>

=head1 SEE ALSO

L<Apache::Throttle::Log>, L<throttleimg>, L<mod_perl>

=head1 COPYRIGHT

Copyright (c) 1998 Don Schwarz. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
