package App::SlowQuitApps;

use 5.010;
use strict;
use warnings;
use List::Util 'max';

our $VERSION = '0.000002';

# What the application is called...
my $APP_NAME  = 'SlowQuitApps';
my $APP_ID = _get_id($APP_NAME) // die "Can't locate $APP_NAME\n";

our ($DELAY, %SLOWQUIT, %FASTQUIT, $CONFIGURED);

END {
    _configure() if !$CONFIGURED;
}


# Export API...
sub import {
    for my $subname (qw< delay slowquit fastquit >) {
        no strict 'refs';
        *{caller().'::'.$subname} = \&{$subname};
    }
}

# Set delay...
sub delay {
    my ($delay) = @_;

    # Convert fractional seconds to integral milliseconds...
    $DELAY = max(1, int($delay * 1000));
}

# Add an application to the blacklist (i.e. will be slowquitted)...
sub slowquit {
    my ($app) = @_;

    my $app_id = _get_id($app);

    if (!$app_id || $app_id !~ /\S/) {
        my (undef, undef, $line) = caller;
        warn "Can't slowquit application '$app' at line $line (application not found)\n";
    }
    else {
        $SLOWQUIT{$app} = $app_id;
    }
}

# Add an application to the whitelist (i.e. will NOT be slowquitted)...
sub fastquit {
    my ($app) = @_;

    my $app_id = _get_id($app);

    if (!$app_id || $app_id !~ /\S/) {
        my (undef, undef, $line) = caller;
        warn "Can't fastquit application '$app' at line $line (application not found)\n";
    }
    else {
        $FASTQUIT{$app} = $app_id;
    }
}

# This takes the information gathered, configures the system _defaults, and restarts the app...
sub _configure {

    # Does the config make sense???
    if (keys(%SLOWQUIT) && keys(%FASTQUIT)) {
        warn "Can't configure both slowquit and fastquit on apps.\nConfiguration unchanged.\n";
    }
    else {
        # Clear everything...
        _defaults("delete $APP_ID");

        # Set up delay...
        if ($DELAY) {
            _defaults("write $APP_ID delay -int $DELAY");
            say "Slowquit after $DELAY msec";
        }

        # Set up whitelist or blacklist...
        if (keys %SLOWQUIT) {
            _defaults("write $APP_ID invertList -bool YES");
            for my $app (keys %SLOWQUIT) {
                _defaults("write $APP_ID whitelist -array-add $SLOWQUIT{$app}");
                say "Slowquit: $app";
            }
        }
        elsif (keys %FASTQUIT) {
            _defaults("write $APP_ID invertList -bool NO");
            for my $app (keys %FASTQUIT) {
                _defaults("write $APP_ID whitelist -array-add $FASTQUIT{$app}");
                say "Fastquit: $app";
            }
        }

        # Restart to effect changes...
        system("killall $APP_NAME");
        system("open -a $APP_NAME");
    }
}

# Given an app name, get the corresponding identifier...
sub _get_id {
    my ($app) = @_;

    my $id = `osascript -so -e 'try' -e 'id of app "$app"' -e 'end try'`;
    chomp $id;

    return $id;
}

# Interface to system defaults utility (with minor cleanup on failure)...
sub _defaults {
    my ($command) = @_;

    my $result = `defaults $command`;
    chomp $result;

    return if $result =~ m{does not exist\s*\Z};
    return $result;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

App::SlowQuitApps - Simplify configuration of SlowQuitApps app on MacOS


=head1 VERSION

This document describes App::SlowQuitApps version 0.000002


=head1 SYNOPSIS

    use App::SlowQuitApps;

    # Set slowness of quit (in seconds)...
    delay 1.25;

    # Make only these apps slow-quit...
    slowquit 'Microsoft PowerPoint';
    slowquit 'Terminal';
    slowquit 'Firefox';

    # Or else...make all apps slow-quit EXCEPT these...
    fastquit 'Calendar';
    fastquit 'Safari';
    fastquit 'Notes';


=head1 DESCRIPTION

This module makes it easier to configure the SlowQuitApps
application (L<https://github.com/dteoh/SlowQuitApps>).

Once the module has been installed, you can simply create a Perl script,
like the one shown in the L<"SYNOPSIS">. That script will then
reconfigure SlowQuitApps when run.


=head1 INTERFACE

The module exports three subroutines:

=over

=item C<< delay( $DELAY_IN_SECONDS ) >>

Call this function to specify how long the slow quit takes to quit.
The argument is the number of (fractional) seconds.

Non-positive delays are rounded up to 1 millisecond,
which is useless...but better than dealing with the inevitable time
paradoxes that crop up when SlowQuitApps attempts to quit an app
I<before> you actually press COMMAND-Q.


=item C<< slowquit( $APP_NAME ) >>

Call this function to specify an application to be added to
the blacklist (i.e. another app to be explicitly slow-quit,
even though most other apps are not).

The single argument is the name of the application to be slow-quit,
as a string.

Calling this function sets SlowQuitApps to blacklist mode.


=item C<< fastquit( $APP_NAME ) >>

Call this function to specify an application to be added to
the whitelist (i.e. another app to be quit in the normal instananeous
manner even though most other apps are being slow-quit).

The single argument is the name of the application to be fast-quit,
as a string.

Calling this function sets SlowQuitApps to whitelist mode.

=back


=head1 DIAGNOSTICS

=over

=item C<< Can't locate SlowQuitApps >>

The application this module configures could not be located.
Therefore that application could not be configured.

Did you forget to install SlowQuitApps?


=item C<< Can't slowquit application %s at line %d (application not found) >>

The application named in the error message either could not be located,
or else its system identifier could not be determined.

In either case, this makes it impossible for C<slowquit()> to add it to
the SlowQuitApps blacklist, as you requested.

Did you misspell the application name?


=item C<< Can't fastquit application %s at line %d (application not found) >>

The application named in the error message either could not be located,
or else its system identifier could not be determined.

In either case, this makes it impossible for C<fastquit()> to add it to
the SlowQuitApps whitelist, as you requested.

Did you misspell the application name?


=item C<< Can't configure both slowquit and fastquit on apps. Configuration unchanged. >>

SlowQuitApps doesn't support having both a whitelist and blacklist at
the same time. Indeed, it's not clear what that would even mean.

But you tried to add two or more apps using both C<slowquit> and
C<fastquit>, so the module gave up.

You're going to have to choose whether you want to explicitly specify
which apps are to be slow-quit (i.e. by calls to C<slowquit>), or else
specify that all apps are to be slow-quit except the ones you explicitly
specify (i.e. one or more calls to C<fastquit>).

=back


=head1 CONFIGURATION AND ENVIRONMENT

App::SlowQuitApps requires no configuration files or environment variables.


=head1 DEPENDENCIES

No Perl dependencies.

Requires the L<SlowQuitApps|https://github.com/dteoh/SlowQuitApps>
application to be installed.

And that you're running on MacOS, obviously.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-slowquitapps@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
