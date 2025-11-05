package Acme::Crux;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Crux - The CTK::App of the next generation

=head1 SYNOPSIS

    use Acme::Crux;

=head1 DESCRIPTION

The CTK::App of the next generation

=head2 new

    my $app = Acme::Crux->new(
        project     => 'MyApp',
        moniker     => 'myapp',

        options     => {foo => 'bar'},

        plugins     => { foo => 'MyApp::Foo', bar => 'MyApp::Bar' },
        preload     => 'Config, Log',

        cachedir    => '/var/cache/myapp',
        configfile  => '/etc/myapp/myapp.conf',
        datadir     => '/var/lib/myapp',
        docdir      => '/usr/share/doc/myapp',
        lockdir     => '/var/lock/myapp',
        logdir      => '/var/log/myapp',
        logfile     => '/var/log/myapp/myapp.log',
        pidfile     => '/var/run/myapp/myapp.pid',
        root        => '/etc/myapp',
        rundir      => '/var/run/myapp',
        sharedir    => '/usr/share/myapp',
        spooldir    => '/var/spool/myapp',
        tempdir     => '/tmp/myapp',
        webdir      => '/var/www/myapp',

        debug       => 0,
        test        => 0,
        verbose     => 0,
    );

=head1 ATTRIBUTES

This class implements the following attributes

=head2 cachedir

    cachedir => '/var/cache/myapp'

Cache dir for project cache files

    $app = $app->cachedir( "/path/to/cache/dir" );
    my $cachedir = $app->cachedir;

Default: /var/cache/<MONIKER>

=head2 configfile

    configfile => '/etc/myapp/myapp.conf'

Path to the configuration file of your project

    $app = $app->configfile( "/path/to/config/file.conf" );
    my $configfile = $app->configfile;

Default: /etc/<MONIKER>/<MONIKER>.conf

=head2 datadir

    datadir => '/var/lib/myapp'

Data dir of project

    $app = $app->datadir( "/path/to/data/dir" );
    my $datadir = $app->datadir;

Default: /var/lib/<MONIKER>

=head2 debug

    debug => 1
    debug => 'on'
    debug => 'yes'

Debug mode

Default: 0

=head2 docdir

    docdir => '/usr/share/doc/myapp'

Doc dir for project documentation

    $app = $app->docdir( "/path/to/docs/dir" );
    my $docdir = $app->docdir;

Default: /usr/share/doc/<MONIKER>

=head2 lockdir

    lockdir => '/var/lock/myapp'

Lock dir for project lock files

    $app = $app->lockdir( "/path/to/lock/dir" );
    my $lockdir = $app->lockdir;

Default: /var/lock/<MONIKER>

=head2 logdir

    logdir => '/var/log/myapp'

Log dir for project logging

    $app = $app->logdir( "/path/to/log/dir" );
    my $logdir = $app->logdir;

Default: /var/log/<MONIKER>

=head2 logfile

    logfile => '/var/log/myapp/myapp.log'

Path to the log file

    $app = $app->logfile( "/path/to/file.log" );
    my $logfile = $app->logfile;

Default: /var/log/<MONIKER>/<MONIKER>.log

=head2 moniker

    moniker => 'myapp'

This attribute sets moniker of project name.

Moniker B<SHOULD> contains only symbols: a-z, 0-9, '_', '-', '.'

    $app = $app->moniker( 'myapp' );
    my $moniker = $app->moniker;

Default: decamelized version of the C<project> attribute

=head2 options

    options => {foo => 'bar'}

Command-line options, or any hash-ref structure with options. See L<Getopt::Long>

    $app = $app->options({ foo => 'bar' });
    my $options = $app->options;

Default: {}

=head2 pidfile

    pidfile => '/var/run/myapp/myapp.pid'

Path to the pid file

    $app = $app->pidfile( "/path/to/file.pid" );
    my $pidfile = $app->pidfile;

Default: /var/run/<MONIKER>/<MONIKER>.pid

=head2 preload, preload_plugins

    preload => [qw/foo bar baz/]
    preload => "foo bar baz"
    preload => "foo, bar, baz"
    preload => "foo; bar; baz"

This attribute sets list of preloading plugins.
Each specified plugin will be loaded and registered during application creation automatically

Default preloading plugins: C<Config>, C<Log>

=head2 plugins

    plugins => { foo => 'MyApp::Foo', bar => 'MyApp::Bar' }

This attribute defines specified plugins only.
B<NOTE!> This attribute NOT performs automatic loading and register specified plugins!

See the L</"plugin"> method below if you want to load and register a plugin

    $app = $app->plugins(
        foo => 'MyApp::Foo',
        bar => 'MyApp::Bar',
    );
    my $plugins = $app->plugins;

Default plugins:

    Config  Acme::Crux::Plugin::Config
    Log     Acme::Crux::Plugin::Log

=head2 project

    project => 'MyApp'

Name of project

    $app = $app->project( 'MyApp' );
    my $project = $app->project;

Default: script name (without file extension) or invocant class

=head2 root

    root => '/etc/myapp'

Root dir of project

    $app = $app->root( "/etc/myapp" );
    my $root = $app->root;

Default: /etc/<MONIKER>

=head2 rundir

    rundir => '/var/run/myapp'

Run dir for project pid files

    $app = $app->rundir( "/path/to/run/dir" );
    my $rundir = $app->rundir;

Default: /var/run/<MONIKER>

=head2 sharedir

    sharedir => '/usr/share/myapp'

Share dir for project

    $app = $app->sharedir( "/path/to/share/dir" );
    my $sharedir = $app->sharedir;

Default: /usr/share/<MONIKER>

=head2 spooldir

    spooldir => '/var/spool/myapp'

Spool is the dir for project pool data

    $app = $app->spooldir( "/path/to/spool/dir" );
    my $spooldir = $app->spooldir;

Default: /var/spool/<MONIKER>

=head2 tempdir

    tempdir => '/tmp/myapp'

Temp dir for project temporary files

    $app = $app->tempdir( "/path/to/temp/dir" );
    my $tempdir = $app->tempdir;

Default: /tmp/<MONIKER>

=head2 test

    test => 1
    test => 'on'
    test => 'yes'

Test mode

Default: 0

=head2 verbose

    verbose => 1
    verbose => 'on'
    verbose => 'yes'

Verbose mode

Default: 0

=head2 webdir

    webdir => '/var/www/myapp'

Web dir for project web files (DocumentRoot)

    $app = $app->webdir( "/path/to/webdoc/dir" );
    my $webdirr = $app->webdir;

Default: /var/www/<MONIKER>

=head1 METHODS

This class implements the following methods

=head2 startup

This is your main hook into the application, it will be called at application startup.
Meant to be overloaded in a subclass.

This method is called immediately after creating the instance and returns it

B<NOTE:> Please use only in your subclasses!

    sub startup {
        my $self = shift;

        . . .

        return $self; # REQUIRED!
    }

=head2 debugmode

    $app->debugmode;

Returns debug flag. 1 - on, 0 - off

=head2 begin

    my $timing_begin = $app->begin;

This method sets timestamp for L</elapsed>

    my $timing_begin = $app->begin;
    # ... long operations ...
    my $elapsed = $app->elapsed( $timing_begin );

=head2 elapsed

    my $elapsed = $app->elapsed;

    my $timing_begin = [gettimeofday];
    # ... long operations ...
    my $elapsed = $app->elapsed( $timing_begin );

Return fractional amount of time in seconds since unnamed timstamp has been created while start application

    my $elapsed = $app->elapsed;
    $app->log->debug("Database stuff took $elapsed seconds");

For formatted output:

    $app->log->debug(sprintf("%+.*f sec", 4, $app->elapsed));

=head2 error

    my $error = $app->error;

Returns error string if occurred any errors while working with application

    $app = $app->error( "error text" );

Sets new error message and returns object

=head2 exedir

    my $exedir = $app->exedir;

Gets exedir value

=head2 handlers

    my @names = $app->handlers;

Returns list of names of registered handlers

    my @names_and_aliases = $app->handlers(1);

Returns list of aliases and names of registered handlers

=head2 lookup_handler

    my $handler = $app->lookup_handler($name)
        or die "Handler not found";

Lookup handler by name or aliase. Returns handler or undef while error

=head2 option, opt, getopt

    my $value = $app->option("key");

Returns option value by key

    my $options = $app->option;

Returns hash-ref structure to all options

See L</options>

=head2 orig

    my $origin_args = $app->orig;

Returns hash-ref structure to all origin arguments

=head2 plugin

    $app->plugin(foo => 'MyApp::Plugin::Foo');
    $app->plugin(foo);
    $app->plugin(foo => 'MyApp::Plugin::Foo', {bar => 123, baz => 'test'});
    $app->plugin(foo => 'MyApp::Plugin::Foo', bar => 123, baz => 'test');
    $app->plugin(foo, undef, {bar => 123, baz => 'test'});

Load a plugin by name or pair - name and class

=head2 pwd

    my $pwd = $app->pwd;

This method returns current/working directory

=head2 register_handler

    use parent qw/Acme::Crux/;

    __PACKAGE__->register_handler(
        handler     => "foo",
        aliases     => "one, two",
        description => "Foo handler",
        params => {
            param1 => "test",
            param2 => 123,
        },
        code => sub {
    ### CODE:
        my $self = shift; # App
        my $meta = shift; # Meta data
        my @args = @_; # Arguments

        print Acrux::Util::dumper({
            meta => $meta,
            args => \@args,
        });

        return 1;
    });

Method for register new handler

Example output while running:

    $app->run('one', abc => 123, def => 456); # returns 1

    {
      "args" => ["abc", 123, "def", 456],
      "meta" => {
        "aliases" => ["one", "two"],
        "description" => "Foo handler",
        "name" => "foo",
        "params" => {
            "param1" => "test",
            "param2" => 123
        }
      },
      "name" => "foo"
    }

This method supports the following options:

=over 4

=item aliases, alias

    aliases => 'foo bar baz'
    aliases => 'foo, bar, baz'
    aliases => [qw/foo bar baz/]
    alias => 'foo'

Sets aliases list for handler lookup

=item code

    code => sub {
        my ($self, $meta, @args) = @_;
        # . . .
    }

Sets code oh handler

=item description

    description => 'Short description, abstract or synopsis'

=item handler, name

    handler => 'version'
    name => 'version'

Sets handler name. Default to 'default'

=item params, parameters

    params => { foo => 'bar' }

List of handler parameters. All handler parameters will passed to $meta

=back

=head2 register_method

    $app->register_method($namespace, $method, sub { 1 });
    $app->register_method($method => sub { 1 });
    __PACKAGE__->register_method($namespace, $method, sub { 1 });

This method performs register the new method in your namespace

By default use current application namespace

=head2 register_plugin

    $app->register_plugin('foo', 'MyApp::Plugin::Foo');
    $app->register_plugin('foo', 'MyApp::Plugin::Foo', {bar => 123});
    $app->register_plugin('foo', 'MyApp::Plugin::Foo', bar => 123);

Load a plugin and run C<register> method, optional arguments are passed through

=head2 run

By default this method is alias for L</run_handler> method.

This method meant to be overloaded in a subclass

=head2 run_handler

    my $result = $app->run_handler("foo",
        foo => "one",
        bar => 1
    ) or die $app->error;

Runs handler by name and returns result of it handler running

=head2 silentmode

    $app->silentmode;

Returns the verbose flag in the opposite value. 0 - verbose, 1 - silent.

See L</verbosemode>

=head2 testmode

    $app->testmode;

Returns test flag. 1 - on, 0 - off

=head2 verbosemode

    $app->verbosemode;

Returns verbose flag. 1 - on, 0 - off

See L</silentmode>

=head1 PLUGINS

The following plugins are included in the Acrux distribution

=over 4

=item L<Acme::Crux::Plugin::Config>

    Config => Acme::Crux::Plugin::Config

L<Acrux::Config> configuration plugin

=item L<Acme::Crux::Plugin::Log>

    Log => Acme::Crux::Plugin::Log

L<Acrux::Log> logging plugin

=back

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<CTK>, L<CTK::App>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.04';

use Carp qw/carp croak/;
use Time::HiRes qw/gettimeofday tv_interval/;
use FindBin qw/$RealBin $Script/;
use File::Spec qw//;
use Cwd qw/getcwd/;
use Sub::Util qw/set_subname/;
use Acrux::RefUtil qw/
        as_hash_ref is_hash_ref
        as_array_ref is_array_ref
        is_value is_code_ref is_true_flag
    /;
use Acrux::Const qw/:dir/;
use Acrux::Util qw/load_class trim words/;

use constant {
    WIN             => !!($^O =~ /mswin/i),
    ALOWED_MODES    => [qw/debug test verbose/],
    PRELOAD_PLUGINS => [qw/Config Log/], # Order is very important!
    DEFAULT_PLUGINS => {
        Config  => "Acme::Crux::Plugin::Config",
        Log     => "Acme::Crux::Plugin::Log",
    },
};

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

    # Get project name and moniker
    my $project = $args->{project} || $args->{name}
      || ($Script =~ /^(.+?)\.(pl|t|pm|cgi)$/ ? $1 : $Script)
      || $class || scalar(caller(0));
    my $moniker = $args->{moniker} || _project2moniker($project)
      || _project2moniker($class || scalar(caller(0)));

    # Current dir
    my $pwd = getcwd();

    # Create
    my $self = bless {
        # Common
        error       => "",
        script      => $Script,
        invocant    => scalar(caller(0)),
        project     => $project,
        moniker     => $moniker,
        pid         => $$,
        running     => 0,

        # General
        orig        => {%$args},
        created     => Time::HiRes::time,
        hitime      => [gettimeofday],
        options     => as_hash_ref($args->{options}), # Options of command line
        plugins     => {},
        preload_plugins => $args->{preload} || $args->{preload_plugins} || PRELOAD_PLUGINS,

        # Modes (defaults)
        debugmode   => 0,
        testmode    => 0,
        verbosemode => 0,

        # Dirs
        pwd         => $pwd,
        exedir      => $RealBin, # Script dir
        root        => $args->{root}, # Root dir of project. Default: /etc/moniker
        tempdir     => $args->{tempdir}, # Temp dir of project. Default: /tmp/moniker
        datadir     => $args->{datadir}, # Data dir of project. Defaut: /var/lib/moniker
        logdir      => $args->{logdir}, # Log dir of project. Default: /var/log/moniker
        sharedir    => $args->{sharedir}, # Share dir. Default: /usr/share/moniker
        docdir      => $args->{docdir}, # Share dir. Default: /usr/share/doc/moniker
        cachedir    => $args->{cachedir}, # Cache dir. Default: /var/cache/moniker
        spooldir    => $args->{spooldir}, # Spool dir. Default: /var/spool/moniker
        rundir      => $args->{rundir}, # Run dir. Default: /var/run/moniker
        lockdir     => $args->{lockdir}, # Lock dir. Default: /var/lock/moniker
        webdir      => $args->{webdir}, # Web dir. Default: /var/www/moniker

        # Files
        logfile     => $args->{logfile}, # Log file of project. Default: /var/log/moniker/moniker.log
        configfile  => $args->{configfile}, # Config file of project. Default: /etc/moniker/moniker.conf
        pidfile     => $args->{pidfile}, # PID file of project. Default: /var/run/moniker.pid

    }, $class;

    # Modes
    foreach my $mode ( @{(ALOWED_MODES)}) {
        $self->{$mode."mode"} = 1 if is_true_flag($args->{$mode});
    }

    # Root dir
    my $root = $self->{root};
    $root = $self->{root} = $pwd if defined($root) && $root eq '.'; # Set root to cwd if specified as '.'
    unless (defined($root) && length($root)) {
        $root = $self->{root} = File::Spec->catdir(SYSCONFDIR, $moniker);
    }

    # Temp dir
    my $temp = $self->{tempdir};
    unless (defined($temp) && length($temp)) {
        $temp = $self->{tempdir} = File::Spec->catdir(File::Spec->tmpdir(), $moniker);
    }

    # Data dir
    my $datadir = $self->{datadir};
    unless (defined($datadir) && length($datadir)) {
        $datadir = $self->{datadir} = File::Spec->catdir(SHAREDSTATEDIR, $moniker);
    }

    # Log dir
    my $logdir = $self->{logdir};
    unless (defined($logdir) && length($logdir)) {
        $logdir = $self->{logdir} = File::Spec->catdir(LOGDIR, $moniker);
    }

    # Share dir
    my $sharedir = $self->{sharedir};
    unless (defined($sharedir) && length($sharedir)) {
        $self->{sharedir} = File::Spec->catdir(DATADIR, $moniker);
    }

    # Doc dir
    my $docdir = $self->{docdir};
    unless (defined($docdir) && length($docdir)) {
        $self->{docdir} = File::Spec->catdir(DOCDIR, $moniker);
    }

    # Cache dir
    my $cachedir = $self->{cachedir};
    unless (defined($cachedir) && length($cachedir)) {
        $self->{cachedir} = File::Spec->catdir(CACHEDIR, $moniker);
    }

    # Spool dir
    my $spooldir = $self->{spooldir};
    unless (defined($spooldir) && length($spooldir)) {
        $self->{spooldir} = File::Spec->catdir(SPOOLDIR, $moniker);
    }

    # Run dir
    my $rundir = $self->{rundir};
    unless (defined($rundir) && length($rundir)) {
        $rundir = $self->{rundir} = File::Spec->catdir(RUNDIR, $moniker);
    }

    # Lock dir
    my $lockdir = $self->{lockdir};
    unless (defined($lockdir) && length($lockdir)) {
        $self->{lockdir} = File::Spec->catdir(LOCKDIR, $moniker);
    }

    # Web dir
    my $webdir = $self->{webdir};
    unless (defined($webdir) && length($webdir)) {
        $self->{webdir} = File::Spec->catdir(WEBDIR, $moniker);
    }

    # Config file
    my $configfile = $self->{configfile};
    unless (defined($configfile) && length($configfile)) {
        $self->{configfile} = $configfile = File::Spec->catfile($root, sprintf("%s.conf", $moniker));
    }
    unless (File::Spec->file_name_is_absolute($configfile)) {
        $self->{configfile} = $configfile = File::Spec->rel2abs($configfile);
    }

    # Log file
    my $logfile = $self->{logfile};
    unless (defined($logfile) && length($logfile)) {
        $self->{logfile} = $logfile = File::Spec->catfile($logdir, sprintf("%s.log", $moniker));
    }
    unless (File::Spec->file_name_is_absolute($logfile)) {
        $self->{logfile} = $logfile = File::Spec->rel2abs($logfile);
    }

    # PID file
    my $pidfile = $self->{pidfile};
    unless (defined($pidfile) && length($pidfile)) {
        $self->{pidfile} = $pidfile = File::Spec->catfile($rundir, sprintf("%s.pid", $moniker));
    }
    unless (File::Spec->file_name_is_absolute($pidfile)) {
        $self->{pidfile} = $pidfile = File::Spec->rel2abs($pidfile);
    }

    # Define plugins list to plugin map
    $self->plugins(as_hash_ref($args->{plugins}));

    # Preloading plugins
    my $preload_plugins = $self->{preload_plugins};
       $preload_plugins = [$preload_plugins] unless is_array_ref($preload_plugins);
    my $pplgns = words(@$preload_plugins);
    $self->plugin($_) for @$pplgns;
    #foreach my $p (@$preload_plugins) {
    #    next unless defined($p) && is_value($p);
    #    $self->plugin($_) for split(/[\s;,]+/, $p);
    #}

    return $self->startup(%$args);
}
sub startup { shift }

# Attributes
sub options {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{options} = shift;
        return $self;
    }
    return $self->{options};
}
sub project {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{project} = shift;
        return $self;
    }
    return $self->{project};
}
sub moniker {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{moniker} = shift;
        return $self;
    }
    return $self->{moniker};
}

# Files and directories
sub pwd { shift->{pwd} }
sub root {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{root} = shift;
        return $self;
    }
    return $self->{root};
}
sub tempdir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{tempdir} = shift;
        return $self;
    }
    return $self->{tempdir};
}
sub datadir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{datadir} = shift;
        return $self;
    }
    return $self->{datadir};
}
sub logdir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{logdir} = shift;
        return $self;
    }
    return $self->{logdir};
}
sub sharedir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{sharedir} = shift;
        return $self;
    }
    return $self->{sharedir};
}
sub docdir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{docdir} = shift;
        return $self;
    }
    return $self->{docdir};
}
sub cachedir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{cachedir} = shift;
        return $self;
    }
    return $self->{cachedir};
}
sub spooldir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{spooldir} = shift;
        return $self;
    }
    return $self->{spooldir};
}
sub rundir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{rundir} = shift;
        return $self;
    }
    return $self->{rundir};
}
sub lockdir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{lockdir} = shift;
        return $self;
    }
    return $self->{lockdir};
}
sub webdir {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{webdir} = shift;
        return $self;
    }
    return $self->{webdir};
}
sub configfile {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{configfile} = shift;
        return $self;
    }
    return $self->{configfile};
}
sub logfile {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{logfile} = shift;
        return $self;
    }
    return $self->{logfile};
}
sub pidfile {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{pidfile} = shift;
        return $self;
    }
    return $self->{pidfile};
}

# Modes (methods)
sub testmode    { !! shift->{testmode} }
sub debugmode   { !! shift->{debugmode} }
sub verbosemode { !! shift->{verbosemode} }
sub silentmode  { ! shift->{verbosemode} }

# Methods
sub error {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{error} = shift;
        return $self;
    }
    return $self->{error};
}
sub begin {
    my $self = shift;
    $self->{hitime} = [gettimeofday];
    return $self->{hitime}
}
sub elapsed {
    my $self = shift;
    my $timing_begin = shift;
    return undef unless my $started = $timing_begin || $self->{hitime};
    return tv_interval($started, [gettimeofday]);
}
sub exedir { shift->{exedir} }
sub orig { shift->{orig} }
sub option {
    my $self = shift;
    my $key  = shift;
    my $opts = $self->{options};
    return undef unless $opts;
    return $opts unless defined $key;
    return $opts->{$key};
}
sub opt { goto &option }
sub getopt { goto &option }

# Register method. See Mojo::Util::monkey_patch
sub register_method {
    my $self = shift;
    my $code = pop || sub { 1 }; # last param
    my $method = pop;
    my $namespace = pop || ref($self) || $self || __PACKAGE__;
    croak qq{Can't register method: method name is missing} unless $method;
    croak qq{Can't register method "$method": subroutine code is not defined}
        unless is_code_ref($code);
    my $ent = sprintf("%s::%s", $namespace, $method);

    # Create new method
    no strict 'refs';
    no warnings 'redefine';
    *{$ent} = set_subname($ent, $code);

    ### Old version from CTK::Plugin::register_method
    ### Check
    ##return if do { no strict 'refs'; defined &{$ff} };
    ### Create method!
    ##do {
    ##    no strict 'refs';
    ##    *{$ff} = \&$callback;
    ##};

    return 1;
}

# Plugins
sub plugins {
    my $self = shift;
    return $self->{plugins} if scalar(@_) < 1;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $plugins = $self->{plugins};
    foreach my $k (keys %$args) {
        next if exists($plugins->{$k}) && $plugins->{$k}->{loaded}; # Skip loaded plugins
        $plugins->{$k} = { class => $args->{$k}, loaded => 0 } if length($args->{$k} // '');
    }
    return $self;
}
sub plugin {
    my $self = shift;
    my $name = shift // ''; # Plugin name
    my $class = shift // ''; # Plugin class
    my @args = @_;
    my $plugins = $self->{plugins}; # Get list of plugins
    return unless length $name;

    # Lookup class by name
    unless (length($class)) {
        # Lookup in existing plugins
        $class = $plugins->{$name}->{class} // '' if exists $plugins->{$name};

        # Lookup in defaults
        $class = DEFAULT_PLUGINS()->{$name} // '' unless length $class;
    }
    return unless length $class;

    # Register found plugin
    $self->register_plugin($name, $class, @args); # name, class, args
}
sub register_plugin {
    my $self = shift;
    my $name = shift // ''; # Plugin name
    my $class = shift // ''; # Plugin class
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}; # Plugin arguments
    my $plugins = $self->{plugins};
    croak "No plugin name specified!" unless length $name;
    croak "No plugin class specified!" unless length $class;

    # Load plugin if not exists in already loaded plugins list
    return 1 if exists($plugins->{$name}) && $plugins->{$name}->{loaded};
    if (my $error = load_class($class)) {
        $self->verbosemode
            ? die qq{Plugin "$name" missing, maybe you need to install it?\n$error\n}
            : die qq{Plugin "$name" missing, maybe you need to install it?\n};
    }

    # Create plugin instance
    die qq{Plugin "$name" no contains required the "new" method\n} unless $class->can('new');
    my $p = $class->new($name);

    # Register this plugin
    my $ret = $p->register($self, $args); # $app, $args

    # Fixup
    $plugins->{$name} = {
        'class'     => $class,
        'loaded'    => 1,
        'time'      => time,
        'something' => $ret,
    };

    return $ret;
}

# Handlers
sub register_handler {
    my $class = shift;
       $class = ref($class) if ref($class);
    my %info = @_;
    my $k = "$class.$$";
    $Acme::Crux::Sandbox::HANDLERS{$k} = {} unless exists($Acme::Crux::Sandbox::HANDLERS{$k});
    my $handlers = $Acme::Crux::Sandbox::HANDLERS{$k};

    # Handler name
    my $name = trim($info{handler} // $info{name} // 'default');
    croak("The handler name missing") unless length($name);
    delete $info{handler};
    $info{name} = $name;
    croak("The $name duplicate handler definition") if defined($handlers->{$name});

    # Handler aliases
    my $_aliases = $info{alias} // $info{aliases} // [];
       $_aliases = [ trim($_aliases) ] unless is_array_ref($_aliases);
    my $aliases = words(@$_aliases);
    #foreach my $al (@$_aliases) {
    #    next unless defined($al) && is_value($al);
    #    foreach my $p (split(/[\s;,]+/, $al)) {
    #        next unless defined($p) && length($p);
    #        $aliases{$p} = 1;
    #    }
    #}
    delete $info{alias};
    $info{aliases} = [grep {$_ ne $name} @$aliases];

    # Handler description
    $info{description} //= '';

    # Handler params
    my $params = $info{parameters} || $info{params} || {};
    delete $info{parameters};
    $params = {} unless is_hash_ref($params);
    $info{params} = $params;

    # Handler code
    my $code = $info{code} || sub {return 1};
    $info{code} = is_code_ref($code) ? $code : sub { $code };

    # Set info to handler data
    $handlers->{$name} = {%info};
    return 1;
}
sub lookup_handler {
    my $self = shift;
    my $name = trim(shift // '');
    return undef unless length $name;
    my $invocant = ref($self) || scalar(caller(0));
    my $handlers = $Acme::Crux::Sandbox::HANDLERS{"$invocant.$$"};
    return undef unless defined($handlers) && is_hash_ref($handlers);
    foreach my $n (keys %$handlers) {
        my $aliases = as_array_ref($handlers->{$n}->{aliases});
        return $handlers->{$n} if grep {defined && $_ eq $name} ($n, @$aliases);
    }
    return undef;
}
sub handlers {
    my $self = shift;
    my $all = shift // 0; # returns aliases too
    my $invocant = ref($self) || scalar(caller(0));
    my $handlers = $Acme::Crux::Sandbox::HANDLERS{"$invocant.$$"};
    return [] unless defined($handlers) && is_hash_ref($handlers);
    return [(sort {$a cmp $b} keys %$handlers)] unless $all;

    # All: names and aliases
    my %seen = ();
    foreach my $n (keys %$handlers) {
        my $aliases = as_array_ref($handlers->{$n}->{aliases});
        foreach my $_a ($n, @$aliases) {
            $seen{$_a} = 1 if defined($_a) and length($_a);
        }
    }
    return [(sort {$a cmp $b} keys %seen)];
}
sub run_handler {
    my $self = shift;
    my $name = shift // 'default';
    my @args = @_;
    if ($self->{running}) {
        $self->error(sprintf(qq{The application "%s" is already runned}, $self->project));
        return 0;
    }
    unless(length($name)) {
        $self->error("Invalid handler name");
        return 0;
    }
    my $meta = $self->lookup_handler($name);
    unless ($meta) {
        $self->error(sprintf("Handler %s not found", $name));
        return 0;
    }

    # Run
    my %info;
    my $func;
    $self->{running} = 1;
    foreach my $k (keys %$meta) {
        next unless defined $k;
        if ($k eq 'code') {
            $func = $meta->{code};
            next;
        }
        $info{$k} = $meta->{$k};
    }
    unless(is_code_ref($func)) {
        $self->error("Handler code not found! Maybe you need to implement it?");
        return 0;
    }

    # Call function and return
    my $ret = &$func($self, {%info}, @args);
    $self->{running} = 0;
    return $ret;
}
sub run { goto &run_handler }

# Internal functions (NOT METHODS)
sub _project2moniker {
    my $prj = shift;
    return unless defined($prj);
    $prj =~ s/::/-/g;
    $prj =~ s/[^A-Za-z0-9_\-.]/_/g; # Remove incorrect chars
    $prj =~ s/([_\-.]){2,}/$1/g; # Remove dubles
    return unless length($prj);
    return lc($prj);
}

1;

package Acme::Crux::Sandbox;

our %HANDLERS = ();

1;

__END__
