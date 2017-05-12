package Dancer::Plugin::NYTProf;

use strict;
use Capture::Tiny ':all';
use Dancer::Plugin;
use base 'Dancer::Plugin';
use Dancer qw(:syntax);
use Dancer::FileUtils;
use File::stat;
use File::Temp;
use File::Which;

our $VERSION = '0.50';


=head1 NAME

Dancer::Plugin::NYTProf - easy Devel::NYTProf profiling for Dancer apps

=head1 SYNOPSIS

    package MyApp;
    use Dancer ':syntax';

    # enables profiling and "/nytprof"
    use Dancer::Plugin::NYTProf;

Or, if you want to enable it only under development environment (as you should!),
you can do something like:

    package MyApp;
    use Dancer ':syntax';

    # enables profiling and "/nytprof"
    if (setting('environment') eq 'development') {
        eval 'use Dancer::Plugin::NYTProf';
    }

=head1 DESCRIPTION

A plugin to provide easy profiling for Dancer applications, using the venerable
L<Devel::NYTProf>.

By simply loading this plugin, you'll have the detailed, helpful profiling
provided by Devel::NYTProf.

Each individual request to your app is profiled.  Going to the URL
C</nytprof> in your app will present a list of profiles; selecting one will
invoke C<nytprofhtml> to generate the HTML reports (unless they already exist),
then serve them up.

B<WARNING> This is an early version of this code which is still in development.
In general this isn't a plugin I'd advise to use in a production environment
anyway, but in particular, it uses C<system> to execute C<nytprofhtml>, and I
need to very carefully re-examine the code to make sure that user input cannot
be used to nefarious effect.  You are recommended to only use this in your
development environment.

=head1 CONFIGURATION

The plugin will work by default without any configuration required - it will
default to writing profiling data into a dir named C<profdir> within your Dancer
application's C<appdir>, present profiling output at C</nytprof> (not yet
configurable), and profile all requests.

Below is an example of the options you can configure:

    plugins:
        NYTProf:
            enabled: 1
            profiling_enabled: 1
            profdir: '/tmp/profiledata'
            nytprofhtml_path: '/usr/local/bin/nytprofhtml'
            show_durations: 1

=head2 profdir

Where to store profiling data. Defaults to: C<$appdir/nytprof>

=head2 nytprofhtml_path

Path to the C<nytprofhtml> script that comes with L<Devel::NYTProf>. Defaults to
the first one we can find in your PATH environment. You should only  need to
change this in very specific environments, where C<nytprofhtml> can't be found by
this plugin.

=head2 enabled

Whether the plugin as a whole is enabled; disabling this setting will disable
profiling route executions, and also disable the route which serves up the
results at C</nytprof>.  Enabled by default, so you only have to provide this
setting if you wish to set it to a false value.

=head2 profiling_enabled

Whether route executions are profiled or not; if this is set to a false value,
the before hook which would usually cause L<Devel::NYTProf> to profile that
route execution will not do so.  This allows you to disable profiling but still
be able to browse the results of existing profiled executions.  Enabled by
default, so you only have to provide this setting if you wish to set it to a
false value.

=head2 show_durations

When listing profile runs, show the duration of each run, extracted from the
profiling data.  If you have a lot of profiled runs, this might get slow, so
this option is provided if you don't need the profile durations displayed when
listing profiles, preferring a faster list.  Defaults to 1.

More configuration (such as the URL at which output is produced, and options to
control which requests get profiled) will be added in a future version.  (If
there's something you'd like to see soon, do contact me and let me know - it'll
likely get done a lot quicker then!)

=cut


my $setting = plugin_setting;

if (!exists $setting->{enabled} || $setting->{enabled}) {

    # Work out where nytprof_html is, or die with a sensible error
    my $nytprofhtml_path = $setting->{nytprofhtml_path}
        || File::Which::which('nytprofhtml')
        or die "Could not find nytprofhtml script.  Ensure it's in your path, "
        . "or set the nytprofhtml_path option in your config.";


    # Make sure that the directories we need to put profiling data in exist
    # first:
    $setting->{profdir} ||= Dancer::FileUtils::path(
        setting('appdir'), 'nytprof'
    );
    if (! -d $setting->{profdir}) {
        mkdir $setting->{profdir}
            or die "$setting->{profdir} does not exist and cannot create"
            . " - $!";
    }
    if (!-d Dancer::FileUtils::path($setting->{profdir}, 'html')) {
        mkdir Dancer::FileUtils::path($setting->{profdir}, 'html')
            or die "Could not create html dir.";
    }

    # Need to load Devel::NYTProf at runtime after setting env var, as it will
    # insist on creating an nytprof.out file immediately - even if we tell it
    # not to start profiling.  Dirty workaround: get a temp file, then let
    # Devel::NYTProf use that, with addpid enabled so that it will append the
    # PID too (so the filename won't exist), load Devel::NYTProf, then unlink
    # the file.  This is dirty, hacky shit that needs to die, but should make
    # things work for now.
    my $tempfh = File::Temp->new;
    my $file = $tempfh->filename;
    $tempfh = undef; # let the file get deleted
    $ENV{NYTPROF} = "start=no:file=$file";
    require Devel::NYTProf;
    unlink $file;

    # Set up the hook that will start profiling each route execution.
    hook 'before' => sub {
        my $path = request->path;

        # Do nothing if profiling is disabled, or if we're disabled globally.
        # (Note: if we were disabled globally by the config file's enabled
        # setting, then this hook won't have even been installed - but check
        # anyway in order to do the expected thing if someone has modified the 
        # config at runtime)
        return if ((exists $setting->{enabled} && !$setting->{enabled})
            || (exists $setting->{profiling_enabled} &&
                !$setting->{profiling_enabled})
        );

        # Go no further if this request was to view profiling output:
        return if $path =~ m{^/nytprof};

        # Now, fix up the path into something we can use for a filename:
        $path =~ s{^/}{};
        $path =~ s{/}{_s_}g;
        $path =~ s{[^a-z0-9]}{_}gi;

        # Start profiling, and let the request continue
        if (
            !exists $setting->{profiling_enabled} 
            || $setting->{profiling_enabled}
        ) {
            DB::enable_profile(
                Dancer::FileUtils::path(
                    $setting->{profdir}, "nytprof.out.$path.$$"
                )
            );
        }
    };

    hook 'after' => sub {
        if (!exists $setting->{profiling_enabled}
            || $setting->{profiling_enabled})
        {
            DB::disable_profile();
            DB::finish_profile();
        }
    };

    get '/nytprof' => sub {
        # First of all, if we were enabled initially, so the route got
        # installed, but later enabled was set to a false value at runtime,
        # refuse to serve:
        if (exists $setting->{enabled} && !$setting->{enabled}) {
            return "Disabled via 'enabled' setting";
        }

        require Devel::NYTProf::Data;
        opendir my $dirh, $setting->{profdir}
            or die "Unable to open profiles dir $setting->{profdir} - $!";
        my @files = grep { /^nytprof\.out/ } readdir $dirh;
        closedir $dirh;

        # HTML + CSS here is a bit ugly, but I want this to be usable as a
        # single-file plugin that Just Works, without needing to copy over templates
        # / CSS etc.
        my $html = <<LISTSTART;
<html><head><title>NYTProf profile run list</title>
<style>
* { font-family: Verdana, Arial, Helvetica, sans-serif; }
</style>
</head>
<body>
<h1>Profile run list</h1>
<p>Select a profile run output from the list to view the HTML reports as
produced by <tt>Devel::NYTProf</tt>.</p>

<ul>
LISTSTART

        for my $file (
            sort {
                (stat Dancer::FileUtils::path($setting->{profdir},$b))->ctime
                <=>
                (stat Dancer::FileUtils::path($setting->{profdir},$a))->ctime
            } @files
        ) {
            my $fullfilepath = Dancer::FileUtils::path(
                $setting->{profdir}, $file,
            );
            my $label = $file;
            $label =~ s{nytprof\.out\.}{};
            $label =~ s{_s_}{/}g;
            $label =~ s{\.(\d+)$}{};
            my $pid = $1;  # refactor this crap
            my $created = scalar localtime( (stat $fullfilepath)->ctime );

            # read the profile to find out the duration of the profiled request.
            # Done in an eval to catch errors (e.g. if a profile run died,
            # the data will be incomplete)
            my ($profile,$duration);

            if (!defined $setting->{show_durations}
                || $setting->{show_durations}) 
            {
                eval {
                    my ($stdout, $stderr, @result) = Capture::Tiny::capture {
                        $profile = Devel::NYTProf::Data->new(
                            { filename => $fullfilepath },
                        );
                    };
                };
                if ($profile) {
                    $duration = sprintf '%.4f secs', 
                        $profile->attributes->{profiler_duration};
                } else {
                    $duration = '??? seconds - corrupt profile data?';
                }
            }
            $pid = "PID $pid";
            my $url = request->uri_for("/nytprof/$file")->as_string;
            $html .= qq{<li><a href="$url"">$label</a> (}
                . join(',', grep { defined $_ } ($pid, $created, $duration))
                . qq{)</li>};
        }

        my $nytversion = $Devel::NYTProf::VERSION;
        $html .= <<LISTEND;
</ul>

<p>Generated by <a href="http://github.com/bigpresh/Dancer-Plugin-NYTProf">
Dancer::Plugin::NYTProf</a> v$VERSION
(using <a href="http://metacpan.org/dist/Devel::NYTProf">
Devel::NYTProf</a> v$nytversion)</p>
</body>
</html>
LISTEND

        return $html;
    };


# Serve up HTML reports
    get '/nytprof/html/**' => sub {
        # First of all, if we were enabled initially, so the route got
        # installed, but later enabled was set to a false value at runtime,
        # refuse to serve:
        if (exists $setting->{enabled} && !$setting->{enabled}) {
            return "Disabled via 'enabled' setting";
        }

        my ($path) = splat;
        send_file Dancer::FileUtils::path(
            $setting->{profdir}, 'html', map { _safe_filename($_) } @$path
        ), system_path => 1;
    };

    get '/nytprof/:filename' => sub {
        # First of all, if we were enabled initially, so the route got
        # installed, but later enabled was set to a false value at runtime,
        # refuse to serve:
        if (exists $setting->{enabled} && !$setting->{enabled}) {
            return "Disabled via 'enabled' setting";
        }

        my $profiledata = Dancer::FileUtils::path(
            $setting->{profdir}, _safe_filename(param('filename'))
        );

        if (!-f $profiledata) {
            send_error 'not_found';
            return "No such profile run found.";
        }

        # See if we already have the HTML for this run stored; if not, invoke
        # nytprofhtml to generate it

        # Right, do we already have generated HTML for this one?  If so, use it
        my $htmldir = Dancer::FileUtils::path(
            $setting->{profdir}, 'html', _safe_filename(param('filename'))
        );
        if (! -f Dancer::FileUtils::path($htmldir, 'index.html')) {
            # TODO: scrutinise this very carefully to make sure it's not
            # exploitable
            system($nytprofhtml_path, "--file=$profiledata", "--out=$htmldir");

            if ($? == -1) {
                die "'$nytprofhtml_path' failed to execute: $!";
            } elsif ($? & 127) {
                die sprintf "'%s' died with signal %d, %s coredump",
                    $nytprofhtml_path,,
                    ($? & 127),
                    ($? & 128) ? 'with' : 'without';
            } elsif ($? != 0) {
                die sprintf "'%s' exited with value %d",
                    $nytprofhtml_path, $? >> 8;
            }
        }

        # Redirect off to view it:
        return redirect '/nytprof/html/'
            . param('filename') . '/index.html';

    };

}

# Rudimentary security - remove any directory traversal or poison null
# attempts.  We're dealing with user input here, and if they're a sneaky
# bastard, they could convince us to send a file we shouldn't, or have
# nytprofhtml write its output to somewhere it shouldn't.  We don't want that.
sub _safe_filename {
    my $filename = shift;
    $filename =~ s/\\//g;
    $filename =~ s/\0//g;
    $filename =~ s/\.\.//g;
    $filename =~ s/[\/]//g;
    return $filename;
}

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>


=head1 ACKNOWLEDGEMENTS

Stefan Hornburg (racke)

Neil Hooey (nhooey)

J. Bobby Lopez (jbobbylopez)

leejo

Breno G. de Oliveira (garu)


=head1 BUGS

Please report any bugs or feature requests at
L<http://github.com/bigpresh/Dancer-Plugin-NYTProf/issues>.

=head1 CONTRIBUTING

This module is developed on GitHub:

L<http://github.com/bigpresh/Dancer-Plugin-NYTProf>

Bug reports, suggestions and pull requests all welcomed!

=head1 SEE ALSO

L<Dancer>

L<Devel::NYTProf>

L<Plack::Middleware::Debug::Profiler::NYTProf>


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # Sam Kington didn't like that this said "End of Dancer::Plugin::NYTProf",
   # as it's fairly obvious.  So, just for Sam's pleasure,
   # "It's the end of the world as we know it!" ... or something.
