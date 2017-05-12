package Dancer2::Plugin::Etcd::CLI;

use utf8;
use strict;
use warnings;

=head1 NAME

Dancer2::Plugin::Etcd::CLI

=cut

our $VERSION = '0.003';

use Dancer2::Core::Runner;
use Dancer2::FileUtils qw/dirname path/;
use Sys::Hostname;
use File::Spec qw/catfile/;
use Getopt::Long;
use Path::Tiny;
use Hash::Flatten;
use Cwd;
use Etcd3;
use JSON;
use YAML::Syck;
use Path::Class qw( file );
use File::Spec;
use Try::Tiny;
use Data::Dumper;

use constant { SUCCESS => 0, INFO => 1, WARN => 2, ERROR => 3 };

use Class::Tiny;

our $UseSystem = 0; # 1 for unit testing

{
    package ReadConfig;
    use Moo;
    with 'Dancer2::Core::Role::ConfigReader';

    has '+location' => (
        is => 'ro'
    );

    has '+environment' => (
        is => 'ro'
    );
}

=head2 run

=cut

sub run {
    my($self, @args) = @_;

    my @commands;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_ignore_case", "pass_through" ],
    );
    $p->getoptionsfromarray(
        \@args,
        "h|help"    => sub { unshift @commands, 'help' },
        "v|version" => sub { unshift @commands, 'version' },
        "verbose!"  => sub { $self->verbose($_[1]) },
    );

    push @commands, @args;

    my $cmd = shift @commands || 'help';

    my $code = try {
        my $call = $self->can("cmd_$cmd")
            or die "Could not find command '$cmd'";
        $self->$call(@commands);
        return 0;
    } catch {
        die $_ ;
    };

    return $code;
}

=head2 commands

=cut

sub commands {
    my $self = shift;

    no strict 'refs';
    map { s/^cmd_//; $_ }
        grep { /^cmd_.*/ && $self->can($_) } sort keys %{__PACKAGE__."::"};
}

=head2 cmd_help

=cut

sub cmd_help {
    my $self = shift;
    $self->print(<<HELP);
Usage: shepherd <command>
where <command> is one of:
  @{[ join ", ", $self->commands ]}
Options:
--env       Define current running environment.
            Note: Default is development.
--apphost   The hostname is the domain related to the config.
--appname   The name of the Dancer app.
--apppath   Path to app
--version   By default we use the last version.  This flag allows selection of specific version.
--etcdhost  Etcd host
--etcdssl   Etcd ssl connection
--etcdport  Etcd port
--etcduser  Etcd user
--etcdpass  Etcd user password
--readonly  Only print the new configs to screen do no replace current.
--help      This help screen

Run shepherd -h <command> for help.
HELP
}

=head2 parse_options

=cut

sub parse_options {
    my($self, $args, @spec) = @_;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_auto_abbrev", "no_ignore_case" ],
    );
    $p->getoptionsfromarray($args, @spec);
}

=head2 parse_options_pass_through

=cut

sub parse_options_pass_through {
    my($self, $args, @spec) = @_;

    my $p = Getopt::Long::Parser->new(
        config => [ "no_auto_abbrev", "no_ignore_case", "pass_through" ],
    );
    $p->getoptionsfromarray($args, @spec);

    # with pass_through keeps -- in args
    shift @$args if $args->[0] && $args->[0] eq '--';
}

=head2 printf

=cut

sub printf {
    my $self = shift;
    my $type = pop;
    my($temp, @args) = @_;
    $self->print(sprintf($temp, @args), $type);
}

=head2 print

=cut

sub print {
    my($self, $msg, $type) = @_;
    my $fh = $type && $type >= WARN ? *STDERR : *STDOUT;
    print {$fh} $msg;
}

=head2 cmd_get

=cut

sub cmd_get{
    my($self, @args) = @_;

    my($env, $version, $app_path, $app_name, $app_host, $readonly, $etcd_host,
      $etcd_ssl, $etcd_port, $etcd_user, $etcd_pass, $settings);

    $self->parse_options(
        \@args,
        "e|env=s"      => \$env,
        "v|version=i"  => \$version,
        "h|apphost=s"  => \$app_host,
        "p|apppath=s"  => \$app_path,
        "n|appname=s"  => \$app_name,
        "etcdhost=s"   => \$etcd_host,
        "etcdssl=s"    => \$etcd_ssl,
        "etcdport=s"   => \$etcd_port,
        "etcduser=s"   => \$etcd_user,
        "etcdpass=s"   => \$etcd_pass,
        "readonly!"    => \$readonly,
    );

    $env    ||= 'development';
    $app_path ||= getcwd;
    $app_host ||= hostname;

    $settings->{username} = $etcd_user if $etcd_user;
    $settings->{password} = $etcd_pass if $etcd_pass;
    $settings->{ssl} = $etcd_ssl if $etcd_ssl;
    $settings->{port} = $etcd_port if $etcd_port;

    my $app = ReadConfig->new( location => $app_path, environment => $env );
    my $files = $app->config_files;

    die "This command must be run from the base dir of a dancer app.\n" unless (@$files);

    my $etcd = $self->{etcd} || Etcd3->connect($etcd_host, $settings);

#    print STDERR Dumper($etcd);

    for my $file (@$files) {
        my $conf_path = file( File::Spec->rel2abs($file) );

        my $conf_data = LoadFile($conf_path);

        unless ($app_name) {
            $app_name = $conf_data->{'appname'} if $conf_data->{'appname'};
        }

        my $env_path = File::Spec->catdir( $app_name, $app_host, $env);
        my $key_path = File::Spec->catdir( $env_path, $conf_path->relative );
        my $version = $version ? sprintf("%08d", $version) : $etcd->range({ key => "/$env_path/version" })->get_value;

        my $input = $etcd->range({ key => "/$key_path/$version/00000000", range_end => "/$key_path/$version/99999999"});
        my @range = @{$input->all};
        die "No confiuration exists for this version." unless @range;

        my $line_hash;
        for my $row (@range) {
            my $key = $row->{key};
            my $value = $row->{value};

            # print " key: $row, value: $value";
            $key =~ s/\/.+[a-zA-Z]\/\d+//;
            $value =~ s/\\n//;
            $value =~ s/\\('|")/$1/g;
            $line_hash->{$key} = $value;
        }

        my $o = Hash::Flatten->new({
                    HashDelimiter => '/',
                    ArrayDelimiter => '/-/',
                    OnRefScalar => 'warn',
        });

        my $config_file = path($conf_path->relative);
        my @output;
        #TODO need to clean this up into a function and make it scalable.
        my $flat = $o->unflatten($line_hash);
        foreach my $row (keys %$flat) {
            foreach my $line (sort keys %{ $flat->{$row} }) {
                foreach my $indent (keys %{ $flat->{$row}{$line} }) {
                   foreach my $config (keys %{ $flat->{$row}{$line}{$indent} }) {
                        if (ref($flat->{$row}{$line}{$indent}{$config}) ne 'HASH') {
                            push @output, $flat->{$row}{$line}{$indent}{$config} . "\n";
                        }
                        else {
                            push @output, sprintf "%-*s%s", $indent, '', $config;
                        }
                        no strict; #FIXME
                        foreach my $value (keys %{ $flat->{$row}{$line}{$indent}{$config}}) {
                            if (ref($flat->{$row}{$line}{$indent}{$config}{$value}) ne 'HASH') {
                                my $cvalue = $flat->{$row}{$line}{$indent}{$config}{$value};
                                push @output, $cvalue ? ": $flat->{$row}{$line}{$indent}{$config}{$value}\n" : ":\n";
                            }
                            else{
                                 foreach my $avalue (keys %{ $flat->{$row}{$line}{$indent}{$config}{$value}}) {
                                     push @output, " $flat->{$row}{$line}{$indent}{$config}{$value}{$avalue}\n";
                                 }
                            }
                        }
                    }
                }
            }
        }
        $readonly ? print "@output\n" : $config_file->spew_utf8( @output );
        $self->print("Complete! Config $file saved.\n", SUCCESS);
    }
}

=head2 cmd_put

=cut

sub cmd_put{
    my($self, @args) = @_;

    my($env, $app_path, $app_name, $app_host, $readonly, $etcd_host,
      $etcd_ssl, $etcd_port, $etcd_user, $etcd_pass, $settings, @configs);

    $self->parse_options(
        \@args,
        "e|env=s"      => \$env,
        "h|apphost=s"  => \$app_host,
        "p|apppath=s"  => \$app_path,
        "n|appname=s"  => \$app_name,
        "etcdhost=s"   => \$etcd_host,
        "etcdssl=s"    => \$etcd_ssl,
        "etcdport=s"   => \$etcd_port,
        "etcduser=s"   => \$etcd_user,
        "etcdpass=s"   => \$etcd_pass,
        "readonly!"    => \$readonly,
    );

    $env    ||= 'development';
    $app_path ||= getcwd;
    $app_host ||= hostname;

    $settings->{username} = $etcd_user if $etcd_user;
    $settings->{password} = $etcd_pass if $etcd_pass;
    $settings->{ssl} = $etcd_ssl if $etcd_ssl;
    $settings->{port} = $etcd_port if $etcd_port;

    my $etcd = Etcd3->connect($etcd_host, $settings);

#    print STDERR Dumper($etcd);

    my $app = ReadConfig->new( location => $app_path, environment => $env );
    my $files = $app->config_files;

    die "This command must be run from the base dir of a dancer app.\n" unless (@$files);

    for my $file (@$files) {
        my $conf_path = file( File::Spec->rel2abs($file) );

        print 'backing up ' . $file . "\n";

        # to properly define the yaml we load raw data
        my @lines = path($conf_path)->lines_utf8;

        # we also use the hashref to get data like
        my $conf_data = LoadFile($conf_path);

        unless ($app_name) {
            $app_name = $conf_data->{'appname'} if $conf_data->{'appname'};
        }

        my $output;
        my $line_count = 0;

        # format data for etcd
        for my $out (@lines) {
            $line_count++;
            my $ln = sprintf("%08d", $line_count);
            $out =~ /^( *)/;
            my $count = length( $1 );
            # save comments
            if ($out =~ s/(#.*)//){
               $output->{$ln}{$count} = $1;
            }
            else {
                # escape quotes in values
                $out =~ s/(:*'|")/\\$1/g;
                # handle unquoted zero
                $out =~ s/(.*: *)([0])/$1\\'$2\\'/g;
                $output->{$ln}{$count} = Load($out);
            }
        }
        my $o = Hash::Flatten->new({
                    HashDelimiter => '/',
                    ArrayDelimiter => '/-/',
                    OnRefScalar => 'warn',
        });

        my $flat_conf_data = $o->flatten($output);
        push @configs, { path => $conf_path->relative, environment => $env,
          data => $flat_conf_data, line_count => $line_count };
    }

    my $env_path = File::Spec->catdir( $app_name, $app_host, $env);
    print "env_path : $env_path";
    my $version = $etcd->range({ key => "/$env_path/version" })->get_value || sprintf("%08d", 0);
    $version++;

    for my $config (@configs) {
        die "The AppName must be set." unless $app_name;
        my $data = $config->{data};
        my $key_path = File::Spec->catdir($env_path, $config->{path});

        for my $key ( keys %$data ) {
            my $value = $data->{$key} || '\n';
            #print "/$key_path/$version/$key/, $value\n";
            $etcd->put( { key => "/$key_path/$version/$key/", value => $value })->request;
        }
    }
    print "latest version is now: /$env_path/$version\n";
    $etcd->put({ key => "/$env_path/version", value =>  sprintf("%08d", $version) })->request;
}

1;
