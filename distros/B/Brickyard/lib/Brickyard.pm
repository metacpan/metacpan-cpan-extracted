
package Brickyard;

use 5.010;
use warnings;
use strict;

our $VERSION = '2.0.0';

use Brickyard::Accessor rw =>
  [qw(base_package expand plugins plugins_role_cache)];
use Carp qw(croak);

sub new {
    my $class = shift;
    bless {
        base_package       => 'MyApp',
        expand             => [],
        plugins            => [],
        plugins_role_cache => {},
        @_
    }, $class;
}

sub plugins_with {
    my ($self, $role) = @_;
    $role = $self->expand_package($role);
    $self->plugins_role_cache->{$role} ||=
      [ grep { $_->DOES($role) } @{ $self->plugins } ];
    @{ $self->plugins_role_cache->{$role} };
}

sub plugins_agree {
    my ($self, $role, $code) = @_;
    my @plugins = $self->plugins_with($role);
    return unless @plugins;
    for (@plugins) {

        # $code can use $_->foo($bar)
        return unless $code->();
    }
    1;
}

sub reset_plugins {
    my $self = shift;
    $self->plugins([]);
    $self->plugins_role_cache({});
}

sub parse_ini {
    my ($self, $ini, $callback) = @_;
    $callback //= sub { $_[0] };    # default: identity function
    my @result = ([ '_', '_', {} ]);
    my $counter = 0;
    foreach (split /(?:\015{1,2}\012|\015|\012)/, $ini) {
        $counter++;
        next if /^\s*(?:\#|\;|$)/;    # Skip comments and empty lines
        s/\s\;\s.+$//g;               # Remove inline comments

        # Handle section headers
        if (/^\s*\[\s*(.+?)\s*\]\s*$/) {
            push @result, [ $1, $1, {} ];
            next;
        }

        # Handle properties
        if (/^\s*([^=]+?)\s*=\s*(.*?)\s*$/) {
            my ($key, $value) = ($1, $2);
            $value = $callback->($value);
            my $section = $result[-1][2];

            # if a property is seen multiple times, it becomes an array
            if (exists $section->{$key}) {
                $section->{$key} = [ $section->{$key} ]
                  unless ref $section->{$key} eq 'ARRAY';
                push @{ $section->{$key} } => $value;
            } else {
                $section->{$key} = $value;
            }
            next;
        }
        die "Syntax error in INI file at line $counter: '$_'";
    }
    \@result;
}

# appropriated from CGI::Expand
sub _expand_hash {
    my $flat = $_[1];
    my $deep = {};
    for my $name (keys %$flat) {
        my ($first, @segments) = split /\./, $name;
        my $box_ref = \$deep->{$first};
        for (@segments) {
            if (/^(0|[1-9]\d*)$/) {
                $$box_ref = [] unless defined $$box_ref;
                croak "param clash for $name($_)"
                  unless ref $$box_ref eq 'ARRAY';
                $box_ref = \($$box_ref->[$1]);
            } else {
                $$box_ref = {} unless defined $$box_ref;
                croak "param clash for $name($_)"
                  unless ref $$box_ref eq 'HASH';
                $box_ref = \($$box_ref->{$_});
            }
        }
        croak "param clash for $name value $flat->{$name}"
          if defined $$box_ref;
        $$box_ref = $flat->{$name};
    }
    $deep;
}

sub expand_package {
    my $self = shift;
    local $_ = shift;
    my $base = s/^\*// ? 'Brickyard' : $self->base_package;
    return $_ if s/^@(?=\w)/$base\::PluginBundle::/;
    return $_ if s/^-(?=\w)/$base\::Role::/;
    return $_ if s/^=(?=\w)//;
    for my $expand (@{ $self->expand }) {
        my $before = $_;
        eval $expand;
        return $_ if $_ ne $before;
        die $@ if $@;
    }
    "$base\::Plugin::$_";
}

sub _read_config_file {
    my ($self, $file) = @_;
    open my $fh, '<', $file or die "can't open $file for reading: $!\n";
    my $config = do { local $/; <$fh> };
    close $fh or die "can't close $file: $!\n";
    $config;
}

sub _merge_configs {
    my ($self, $merged_config, $new_config) = @_;
    return $new_config unless ref $merged_config eq 'ARRAY';
    for my $new_section (@$new_config) {
        my ($local_name, $plugin_config) = @{$new_section}[0,2];
        if ($local_name eq '_') {
            # assume the merged config's root section is at the start
            $merged_config->[0][2] = {
                %{ $merged_config->[0][2] },
                %$plugin_config
            };
        } else {
            push @$merged_config => $new_section;
        }
    }
    $merged_config;
}

sub init_from_config {
    my ($self, $config, $root, $callback) = @_;
    if (ref $config eq 'SCALAR') {
        # $config is a reference to the INI string
        my $this_config = $self->parse_ini($$config, $callback);
        $_->[2] = $self->_expand_hash($_->[2]) for @$this_config;
        $self->init_from_config_structure($this_config, $root, $callback);
    } else {
        # $config is a filename
        my $merged_config;
        my @files = split /:/ => $config;
        for my $file (@files) {
            my $this_config = $self->parse_ini($self->_read_config_file($file), $callback);
            $_->[2] = $self->_expand_hash($_->[2]) for @$this_config;
            $merged_config = $self->_merge_configs($merged_config, $this_config);
        }
        $self->init_from_config_structure($merged_config, $root, $callback);
    }
}

sub init_from_config_structure {
    my ($self, $config, $root, $callback) = @_;
    for my $section (@$config) {
        my ($local_name, $name, $plugin_config) = @$section;
        if ($local_name eq '_') {

            # Global container configuration
            while (my ($key, $value) = each %$plugin_config) {
                if ($key eq 'expand') {
                    push @{ $self->expand },
                      ref $value eq 'ARRAY' ? @$value : $value;
                } else {
                    $root->$key($value);
                }
            }
        } else {
            my $package = $section->[1] = $self->expand_package($name);
            eval "require $package";
            die "Cannot require $package: $@" if $@;
            if ($package->DOES('Brickyard::Role::PluginBundle')) {
                my $bundle = $package->new(brickyard => $self, %$plugin_config);
                $self->init_from_config_structure($bundle->bundle_config, $root);
            } else {
                push @{ $self->plugins } => $package->new(
                    name      => $local_name,
                    brickyard => $self,
                    %$plugin_config
                );
            }
        }
    }
}
1;

=head1 NAME

Brickyard - Plugin system based on roles

=head1 SYNOPSIS

    use Brickyard;
    my $brickyard = Brickyard->new(base_package => 'My::App');
    my $root_config = MyApp::RootConfig->new;
    $brickyard->init_from_config('myapp.ini', $root_config);
    $_->some_method for $brickyard->plugins_with(-SomeRole);

=head1 DESCRIPTION

This is a lightweight plugin system based on roles. It does not use Moose but
relies on C<Role::Basic> instead, and very few other modules.

It takes its inspiration from L<Dist::Zilla>, but has much less flexibility
and therefore is also much less complex.

=head1 METHODS

=head2 new

Constructs a new object. Takes an optional hash of arguments to initialize the
object.

=head2 base_package

Read-write accessor for the base package name that is used in
C<expand_package()>. Defaults to C<MyApp>.

=head2 parse_ini

Takes a string that contains configuration in C<INI> format and parses it into
an array of configuration sections. It returns a reference to that array.

Using an array, as opposed to a hash, ensures that the section order is
preserved, so we know in which order to process plugins in L<Brickyard>'s
C<plugins_with()> method.

Each array element corresponds to an C<INI> section. Each section is itself a
reference to an array with three elements:

The first element is the section name. The second element is the package name
of the plugin; it is obtained by expanding the section name using
C<expand_package()>. The third element is a reference to a plugin
configuration hash; it is the section's payload. If a section payload key
occurs several times, it is turned into an array reference in the plugin
configuration hash.

The first section is the global section, denoted by the name C<_>. Any payload
in the C<INI> configuration that occurs before the first section ends up in
this section.

For example:

    ; A comment
    name = Foobar

    [@Default]

    [Some::Thing]
    foo = bar
    baz = 43
    baz = blah

is parsed into this structure:

    [ '_',        'MyApp::Plugin::_',             { name => 'Foobar' } ],
    [ '@Default', 'MyApp::PluginBundle::Default', {} ],
    [   'Some::Thing',
        'MyApp::Plugin::Some::Thing',
        {   'baz' => [ '43', 'blah' ],
            'foo' => 'bar'
        }
    ]

What if you want to pass more complex configuration like a hash of
arrays? An C<INI> file is basically just a key-value mapping. In that
case you can use a special notation for the key where you use dots to
separate the individual elements - array indices and hash keys. For
example:

    foo.0.web.1  = bar
    foo.0.web.2  = baz
    foo.0.mailto = the-mailto
    foo.1.url    = the-url

And this would be parsed into this structure:

    foo => [
        { web    => [ undef, 'bar', 'baz' ],
          mailto => 'the-mailto',
        },
        { url => 'the-url' }
    ]

=head2 expand_package

Takes an abbreviated package name and expands it into the real package
name. C<INI> section names are processed this way so you don't have to
repeat common prefixes all the time.

If C<@> occurs at the start of the string, it is replaced by the base
name plus <::PluginBundle::>.

A C<-> is replaced by the base name plus C<::Role::>.

A C<=> is replaced by the empty string, so the remainder is returned
unaltered.

If the package name still hasn't been altered by the expansions
mentioned above, custom expansions are applied; see below.

As a fallback, the base name plus C<::Plugin::> is prepended.

The base name is normally whatever C<base_package()> returns, but if
the string starts with C<*>, the asterisk is deleted and C<Brickyard>
is used for the base name.

A combination of the default prefixes is not expanded, so C<@=>, for
example, is treated as the fallback case, which is probably not what
you intended.

Here are some examples of package name expansion:

    @Service::Default     MyApp::PluginBundle::Service::Default
    *@Filter              Brickyard::PluginBundle::Filter
    *Filter               Brickyard::Plugin::Filter
    =Foo::Bar             Foo::Bar
    Some::Thing           MyApp::Plugin::Some::Thing
    -Thing::Frobnulizer   MyApp::Role::Thing::Frobnulizer

You can also define custom expansions. There are two ways to do this.
First you can pass a reference to an array of expansions to the
C<expand()> method, or you can define them using the C<expand> key
in the configuration's root section. Each expansion is a string that
is evaluated for each package name. Custom expansions are useful if
you have plugins in several namespaces, for example.

Here is an example of defining a custom expansion directly on the
L<Brickyard> object:

    my $brickyard = Brickyard->new(
        base_package => 'My::App',
        expand       => [ 's/^%/MyOtherApp::Plugin::/' ],
    );

Here is an example of defining it in the configuration's root section:

    expand = s/^%/MyOtherApp::Plugin::/

    [@Default]

    # this now refers to MyOtherApp::Plugin::Foo::Bar
    [%Foo::Bar]
    baz = 44

=head2 init_from_config

Takes a configuration file name specification or a reference to a
string containing the C<INI> string, a root object, and an optional
callback. The file specification can be a simple file name or
a colon-separated list of file names. Each of these files is
parsed with C<parse_ini()> and merged. The result is passed to
C<init_from_config_structure()>, along with the root object and
optional callback - see its documentation for what these things do.

When two configurations are merged, the root sections are merged like
a hash, but any plugin sections are appended in the order they are
found.

This mechanism exists so you can, for example, have sensitive
information like passwords in a separate file. For example:

    $ cat myapp.ini
    key1   = foo
    key2.0 = bar0
    key2.1 = bar1
    [@Default]

    $ cat secret.ini
    username = admin
    password = mysecret
    [Foo::Bar]

To process both configuration files, use:

    $brickyard->init_from_config(
        'myapp.ini:secret.ini', $root_config, $callback
    );

This is the same as having the following all-in-one configuration
file:

    key1     = foo
    key2.0   = bar0
    key2.1   = bar1
    username = admin
    password = mysecret

    [@Default]
    [Foo::Bar]

We use colons to separate configuration file names so it's easy to get
the specification from an environment variable.

If the first argument is a scalar reference, it is assumed that it
refers to the C<INI> string. So you could pass the configuration
directly, without having a separate configuration file, like this:

    my $config = <<EOINI;
    key1     = foo
    key2.0   = bar0
    key2.1   = bar1

    [@Default]
    [Foo::Bar]
    EOINI

    $brickyard->init_from_config(\$config, $root_config, $callback);

=head2 init_from_config_structure

Takes a configuration structure and a root object, and an optional
callback. For each configuration section it creates a plugin object,
initializes it with the plugin configuration hash and adds it to the
brickyard's array of plugins.

Any configuration keys that appear in the configuration's root section
are set on the root object. So the root object can be anything that
has set-accessors for all the configuration keys that can appear in
the configuration's root section. One exception is the C<expand> key,
which is turned into a custom expansion; see above.

The configuration needs to be a reference to a list of sections as
returned by C<init_from_config()>, for example.

If an object is created that consumes the
L<Brickyard::Role::PluginBundle> role, the bundle is processed
recursively.

If the callback is given, each value from a key-value pair is filtered
through that callback. For example, you might want to support
environment variable expansion like this:

    $brickyard->init_from_config(
        'myapp.ini',
        $root_config,
        sub {
            my $value = shift;
            $value =~ s/\$(\w+)/$ENV{$1} || "\$$1"/ge;
            $value;
        }
    );

=head2 plugins

Read-write accessor for the reference to an array of plugins.

=head2 plugins_with

Takes a role name and returns a list of all the plugins that consume
this role. The result is cached, keyed by the role name.

=head2 plugins_agree

Takes a role name and a code reference and calls the code reference
once for each plugin that consumes the role. It returns 1 if the code
returns a true value for all plugins, 0 otherwise.

An example will make this clearer:

    # Let the plugins decide
    sub value_is_valid {
        my ($self, $value) = @_;
        $self->brickyard->plugins_agree(-ValueChecker =>
            sub { $_->value_is_valid($value) }
    }

=head2 reset_plugins

Clears the array of plugins as well as the cache - see
C<plugins_with()>.

=head2 expand

Holds custom package name expansions; see above.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Brickyard>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Brickyard/>.

The development version lives at L<http://github.com/hanekomu/Brickyard>
and may be cloned from L<git://github.com/hanekomu/Brickyard.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
