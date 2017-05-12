use strict;
use warnings;

package App::PM::Website::Command::Init;
{
  $App::PM::Website::Command::Init::VERSION = '0.131611';
}
use base 'App::PM::Website::Command';
use YAML::Any;
use File::Spec;
use File::Path 2.07 qw(make_path);
use Data::Dumper;

#ABSTRACT: create skeleton config/pm-website.yaml

sub options
{
    my ($class, $app) = @_;

    return (
        [   'username' => 'pm.org username',
            { default => 'USERNAME' }
        ],
        [   'groupname' => 'long city name of monger group',
            { default => 'GROUPNAME' }
        ],
    );
    return
}

sub validate
{
    my ($self, $opt, $args ) = @_;
    die $self->usage_error( "no arguments allowed") if @$args;

    return 1;
}

sub _create_config_dir
{
    my ( $self, $opt, $config_file) = @_;
    # get path from $config_file, check that path exists as directory
    {
#TODO: use File::Basename, File::Dirname
        my ( $volume, $directories, $file )
            = File::Spec->splitpath($config_file);
        my $config_dir = File::Spec->catpath( $volume, $directories );
        if ( !-d $config_dir )
        {
            die "config_dir: $config_dir exists and is not a dir"
                if -e $config_dir;
            print "creating config directory: $config_dir\n"
                if $opt->{verbose};
            make_path($config_dir);
        }
    }
}

sub _create_config_file
{
    my ( $self, $opt, $config_file ) = @_;
    open my $config_fh, '>', $config_file
        or die "failed to open config_file:$config_file for writing: $!";
    my $groupname = $opt->groupname;
    my $username  = $opt->username;
    my $yaml      = <<"EOYAML";
---
config:
  website:
    certificate: cacert.pem
    machine: groups.pm.org
    url: https://groups.pm.org/groups/$groupname/
    username: $username
    template_dir:
    build_dir:
location:
  default:
    address:
    name:
    url:
presenter:
  default:
    cpan: cpan username
    description:
    github: github username
    name:
    url:
meetings:
  - event_date: 2012/06/14
    location: default
    open_call: 1
    presentations:
      - abstract: 'our first talk will be about #winning'
        presenter: default
        title: first
      - abstract: our first talk will be about App::PM::Website
        presenter: default
        title: second talk
EOYAML
    print $config_fh $yaml;
    close $config_fh;
    print "creating new config file: $config_file\n";
}

sub validate_config
{
    my ( $self, $opt, $args ) = @_;
    my $config_file = $opt->{config_file};
    if ( !-e $config_file )
    {
        $self->_create_config_dir( $opt, $config_file );
        $self->_create_config_file( $opt, $config_file );
    }
    else
    {
        print "config file already exists: $config_file\n";
    }
}

sub execute
{
    my( $self, $opt, $args ) = @_;

    $self->{config}
}

__PACKAGE__

__END__
=pod

=head1 NAME

App::PM::Website::Command::Init - create skeleton config/pm-website.yaml

=head1 VERSION

version 0.131611

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

