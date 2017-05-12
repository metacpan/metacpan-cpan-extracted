package App::ForExample;

use warnings;
use strict;

=head1 NAME

App::ForExample - A guide through Catalyst, Apache, lighttpd, nginx, monit, ..., configuration hell

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';

=head1 SYNOPSIS

    # To output a FastCGI (ExternalServer)/Apache configuration (with monit stub and start-stop script), run:
    for-example catalyst/fastcgi apache2 standalone --class My::App --hostname example.com --output my-app

    # The above command would have created the following:

        my-app.apache2      The Apache2 virtual host configuration (hosted at (www.)example.com)
        my-app.start-stop   The start/stop script to launch the FastCGI process
        my-app.monit        A monit stub used for monitoring the FastCGI process

    # This will generate a basic, stripped-down monit configuration (monitrc) suitable for a non-root user:
    for-example monit --home $HOME/monit --output $HOME/monit/monitrc

    # A mod_perl configuration for Catalyst:
    for-example catalyst/mod_perl --class Project::Xyzzy --hostname xyzzy.com --home Project-Xyzzy

=head1 DESCRIPTION

App::ForExample is a command-line tool for generating sample configurations. It is not designed to do configuration
management, but rather as a guide to get you 80% of the way there

Besides the usual Apache, lighttpd, nginx, and FastCGI configurations, App::ForExample can create a FastCGI start-stop script and a
monit configuration for monitoring those processes

=head1 USAGE

    Usage: for-example ACTION

    Where ACTION can be

    (Note: Every option below is, well, optional. If not specified, a fun default will be chosen/guessed for you)

        catalyst/fastcgi ...

            Generate a Catalyst FastCGI configuration (for monit, start-stop, or the specified http daemon and fastcgi method)

            --class             The Catalyst class for your application (e.g. Project::Xyzzy or My::App)
            --home              The path to your Catalyst home directory, default: . (The current directory)
            --log-home          The directory to log into, default: <home>/log (Below the directory given by --home)
            --base              The base for your application, default: / (At the root)
            --hostname          The hostname from which your application is served (e.g. example.com)

            --bare              Do not output anything BUT the configuration (no monit, no start-stop)
            --output -          Print output to stdout
            --output <path>     Write output to <path> (which can be either a directory or file)
                                This will split output appropiately (e.g. <file>.apache2, <file>.start-stop, <file>.monit)

            --fastcgi-script                The <path> to the Catalyst fastcgi script (e.g. script/xyzzy_fastcgi.pl)
            --fastcgi-socket <path>         Have fastcgi use <path> for the file socket
            --fastcgi-socket <host:port>    Have fastcgi use <host:port> for the socket
            --fastcgi-pid-file <path>       Store the pid for the process in <path>

            apache2 standalone  Apache2 with standalone FastCGI (mod_fastcgi)
            apache2 static      Apache2 with static FastCGI (mod_fastcgi)
            apache2 dynamic     Apache2 with dynamic FastCGI (mod_fastcgi)

            lighttpd standalone lighttpd with dynamic FastCGI
            lighttpd static     lighttpd with static FastCGI

            nginx               nginx with standalone FastCGI (the only kind supported)

            monit               A monit configuration for a standalone FastCGI setup
            start-stop          A start-stop script for a standalone FastCGI setup
            
        catalyst/mod_perl

            Generate a mod_perl2 (for Apache2) Catalyst configuration

            --class             The Catalyst class for your application (e.g. Project::Xyzzy or My::App)
            --home              The path to your Catalyst home directory, default: . (The current directory)
            --log-home          The directory to log into, default: <home>/log (Below the directory given by --home)
            --base              The base for your application, default: / (At the root)
            --hostname          The hostname from which your application is served (e.g. example.com)

        monit

            Generate a basic, stripped-down monit configuration suitable for a non-root user

            --home              The directory designated monit home (containing the pid file, log, rc, ...)

=head1 TUTORIAL

=head2 Apache2 with FastCGI on Ubuntu

Install apache2, mod_fastcgi, and L<FCGI>

    sudo apt-get install apache2 libapache2-mod-fastcgi

    cpan -i FCGI

Create the Catalyst application C<My::App>

    catalyst.pl My::App

Use L<App::ForExample> to generate the configuration

    cd My-App
    for-example catalyst/fastcgi apache2 standalone --class My::App --hostname my-app.localhost --output my-app

Make the log directory

    mkdir log

Install the apache2 configuration

    sudo cp my-app.apache2 /etc/apache2/sites-enabled

Enable the fastcgi start-stop script (with execute permissions)

    chmod +x my-app.start-stop

Add a C<my-app.localhost> entry to C</etc/hosts>

    127.0.0.1       my-app.localhost
    
Start your application

    ./my-app.start-stop start
    sudo /etc/init.d/apache restart

Visit your application at L<http://my-app.localhost>

=head1 INSTALL

You can install L<App::ForExample> by using L<CPAN>:

    cpan -i App::ForExample

If that doesn't work properly, you can find help at:

    http://sial.org/howto/perl/life-with-cpan/
    http://sial.org/howto/perl/life-with-cpan/macosx/ # Help on Mac OS X
    http://sial.org/howto/perl/life-with-cpan/non-root/ # Help with a non-root account

=head1 CONTRIBUTE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/App-ForExample/tree/master>

    git clone git://github.com/robertkrimen/App-ForExample.git

=cut

use App::ForExample::Catalog;

use Template;
use Carp;
use Path::Class;

my $catalog = App::ForExample::Catalog->catalog;
my $tt = Template->new({ BLOCKS => $catalog->{common} });

sub process ($@) {
    my $given = shift;

    my ($template);
    if ( ref $given eq 'SCALAR' ) {
        $template = $given;
    }
    else {
        $template = $catalog->{$given} or croak "Template \"$given\" does not exist in the catalog";
    }

    my $output;
    $tt->process( $template => { @_ }, \$output ) or croak "Error processing template \"$given\": ", $tt->error; 
    return $output;
}

sub output ($@) {
    my $ctx = shift;

    my $to = $ctx->option( 'output' );
    $to = '-' unless defined $to && length $to;

    if ( $to eq '-' ) {
        my $ii = 0;
        while ( @_ ) {
            shift;
            print "---\n" if $ii++ > 0;
            print shift;
        }
    }
    else {
        my $name_hint = shift;

        if ( $name_hint =~ m/^(.*)\.(.*)$/ ) { # E.g. catalyst-fastcgi.apache or .lighttpd
            $name_hint = $1;
            unshift @_, $2;
        }

        if ( ! -f $to && ( $to =~ m/\/$/ || -d _ ) ) {
            $to = file( $to, $name_hint );
        }
        else {
            $to = file $to;
        }

        my $parent = $to->parent;
        $parent->mkpath unless -d $parent;

        while ( @_ ) {
            my $name = shift;
            my $content = shift;

            my $file = file( join '.', $to, $name );
            $file->openw->print( $content );
            print "Made $file\n";
        }
    }
}

use Getopt::Chain::Declare;

sub package2name ($) {
    my $package = shift;
    my $name = $package;
    $name =~ s/::/-/g;
    $name = lc $name;
    my $name_underscore = $name;
    $name_underscore =~ s/-/_/g;
    return ( $name, $name_underscore );
}

my @parse_catalyst = qw/ package|class=s name=s home=s log-home=s base=s hostname=s fastcgi-script=s fastcgi-socket=s fastcgi-socket-path=s fastcgi-pid-file=s/;
sub parse_catalyst ($) {
    my $ctx = shift;

    # Catalyst package
    my $package = $ctx->option( 'package' ) || 'Project::Xyzzy';
    my ($package_name, $name_underscore) = package2name $package;

    # Catalyst name
    my $name = $ctx->option( 'name' );
    $name = $package_name unless defined $name;

    # Catalyst home
    my $home = $ctx->option( 'home' ) || "./";
    $home = dir( $home )->absolute;

    my $log_home = $ctx->option( 'log_home' ) || $home->subdir( 'log' );
    $log_home = dir( $log_home )->absolute;

    # Catalyst application base
    my $base = $ctx->option( 'base' ) || '/';
    $base =~ s/^\/+//;
    my $alias_base = $base eq '' ? '/' : "/$base/";

    # Hostname
    my $hostname = $ctx->option( 'hostname' ) || "$name.example.com";

    my $fastcgi_script = $ctx->option( 'fastcgi-script' );
    $fastcgi_script = join '/', $home, 'script', "${name_underscore}_fastcgi.pl" unless defined $fastcgi_script;
    my $fastcgi_script_basename = file( $fastcgi_script )->basename;
    my $fastcgi_socket = $ctx->option( 'fastcgi-socket' );
    $fastcgi_socket = "/tmp/$name.socket" unless defined $fastcgi_socket;
    my $fastcgi_host_port;
    if ( $fastcgi_socket =~ m/^(.+):(\d+)$/ ) {
        $fastcgi_host_port = [ $1, $2 ];
    }
    my $fastcgi_socket_path = $ctx->option( 'fastcgi-socket-path' );
    $fastcgi_socket_path = "/tmp/$name.fcgi" unless defined $fastcgi_socket_path;
    my $fastcgi_pid_file = $ctx->option( 'fastcgi-pid-file' );
    $fastcgi_pid_file = "$name-fastcgi.pid" unless $fastcgi_pid_file;
    $fastcgi_pid_file = join '/', $home, $fastcgi_pid_file unless $fastcgi_pid_file =~ m/^\//;

    my @data;
    push @data, package => $package,
        name => $name,
        name_underscore => $name_underscore,
        home => $home,
        log_home => $log_home,
        base => $base,
        alias_base => $alias_base,
        hostname => $hostname,
        fastcgi_script => $fastcgi_script,
        fastcgi_script_basename => $fastcgi_script_basename,
        fastcgi_socket => $fastcgi_socket,
        fastcgi_host_port => $fastcgi_host_port,
        fastcgi_socket_path => $fastcgi_socket_path,
        fastcgi_pid_file => $fastcgi_pid_file,
    ;
    return { @data };
}

sub do_help ($) {
    my $ctx = shift;

    print <<_END_;
Usage: for-example ACTION

Where ACTION can be

(Note: Every option below is, well, optional. If not specified, a fun default will be chosen/guessed for you)

    catalyst/fastcgi ...

        Generate a Catalyst FastCGI configuration (for monit, start-stop, or the specified http daemon and fastcgi method)

        --class             The Catalyst class for your application (e.g. Project::Xyzzy or My::App)
        --home              The path to your Catalyst home directory, default: . (The current directory)
        --log-home          The directory to log into, default: <home>/log (Below the directory given by --home)
        --base              The base for your application, default: / (At the root)
        --hostname          The hostname from which your application is served (e.g. example.com)

        --bare              Do not output anything BUT the configuration (no monit, no start-stop)
        --output -          Print output to stdout
        --output <path>     Write output to <path> (which can be either a directory or file)
                            This will split output appropiately (e.g. <file>.apache2, <file>.start-stop, <file>.monit)

        --fastcgi-script                The <path> to the Catalyst fastcgi script (e.g. script/xyzzy_fastcgi.pl)
        --fastcgi-socket <path>         Have fastcgi use <path> for the file socket
        --fastcgi-socket <host:port>    Have fastcgi use <host:port> for the socket
        --fastcgi-pid-file <path>       Store the pid for the process in <path>

        apache2 standalone  Apache2 with standalone FastCGI (mod_fastcgi)
        apache2 static      Apache2 with static FastCGI (mod_fastcgi)
        apache2 dynamic     Apache2 with dynamic FastCGI (mod_fastcgi)

        lighttpd standalone lighttpd with dynamic FastCGI
        lighttpd static     lighttpd with static FastCGI

        nginx               nginx with standalone FastCGI (the only kind supported)

        monit               A monit configuration for a standalone FastCGI setup
        start-stop          A start-stop script for a standalone FastCGI setup
        
    catalyst/mod_perl

        Generate a mod_perl2 (for Apache2) Catalyst configuration

        --class             The Catalyst class for your application (e.g. Project::Xyzzy or My::App)
        --home              The path to your Catalyst home directory, default: . (The current directory)
        --log-home          The directory to log into, default: <home>/log (Below the directory given by --home)
        --base              The base for your application, default: / (At the root)
        --hostname          The hostname from which your application is served (e.g. example.com)

    monit

        Generate a basic, stripped-down monit configuration suitable for a non-root user

        --home              The directory designated monit home (containing the pid file, log, rc, ...)

For example:

    for-example catalyst/fastcgi apache2 standalone --class My::App --hostname example.com
    for-example monit --home \$HOME/my-monit
    for-example catalyst/mod_perl --class Project::Xyzzy --hostname xyzzy.com --home Project-Xyzzy

_END_
}

start [qw/ help|h|? /], sub {
    my $ctx = shift;

    if ( $ctx->option( 'help' ) || $ctx->last ) {
        do_help $ctx;
        exit 0;
    }
};

rewrite qr#catalyst/(?:mod_perl[12]|modperl[12]?)# => 'catalyst/mod_perl';

on 'catalyst/mod_perl *' => 
    [ qw/ output=s /, @parse_catalyst ] => sub {
    my $ctx = shift;
    
    my ($server);
    for ( @_ ) {
        m/(apache2?)/ and ($server) = ($1) or

        croak "Don't understand argument $_ (@_)";
    }
    ($server) = qw/apache2/;

    my @data;
    my $catalyst_data = parse_catalyst $ctx;
    push @data, %$catalyst_data;

    if ( $server =~ m/^apache2?$/ ) {
        output( $ctx, 'catalyst-mod_perl' => process 'catalyst/mod_perl/apache2' => @data );
    }
    else {
        croak "Don't understand server \"$server\""
    }

};

on 'catalyst/fastcgi *' => 
    [ @parse_catalyst, qw/ bare output=s /] => sub {
    my $ctx = shift;
    
    my ($server, $server_module, $mode);
    for ( @_ ) {
        m/(apache2?)(?:=(?:mod_)?(fastcgi|fcgid))?/ and ($server, $server_module) = ($1, $2) or
        m/lighttpd/ and $server = 'lighttpd' or
        m/nginx/ and $server = 'nginx' or
        m/(monit|start-stop)/ and $server = $1 or # Not really a server, but...

        m/standalone/ and $mode = 'standalone' or
        m/static/ and $mode = 'static' or
        m/dynamic/ and $mode = 'dynamic' or

        croak "Don't understand argument $_ (@_)";
    }

    ($server, $server_module) = qw/apache2 fastcgi/ unless $server;
    ($mode) = qw/standalone/ unless $mode;

    my @data;

    my $bare = $ctx->option( 'bare' );

    my $catalyst_data = parse_catalyst $ctx;
    push @data, %$catalyst_data;
    my $name = $catalyst_data->{name};

    if ( $server =~ m/^apache2?$/ ) {

        if ( $mode eq 'standalone' ) {
            # TODO Error in Catalyst::Engine::FastCGI dox?
            my @output;
            push @output, 'catalyst-fastcgi.apache2' => process 'catalyst/fastcgi/apache2/standalone' => @data;
            unless ($bare) {
                push @output, 'start-stop' => process 'catalyst/fastcgi/start-stop' => @data;
                push @output, 'monit' => process 'catalyst/fastcgi/monit' => @data;
            }
            output( $ctx, @output );
        }
        elsif ( $mode eq 'dynamic' ) {
            output( $ctx, 'catalyst-fastcgi.apache2' => process 'catalyst/fastcgi/apache2/dynamic' => @data );
        }
        elsif ( $mode eq 'static' ) {
            output( $ctx, 'catalyst-fastcgi.apache2' => process 'catalyst/fastcgi/apache2/static' => @data );
        }
        else {
            croak "Don't understand mode \"$mode\""
        }
    }
    elsif ( $server eq 'lighttpd' ) {

        if ( $mode eq 'standalone' ) {
            my @output;
            push @output, 'catalyst-fastcgi.lighttpd' => process 'catalyst/fastcgi/lighttpd/standalone' => @data;
            unless ($bare) {
                push @output, 'start-stop' => process 'catalyst/fastcgi/start-stop' => @data;
                push @output, 'monit' => process 'catalyst/fastcgi/monit' => @data;
            }
            output( $ctx, @output );
        }
        elsif ( $mode eq 'static' ) {
            output( $ctx, 'catalyst-fastcgi.lighttpd' => process 'catalyst/fastcgi/lighttpd/static' => @data );
        }
        else {
            croak "Don't understand mode \"$mode\""
        }
    }
    elsif ( $server eq 'nginx' ) {

        if ( $mode eq 'standalone' ) {
            my @output;
            push @output, 'catalyst-fastcgi.nginx' => process 'catalyst/fastcgi/nginx' => @data;
            unless ($bare) {
                push @output, 'start-stop' => process 'catalyst/fastcgi/start-stop' => @data;
                push @output, 'monit' => process 'catalyst/fastcgi/monit' => @data;
            }
            output( $ctx, @output );
        }
        else {
            croak "Don't understand mode \"$mode\""
        }
    }
    elsif ( $server eq 'start-stop' ) {
        output( $ctx, 'catalyst-fastcgi-start-stop' => process 'catalyst/fastcgi/start-stop' => @data );
    }
    elsif ( $server eq 'monit' ) {
        output( $ctx, 'catalyst-fastcgi-monit' => process 'catalyst/fastcgi/monit' => @data );
    }
    else {
        croak "Don't understand server \"$server\""
    }

};

on 'monit' => 
    [qw/ output=s home=s monit-home=s /] => sub {
    my $ctx = shift;

    my @home;
    unless ($home[0] = $ctx->option( 'home' )) {
        @home = qw/ . my-monit /;
    }
    my $home = dir @home;
    $home = $home->absolute;
    output( $ctx, monit => process 'monit' => ( home => $home ) );
};

on 'help' => 
    undef, sub {
    my $ctx = shift;

    do_help $ctx;
};

on qr/.*/ => undef, sub {
    my $ctx = shift;

    my $path = join ' ', $ctx->path;
    print <<_END_;
Don't understand command: $path

Usage: for-example [--help] ...

    catalyst/fastcgi apache2 standalone|static|dynamic
    catalyst/fastcgi lighttpd standalone|static
    catalyst/fastcgi nginx
    catalyst/fastcgi start-stop|monit
    catalyst/mod_perl
    monit

    help

_END_
    exit -1;
};

no Getopt::Chain::Declare;

=head1 SEE ALSO

L<http://dev.catalystframework.org/wiki/deployment>

L<Catalyst::Engine::Apache>

L<Catalyst::Engine::FastCGI>

=head1 ACKNOWLEDGEMENTS

All the people that have put effort into the Catalyst documentation, including the pod, advent, and wiki

Dan Dascalescu, Jay Shirley, Tomas Doran, Daniel Austin, Jason Felds, Moritz Onken, and Brian Friday, who all put effort into the deployment wiki, which
formed the basis for many parts of this tool

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-forexample at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ForExample>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ForExample


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ForExample>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ForExample>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ForExample>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ForExample/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__PACKAGE__; # End of App::ForExample
