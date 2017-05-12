use strict;
use warnings;
package App::Padadoy;
{
  $App::Padadoy::VERSION = '0.125';
}
#ABSTRACT: Simply deploy PSGI applications

use 5.010;
use autodie;
use Try::Tiny;
use IPC::System::Simple qw(run capture $EXITVAL);
use File::Slurp;
use List::Util qw(max);
use File::ShareDir qw(dist_file);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir catfile rel2abs);
use Git::Repository;
use Sys::Hostname;
use YAML::Any qw(LoadFile Dump);
use Cwd;

# required for deployment
use Plack::Handler::Starman qw();
use Carton qw(0.9.4);

# required for testing
use Plack::Test qw();
use HTTP::Request::Common qw();

our @commands = qw(init start stop restart config status create checkout
        deplist cartontest remote version update enable logs);
our @remote_commands = qw(init start stop restart config status version); # TODO: create deplist checkout cartontest
our @configs = qw(user base repository port pidfile quiet remote);

# _msg( $fh, [\$caller], $msg [@args] )
sub _msg (@) { 
    my $fh = shift;
    my $caller = ref($_[0]) ? ${(shift)} :
            ((caller(2))[3] =~ /^App::Padadoy::(.+)/ ? $1 : '');
    my $text  = shift;
    say $fh (($caller ? "[$caller] " : "") 
        . (@_ ? sprintf($text, @_) : $text));
}

sub fail (@) {
    _msg(*STDERR, @_);
    exit 1;
}

sub msg {
    my $self = shift;
    _msg( *STDOUT, @_ ) unless $self->{quiet};
}


sub new {
    my ($class, $config, %values) = @_;

    my $self = bless { }, $class;
    my $yaml = { };

    if ($config) {
        # $self->msg("Reading configuration from $config");
        try {
            $yaml = LoadFile( $config );
        } catch {
            fail $_;
        };
        $self->{base} = rel2abs(dirname($config));
    } else {
        $self->{base} = $values{base} // cwd;
    }

    foreach (@configs) {
        $yaml->{$_} = $values{$_} if defined $values{$_};
    }

    $self->{user}       = $yaml->{user} || getlogin || getpwuid($<);
    $self->{repository} = $yaml->{repository} || catdir($self->{base},'repository');
    $self->{port}       = $yaml->{port} || 6000;
    $self->{pidfile}    = $yaml->{pidfile} || catfile($self->{base},'starman.pid');
    $self->{remote}     = $yaml->{remote};

    # config file
    $self->{config} = $config;

    # TODO: validate config values

    fail "Invalid remote value: ".$self->{remote} 
        if $self->{remote} and $self->{remote} !~ qr{^[^@]+@[^:]+:[~/].*$};

    $self;
}


sub create {
    my $self   = shift;
    my $module = shift;

    $self->{module} = $module;
    fail("Invalid module name: $module") 
        if $module and $module !~ /^([a-z][a-z0-9]*(::[a-z][a-z0-9]*)*)$/i;

    $self->_provide_config('create');

    $self->msg('Using base directory '.$self->{base});
    chdir $self->{base};

    $self->msg('app/');
    mkdir 'app';

    $self->msg('app/Makefile.PL');
    write_file('app/Makefile.PL',{no_clobber => 1},
        read_file(dist_file('App-Padadoy','Makefile.PL')));

    if ( $module ) {
        $self->msg("app/app.psgi (calling $module)");
        my $content = read_file(dist_file('App-Padadoy','app2.psgi'));
        $content =~ s/YOUR_MODULE/$module/mg;
        write_file('app/app.psgi',{no_clobber => 1},$content);

        my @parts = ('app', 'lib', split('::', $module));
        my $name = pop @parts;

        my $path = join '/', @parts;
        $self->msg("$path/");
        make_path ($path);

        $self->msg("$path/$name.pm");
        $content = read_file(dist_file('App-Padadoy','Module.pm.tpl'));
        $content =~ s/YOUR_MODULE/$module/mg;
        write_file( "$path/$name.pm", {no_clobber => 1}, $content );

        $self->msg('app/t/');
        make_path('app/t');

        $self->msg('app/t/basic.t');
        my $test = read_file(dist_file('App-Padadoy','basic.t'));
        $test =~ s/YOUR_MODULE/$module/mg;
        write_file('app/t/basic.t',{no_clobber => 1},$test);
    } else {
        $self->msg('app/app.psgi');
        write_file('app/app.psgi',{no_clobber => 1},
            read_file(dist_file('App-Padadoy','app1.psgi')));

        $self->msg('app/lib/');
        mkdir 'app/lib';
        write_file('app/lib/.gitkeep',{no_clobber => 1},''); # TODO: required?

        $self->msg('app/t/');
        mkdir 'app/t';
        write_file('app/t/.gitkeep',{no_clobber => 1},''); # TODO: required?
    }

    $self->msg('data/');
    mkdir 'data';

    $self->msg('dotcloud.yml');
    write_file( 'dotcloud.yml',{no_clobber => 1},
         "www:\n  type: perl\n  approot: app" );
    
    my $content = read_file(dist_file('App-Padadoy','index.pl.tpl'));
    $self->msg("perl/index.pl");
    make_path("perl");
    write_file('perl/index.pl',{no_clobber => 1},$content);

    my %symlinks = (libs => 'app/lib','app/deplist.txt' => 'deplist.txt');
    while (my ($from,$to) = each %symlinks) {
        $self->msg("$from -> $to");
        symlink $to, $from;
    }

    # TODO:
    # .openshift/      - hooks for OpenShift (o)
    #   action_hooks/  - scripts that get run every git push (o)
}


sub deplist {
    my $self = shift;

    eval "use Perl::PrereqScanner";
    fail "Perl::PrereqScanner required" if $@;

    fail "not implemented yet";

    # TODO: dependencies should be detectable automatically
    # with Perl::PrereqScanner::App

    $self->msg("You must initialize a git repository and add remotes");
}


sub init {
    my $self = shift;
    $self->msg("Initializing environment");

    fail "Expected to run in ".$self->{base} 
        unless cwd eq $self->{base};
    fail 'Expected to run in an EMPTY base directory' 
        if grep { $_ ne $0 and $_ ne 'padadoy.yml' } <*>;

    $self->_provide_config('init');

    try { 
        my $out = capture('git', 'init', '--bare', $self->{repository});
        $self->msg(\'init',$_) for split "\n", $out;
    } catch {
        fail 'Failed to init git repository in ' . $self->{repository};
    };

    my $file = $self->{repository}.'/hooks/update';
    $self->msg("$file as executable");
    write_file($file, read_file(dist_file('App-Padadoy','update')));
    chmod 0755,$file;

    $file = $self->{repository}.'/hooks/post-receive';
    $self->msg("$file as executable");
    write_file($file, read_file(dist_file('App-Padadoy','post-receive')));
    chmod 0755,$file;

    $self->msg("logs/");
    mkdir 'logs';
 
    $self->msg("app -> current/app");
    symlink 'current/app','app';

    $self->msg("Pushing to git repository %s@%s:%s will update", 
        $self->{user}, hostname, $self->{repository});
}


sub config {
    say shift->_config;
}

sub _config {
    my $self = shift;
    Dump( { map { $_ => $self->{$_} // '' } @configs } );
}


sub restart {
    my $self = shift;

    my $pid = $self->_pid;
    if ($pid) {
        $self->msg("Gracefully restarting starman as deamon on port %d (pid in %s)",
            $self->{port}, $self->{pidfile});
        run('kill','-HUP',$pid);
    } else {
        $self->start;
    }
}


sub start {
    my $self = shift;

    fail "No configuration file found" unless $self->{config};

    chdir $self->{base}.'/app';


if (0) { # FIXME
    # check whether dependencies are satisfied
    my @out = split "\n", capture('carton check --nocolor 2>&1');
    if (@out > 1) { # carton check always seems to exit with zero (?!)
        $out[0] = 
        _msg( *STDERR, \'start', $_) for @out;
        exit 1;
    }
}

    # make sure log files exist
    my $logs = catdir($self->{base},'logs');
    make_path($logs) unless -d $logs;

    foreach ( grep { ! -e $_ } 
              map { catfile($logs,$_) } qw(error.log access.log) ) {
        open (my $fh, '>>', $_); 
        close $fh;
    }

    $self->msg("Starting starman as deamon on port %d (pid in %s)",
        $self->{port}, $self->{pidfile});

    # TODO: refactor after release of carton 1.0
    $ENV{PLACK_ENV} = 'production';
    my @opt = (
        'starman','--port' => $self->{port},
        '-D','--pid'   => $self->{pidfile},
        '--error-log'  => catfile($logs,'error.log'),
        '--access-log' => catfile($logs,'access.log'),
    );
    run('carton','exec','-Ilib','--',@opt);
}


sub stop {
    my $self = shift;

    my $pid = $self->_pid;
    if ( $pid ) {
        $self->msg("killing old process");
        run('kill',$pid);
    } else {
        $self->msg("no PID file found");
    }
}

sub _pid {
    my $self = shift;
    return unless $self->{pidfile} and -f $self->{pidfile};
    my $pid = read_file($self->{pidfile}) || 0;
    return ($pid =~ s/^(\d+).*$/$1/sm ? $pid : 0);
}


sub status {
    my $self = shift;

    fail "No configuration file found" unless $self->{config};
    $self->msg("Configuration from ".$self->{config});

    # PID file?
    my $pid = $self->_pid;
    if ($pid) {
        $self->msg("Process running: $pid (PID in %s)", $self->{pidfile});
    } else {
        $self->msg("PID file %s not found or broken", $self->{pidfile});
    }

    my $port = $self->{port};
    
    # something listening on the port?
    my $sock = IO::Socket::INET->new( PeerAddr => "localhost:$port" );
    $self->msg("Port is $port - " . ($sock ? "currently used" : "not used"));

    # find out whether this users owns the socket (there should be a better way!) 
    my ($command,$pid2,$user);
    my @lsof = eval { grep /LISTEN/, ( capture('lsof','-i',":$port") ) };
    if (@lsof) { 
        foreach (@lsof) { # there may be multiple processes
            my @f = split /\s+/, $_;
            ($command,$pid2,$user) = @f if !$pid2 or $f[1] < $pid2;
        }
    } else {
        $self->msg("Not listening at port $port");
    }

    if ($sock or $pid2) {
        if ($pid and $pid2 and $pid eq $pid2) {
            $self->msg("Port $port is used by process $pid as given in ".$self->{pidfile});
        } elsif (!$pid and $user and $user eq $self->{user}) {
            $self->msg("Looks like " . $self->{pidfile} . " is missing (should contain PID $pid2) ".
                "maybe you run another instance as same user ".$self->{user});
        } else {
            $self->msg("Looks like the port $port is used by someone else!"); 
        }
    }
}

sub _provide_config {
    my ($self, $caller) = @_;
    return if $self->{config};

    $self->{config} = cwd.'/padadoy.yml';
    $self->msg(\$caller,"Writing default configuration to ".$self->{config});
    # TODO: better use template with comments instead
    write_file( $self->{config}, $self->_config );
}


sub checkout {
    my ($self, $revision, $directory, $current) = @_;
    $revision  ||= 'master';
    $directory ||= catdir($self->{base},$revision);

    my $git_dir = $self->{repository};
    fail("git repository directory not found: $git_dir") unless -d $git_dir;

    $self->msg("checking out $revision to $directory");
    fail("Working directory already exists: $directory") 
        if -e $directory;

    if ( $current ) {
        fail("Current working directory not found") unless -d $current;
    } else {
        $current =  catdir($self->{base},'current');
    }

    mkdir $directory;
    my $local = catdir( $current, 'app', 'local' );
    if (-d $local) {
        my $newlocal = catdir($directory,'app');
        $self->msg("rsyncing $local into $newlocal");
        mkdir $newlocal;
        run('rsync', '-a', $local, catdir($directory,'app') );
    }

    $self->msg("repository is $git_dir");
    my $r = Git::Repository->new(
        work_tree => $directory, 
        git_dir   => $git_dir,
    );
    $r->run( checkout => '-q', '-f', $revision );
}


sub cartontest {
    my $self = shift;

    chdir $self->{base}.'/app';
    $self->msg("installing dependencies and testing");

    run('carton install');
    run('perl Makefile.PL');
    run('carton exec -Ilib -- make test');
    run('carton exec -Ilib -- make clean > /dev/null');
}


sub update {
    my $self = shift;
    my $revision = shift || 'master';

    $self->msg("updating to revision $revision");

    # check out to $newdir
    $self->checkout($revision);
    my $revdir = catdir($self->{base},$revision);
    my $newdir = catdir($self->{base},'new');

    # TODO: call directly
    run('padadoy','cartontest',"base=$revdir");

    chdir $self->{base};
    run('rm','-f','new');
    symlink $revision, 'new';

    $self->msg("revision $revision checked out and tested at $newdir");
}


sub enable {
    my $self = shift;

    fail "Missing directory ".$self->{base} unless -d $self->{base};
    chdir $self->{base};

    my $new     = catdir($self->{base},'new');
    my $current = catdir($self->{base},'current');

    fail "Missing directory $new" unless -d $new;
 
    $self->msg("$new -> current");
    run('rm','-f','current');
    run('mv','new','current');

    chdir $current;

    # TODO: re-read full configuration (?)
    $self->{base} = $current;

    # graceful restart seems broken
    $self->stop;
    $self->start;

    # TODO: cleanup old revisions?
}


sub remote {
    my $self = shift;
    my $command = shift;

    fail 'no remote configured' unless $self->{remote};
    fail 'missing remote command' unless $command;

    fail "command $command not supported on remote"
        unless grep { $_ eq $command } @remote_commands;
    
    $self->{remote} =~ /^(.+):(.+)$/ or fail 'invalid remote value: '.$self->{remote};
    my ($userhost,$dir) = ($1,$2);
    fail 'remote directory should not contain spaces' if $dir =~ /\s/;

    $self->msg("running padadoy on ".$self->{remote});

    run('ssh',$userhost,"cd $dir && padadoy $command ".join ' ', @_);
}


sub logs {
    my $self = shift;
    my $logs = catdir($self->{base},'logs');
    run('tail','-F', map { catfile($logs,$_) } qw(error.log access.log));
}


sub version {
    say 'This is padadoy version '.($App::Padadoy::VERSION || '??');
    exit;
}

1;


__END__
=pod

=head1 NAME

App::Padadoy - Simply deploy PSGI applications

=head1 VERSION

version 0.125

=head1 SYNOPSIS

Create a new application and start it locally on your development machine:

  $ padadoy create Your::Module
  $ plackup app/app.psgi

Start application locally as deamon with bundled dependencies:

  $ padadoy cartontest
  $ padadoy start

Show status of your running application and stop it:

  $ padadoy status
  $ padadoy stop

Manage your application files in a git repository:

  $ git add *
  $ git commit -m "inial commit"

Deploy the application at dotCloud

  $ dotcloud create nameoryourapp
  $ dotcloud push nameofyourapp

Prepare your own deployment machine (as C<remote> in C<padadoy.yml>):

  $ padadoy remote init

Add your deployment machine as git remote and deploy:

  $ git remote add prod ...
  $ git push prod master

=head1 DESCRIPTION

I<This is an early preview release, be warned! Design changes are likely,
at least until a stable carton 1.0 has been released!>

L<Padadoy|padadoy> is a command line application to facilitate deployment of
L<PSGI> applications, inspired by L<http://dotcloud.com>. Padadoy is based on
the L<Carton> module dependency manager, L<Starman> webserver, and git. In
short, an application is managed in a git repository and pushed to a remote
repository for deployment. At the remote server, required modules are installed
and unit tests are run, to minimize the chance of a broken installation.

An application is managed in a git repository with following structure.  You
can create it automatically with C<padadoy create> or C<padadoy create
Your::App::Module>.  

    app/
       app.psgi      - application startup script
       lib/          - local perl modules (at least the actual application)
       t/            - unit tests
       Makefile.PL   - used to determine required modules and to run tests

    deplist.txt      - a list of perl modules required to run (o)
      
    data/            - persistent data (o)

    dotcloud.yml     - basic configuration for dotCloud (o)
    
    libs -> app/lib                - symlink for OpenShift (o)
    deplist.txt -> app/deplist.txt - symlink for OpenShift (o)
    perl/index.pl                  - CGI script for OpenShift (o)

This directory layout helps to easy deploy on multiple platforms. Files and 
directories marked by C<(o)> are optional, depending on what platform you want
to deploy. Padadoy also facilitates deploying to your own servers just like
a PaaS provider.

On the deployment machine there is a directory with the following structure:

    repository/      - the bare git repository that the app is pushed to
    current -> ...   - symbolic link to the current working directory
    new -> ...       - symbolic link to the new working directory on updates
    padadoy.yml      - local configuration

You can create this layout with C<padadoy remote init>. After adding the remote
repository as git remote, you can simply deploy new versions with C<git push>.

=head1 METHODS

=head2 new ( [$configfile] [%configvalues] )

Start padadoy, optionally with some configuration (C<padadoy.yml>).

=head2 create

Create an application boilerplate.

=head2 deplist

List dependencies (not implemented yet).

=head2 init

Initialize on your deployment machine.

=head2 config

Show configuration values.

=head2 restart

Start or gracefully restart the application if running.

=head2 start

Start starman webserver with carton.

=head2 stop

Stop starman webserver.

=head2 status

Show some status information.

=head2 checkout ( [$revision], [$directory], [$current] ) 

Check out a revision to a new working directory. If no directory name is
specified, the revision name will be concatenated to the base directory.
If a current directory is specified, the C<local> directory will first be 
copied with rsync to avoid reinstallation of dependent packages with carton.

=head2 cartontest

Update dependencies with carton and run tests.

=head2 update ( [$revision] )

Checkout a revision, test it, and create a symlink called C<new> on success.

=head2 enable

This method is called as post-receive hook in the deployment repository.  It
creates (or changes) the symlink C<new> to the symlink C<current> and
restarts the application.

=head2 remote ( $command [@options] )

Run padadoy on a remote machine.

=head2 logs

Consult logfiles.

=head2 version

Show version number and exit.

=head1 DEPLOYMENT

Actually, you don't require padadoy if you only deploy at some PaaS provider, but
deployment at dotCloud and OpenShift is also documented below for convenience.

=head2 On your own server

The following should work at least with a fresh Ubuntu installation and Perl >=
5.10.  First you need to install git, a build toolchain, and cpanminus:

  $ sudo apt-get install git-core build-essential lbssl-dev
  $ wget -O - http://cpanmin.us | sudo perl - --self-upgrade

Now you can install padadoy from CPAN:

  $ sudo cpanm App::Padadoy

Depending on the Perl modules your application requires, you may need some
additional packages, such as C<libexpat1-dev> for XML. For instance for HTTPS 
you need L<LWP::Protocol::https> that requires C<libnet-ssleay-perl> to build:

  $ sudo apt-get install libnet-ssleay-perl
  $ sudo cpanm LWP::Protocol::https

For each deployment you create a remote repository and initialize it:

  $ padadoy init

You may then edit the file C<padadoy.yml> to adjust the port and other
settings. Back on another machine you can simply push to the deployment
repository with C<git push>. C<padadoy init> installs some hooks in the
deployment repository so new code is first tested before activation.

In most cases, you will run your application begind a reverse proxy, so you
should include L<Plack::Middleware::XForwardedFor> to get real remote IPs.

=head2 On dotCloud

Create a dotCloud account and install the command line client as documented at
L<https://docloud.com>.

=head2 On OpenShift

Create an OpenShift account, install the command line client, and create a
domain, as documented at L<https://openshift.redhat.com/app/getting_started>
(you may need to C<sudo apt-get install libopenssl-ruby>, and to find and
fiddle around the client at C</var/lib/gems/1.8/bin/rhc> to actually make use
of it). Att your OpenShift repository as remote and merge.

=head1 BACKGROUND

The remote repository contains two git hooks, which are enabled by 
C<padadoy init>: the C<update> hook calls C<padadoy update> with the
revision hash that is pushed to the repository:

    #!/bin/bash
    newrev="$3"
    padadoy update $newrev

On success, the C<post-receive> hook calls C<padadoy enable> to

=head1 SEE ALSO

There are many ways to deploy PSGI applications. See this presentation by 
Tatsuhiko Miyagawa for an overview:

L<http://www.slideshare.net/miyagawa/deploying-plack-web-applications-oscon-2011-8706659>

By now, padadoy only supports Starman web server, but it might be easy to
support more.

This should also work on Amazon EC2 but I have not tested yet. See for instance
L<http://www.deepakg.com/prog/2011/01/deploying-a-perl-dancer-application-on-amazon-ec2/>.

=head1 FAQ

I<What does "padadoy" mean?> The funny name was derived from "PlAck DAncer
DeplOYment" but it does not mean anything.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

