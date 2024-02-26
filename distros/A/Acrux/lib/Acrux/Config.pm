package Acrux::Config;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Acrux::Config - Config::General Configuration of Acrux

=head1 SYNOPSIS

    use Acrux::Config;

    my $config = Acrux::Config->new(
        file => '/etc/myapp.conf',
    );
    say $config->get('foo');

=head1 DESCRIPTION

The module works with the configuration using L<Config::General>

All getters of this class are allows get access to configuration parameters by path-pointers.
See L<Acrux::Pointer> and L<RFC 6901|https://tools.ietf.org/html/rfc6901>

=head2 new

    my $config = Acrux::Config->new(
        file => '/etc/myapp.conf',
        default => {foo => 'bar'},
    );

=head1 ATTRIBUTES

This plugin supports the following attributes

=head2 default

    default => {foo => 'bar'}

Default configuration data

=head2 dirs

    dirs => ['/etc/foo', '/etc/bar']

Paths to additional directories of config files

=head2 file

    file => '/etc/foo.stuff'

Path to configuration file, absolute or relative, defaults to the value of the
C<$0.conf> in the current directory

=head2 noload

    noload => 1

This attribute disables loading config file

=head2 options

    options => {'-AutoTrue' => 0}

Sets the L<Config::General> options directly

=head2 root

    root => '/etc/myapp'

Sets the root directory to configuration files and directories location

=head1 METHODS

This plugin implements the following methods

=head2 array, list

    dumper $config->array('/foo'); # ['first', 'second', 'third']
        # ['first', 'second', 'third']
    dumper $config->array('/foo'); # 'value'
        # ['value']

Returns an array of found values from configuration

=head2 config, conf

    my $config_hash = $config->config; # { ... }

This method returns config structure directly as hash ref

=head2 error

    my $error = $config->error;

Returns error string if occurred any errors while creating the object or reading the configuration file

=head2 first

    say $config->first('/foo'); # ['first', 'second', 'third']
        # first

Returns an first value of found values from configuration

=head2 get

    say $config->get('/datadir');

Returns configuration value by path

=head2 hash, object

    dumper $config->hash('/foo'); # { foo => 'first', bar => 'second' }
        # { foo => 'first', bar => 'second' }

Returns an hash of found values from configuration

=head2 latest

    say $config->latest('/foo'); # ['first', 'second', 'third']
        # third

Returns an latest value of found values from configuration

=head2 load

    my $config = $config->load;

Loading config files

=head2 pointer

    my $pointer = $config->pointer;

Returns current L<Acrux::Pointer> object

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Config::General>, L<Acrux::Pointer>

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

use Config::General qw//;
use Cwd qw/getcwd/;
use File::Spec qw//;
use File::Basename qw/basename/;
use Acrux::Pointer;
use Acrux::RefUtil qw/as_array is_array_ref is_hash_ref is_value/;
use Acrux::Util qw/clone/;

use constant DEFAULT_CG_OPTS => {
    '-ApacheCompatible' => 1, # Makes possible to tweak all options in a way that Apache configs can be parsed
    '-LowerCaseNames'   => 1, # All options found in the config will be converted to lowercase
    '-UTF8'             => 1, # All files will be opened in utf8 mode
    '-AutoTrue'         => 1, # All options in your config file, whose values are set to true or false values, will be normalised to 1 or 0 respectively
};

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $self  = bless {
            default => $args->{defaults} || $args->{default} || {},
            file    => $args->{file} // '',
            root    => $args->{root} // '', # base path to default files/directories
            dirs    => $args->{dirs} || [],
            noload  => $args->{noload} || 0,
            options => {},
            error   => '',
            config  => {},
            pointer => Acrux::Pointer->new,
            files   => [],
            orig    => $args->{options} || $args->{opts} || {},
        }, $class;
    my $myroot = length($self->{root}) ? $self->{root} : getcwd();

    # Set dirs
    my @dirs = ();
    foreach my $dir (as_array($self->{dirs})) {
        unless (File::Spec->file_name_is_absolute($dir)) { # rel
            $dir = length($myroot)
                ? File::Spec->rel2abs($dir, $myroot)
                : File::Spec->rel2abs($dir);
        }
        push @dirs, $dir if -e $dir;
    }
    $self->{dirs} = [@dirs];

    # Set config file
    my $file = $self->{file};
       $file = sprintf("%s.conf", basename($0)) unless length $file;
    unless (File::Spec->file_name_is_absolute($file)) { # rel
        $file = length($myroot)
                ? File::Spec->rel2abs($file, $myroot)
                : File::Spec->rel2abs($file);
    }
    $self->{file} = $file;
    unless ($self->{noload}) {
        unless (-r $file) {
            $self->{error} = sprintf("Configuration file \"%s\" not found or unreadable", $file);
            return $self;
        }
    }

    # Config::General Options
    my $orig    = $self->{orig};
       $orig = {} unless is_hash_ref($orig);
    my %options = (%{DEFAULT_CG_OPTS()}, %$orig); # Merge everything
       $options{'-ConfigFile'} = $file;
       $options{"-ConfigPath"} ||= [@dirs] if scalar(@dirs);
    $self->{options} = {%options};

    # Load
    return $self if $self->{noload};
    return $self->load;
}
sub default {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{default} = shift;
        return $self;
    }
    return $self->{default};
}
sub error {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{error} = shift;
        return $self;
    }
    return $self->{error};
}
sub file {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{file} = shift;
        return $self;
    }
    return $self->{file};
}
sub dirs {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{dirs} = shift;
        return $self;
    }
    return $self->{dirs};
}
sub pointer { shift->{pointer} }
sub load {
    my $self = shift;
    my $opts = $self->{options};
    $self->{error} = "";

    # Load
    my $cfg = eval { Config::General->new(%$opts) };
    return $self->error(sprintf("Can't load configuration from file \"%s\": %s", $self->file, $@)) if $@;
    return $self->error(sprintf("Configuration file \"%s\" did not return a Config::General object", $self->file))
        unless ref $cfg eq 'Config::General';
    my %config = $cfg->getall;
    my @files = $cfg->files;

    # Merge defaults
    my $defaults = $self->default || {};
    %config = (%$defaults, %config) if is_hash_ref($defaults) && scalar keys %$defaults;

    # Add system values
    $config{'_config_files'} = [@files];
    $config{'_config_loaded'} = scalar @files;

    # Set config data
    $self->{config} = {%config}; # hash data
    $self->pointer->data(clone($self->{config}));

    return $self;
}
sub config {
    my $self = shift;
    my $key  = shift;
    return undef unless $self->{config};
    return $self->{config} unless defined $key and length $key;
    return $self->{config}->{$key};
}
sub conf { goto &config }
sub get {
    my $self = shift;
    my $key = shift;
    return $self->pointer->get($key);
}
sub first {
    my $self = shift;
    return undef unless defined($_[0]) && length($_[0]);
    my $node = $self->pointer->get($_[0]);
    if (is_array_ref($node)) { # Array ref
        return exists($node->[0]) ? $node->[0] : undef;
    } elsif (is_value($node)) { # Scalar value
        return $node;
    }
    return undef;
}
sub latest {
    my $self = shift;
    return undef unless defined($_[0]) && length($_[0]);
    my $node = $self->pointer->get($_[0]);
    if (is_array_ref($node)) { # Array ref
        return exists($node->[0]) ? $node->[-1] : undef;
    } elsif (is_value($node)) { # Scalar value
        return $node;
    }
    return undef;
}
sub array {
    my $self = shift;
    return undef unless defined($_[0]) && length($_[0]);
    my $node = $self->pointer->get($_[0]);
    if (is_array_ref($node)) { # Array ref
        return $node;
    } elsif (defined($node)) {
        return [$node];
    }
    return [];
}
sub list { goto &array }
sub hash {
    my $self = shift;
    return undef unless defined($_[0]) && length($_[0]);
    my $node = $self->pointer->get($_[0]);
    return $node if is_hash_ref($node);
    return {};
}
sub object { goto &hash }

1;

__END__
