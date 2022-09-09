package CTK::Configuration;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Configuration - Configuration of CTK

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK::Configuration;

    my $config = CTK::Configuration->new(
            config  => "foo.conf",
            confdir => "conf",
            options => {... Config::General options ...},
        );

=head1 DESCRIPTION

The module works with the configuration

=head2 new

    my $config = CTK::Configuration->new(
            config  => "/path/to/config/file.conf",
            confdir => "/path/to/config/directory",
            options => {... Config::General options ...},
        );

Example foo.conf file:

    Foo     1
    Bar     test
    Flag    true

Example of the "conf" structure of $config object:

    print Dumper($config->{conf});
    $VAR1 = {
        'foo' => 1
        'bar' => 'test',
        'flag' => 1,
    }

=over 8

=item B<config>

    config => "/etc/myapp/myapp.conf"

Specifies absolute or relative path to config-file.

=item B<confdir, dir>

    confdir => "/etc"

Specifies absolute or relative path to config-dir.

=item B<no_autoload>

    no_autoload => 1

Disables auto loading configuration files. Default: false (loading is enabled)

=item B<options>

    options => { ... }

Options of L<Config::General>

=back

=head1 METHODS

=over 8

=item B<error>

    my $error = $config->error;

Returns error string if occurred any errors while creating the object or reading the configuration file

=item B<conf>

    my $value = $config->conf( 'key' );

Gets value from config structure by key

    my $config_hash = $config->conf;

Returns config hash structure

=item B<get>

    my $value = $config->get( 'key' );

Gets value from config structure by key

=item B<getall>

    my $config_hash = $config->getall;

Returns config hash structure

=item B<load>

    my $config = $config->load;

Loading config files

=item B<reload>

    my $config = $config->reload;

Reloading config files. All the previous config options will be flushes

=item B<set>

    $config->set( 'key', 'value' );

Sets value to config structure by key. Returns setted value

=item B<status>

    print $config->error unless $config->status;

Returns boolean status of loading config file

=back

=head1 HISTORY

=over 8

=item B<1.00 Mon Apr 29 10:36:06 MSK 2019>

Init version

=back

See C<Changes> file

=head1 DEPENDENCIES

L<Config::General>, L<Try::Tiny>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<Config::General>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = '1.01';

use Carp;
use Config::General;
use Try::Tiny;
use Time::HiRes qw/gettimeofday/;
use Cwd qw/getcwd/;
use File::Spec ();

use constant {
    CONF_DIR    => "conf",
    LOCKED_KEYS => [qw/hitime loadstatus/],
};

sub new {
    my $class = shift;
    my %args = @_;

    # Create object
    my $myhitime = gettimeofday() * 1;
    my $self = bless {
        status  => 0,
        dirs    => [],
        error   => "",
        files   => [],
        created => time(),
        orig    => {},
        myhitime=> $myhitime,
        conf    => {
            hitime      => $myhitime,
            loadstatus  => 0, # == $self->{status}
        },
    }, $class;

    # Set dirs
    my @dirs = ();
    my $mydir = $args{confdir} // $args{dir};
    my $root = getcwd();
    my $confdir;
    if ($mydir) {
        $confdir = File::Spec->file_name_is_absolute($mydir)
            ? $mydir
            : File::Spec->catdir($root, $mydir);
        push (@dirs, $root) unless File::Spec->file_name_is_absolute($mydir);
    } else {
        $confdir = File::Spec->catdir($root, CONF_DIR);
        push (@dirs, $root);
    }
    push(@dirs, $confdir) if length($confdir);
    push(@dirs, CONF_DIR) if $confdir ne CONF_DIR;
    $self->{dirs} = [@dirs];

    # Set files
    my $fileconf = $args{config} // $args{file} // $args{fileconf};
    unless ($fileconf) {
        $self->{error} = "Config file not specified";
        return $self;
    }
    $fileconf = File::Spec->catfile($root, $fileconf)
        unless File::Spec->file_name_is_absolute($fileconf);
    $self->{files} = [$fileconf];
    unless (-e $fileconf) {
        $self->{error} = sprintf("Config file not found: %s", $fileconf);
        return $self;
    }

    # Options
    my $tmpopts = $args{options} || {};
    my %options = %$tmpopts;
    $options{"-ConfigFile"}         = $fileconf;
    $options{"-ConfigPath"}         ||= [@dirs];
    $options{"-ApacheCompatible"}   = 1 unless exists $options{"-ApacheCompatible"};
    $options{"-LowerCaseNames"}     = 1 unless exists $options{"-LowerCaseNames"};
    $options{"-AutoTrue"}           = 1 unless exists $options{"-AutoTrue"};
    $self->{orig} = {%options};

    return $self if $args{no_autoload};
    return $self->load;
}
sub load {
    my $self = shift;
    my $orig = $self->{orig} || {};
    $self->{error} = "";

    # Loading
    my $cfg;
    try {
        $cfg = Config::General->new( %$orig );
    } catch {
        $self->{error} = $_ // '';
    };
    return $self if length($self->{error});

    # Ok
    my %newconfig = $cfg->getall if $cfg && $cfg->can('getall');
    $self->{files} = [$cfg->files] if $cfg && $cfg->can('files');

    # Set only unlocked keys
    my %lkeys = ();
    foreach my $k (@{(LOCKED_KEYS)}) { $lkeys{$k} = 1 }
    foreach my $k (keys(%newconfig)) { $self->{conf}->{$k} = $newconfig{$k} if $k && !$lkeys{$k} }

    # Set statuses
    $self->{status} = 1;
    $self->{conf}->{loadstatus} = 1;

    return $self;
}
sub reload {
    my $self = shift;

    # Flush settings
    $self->{conf} = {
        hitime      => $self->{myhitime},
        loadstatus  => 0,
    };

    return $self->load;
}
sub error {
    my $self = shift;
    return $self->{error} // '';
}
sub status {
    my $self = shift;
    return $self->{status} ? 1 : 0;
}
sub set {
    my $self = shift;
    my $key = shift;
    return undef unless defined($key) && length($key);
    my $val = shift;
    $self->{conf}->{$key} = $val;
}
sub get {
    my $self = shift;
    my $key = shift;
    return undef unless defined($key) && length($key);
    return $self->{conf}->{$key};
}
sub getall {
    my $self = shift;
    return $self->{conf};
}
sub conf {
    my $self = shift;
    my $key  = shift;
    return undef unless $self->{conf};
    return $self->{conf} unless defined $key;
    return $self->{conf}->{$key};
}

1;

__END__
