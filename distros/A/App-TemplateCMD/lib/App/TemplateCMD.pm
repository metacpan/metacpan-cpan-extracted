package App::TemplateCMD;

# Created on: 2008-03-26 13:47:07
# Create by:  ivanw
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use File::Find;
use Getopt::Long;
use YAML qw/Dump LoadFile/;
use Readonly;
use Template;
use Template::Provider;
use File::ShareDir qw/dist_dir/;
use JSON qw/decode_json/;
use base qw/Exporter/;

our $VERSION     = version->new('0.6.10');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

# Set the default name for the configuration file
# Note when this appears in the home dir a dot '.' is prepended
Readonly my $CONFIG_NAME => 'template-cmd.yml';

sub new {
    my $caller = shift;
    my $class  = ref $caller ? ref $caller : $caller;
    my %param  = @_;
    my $self   = \%param;

    bless $self, $class;

    # Find the available commands
    $self->{cmds} = { map {lc $_ => $_} $self->get_modules('App::TemplateCMD::Command') };

    # read the configuration files
    $self->config();

    return $self;
}

sub get_modules {
    my ($self, $base) = @_;
    $base =~ s{::}{/}gxms;

    my %modules;

    for my $dir (grep {-d $_} map { "$_/$base/" } @INC) {
        find(
            sub {
                my ($name) = $File::Find::name =~ m{^ $dir ( [\w/]+ ) .pm $}xms;
                return if !$name;

                $modules{$name}++;
            },
            $dir
        );
    }

    return keys %modules;
}

sub process {

    my ($self, @argv) = @_;

    my $cmd = shift @argv;

    if ( !$cmd || !grep { $_ eq $cmd } keys %{$self->{'cmds'}} ) {
        if ($cmd) {
            $self->unknown_cmd($cmd);
        }

        unshift @argv, $cmd;
        $cmd = 'help';
    }

    my $module  = $self->load_cmd($cmd);
    my %default = $module->default($self);
    my @args    = (
        'out|o=s',
        'args|a=s%',
        'verbose|v!',
        'path|p=s',
        $module->args($self),
    );

    {
        local @ARGV = @argv;
        Getopt::Long::Configure('bundling');
        GetOptions( \%default, @args ) or $module = 'App::TemplateCMD::Command::Help';
        $default{files} = [ @ARGV ];
    }

    my $conf = $self->add_args(\%default);
    my $out;

    my $path = $conf->{path};
    if ( $default{path} ) {
        $path = "$default{path}:$path";
    }
    $path =~ s(~/)($ENV{HOME}/)gxms;

    $self->{providers} = [
        Template::Provider->new({ INCLUDE_PATH => $path }),
    ];

    $self->{template} = Template->new({
        LOAD_TEMPLATES => $self->{providers},
        EVAL_PERL      => 1,
    });

    if ( $default{'out'} ) {
        open $out, '>', $default{out} or die "Could not open the output file '$default{out}': $OS_ERROR\n";
    }
    else {
        $out = *STDOUT;
    }

    print {$out} $module->process($self, %default);

    return;
}

sub add_args {
    my ($self, $default) = @_;
    my @files;

    my $args  = $default->{args}  || {};
    my $files = $default->{files} || [];

    # add any args not prefixed by -a[rgs]
    for my $file (@{$files}) {
        if ($file =~ /=/ ) {

            # merge the argument on to the args hash
            my ($arg, $value) = split /=/, $file, 2;
            $default->{args}->{$arg} = eval { decode_json($value) } || $value;
        }
        else {

            # store the "real" file
            push @files, $file;
        }
    }

    for my $value (values %{$args}) {
        $value = $value =~ /^( q[wqr]?(\W) ) .* ( \2 )$/xms? [ eval($value)  ]    ## no critic
               : $value =~ /^(    \{       ) .* ( \} )$/xms?   eval($value)       ## no critic
               : $value =~ /^(    \[       ) .* ( \] )$/xms?   eval($value)       ## no critic
               : $value =~ /^(      ,      )(.*)      $/xms? [ split /,/xms, $2 ]
               :                                             $value;
    }

    # replace the files with the list with out args
    $default->{files} = \@files;

    # merge the args with the config and save
    return $self->{config} = $self->conf_join($self->config(), $args);
}

sub config {

    my ($self, %option) = @_;

    return $self->{'config'} if $self->{'config'};

    my $conf = {
        path    => '~/template-cmd:~/.template-cmd/:~/.template-cmd-local:/usr/local/template-cmd/src/:' . dist_dir('App-TemplateCMD'),
        aliases => {
            ls  => 'list',
            des => 'describe',
        },
        contact => {
            fullname => $ENV{USER},
            name     => $ENV{USER},
            email    => "$ENV{USER}@" . ($ENV{HOST} ? $ENV{HOST} : 'localhost'),
            address  => '123 Timbuc Too',
        },
        company => {
            name     => '',
            address  => '',
        },
    };

    $self->{configs} = [];
    $self->{config_default} = "$ENV{HOME}/.$CONFIG_NAME";

    if ( -f "/etc/$CONFIG_NAME" ) {
        my $second = LoadFile("/etc/$CONFIG_NAME");
        $conf = $self->conf_join($conf, $second);
        push @{$self->{configs}}, "/etc/$CONFIG_NAME";
    }
    if ( $option{'conf'} && -f $option{'conf'} ) {
        my $second = LoadFile($option{'conf'});
        $conf = $self->conf_join($conf, $second);
        push @{$self->{configs}}, $option{'conf'};
    }
    elsif ( -f "$ENV{HOME}/.$CONFIG_NAME" ) {
        my $second = LoadFile("$ENV{HOME}/.$CONFIG_NAME");
        $conf = $self->conf_join($conf, $second);
        push @{$self->{configs}}, "$ENV{HOME}/.$CONFIG_NAME";
    }
    $conf = $self->conf_join($conf, \%option);

    # set up some internal config options
    if ($ENV{'TEMPLATE_CMD_PATH'}) {
        $conf->{'path'} .= $ENV{'TEMPLATE_CMD_PATH'};
    }

    # set up the aliases
    if ($conf->{'aliases'}) {
        for my $alias (keys %{ $conf->{aliases} }) {
            $self->{'cmds'}{$alias} = ucfirst $conf->{aliases}{$alias};
        }
    }

    # set up temporial variables (Note that these are always the values to
    # use and over ride what ever is set in the configuration files)
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime;
    $mon++;
    $year += 1900;

    $conf->{date} = "$year-" . ( $mon < 10 ? '0' : '' ) . "$mon-" . ( $mday < 10 ? '0' : '' ) . $mday;
    $conf->{time} = ( $hour < 10 ? '0' : '' ) . "$hour:" . ( $min < 10 ? '0' : '' ) . "$min:" . ( $sec < 10 ? '0' : '' ) . $sec;
    $conf->{year} = $year;
    $conf->{user} = $ENV{USER};
    $conf->{path} =~ s/~/$ENV{HOME}/gxms;
    $conf->{path} =~ s{/:}{:}gxms;

    # return and cache the configuration item
    return $self->{'config'} = $conf;
}

sub conf_join {

    my ($self, $conf1, $conf2, $t) = @_;
    my %conf = %{$conf1};
    warn '-'x10, Dumper $conf1, $conf2 if $t;

    for my $key ( keys %{$conf2} ) {
        if ( ref $conf2->{$key} eq 'HASH' && ref $conf{$key} eq 'HASH' ) {
            warn 'merging' if $t;
            $conf{$key} = $self->conf_join($conf{$key}, $conf2->{$key});
        }
        else {
            warn "replacing: $key" if $t;
            $conf{$key} = $conf2->{$key};
        }
    }

    return \%conf;
}

sub load_cmd {

    my ($self, $cmd) = @_;

    if (!$cmd) {
        carp 'No command passed!';
        return;
    }

    # check if we have already loaded the command module
    if ( $self->{'loaded'}{$cmd} ) {
        return $self->{'loaded'}{$cmd};
    }

    if (!$self->{cmds}{$cmd}) {
        $self->unknown_cmd($cmd);
    }

    # construct the command module's file name and require that
    my $file   = "App/TemplateCMD/Command/$self->{cmds}{$cmd}.pm";
    my $module = "App::TemplateCMD::Command::$self->{cmds}{$cmd}";
    eval { require $file };

    # check if there were any errors
    if ($EVAL_ERROR) {
        die "Could not load the command $cmd: $EVAL_ERROR\n$file\n$module\n";
    }

    # return success
    return $self->{'loaded'}{$cmd} = $module;
}

sub list_templates {
    my ($self) = @_;

    my $path = $self->config->{path};
    my @path = grep {-d $_} split /:/, $path;

    my @files;

    for my $dir (@path) {
        next if !-d $dir;
        $dir =~ s{/$}{}xms;

        find(
            sub {
                return if -d $_;
                my $file = $File::Find::name;
                $file =~ s{^$dir/}{}xms;
                push @files, { path => $dir, file => $file };
            },
            $dir
        );
    }

    return @files;
}

sub unknown_cmd {

    my ($self, $cmd) = @_;

    my $program = $0;
    $program =~ s{^.*/}{}xms;

    die <<"DIE";
There is no command named $cmd
For help on commands try '$program help'
DIE
}
1;

__END__

=head1 NAME

App::TemplateCMD - Sets up an interface to passing Template Toolkit templates

=head1 VERSION

This documentation refers to App::TemplateCMD version 0.6.10.

=head1 SYNOPSIS

   use App::TemplateCMD;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<new ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description:

=head3 C<get_modules ( $base )>

Arg: C<$base> - string - The base module to search for modules under

Return: Array - A list of modules found under $base

Description: Finds all modules that start with $base

=head3 C<process ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description:

=head3 C<add_args ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description: Adds command line arguments to the current configuration

=head3 C<config ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description:

=head3 C<conf_join ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description:

=head3 C<load_cmd ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description:

=head3 C<list_templates ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description:

=head3 C<unknown_cmd ( %args )>

Arg: C<search> - type (detail) - description

Return: App::TemplateCMD -

Description:

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

Source code can be found on github:

    git://github.com/ivanwills/Catalyst-Plugin-LogDeep.git

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, NSW, Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
