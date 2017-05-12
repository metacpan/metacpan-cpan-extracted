package Config::Context::ConfigScoped;

use warnings;
use strict;

use Carp;
use Cwd;

=head1 NAME

Config::Context::ConfigScoped - Use Config::Scoped config files with Config::Context

=head1 SYNOPSIS

    use Config::Context;

    my $config_text = '
        Location /users {
            user_area = 1
        }

        LocationMatch '\.*(jpg|gif|png)$' {
            image_file = 1
        }
    ';

    my $conf = Config::Context->new(
        string        => $config_text,
        driver        => 'ConfigScoped',
        match_sections => [
            {
                name          => 'Location',
                match_type    => 'path',
            },
            {
                name          => 'LocationMatch',
                match_type    => 'regex',
            },
        ],
    );

    my %config = $conf->context('/users/~mary/index.html');

    use Data::Dumper;
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => undef,
    };

    my %config = $conf->context('/users/~biff/images/flaming_logo.gif');
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => 1,
    };


=head1 DESCRIPTION

This module uses C<Config::Scoped> to parse config files for
C<Config::Context>.

=head1 DEFAULT OPTIONS

In addition to the options normally enabled by Config::Scoped, the
following options are turned on by default:

    warnings => {
        parameter   => 'off',
        declaration => 'off',
    }

You can change this behaviour by passing a different value to
C<driver_params> to C<new>:

    my $conf = Config::Context->new(
        driver => 'ConfigScoped',
        driver_options => {
            ConfigScoped = > {
                warnings => {
                    parameter  => 'on',
                }
            },
        },
    );

=head1 CONSTRUCTOR

=head2 new(...)

    my $driver = Config::Context::ConfigScoped->new(
        file             => $config_file,
        lower_case_names => 1,  # optional
        options          => {
            # ...
        }
    );

or:

    my $driver = Config::Context::ConfigScoped->new(
        string           => $config_string,
        lower_case_names => 1,  # optional
        options          => {
            # ...
        }
    );

Returns a new driver object, using the provided options.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %args  = @_;

    Config::Context->_require_prerequisite_modules($class);

    # Copy driver opts
    my %driver_opts = %{ $args{'options'}{'ConfigScoped'} || {} };
    my %warnings    = %{ $driver_opts{'warnings'}         || {} };

    $driver_opts{'warnings'} = \%warnings;

    $warnings{'parameter'} = 'off'
        unless exists $driver_opts{'parameter'};

    $warnings{'declaration'} = 'off'
        unless exists $driver_opts{'declaration'};

    if (exists $args{'lower_case_names'} and not exists $driver_opts{'lc'}) {
        $driver_opts{'lc'} = $args{'lower_case_names'};
    }

    my $self = {};

    if ($args{'string'}) {
        $self->{'text'} = $args{'string'};
        $self->{'conf'} = Config::Scoped->new(
            %driver_opts,
        );
    }
    elsif($args{'file'}) {
        $self->{'conf'} = Config::Scoped->new(
            %driver_opts,
            file => $args{'file'},
        );
    }
    else {
        croak __PACKAGE__ . "->new(): one of 'file' or 'string' is required";
    }

    bless $self, $class;
    return $self;
}

=head1 METHODS

=head2 parse()

Returns the data structure for the parsed config.

=cut

sub parse {
    my $self   = shift;
    my $config;
    if ($self->{'text'}) {
        $config = $self->{'conf'}->parse('text' => $self->{'text'});
    }
    else {
        $config = $self->{'conf'}->parse;
    }

    if ((keys %$config) == 1 and exists $config->{'_GLOBAL'}) {
        $config = $config->{'_GLOBAL'};
    }

    return %$config if wantarray;
    return $config;
}

=head2 files()

Returns a list of all the config files read, including any config files
included in the main file.

=cut

sub files {
    my $self   = shift;

    my @files = values %{$self->{'conf'}{'local'}{'includes'}};

    @files = map { Cwd::abs_path($_) } @files;

    return @files if wantarray;
    return \@files;
}

=head2 config_modules

Returns the modules used to parse the config.  In this case: C<Config::Scoped>

=cut

sub config_modules {
    'Config::Scoped';
}


=head1 CAVEATS

=head2 Limitations of hash merging with included files

When one C<Config::Scoped> file includes another, and they both contain
declarations, the declarations are merged.  For instance:

    # config1.conf
    %include config2.conf
    section /users {
        title     = 'Members Area';
    }

    # config2.conf
    section /users {
        user_area = 1;
        title     = 'users area';
    }

This will result in:

    {
         'section' => {
                         '/users' => {
                                    'user_area' => '1',
                                    'title' => 'Members Area',
                                     },
                      },
    }

However, if you use hashes instead of declarations, then the second hash
with the same name will completely overwrite the first one.  For instance:

    # config1.conf
    %include config2.conf
    section = {
        '/users' = {
            title     = 'Members Area';
        }
    }

    # config2.conf
    section = {
        '/users' = {
            user_area = 1;
            title     = 'users area';
        }
    }

This will result in:

    {
         'section' => {
                         '/users' => {
                                    'title' => 'Members Area',
                                     },
                      },
    }


This is important to keep in mind because C<Config::Scoped> does not
allow nested declarations.


=head2 Avoid using the Default Section

When using the C<Config::Context::ConfigScoped> driver, you must be
careful with the use of the default section, since C<Config::Scoped>
does its own inheritance from the global scope into named sections.  See
the documentation for C<Config::Context::ConfigScoped> for more
information.

So for instance, the following will not work as expected.

    private_area = 0
    image_file   = 0

    LocationMatch admin {
        private_area = 1
    }

    LocationMatch '\.(gif)|(jpg)|(png)$' {
        image_file  = 1
    }

Since this is equivalent to:

    LocationMatch admin {
        image_file   = 0
        private_area = 1
    }

    LocationMatch '\.(gif)|(jpg)|(png)$' {
        private_area = 0
        image_file  = 1
    }

Values set in the default section are inherited into sections before
those sections are matched.

One solution is to use hashes, rather than declarations:

    private_area = 0
    image_file   = 0

    LocationMatch = {

        admin = {
            private_area = 1
        }

        '\.(gif)|(jpg)|(png)$' = {
            image_file  = 1
        }
    }

This works, because in C<Config::Scoped>, hashes do not inherit
parameters from their enclosing scope.

However, note that when two hashes with the same name collide, their
values are not merged together.  Instead, one hash replaces the other
hash.  See above under L<Limitations of hash merging with included files>.

=head2 lower_case_names also affects section names

If you use the lower_case_names option, be aware that it also affects
the names of declaration blocks.  For instance, the following
configuration,

    Location /FOO {
        Some_Param = 'Some Value'
    }

becomes:

    {
        'location' => {
            '/foo' => {
                'some param' => 'Some Value';
            }
        }
    }

Unless you expect this behaviour (which you probably don't), you should
probably avoid using the C<lower_case_names> option with C<Config::Scoped>.

=head2 _GLOBAL Scope automatically merged

Normally, if there are no declarations in a C<Config::Scope> file, all
configuration is placed under a key called C<_GLOBAL>.
C<Config::Context::ConfigScoped> detects this condition and moves the data
under C<_GLOBAL> up a level.  Basically, it does the equivalent of:

    $config = $config->{_GLOBAL};

The reason for this is to allow use of hashes instead of declarations to
enable default values.  See L<Limitations of hash merging with included files>,
above.

=head2 Quote block names

Instead of:

    LocationMatch \.*(jpg|gif|png)$ {
        # some configuration
    }

use:

    LocationMatch '\.*(jpg|gif|png)$' {
        # some configuration
    }

Note that regular expression characters don't have to be quoted beyond
this.

=head1 SEE ALSO

    Config::Context
    CGI::Application::Plugin::Config::Context
    Config::Scoped

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;




