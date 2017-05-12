package App::ZofCMS::Plugin::ConfigToTemplate;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_config_to_template' }
sub _defaults {
    return (
        cell         => 'd',
        key          => 'public_config',
        config_cell  => 'public_config',
        config_keys  => undef,
        noop         => 0,
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    return
        if $conf->{noop};

    my $zcms_config = $config->conf;
    my ( $cell, $key, $ccell, $ckeys ) = @$conf{ qw/cell key config_cell config_keys/ };

    my @keys;
    if ( defined $ckeys ) {
        @keys = @$ckeys;
    }
    else {
        @keys = keys %{ $zcms_config->{ $ccell } || {} };
    }

    for ( @keys ) {
        if ( defined $key  ) {
            $t->{ $cell }{ $key }{ $_ } = $zcms_config->{ $ccell }{ $_ };
        }
        else {
            $t->{ $cell }{ $_ } = $zcms_config->{ $ccell }{ $_ };
        }
    }
};

__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::ConfigToTemplate - plugin to dynamically stuff Main Config File keys into ZofCMS Template

=head1 SYNOPSIS

In Main Config File:

    public_config => {
        name => 'test',
        value => 'plug_test',
    },

In ZofCMS Template:

    plugins => [
        { ConfigToTemplate => 2000 },
    ],

    plug_config_to_template => {
        key     => undef,
        cell    => 't',
    },

Now we can use `name` and `value` variables in HTML::Template template...

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that technically expands functionality of
Main Config File's C<template_defaults> special key.

Using this plugin you can dynamically (and more "on demand") stuff keys from Main Config File
to ZofCMS Template hashref without messing around with other plugins and poking with
->conf method

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 Main Config File and ZofCMS Template First Level Keys

=head2 C<plugins>

    plugins => [
        { ConfigToTemplate => 2000 },
    ],

You need to include the plugin in the list of plugins to run.

=head2 C<plug_config_to_template>

    # these are the default values
    plug_config_to_template => {
        cell         => 'd',
        key          => 'public_config',
        config_cell  => 'public_config',
        config_keys  => undef,
        noop         => 0,
    }

    plug_config_to_template => sub {
        my ( $t, $q, $config ) = @_;
        return {
            cell         => 'd',
            key          => 'public_config',
            config_cell  => 'public_config',
            config_keys  => undef,
            noop         => 0,
        };
    }

The C<plug_config_to_template> must be present in order for the plugin to run. It takesa
hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_config_to_template> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Keys of this hashref can be set in either (or both) Main Config File and
ZofCMS Template - they will be merged together if set in both files; if the same key is set in
both files, the value set in ZofCMS Template will take precedence. All keys are optional, to
run the plugins with all the defaults use an empty hashref. Possible keys/values
are as follows:

=head3 C<cell>

    cell => 'd',

B<Optional>. Specifies the cell (first-level key) in ZofCMS Template hashref where to put
config file data. B<Defaults to:> C<d>

=head3 C<key>

    key => 'public_config',

    key => undef,

B<Optional>. Specifies the key in the cell (i.e. the second-level key inside the first-level
key) of where to put config file data. B<Can be set to> C<undef> in which case data will be
stuffed right into the cell. B<Defaults to:> C<public_config>

=head3 C<config_cell>

    config_cell  => 'public_config',

B<Optional>. Specifies the cell (first-level key) in Main Config File from where to take the
data. Note that C<config_cell> must point to a hashref. B<Defaults to:> C<public_config>

=head3 C<config_keys>

    config_keys  => undef,
    config_keys  => [
        qw/foo bar baz/,
    ],

B<Optional>. Takes either C<undef> or an arrayref. Specifies the keys in the cell (i.e.
the second-level key inside the first-level key) in Main Config File from where to take the
data. When set to an arrayref, the elements of the arrayref represent the names of the keys.
When set to C<undef> all keys will be taken. Note that C<config_cell> must point to
a hashref. B<Defaults to:> C<undef>

=head3 C<noop>

    noop => 0,

B<Optional>. Pneumonic: B<No> B<Op>eration. Takes either true or false values. When set to
a true value, the plugin will not run. B<Defaults to:> C<0>

=head1 EXAMPLES

=head2 EXAMPLE 1

    Config File:
    plug_config_to_template => {}, # all defaults

    public_config => {
        name => 'test',
        value => 'plug_test',
    },


    Relevant dump of ZofCMS Template hashref:

    $VAR1 = {
        'd' => {
            'public_config' => {
                'value' => 'plug_test',
                'name' => 'test'
            }
        },
    };

=head2 EXAMPLE 2

    Config File:
    plug_config_to_template => {
        key     => undef,
        cell    => 't',
    },

    public_config => {
        name => 'test',
        value => 'plug_test',
    },


    Relevant dump of ZofCMS Template hashref:

    $VAR1 = {
        't' => {
            'value' => 'plug_test',
            'name' => 'test'
        }
    };

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut