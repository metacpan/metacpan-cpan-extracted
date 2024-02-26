package Acme::Crux::Plugin::Config;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Crux::Plugin::Config - The Acme::Crux plugin for configuration your application

=head1 SYNOPSIS

    # In startup
    my $config = $app->plugin('Config');
    my $config = $app->plugin('Config', undef, {file => '/etc/myapp.conf'});

    # In application
    my $val = $app->config->get("/foo/bar/baz");
    my $all = $app->config->conf;

    my $array = $app->config->array('/foo'); # 'value'
        # ['value']

    my $hash = $app->config->hash('/foo'); # { foo => 'first', bar => 'second' }
        # { foo => 'first', bar => 'second' }

    my $first = $app->config->first('/foo'); # ['first', 'second', 'third']
        # first

    my $latest = $app->config->latest('/foo'); # ['first', 'second', 'third']
        # third

=head1 DESCRIPTION

The Acme::Crux plugin for configuration your application

=head1 OPTIONS

This plugin supports the following options

=head2 default

    $app->plugin(Config => undef, {default => {foo => 'bar'});

Sets the default configuration hash

Default: no defaults, empty config structure

=head2 dirs

    $app->plugin(Config => undef, {dirs => ['/etc/foo', '/etc/bar']});

Paths to additional directories of config files

Default: no additional directories

=head2 file

    $app->plugin(Config => undef, {file => '/etc/myapp.conf'});

Path to configuration file, absolute or relative to the application root directory,
defaults to the value of the C<$moniker.conf> in the application root directory.

Default: C<configfile> command line option or C<configfile> application argument
or C</etc/$moniker/$moniker.conf> otherwise

=head2 noload

    $app->plugin(Config => undef, {noload => 1});

This option disables auto loading config file

Default: C<noload> command line option or C<config_noload> application argument
or C<0> otherwise

=head2 opts, options

    $app->plugin(Config => undef, {opts => {'-AutoTrue' => 0}});
    $app->plugin(Config => undef, {options => {'-AutoTrue' => 0}});

Sets the L<Config::General> options directly

Default: no special options

=head2 root

    $app->plugin(Config => undef, {root => '/etc/myapp'});

Sets the root directory to configuration files and directories location

Default: C<configroot> command line option or C<root> application argument
or C</etc/$moniker> otherwise

=head1 METHODS

This class inherits all methods from L<Acme::Crux::Plugin> and implements the following new ones

=head2 register

    $plugin->register($app, {file => '/etc/app.conf'});

Register plugin in Acme::Crux application and merge configuration

=head1 HELPERS

All helpers of this plugin are allows get access to configuration object.
See L<Acrux::Config> for details

=head2 config, conf

Returns L<Acrux::Config> object

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acme::Crux::Plugin>, L<Acrux::Config>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.02';

use parent 'Acme::Crux::Plugin';

use Acrux::Config;
use Acrux::RefUtil qw/as_array_ref as_hash_ref is_true_flag/;

sub register {
    my ($self, $app, $args) = @_;

    # NoLoad flag: PLGARGS || OPTS || ORIG || DEFS
    my $noload = is_true_flag($args->{noload}) # From plugin arguments first
      || $app->getopt("noload")                # From command line options
      || $app->orig->{"config_noload"}         # From App arguments
      || 0;

    # Config file: PLGARGS || OPTS || ORIG || DEFS
    my $file = $args->{file} || $app->getopt("configfile") || $app->configfile;

    # Config::General Options: PLGARGS || DEFS
    my $options = as_hash_ref($args->{options} || $args->{opts});

    # Merge defaults
    my $defaults = as_hash_ref($args->{defaults} || $args->{default}) || {};

    # Config root dir: PLGARGS || OPTS || ORIG || DEFS
    my $root = $args->{root} || $app->getopt("config_root") || $app->getopt("configroot") || $app->root;

    # Additional config directories: PLGARGS || DEFS
    my $dirs = as_array_ref($args->{dirs});

    # Create instance
    my $config = Acrux::Config->new(
        file        => $file,
        options     => $options,
        noload      => $noload,
        defaults    => $defaults,
        root        => $root,
        dirs        => $dirs,
    );
    if (my $err = $config->error) {
        if ($app->debugmode) {
            $app->verbosemode
              ? warn qq{Can't load configuration file "$file"\n$err\n}
              : warn qq{Can't load configuration file "$file"\n};
        }
    }

    # Set conf and config helpers (methods)
    $app->register_method(config => sub { $config });
    $app->register_method(conf => sub { $config });

    return $config;
}

1;

__END__
