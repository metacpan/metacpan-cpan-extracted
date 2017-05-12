package CGI::Application::Plugin::Config::YAML;

use strict;
use warnings;
use vars qw($VERSION @EXPORT);
use CGI::Application;
use Config::YAML;

$VERSION = '0.01';

@EXPORT = qw(
    config_file
    config_param
    config
    config_fold
    config_read
    get_hash
);

sub import {
    my $pkg  = shift;
    my $call = caller;
    no strict 'refs';
    foreach my $sym (@EXPORT) {
        *{"${call}::$sym"} = \&{$sym};
    }
}

sub config_file {
    my $self = shift;
    my $file_name = shift;

    if ( defined $file_name ) {
        $self->{__CONFIG_YAML}->{__FILE_NAME} = $file_name;
        $self->{__CONFIG_YAML}->{__FILE_CHANGED} = 1;
    }
    else {
        $file_name = $self->{__CONFIG_YAML}->{__FILE_NAME};
    }

    if ( ! defined $file_name ) {
        $ENV{CGIAPP_CONFIG_FILE} =~ /(.*)/;
        $file_name = $1;
    }

    $file_name;
}

sub config_param {
    my $self = shift;
    my @params = @_;
    my $conf = $self->config();

    if ( scalar(@params) == 0 ) {
        return scalar($self->get_hash);
    }
    elsif ( scalar(@params) == 1 ) {
        return $conf->get($params[0]);
    }
    else {
        my %params = (@params);
        $conf->set($_ => $params{$_}) foreach (keys %params);
        if ( $conf->write ) {
            return;
        }
        else{
            die "Config-Plugin: Could not write to config file (" . $self->config_file . ")! ";
        }
    }
}

sub config_fold {
    my ($self, $data) = @_;
    my $conf = $self->config();
    $conf->fold($data);
    return;
}

sub config_read {
    my ($self, $file) = @_;
    my $conf = $self->config();
    $conf->read($file);
    return;
}

sub config {
    my $self = shift;
    my $create = !$self->{__CONFIG_YAML}->{__CONFIG_OBJ} || $self->{__CONFIG_YAML}->{__FILE_CHANGED};
    if ( $create ) {
        my $file_name = $self->config_file or die "No config file specified!";

        my $conf;
        eval{
            $conf = Config::YAML->new(config => $file_name);
        };

        die "Could not create Config::YAML object for file $file_name! $@" if $@;

        $self->{__CONFIG_YAML}->{__CONFIG_OBJ} = $conf;
        $self->{__CONFIG_YAML}->{__FILE_CHANGED} = 0;
    }

    return $self->{__CONFIG_YAML}->{__CONFIG_OBJ};
}

sub get_hash {
    my $self = shift;
    my $yaml;

    open(FH,'<',$self->config_file) or die "Can't open $self->config_file; $!\n";
    while (my $line = <FH>) {
        next if ($line =~ /^\-{3,}/);
        next if ($line =~ /^#/);
        next if ($line =~ /^$/);
        $yaml .= $line;
    }
    close(FH);

    my $tmpyaml = YAML::Load($yaml);
    return $tmpyaml;
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::Config::YAML - add Config::YAML support to CGI::Application

=head1 VERSION

This documentation refers to CGI::Application::Plugin::Config::YAML version 0.01

=head1 SYNOPSIS

    package My::App;
    
    use CGI::Application::Plugin::Config::YAML;
    
    sub cgiapp_init {
        my $self = shift;
        $self->config_file('ataris.yml');
    }
    
    sub myrunmode{
        my $self = shift;
    
        my $artist_name = $self->config_param('artist_name');
    
        $self->config_param(artist_name => 'ataris');
    
        my $new_artist_name = $self->config_param('artist_name');
    
        my %data = (cd => 'So Long, Astoria');
        $self->config_fold(\%data);
    
        my $cd = $self->config_param('cd');
    
        $self->config_read('U2.yml');
    
         .....
    }

=head1 DESCRIPTION

This plug-in add Config::YAML support to CGI::Application.
The usage of this plug-in is almost the same as CGI::Application::Plugin::Config::Simple.
This plug-in can be easily used instead of CGI::Application::Plugin::Config::Simple.
This plug-in refers to CGI::Application::Plugin::Config::Simple.

=head1 METHOD

=head2 config_file

 $self->config_file('ataris.yml');

YAML file is set.
$ENV{CGIAPP_CONFIG_FILE} is used if there is no args.

=head2 config_param

 my $name = $self->config_param('artist_name');

A corresponding value to the argument is returned. 

 my $config_hash = $self->config_param();

The entire config structure will be returned as a hash ref.

=head2 config

 $self->config;

This method will return the Config::YAML's object.
A new Config::YAML's object is made if there is a change in config_file.

=head2 config_fold

    my %data = (cd => 'So Long, Astoria');
    $self->config_fold(\%data);

Call Config::YAML::fold.

=head2 config_read

 $self->config_read('./U2.yml');

Call Config::YAML::read.

=head1 DEPENDENCIES

L<strict>

L<warnings>

L<CGI::Application>

L<Config::YAML>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 SEE ALSO

L<CGI::Application>

L<YAML>

L<Config::YAML>

L<CGI::Application::Plugin::Config::Simple>

=head1 Thanks TO

Michael Peters (CGI::Application::Plugin::Config::Simple's AUTHOR)

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut

