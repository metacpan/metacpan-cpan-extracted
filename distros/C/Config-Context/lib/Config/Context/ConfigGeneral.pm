package Config::Context::ConfigGeneral;

use warnings;
use strict;

use Carp;
use Cwd;

=head1 NAME

Config::Context::ConfigGeneral - Use Config::General (Apache-style) config files with Config::Context

=head1 SYNOPSIS

    use Config::Context;

    my $config_text = '

        <Location /users>
            title = "User Area"
        </Location>

        <LocationMatch \.*(jpg|gif|png)$>
            image_file = 1
        </LocationMatch>

    ';

    my $conf = Config::Context->new(
        string        => $config_text,
        driver        => 'ConfigGeneral',
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

    my %config = $conf->getall_matching('/users/~biff/images/flaming_logo.gif');
    print Dumper(\%config);
    --------
    $VAR1 = {
        'title'         => 'User Area',
        'image_file'    => 1,
    };

=head1 DESCRIPTION

This module uses C<Config::General> to parse Apache-style config files for
C<Config::Context>.  See the C<Config::Context> docs for more information.

=head1 DEFAULT OPTIONS

In addition to the options normally enabled by Config::Scoped, the
following options are turned on by default:

    -MergeDuplicateBlocks  => 1
    -MergeDuplicateOptions => 1
    -IncludeRelative       => 1

You can change this behaviour by passing a different value to
C<driver_params> to C<new>:

    my $conf = Config::Context->new(
        driver => 'ConfigGeneral',
        driver_options => {
           ConfigGeneral = > {
               -MergeDuplicateBlocks  => 0,
           },
        },
    );


=head1 CONSTRUCTOR

=head2 new(...)

    my $driver = Config::Context::ConfigGeneral->new(
        file             => $config_file,
        lower_case_names => 1,  # optional
        options          => {
            # ...
        }
    );

or:

    my $driver = Config::Context::ConfigGeneral->new(
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

    my %driver_opts = %{ $args{'options'}{'ConfigGeneral'} || {} };

    $driver_opts{'-MergeDuplicateBlocks'} = 1
        unless defined $driver_opts{'-MergeDuplicateBlocks'};

    $driver_opts{'-MergeDuplicateOptions'} = 1
        unless defined $driver_opts{'-MergeDuplicateOptions'};

    $driver_opts{'-IncludeRelative'} = 1
        unless defined $driver_opts{'-IncludeRelative'};


    $driver_opts{'-LowerCaseNames'} = $args{'lower_case_names'};

    my $self = {};

    if ($args{'string'}) {
        local $^W; # suppress 'uninitialized value' warnings from within Config::General

        $self->{'conf'} = Config::General->new(
            %driver_opts,
            -String  => $args{'string'},
        );
    }
    elsif($args{'file'}) {
        local $^W; # suppress 'uninitialized value' warnings from within Config::General

        $self->{'conf'} = Config::General->new(
            %driver_opts,
            -ConfigFile => $args{'file'},
        );
        $self->{'file'} = $args{'file'};
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
    my $self = shift;
    my %config = $self->{'conf'}->getall;
    return %config if wantarray;
    return \%config;
}

=head2 files()

Returns a list of all the config files read, including any config files
included in the main file.

=cut

sub files {
    my $self = shift;

    my @files;
    if ($self->{'conf'}->can('files')) {
        @files = $self->{'conf'}->files;
    }
    elsif (exists $self->{'file'}) {
        @files = ($self->{'file'});
    }

    @files = map { Cwd::abs_path($_) } @files;

    return @files if wantarray;
    return \@files;
}

=head2 config_modules

Returns the modules used to parse the config.  In this case: C<Config::General>

=cut

sub config_modules {
    'Config::General';
}

=head1 CAVEATS

=head2 Don't quote block names

Instead of:

    <Location '/foo'>
    </Location>

Use:

    <Location /foo>
    </Location>

=head1 SEE ALSO

    Config::Context
    CGI::Application::Plugin::Config::Context
    Config::General

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;




