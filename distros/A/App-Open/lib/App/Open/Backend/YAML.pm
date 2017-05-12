#
#===============================================================================
#
#         FILE:  YAML.pm
#
#  DESCRIPTION:  App::Open::Backend::YAML - YAML-oriented MIME backend; hand-configured
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  06/02/2008 04:19:15 AM PDT
#     REVISION:  ---
#===============================================================================

package App::Open::Backend::YAML;

use strict;
use warnings;

use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;

=head1 NAME

App::Open::Backend::YAML: A generic YAML hashmap of extensions/schemes to programs.

=head1 SYNOPSIS

Please read App::Open::Backend for information on how to use backends.

=head1 CONFIGURING

The YAML backend uses a specific key/value format to correlate extensions and
schemes to programs used to launch them.

The file format is fairly simple:

 ----
 "gz": gunzip
 "http:": firefox -newtab %s
 "tar.gz": tar vxzf %s

There are two types of keys: extensions and schemes. Extensions are your
standard file extensions, and omit any leading punctuation. Schemes are the
protocol scheme in a URL (e.g., http) and are postfixed with a colon (`:'). A
scheme without this colon will be treated like an extension and thusly ignored
for URLs, and obviously the inverse is true for extensions.

Extensions can be compound and have a defined processing order. See
App::Open::Backend or App::Open::Using for more information.

The default filename for these references is $HOME/.mimeyaml, but this is
trivial to redefine by providing an argument to the backend configuration. See
the aforementioned documentation for more information.

=head1 METHODS

Read App::Open::Backend for what the interface provides, method descriptions
here will only cover implementation.

=over 4

=item new

The only argument provided here is the name of the YAML definition file, which
defaults to $HOME/.mimeyaml if nothing is provided.

The filename is stowed and load_definitions() is called. BACKEND_CONFIG_ERROR
is thrown if the constructor argument is not an array containing strings.

=cut

sub new {
    my ( $class, $def_file ) = @_;

    $def_file ||= [];

    die /BACKEND_CONFIG_ERROR/ if ($def_file && (!ref($def_file) || !ref($def_file) eq 'ARRAY'));

    my $self = bless { 
        def_file => ($def_file->[0] || "$ENV{HOME}/.mimeyaml") 
    }, $class;

    $self->load_definitions;

    return $self;
}

=item load_definitions

Load the definitions from the YAML file. BACKEND_CONFIG_ERROR is thrown if
syntax checking fails, the result is an abnormal data structure (not a flat
hash), or the loading resulted in undef.

With any luck, a correct data structure will get stowed in the `defs` member
and processing will continue.

=cut

sub load_definitions {
    my $self = shift;

    my $config;

    eval { $config = LoadFile( $self->def_file ) };

    #
    # so you think you're tough, eh?
    #
    # let's see if you can pass... A SYNTAX CHECK!
    #
    if ($@) {
        die "BACKEND_CONFIG_ERROR";
    }
    else {
        if ( $config and ref($config) eq 'HASH' ) {
            foreach my $value ( values %$config ) {
                die "BACKEND_CONFIG_ERROR" unless ( $value and !ref($value) );
            }
        }
        else {
            die "BACKEND_CONFIG_ERROR";
        }
    }

    $self->{defs} = $config;
}

=item lookup_file($extension)

Return the command string from the extension lookup.

=cut

sub lookup_file {
    my ( $self, $extension ) = @_;

    $extension =~ s/^\.//g;

    return $self->{defs}{$extension};
}

=item lookup_url($scheme)

Return the command string from the scheme lookup.

This actually just cheats and calls `lookup file` with a colon appended.

=cut

sub lookup_url { $_[0]->lookup_file($_[1].":") }

=item def_file

Returns the filename where the defintions used are kept.

=cut

sub def_file { $_[0]->{def_file} }

=back

=head1 LICENSE

This file and all portions of the original package are (C) 2008 Erik Hollensbe.
Please see the file COPYING in the package for more information.

=head1 BUGS AND PATCHES

Probably a lot of them. Report them to <erik@hollensbe.org> if you're feeling
kind. Report them to CPAN RT if you'd prefer they never get seen.

=cut

1;
