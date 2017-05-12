use strict;
use warnings;

package Bot::Net::Script::Net;
use base qw/ App::CLI::Command Class::Accessor::Fast /;

use Bot::Net;
use File::Basename;
use File::Copy;
use File::Path;
use File::Spec;
use FindBin;
use YAML::Syck qw/ DumpFile /;

__PACKAGE__->mk_accessors(qw/ prefix dist_name mod_name /);

=head1 NAME

Bot::Net::Script::Net - Create the scaffolding for a new bot net

=head1 SYNOPSIS

  bin/botnet net --name <bot net app name>

=head1 DESCRIPTION

This will create a folder named according to the C<--name> argument and fill it in with a skeleton L<Bot::Net> application.

=head1 METHODS

=head2 actions

Returns the arguments used by the this script. See L<App::CLI::Command>.

=cut

sub options {
    ( 'name=s' => 'name' );
}

=head2 run

Creates the bot net scaffoldering.

=cut

sub run {
    my ($self, @args) = @_;

    defined $self->{name}
        or die "No bot net name given with required --name option.\n";

    $self->prefix( $self->{name} );

    # Split by - or :: and DWIM
    my @path_comp = split /\-|::/, $self->prefix;
    $self->mod_name( join '::', @path_comp );
    $self->dist_name( join '-', @path_comp );

    print "Creating new application $self->{name}\n";
    $self->_make_directories;
    $self->_install_botnet_binary;
    $self->_write_makefile;
    $self->_write_config_file;
    $self->_create_log4perl_config_file;
}

sub _make_directories {
    my $self = shift;

    # Make the main directory
    print "Creating directories...\n";
    mkpath($self->dist_name, 1);

    my @lib_dirs = split /::/, $self->mod_name;
    my $lib_dir  = File::Spec->catfile(@lib_dirs);
    
    my @dirs = map { 
        s/__APP__/$lib_dir/; 
        File::Spec->catfile($self->dist_name, $_) 
    } $self->_directories;

    mkpath(\@dirs, 1);
}

sub _install_botnet_binary {
    my $self   = shift;
    my $bin    = $FindBin::Bin;
    my $script = basename($0);

    # Get ready to copy
    my $source_file = File::Spec->catfile($bin, $script);
    my $dest_file   = File::Spec->catfile($self->dist_name, 'bin', $script);

    # Copy and make it executable
    print "Copying in $dest_file...\n";
    copy($source_file, $dest_file);
    chmod 0555, $dest_file;

    # If on a DOSish platform make bat file too
    if (-e $source_file.'.bat') {
        print "Copying in $dest_file.bat...\n";
        copy($source_file.'.bat', $dest_file.'.bat');
        chmod 0555, $dest_file.'.bat';
    }
}

sub _write_makefile {
    my $self = shift;

    my $makefile = File::Spec->catfile($self->dist_name, 'Makefile.PL');

    print "Creating $makefile...\n";
    open my $makefh, '>', $makefile
        or die "Cannot write $makefile: $!";
    print $makefh <<"END_OF_MAKEFILE_PL";
use inc::Module::Install;

name     '@{[$self->mod_name]}';
version  '0.01';

requires 'Bot::Net' => '@{[$Bot::Net::VERSION]}';

WriteAll;
END_OF_MAKEFILE_PL
}

sub _write_config_file {
    my $self = shift;

    my $config_file = File::Spec->catfile($self->dist_name, 'etc/net.yml');

    print "Creating $config_file...\n";
    DumpFile($config_file, { 
        ApplicationClass => $self->mod_name,
        ApplicationName => $self->mod_name,
    });
}

sub _create_log4perl_config_file {
    my $self   = shift;
    my $bin    = $FindBin::Bin;

    # Get ready to create
    my $dest_file   = File::Spec->catfile(
        $self->dist_name, 'etc', 'log4perl.conf');
    open my $log4perl, '>', $dest_file 
        or die "Could not write to $dest_file: $!";

    print "Creating $dest_file...\n";
    print $log4perl <<'END_OF_LOG4PERL_CONF';
log4perl.rootLogger=DEBUG, SCREEN

log4perl.appender.SCREEN=Log::Log4perl::Appender::Screen
log4perl.appender.SCREEN.stderr=0

log4perl.appender.SCREEN.layout=PatternLayout
log4perl.appender.SCREEN.layout.ConversionPattern=[%d] %c - %m%n
END_OF_LOG4PERL_CONF
}

sub _directories {
    return qw{
        bin
        doc
        etc
        etc/bot
        etc/server
        lib/__APP__/Bot
        lib/__APP__/Server
        log
        t
        var/bot
        var/server
    };
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
