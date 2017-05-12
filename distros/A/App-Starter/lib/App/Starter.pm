package App::Starter;

use warnings;
use strict;
use File::Find;
use File::Spec;
use File::Path;
use Cwd;
use Data::Dumper;
use YAML::Syck;
use Template;
use IO::All;
use base qw/Class::Accessor/;

our $VERSION = '0.13';

my $DIR = {};

__PACKAGE__->mk_accessors(
    qw/config name from replace ignore tag_style template/);

sub create {
    my $self = shift;

    # get config
    my $config = {};
    $config->{replace} = $self->{replace} ? $self->{replace} : {};
    $config->{ignore}  = $self->{ignore}  ? $self->{ignore}  : [];
    $config->{from}      = $self->{from}      if $self->{from};
    $config->{name}      = $self->{name}      if $self->{name};
    $config->{tag_style} = $self->{tag_style} if $self->{tag_style};
    $config->{template}  = $self->{template}  if $self->{template};

    if ( $config->{template} ) {
        $config->{from}
            = File::Spec->catfile( $ENV{HOME}, '/.app-starter/skel',
            $config->{template} );

        my $conf_file = '';
        if (-e File::Spec->catfile(
                $ENV{HOME}, '/.app-starter/conf',
                $config->{template} . '.yml'
            )
            )
        {
            $conf_file
                = File::Spec->catfile( $ENV{HOME}, '/.app-starter/conf',
                $config->{template} . '.yml' );
        }
        else {
            $conf_file
                = File::Spec->catfile( $ENV{HOME}, '/.app-starter/conf',
                $config->{template} . '.yaml' );
        }

        $self->{config} = $conf_file;
    }

    if ( $self->{config} ) {
        my $config_from_file = LoadFile( $self->{config} );
        %$config = ( %$config_from_file, %$config );

        $config->{replace}
            = { %{ $config_from_file->{replace} }, %{ $config->{replace} } }
            if $config_from_file->{replace};

        push @{ $config->{ignore} }, @{ $config_from_file->{ignore} }
            if $config_from_file->{ignore};
    }

    my $to        = getcwd;
    my $from      = $config->{from};
    my $name      = $config->{name};
    my $tag_style = $config->{tag_style} || 'template';

    # check
    die 'you must set [from]' unless $from;
    die 'you must set [name]' unless $name;

    if ( -e File::Spec->catfile( $to, $name ) ) {
        die File::Spec->catfile( $to, $name ) . 'is already exist';
    }

    # load tree
    find( sub { $self->_wanted( $from, $config->{ignore} ) }, $from );

    # create directory
    mkpath( File::Spec->catfile( $to, $name ) );
    for my $dir ( @{ $self->{dirs} } ) {
        $dir = File::Spec->catfile( $to, $name, $dir );
        foreach my $key ( keys %{ $config->{replace} } ) {
            $dir =~ s/__$key\__/$config->{replace}{$key}/g;
        }
        mkpath($dir);
    }

    # create files
    my $template
        = Template->new( { INCLUDE_PATH => $from, TAG_STYLE => $tag_style } );
    for my $file ( @{ $self->{files} } ) {
        my $to_file = $file;

        foreach my $key ( keys %{ $config->{replace} } ) {
            $to_file =~ s/__$key\__/$config->{replace}{$key}/g;
        }
        $to_file = File::Spec->catfile( $to, $name, $to_file );
        my $content;
        $template->process( $file, $config->{replace}, \$content );
        $content > io($to_file);
    }

}

sub _wanted {
    my $self   = shift;
    my $from   = shift;
    my $ignore = shift || [];

    return if $_ eq '.';

    my $name = $File::Find::name;

    for my $regexp ( @{$ignore} ) {
        if ( $name =~ /$regexp/ ) {
            return;
        }
    }

    if ( -d $name ) {
        $name =~ s/$from//;
        $name =~ s{^/}{};
        push @{ $self->{dirs} }, $name;
    }
    else {
        $name =~ s/$from//;
        $name =~ s{^/}{};
        push @{ $self->{files} }, $name;
    }

}

1;

=head1 NAME

App::Starter - Application Starter

=head1 SYNOPSIS

    my $app
        = App::Starter->new(
        { config => ' /tmp/conf/config.yml' } )
        ->create;
    
    # or
    # from = 'tmp/a' , replace => { module => 'MyApp' } overwrite config.yml setting.
    my $app = App::Starter->new(
        {   config  => '/tmp/conf/config.yml',
            from    => '/tmp/a',
            name    => 'my_app',
            replace => { module => 'MyApp' }
        }
    )->create;
    
    # or even you can use ~/.app-sterter so taht you do not need to hve from and config options
    
    #~/.app-starter
    #|-- conf
    #|   `-- sample.conf
    #`-- skel
    #    `-- sample
    #        |-- bin
    #        |   `-- __app__.pl
    #        `-- lib
    #            `-- __app__
    #                `-- Foo.pm
    my $app
        = App::Starter->new( { template => 'sample', name => 'foo' } )->create;

=head1 DESCRIPTION

you can start your application quickly once you create skeleton with this module. This module only does is rename key to value. in your template file, you can set like this  [% key_name %]
which replace with value you set in config. and also you can use __key_name__ format as file or directory name which replace as rule you set at config

I recommend to use ~/.app-starter directory to store your app-starter data

=head1 CONFIG

 name    : my_app  # ${current_dir}/my_app is created as new appication skeleton
 from    : /foo/bar/my-skell # where to fine your skel setup. if you use ~/.app-starter then you do not need this.
 tag_style : star # SEE ALSO L<Template> TAG_STYLE OPTION
 ignore  :   # you want to ignore some of files or directories
    - \.svn
    - \.cvs
 replace :   # rule for replace key : value
    module : MyApp

=head1 METHODS

=head2 new

constructor

=head2 create

create starter dir

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

dann

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Tomohiro Teranishi, All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  See L<perlartistic>.

=cut
