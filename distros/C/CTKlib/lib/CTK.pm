package CTK; # $Id: CTK.pm 270 2019-06-19 18:56:25Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK - Command-line ToolKit library (CTKlib)

=head1 VERSION

Version 2.01

=head1 NOTE

The 2.00 version of this library is not compatible with earlier versions

=head1 SYNOPSIS

    use CTK;

    my $ctk = new CTK;
    my $ctk = new CTK (
        project => 'MyApp',
        configfile  => '/path/to/conf/file.conf',
        logfile     => '/path/to/log/file.log',
    );

=head1 DESCRIPTION

CTKlib - is library that provides "extended-features" (utilities) for your robots written on Perl.
Most of the functions and methods this module written very simple language and easy to understand.
To work with CTKlib, you just need to start using it!

=head2 new

    my $ctk = new CTK;
    my $ctk = new CTK (
        project => 'MyApp',
        configfile  => '/path/to/conf/file.conf',
        logfile     => '/path/to/log/file.log',
    );

Main constructor. All the params are optional

=over 4

=item B<configfile>

    configfile => '/etc/myapp/myapp.conf'

Path to the configuration file of the your project

Default: /etc/<PREFIX>/<PREFIX>.conf

=item B<datadir>

    datadir => '/path/to/your/data/dir'

Directory for application data storing

Default: <getcwd()> (current directory)

=item B<debug>

    debug => 1
    debug => 'on'
    debug => 'yes'

Debug mode

Default: 0

=item B<ident>

    ident => "test"

Ident string for logs and debugging

Default: ""

=item B<log>

    log => 1
    log => 'on'
    log => 'yes'

Log mode

Default: 0

=item B<logdir>

    logdir => '/var/log/myapp'

Log directory of project

Default: /var/log/<PREFIX>

=item B<logfile>

    logfile => '/var/log/myapp/myapp.log'

Full path to the log file

Default: /var/log/<PREFIX>/<PREFIX>.log

=item B<options>

    options => {foo => 'bar'}

Command-line options, hash-ref structure. See L<Getopt::Long>

Default: {}

=item B<plugins>

    plugins => [qw/ test /]
    plugins => "test"

Array ref of plugin list or plugin name as scalar:

Default: []

=item B<prefix>

    prefix => "myapp"

Prefix of the Your project

Default: lc(<PROJECT>)

=item B<project>

    project => "MyApp"
    name => "MyApp"

Project name

Default: $FindBin::Script without file extension

=item B<root>

    root => "/etc/myapp"

Root dir of project

Default: /etc/<PREFIX>

=item B<suffix>

    suffix => "devel"
    suffix => "alpha"
    suffix => "beta"
    suffix => ".dev"

Suffix of the your project. Can use in plugins

Default: ""

=item B<tempdir>

    tempdir => "/tmp/myapp"

Temp directory of project

Default: /tmp/<PREFIX>

=item B<tempfile>

    tempfile => "/tmp/myapp/myapp.tmp"

Temp file of project

Default: /tmp/<PREFIX>/<PREFIX>.tmp

=item B<test>

    test => 1
    test => 'on'
    test => 'yes'

Test mode

Default: 0

=item B<verbose>

    verbose => 1
    verbose => 'on'
    verbose => 'yes'

Verbose mode

Default: 0

=back

=head2 again

For internal use only (plugins). Please not call this function

=head2 configfile

    my $configfile = $ctk->configfile;
    $ctk->configfile("/path/to/config/file.conf");

Gets and sets configfile value

=head2 datadir

    my $datadir = $ctk->datadir;
    $ctk->datadir("/path/to/data/dir");

Gets and sets datadir value

=head2 debug

    $ctk->debug( "Message" );

Prints debug information on STDOUT if is set debug mode.
Also sends message to log if log mode is enabled

=head2 debugmode

    $ctk->debugmode;

Returns debug flag. 1 - on, 0 - off

=head2 error

    my $error = $ctk->error;

Returns error string if occurred any errors while creating the object

    $ctk->error("error text");

Sets new error message and returns it. Also prints message on STDERR if is set debug mode
and sends message to log if log mode is enabled

=head2 exedir

    my $exedir = $ctk->exedir;

Gets exedir value

=head2 load

    $ctk->load("My::Foo::Package");

Internal method for loading modules.

Returns loading status: 0 - was not loaded; 1 - was loaded

=head2 load_plugins

    my $summary_status = $self->load_plugins( @plugins );

Loads list of plugins and returns summary status

=head2 logdir

    my $logdir = $ctk->logdir;
    $ctk->logdir("/path/to/log/dir");

Gets and sets logdir value

=head2 logfile

    my $logfile = $ctk->logfile;
    $ctk->logfile("/path/to/log/file.log");

Gets and sets logfile value

=head2 logmode

    $ctk->logmode;

Returns log flag. 1 - on, 0 - off

=head2 origin

    my $args = $ctk->origin();

Returns hash-ref structure to all origin arguments

=head2 option

    my $value = $ctk->option("key");

Returns option value by key

    my $options = $ctk->option;

Returns hash-ref structure to all options

See L</options>

=head2 project, prefix, suffix

    my $project_name = $ctk->projtct;
    my $prefix = $ctk->prefix;
    my $suffix = $ctk->suffix;

Returns project, prefix and suffix values

=head2 revision

    my $revision = $ctk->revision;

Returns revision value

=head2 root

    my $my_root = $ctk->root; # /etc/<PREFIX>

Gets my root dir value

=head2 silentmode

    $ctk->silentmode;

Returns the verbose flag in the opposite value. 0 - verbose, 1 - silent.

See L</verbosemode>

=head2 status

    my $status = $ctk->status;

Returns boolean status of creating and using the object

    my $status = $ctk->status( 1 );

Sets new status and just returns it

=head2 tempfile

    my $tempfile = $ctk->tempfile;
    $ctk->tempfile("/path/to/temp/file.tmp");

Gets and sets tempfile value

=head2 tempdir

    my $tempdir = $ctk->tempdir;
    $ctk->tempdir("/path/to/temp/dir");

Gets and sets tempdir value

=head2 testmode

    $ctk->testmode;

Returns test flag. 1 - on, 0 - off

=head2 tms

    print $ctk->tms; # +0.0080 sec

Returns formatted timestamp

    print $ctk->tms(1); # 0.008000

Returns NOT formatted timestamp

=head2 verbosemode

    $ctk->verbosemode;

Returns verbose flag. 1 - on, 0 - off

See L</silentmode>

=head1 VARIABLES

    use CTK qw/ WIN NULL TONULL ERR2OUT PREFIX /;
    use CTK qw/ :constants /

=over 4

=item B<ERR2OUT>

Returns string:

    2>&1

=item B<NULL>

Returns NULL device path or name for Windows platforms

=item B<%PLUGIN_ALIAS_MAP>

This hash is using for sets aliases of plugins, e.g.:

    use CTK qw/ %PLUGIN_ALIAS_MAP /;
    $PLUGIN_ALIAS_MAP{myplugin} = "My::Custom::Plugin::Module";

=item B<PREFIX>

Return default prefix: ctk

=item B<TONULL>

Returns string:

    >/dev/null 2>&1

=item B<WIN>

Returns 1 if Windows platform

=back

=head1 TAGS

=over 4

=item B<:constants>

Will be exported following variables:

    WIN, NULL, TONULL, ERR2OUT, PREFIX

=item B<:variables>

Will be exported following variables:

    %PLUGIN_ALIAS_MAP

=back

=head1 HISTORY

=over 4

=item B<1.00 / 18.06.2012>

Init version

=item B<2.00 Mon Apr 29 10:36:06 MSK 2019>

New edition of the library

=back

See C<Changes> file

=head1 DEPENDENCIES

L<Class::C3::Adopt::NEXT>,
L<Config::General>,
L<DBI>,
L<ExtUtils::MakeMaker>,
L<File::Copy>,
L<File::Path>,
L<File::Pid>,
L<File::Spec>,
L<File::Temp>,
L<IO>,
L<IO::String>,
L<IPC::Open3>,
L<JSON>,
L<List::Util>,
L<MIME::Base64>,
L<MIME::Lite>,
L<MRO::Compat>,
L<Net::FTP>,
L<Perl::OSType>,
L<Sys::SigAction>,
L<Sys::Syslog>
L<Term::ANSIColor>,
L<Test::Simple>,
L<Text::SimpleTable>,
L<Time::HiRes>,
L<Time::Local>,
L<Try::Tiny>,
L<URI>,
L<XML::Simple>,
L<YAML::XS>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses>

=cut

use vars qw/ $VERSION %PLUGIN_ALIAS_MAP %EXPORT_TAGS @EXPORT_OK /;
$VERSION = '2.01';

use base qw/Exporter/;

use Carp;
use Time::HiRes qw(gettimeofday);
use FindBin qw($RealBin $Script);
use Cwd qw/getcwd/;
use File::Spec ();
use CTK::Util qw/ sysconfdir syslogdir isTrueFlag /;

my @exp_constants = qw(
        WIN NULL TONULL ERR2OUT PREFIX
    );

my @exp_variables = qw(
        %PLUGIN_ALIAS_MAP
    );

@EXPORT_OK = (
    @exp_constants,
    @exp_variables,
);

%EXPORT_TAGS = (
        constants => [@exp_constants],
        variables => [@exp_variables],
    );

%PLUGIN_ALIAS_MAP = (
        cli             => "CTK::Plugin::CLI",
        configuration   => "CTK::Plugin::Config",
        files           => "CTK::Plugin::File",
        arc             => "CTK::Plugin::Archive",
        compress        => "CTK::Plugin::Archive",
    );

use constant {
    WIN       => $^O =~ /mswin/i ? 1 : 0,
    NULL      => $^O =~ /mswin/i ? 'NUL' : '/dev/null',
    TONULL    => $^O =~ /mswin/i ? '>NUL 2>&1' : '>/dev/null 2>&1',
    ERR2OUT   => '2>&1',
    PREFIX    => "ctk",
    PLUGIN_FORMAT => "CTK::Plugin::%s",
    ALOWED_MODES => [qw/debug log test verbose/],
};

sub new {
    my $class = shift;
    my %args = @_;
    my $options = $args{options} // {};
    croak("Can't use \"non hash\" struct for the \"options\" param") unless ref($options) eq "HASH";
    my $project = $args{project} // $args{name} // ($Script =~ /^(.+?)\.(pl|t|pm|cgi)$/ ? $1 : $Script);
    my $prefix = $args{prefix} // _prj2pfx($project) // PREFIX;
    my $plugins = $args{plugins} // [];
    $plugins = [$plugins] unless ref($plugins);
    croak("Can't use \"non array\" for the \"plugins\" param") unless ref($plugins) eq "ARRAY";

    # Create CTK object
    my $self = bless {
        status  => 0,
        error   => "",

        # General
        invocant    => scalar(caller(0)),
        origin      => {%args},
        created     => time(),
        hitime      => gettimeofday() * 1,
        revision    => q/$Revision: 270 $/,
        options     => $options,
        plugins     => {},

        # Modes (defaults)
        debugmode   => 0,
        logmode     => 0,
        testmode    => 0,
        verbosemode => 0,

        # Information
        ident       => $args{ident}, # For logs and debugging
        script      => $Script,
        project     => $project,
        prefix      => $prefix,
        suffix      => $args{suffix} // "",

        # Dirs
        exedir      => $RealBin, # Script dir
        datadir     => $args{datadir} // getcwd(), # Data dir of project. Defaut: current dir
        tempdir     => $args{tempdir}, # Temp dir of project. Default: /tmp/prefix
        logdir      => $args{logdir}, # Log dir of project. Default: /var/log/prefix
        root        => $args{root}, # Root dir of project. Default: /etc/prefix

        # Files
        tempfile    => $args{tempfile}, # Temp file of project. Default: /tmp/prefix/prefix.tmp
        logfile     => $args{logfile}, # Log file of project. Default: /var/log/prefix/prefix.log
        configfile  => $args{configfile}, # Config file of project. Default: /etc/prefix/prefix.conf

    }, $class;

    # Modes
    foreach my $mode ( @{(ALOWED_MODES)}) {
        $self->{$mode."mode"} = 1 if isTrueFlag($args{$mode});
    }

    # Root dir
    my $root = $self->{root};
    unless (defined($root) && length($root)) {
        $self->{root} = File::Spec->catdir(sysconfdir(), $prefix);
    }

    # Config file
    my $configfile = $self->{configfile};
    unless (defined($configfile) && length($configfile)) {
        $self->{configfile} = File::Spec->catfile(sysconfdir(), $prefix, sprintf("%s.conf", $prefix));
    }

    # Temp dir
    my $temp = $self->{tempdir};
    unless (defined($temp) && length($temp)) {
        $self->{tempdir} = File::Spec->catdir(File::Spec->tmpdir(), $prefix);
    }

    # Temp file
    my $tempfile = $self->{tempfile};
    unless (defined($tempfile) && length($tempfile)) {
        $self->{tempfile} = File::Spec->catfile(File::Spec->tmpdir(), $prefix, sprintf("%s.tmp", $prefix));
    }

    # Log dir
    my $ldir = $self->{logdir};
    unless (defined($ldir) && length($ldir)) {
        $self->{logdir} = File::Spec->catdir(syslogdir(), $prefix);
    }

    # Log file
    my $logfile = $self->{logfile};
    unless (defined($logfile) && length($logfile)) {
        $self->{logfile} = File::Spec->catfile(syslogdir(), $prefix, sprintf("%s.log", $prefix));
    }

    # Loading plugins and set status!
    $self->{status} = $self->load_plugins(@$plugins);

    return $self->again;
}
sub again {
    my $self = shift;
    return $self;
}

########################
## Base methods
########################
sub debug {
    my $self = shift;
    my @dbg = @_;
    return unless @dbg;
    my $ident = $self->{ident} // "";
    my $msg = join("", @dbg);
    return unless length($msg);
    $self->log_debug("%s", $msg) if $self->logmode && $self->can("log_debug"); # To log
    if ($self->debugmode) { # To STDOUT
        unshift(@dbg, sprintf("%s ", $ident)) if length($ident);
        print STDOUT @dbg, "\n";
    }
    return 1;
}
sub tms {
    my $self = shift;
    my $no_format = shift;
    my $v = gettimeofday()*1 - $self->{hitime}*1;
    return $v if $no_format;
    return sprintf("%+.*f sec", 4, $v);
}
sub error {
    my $self = shift;
    my @err = @_;
    if (@err) {
        $self->{error} = join("", @err);
        my $ident = $self->{ident} // "";
        if (length($self->{error})) {
            $self->log_error("%s", $self->{error}) if $self->logmode && $self->can("log_error"); # To log
            if ($self->debugmode) { # To STDERR
                unshift(@err, sprintf("%s ", $ident)) if length($ident);
                printf STDERR "%s\n", join("", @err);
            }
        }
    }
    return $self->{error};
}
sub status {
    my $self = shift;
    my $s = shift;
    $self->{status} = $s if defined $s;
    return $self->{status} ? 1 : 0;
}

# Modes
sub testmode { shift->{testmode} }
sub debugmode { shift->{debugmode} }
sub logmode { shift->{logmode} }
sub verbosemode { shift->{verbosemode} }
sub silentmode { !shift->{verbosemode} }

# Information
sub revision { # lasy
    my $self = shift;
    my $rev = $self->{revision};
    return $rev =~ /(\d+\.?\d*)/ ? $1 : '0';
}
sub option {
    my $self = shift;
    my $key  = shift;
    my $opts = $self->{options};
    return undef unless $opts;
    return $opts unless defined $key;
    return $opts->{$key};
}
sub project { shift->{project} }
sub prefix { shift->{prefix} }
sub suffix { shift->{suffix} }
sub origin { shift->{origin} }

# Dirs
sub exedir { shift->{exedir} }
sub root { shift->{root} }
sub datadir {
    my $self = shift;
    my $dir = shift;
    $self->{datadir} = $dir if defined $dir;
    return $self->{datadir};
}
sub logdir {
    my $self = shift;
    my $dir = shift;
    $self->{logdir} = $dir if defined $dir;
    return $self->{logdir};
}
sub tempdir {
    my $self = shift;
    my $dir = shift;
    $self->{tempdir} = $dir if defined $dir;
    return $self->{tempdir};
}

# Files
sub tempfile {
    my $self = shift;
    my $file = shift;
    $self->{tempfile} = $file if defined $file;
    return $self->{tempfile};
}
sub logfile {
    my $self = shift;
    my $file = shift;
    $self->{logfile} = $file if defined $file;
    return $self->{logfile};
}
sub configfile {
    my $self = shift;
    my $file = shift;
    $self->{configfile} = $file if defined $file;
    return $self->{configfile};
}

# Loading plugin's module
sub load_plugins {
    my $self = shift;
    my @plugins = @_;
    my $in = $self->{plugins};
    my $ret = 1;
    my %seen = ();
    for (@plugins) {$seen{lc($_)} = 1}
    foreach my $plugin (keys %seen) {
        next if $in->{$plugin}->{inited};
        my $module = exists($PLUGIN_ALIAS_MAP{$plugin})
            ? $PLUGIN_ALIAS_MAP{$plugin}
            : sprintf(PLUGIN_FORMAT, ucfirst($plugin));
        my $loading_status = $self->load($module);
        my $inited = 0;
        if ($loading_status) {
            if (my $init = $module->can("init")) {
                $inited = $init->($self);
            }
        } else {
            $ret = 0;
        }
        $in->{$plugin} = {
            module => $module,
            loaded => $loading_status,
            inited => $inited,
        };
    };
    return $ret;
}
sub load {
    my $self = shift;
    my $module = shift;
    my $file = sprintf("%s.pm", join('/', split('::', $module)));
    return 1 if exists $INC{$file};
    eval { require $file; };
    if ($@) {
        $self->error("Failed to load $file: $@");
        return 0;
    }
    return 1;
}

sub _prj2pfx {
    my $prj = shift;
    return unless defined($prj);
    $prj =~ s/[^a-z0-9_\-.]/_/ig;
    $prj =~ s/_{2,}/_/g;
    return unless length($prj);
    return lc($prj);
}

1;

__END__
