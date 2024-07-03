package Dancer2::Plugin::NYTProf;
use strict;
use warnings;

our $VERSION = '0.0100'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT:  NYTProf, in your Dancer2 application!

use Dancer2::Plugin;
use Dancer2::FileUtils;
use File::stat;
use File::Which;

has 'enabled' => (
   is => 'ro',
   from_config => 1,
   default => sub { return 1; },
);

has 'nytprofhtml_path' => (
   is => 'ro',
   from_config => 1,
);

has 'profdir' => (
   is => 'ro',
   from_config => 1,
);

has 'profiling_enabled' => (
   is => 'ro',
   from_config => sub { return 1; },
);

has 'show_durations' => (
   is => 'ro',
   from_config => sub { return 1; },
);

sub BUILD {
   my $plugin = shift;
   return if !$plugin->enabled;

   # Work out where nytprof_html is, or die with a sensible error
   my $nytprofhtml_path = $plugin->nytprofhtml_path // File::Which::which('nytprofhtml');
   if (!$nytprofhtml_path || !-e $nytprofhtml_path || !-x $nytprofhtml_path ) {
      die 'Could not find nytprofhtml script.  Ensure it is in your path, '
        . 'or set the nytprofhtml_path option in your config.';
   }

   # Make sure that the directories we need to put profiling data in exist
   my $profdir = $plugin->{profdir}
       || Dancer2::FileUtils::path( $plugin->app->config->{appdir}, 'nytprof' );
   if ( !-d $profdir ) {
      mkdir $profdir
          or die "$profdir does not exist and cannot create" . " - $!";
   }
   my $htmldir = Dancer2::FileUtils::path( $profdir, 'html');
   if ( !-d $htmldir ) {
      mkdir $htmldir
          or die "Could not create html dir - $!";
   }

   local $ENV{NYTPROF} = 'start=no';
   require Devel::NYTProf;

   # Set up the hook that will start profiling each route execution.
   $plugin->app->add_hook( Dancer2::Core::Hook->new(
      name => 'before',
      code => sub {
         my $self         = shift;
         my $path         = $self->app->request->path;
         my $inner_plugin = $self->app->find_plugin('Dancer2::Plugin::NYTProf');

         # Do nothing if profiling is disabled, or if we're disabled globally.
         # (Note: if we were disabled globally by the config file's enabled
         # setting, then this hook won't have even been installed - but check
         # anyway in order to do the expected thing if someone has modified the
         # config at runtime)
         return if ( !$inner_plugin->enabled || !$inner_plugin->profiling_enabled );

         # Go no further if this request was to view profiling output:
         return if $path =~ m{^/nytprof};

         # Now, fix up the path into something we can use for a filename:
         $path =~ s{^/}{};
         $path =~ s{/}{_s_}g;
         $path =~ s{[^a-z0-9]}{_}gi;

         return if !$inner_plugin->profiling_enabled;

         my $inner_profdir = $inner_plugin->profdir
             || Dancer2::FileUtils::path( $self->app->config->{appdir}, 'nytprof' );

         # Start profiling, and let the request continue
         DB::enable_profile(
            Dancer2::FileUtils::path( $inner_profdir, "nytprof.out.$path.$$" ) );
      },
   ) );

   $plugin->app->add_hook( Dancer2::Core::Hook->new(
      name => 'after',
      code => sub {
         my $response = shift;
         DB::disable_profile();
         DB::finish_profile();
      },
   ) );

   my $old_prefix = $plugin->app->prefix;

   $plugin->app->prefix(undef);

   $plugin->app->add_route(
      method => 'get',
      regexp => '/nytprof',
      code => sub {

         # Sneaky mode -- It's nice that the app is passed as a param to a route!
         my $app = shift;
         use File::stat;

         my $inner_plugin = $app->find_plugin('Dancer2::Plugin::NYTProf');

         require Devel::NYTProf::Data;
         my $inner_profdir = $inner_plugin->profdir
             || Dancer2::FileUtils::path( $app->config->{appdir}, 'nytprof' );

         opendir my $dirh, $inner_profdir
             or die "Unable to open profiles dir $inner_profdir - $!";
         my @files = grep { /^nytprof\.out/ } readdir $dirh;
         closedir $dirh or die "Unable to close profiles dir $inner_profdir - $!";

         # HTML + CSS here is a bit ugly, but I want this to be usable as a
         # single-file plugin that Just Works, without needing to copy over templates
         # / CSS etc.
         my $html = <<"LISTSTART";
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
               ( stat( Dancer2::FileUtils::path( $inner_profdir, $a ) )->ctime )
                   <=> ( stat( Dancer2::FileUtils::path( $inner_profdir, $b ) )->ctime )
            } @files
         ) {
            my $fullfilepath = Dancer2::FileUtils::path( $inner_profdir, $file, );
            my $label        = $file;
            $label =~ s{nytprof\.out\.}{};
            $label =~ s{_s_}{/}g;
            my ($pid) = $label =~ /\.(\d+)$/;
            $label =~ s{\.(\d+)$}{};
            $label = '/' if $label eq '';
            # my $pid     = $1;                   # refactor this crap
            my $created = scalar localtime( ( stat $fullfilepath )->ctime );

            # read the profile to find out the duration of the profiled request.
            # Done in an eval to catch errors (e.g. if a profile run died,
            # the data will be incomplete)
            my ( $profile, $duration );

            if ( $inner_plugin->show_durations ) {
               eval {
                  my ( $stdout, $stderr, @result ) = Capture::Tiny::capture {
                     $profile = Devel::NYTProf::Data->new( { filename => $fullfilepath }, );
                  };
               };
               if ($profile) {
                  $duration = sprintf '%.4f secs', $profile->attributes->{profiler_duration};
               } else {
                  $duration = '??? seconds - corrupt profile data?';
               }
            }
            $pid = "PID $pid";
            my $url = "/nytprof/$file";
            $html .=
                  qq{<li><a href="$url"">$label</a> (}
                . join( ',', grep { defined $_ } ( $pid, $created, $duration ) )
                . q{)</li>};
         }

         my $myversion  = $Dancer2::Plugin::NYTProf::VERSION;
         my $nytversion = $Devel::NYTProf::VERSION;
         $html .= <<"LISTEND";
            </ul>
             
            <p>Generated by <a href="https://metacpan.org/pod/Dancer2::Plugin::NYTProf">
            Dancer2::Plugin::NYTProf</a> v$myversion
            (using <a href="https://metacpan.org/pod/Devel::NYTProf">
            Devel::NYTProf</a> v$nytversion)</p>
            </body>
            </html>
LISTEND

         return $html;
      },
   );

   $plugin->app->add_route(
      method => 'get',
      regexp => '/nytprof/html/**',
      code => sub {
         my $app = shift;
         my $request = $app->request;
         my ($path) = $request->splat;
         my $inner_plugin = $app->find_plugin('Dancer2::Plugin::NYTProf');

         my $inner_profdir = $inner_plugin->profdir
             || Dancer2::FileUtils::path( $app->config->{appdir}, 'nytprof' );

         $app->send_file(
            Dancer2::FileUtils::path(
               $inner_profdir, 'html', map { _safe_filename($_) } @$path
            ),
            system_path => 1
         );
      },
   );
 
   $plugin->app->add_route(
      method => 'get',
      regexp => '/nytprof/:filename',
      code => sub {
         my $app = shift;
         my $request = $app->request;
         my ($path) = $request->splat;
         my $inner_plugin = $app->find_plugin('Dancer2::Plugin::NYTProf');

         my $inner_profdir = $inner_plugin->profdir
             || Dancer2::FileUtils::path( $app->config->{appdir}, 'nytprof' );



         my $profiledata = Dancer2::FileUtils::path(
            $inner_profdir, _safe_filename($request->route_parameters->get('filename'))
         );
 
         if (!-f $profiledata) {
            return "No such profile run $profiledata found.";
         }
 
         # See if we already have the HTML for this run stored; if not, invoke
         # nytprofhtml to generate it
 
         # Right, do we already have generated HTML for this one?  If so, use it
         my $inner_htmldir = Dancer2::FileUtils::path(
            $inner_profdir, 'html', _safe_filename($request->route_parameters->get('filename'))
         );
         if (! -f Dancer2::FileUtils::path($inner_htmldir, 'index.html')) {
            my $inner_nytprofhtml_path = $plugin->nytprofhtml_path
                // File::Which::which('nytprofhtml');
            if (  !$inner_nytprofhtml_path
               || !-e $inner_nytprofhtml_path
               || !-x $inner_nytprofhtml_path )
            {
               die 'Could not find nytprofhtml script.  Ensure it is in your path, '
                   . 'or set the nytprofhtml_path option in your config.';
            }
            # TODO: scrutinise this very carefully to make sure it's not
            # exploitable
            system($inner_nytprofhtml_path, "--file=$profiledata", "--out=$inner_htmldir");
 
            if ($? == -1) {
                die "'$nytprofhtml_path' failed to execute: $!";
            } elsif ($? & 127) {
                die sprintf q{'%s' died with signal %d, %s coredump},
                    $nytprofhtml_path,,
                    ($? & 127),
                    ($? & 128) ? 'with' : 'without';
            } elsif ($? != 0) {
                die sprintf q{'%s' exited with value %d},
                    $nytprofhtml_path, $? >> 8;
            }
        }
 
         # Redirect off to view it:
         return $app->redirect(
            '/nytprof/html/' . $request->route_parameters->get('filename') . '/index.html' );
      },
   );

   $plugin->app->prefix($old_prefix);
}

# Rudimentary security - remove any directory traversal or poison null
# attempts.  We're dealing with user input here, and if they're a sneaky
# bastard, they could convince us to send a file we shouldn't, or have
# nytprofhtml write its output to somewhere it shouldn't.  We don't want that.
sub _safe_filename {
    my $filename = shift;
    $filename =~ s/\\//g;
    $filename =~ s/\0//g;
    $filename =~ s/^\.\.//g;
    $filename =~ s/\/\.\./\//g;
    $filename =~ s/\.\.\//\//g;
    $filename =~ s/[\/]//g;
    return $filename;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::NYTProf - NYTProf, in your Dancer2 application!

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

    package MyApp;
    use Dancer2 appname => 'MyApp';
 
    # enables profiling and "/nytprof"
    use Dancer2::Plugin::NYTProf;

Or, if you want to enable it only under development environment (as you should!),
you can do something like:

    package MyApp;
    use Dancer2 appname => 'MyApp';
 
    # enables profiling and "/nytprof"
    if (setting('environment') eq 'development') {
        eval 'use Dancer2::Plugin::NYTProf';
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
the first one we can find in your PATH environment. You should only need to
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
control which requests get profiled) will be added in a future version.

=head1 KEYWORDS

This plugin does not add any keywords to L<Dancer2>.

=head1 ENHANCEMENT OPPORTUNITIES

=over 4

=item * You don't get any choice of the reports URL.

It's C</nytprof> for now, sorry. I may add a config variable later.

=item * The profile run list at C</nytprof> is ugly as homemade sin.

I may switch that to a simple HTML table at a later date.

=back

=head1 ACKNOWLEDGEMENTS

This plugin relies heavily prior work on L<Dancer::Plugin::NYTProf>.  Special thanks
to my employer, Clearbuilt, for giving me time to work on this module.

=head1 SEE ALSO

=over 4

=item * L<Dancer2>

=item * L<Devel::NYTProf>

=back

=cut

=head1 AUTHOR

Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
