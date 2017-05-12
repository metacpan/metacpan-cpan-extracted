use strict;
use warnings;

package Bot::Net::Config;

use File::Find::Rule;
use File::Spec;
use FindBin;
use Hash::Merge qw/ merge /;
use Readonly;
use YAML::Syck qw/ LoadFile DumpFile /;

=head1 NAME

Bot::Net::Config - the configuration for your bot net

=head1 SYNOPSIS

  my $config = Bot::Net->config;

  my $bot_config    = $config->bot('CopyBot');
  my $server_config = $config->server('MasterHost');

head1 DESCRIPTION

This module loads and stores the configuration for your bot net. The bot net configuration is typically stored in F<etc/config.yml> of your bot net application directory. However, you can have multiple configurations, which can be specified to the spawn command using the C<--config> option.

=head1 METHODS

=head2 new

You should not need to call this method directory. Instead:

  my $config = Bot::Net->config;

will call the constructor as needed.

=cut

sub new {
    my $class = shift;
    bless {}, $class;
}

sub _search_paths {
    my @paths = ( [ $FindBin::Bin, '..', 'etc' ] );

    if ($ENV{BOT_NET_CONFIG_PATH}) {
        my @env_paths = split /:/, $ENV{BOT_NET_CONFIG_PATH};
        unshift @paths, map { [ $_ ] } @env_paths;
    }

    return @paths;
}

sub _search_for_file {
    my @file_path = @_;

    for my $search_path (_search_paths()) {
        my $file_name = File::Spec->catfile(@$search_path, @file_path);
        return $file_name if -f $file_name;
    }

    return undef;
}

=head2 net [ KEY ]

The main configuration file for your L<Bot::Net> application is stored in F<etc/net.yml>. This returns a single value from that file if a C<KEY> is specified or returns the entire configuration if no key is given.

=cut

sub net {
    my $self = shift;
    my $key  = shift;

    $self->load_config('net') unless defined $self->{net};

    return defined $key ? $self->{net}{$key} : $self->{net};
}

=head2 net_file

Returns the path to the main configuration file for your L<Bot::Net> application, which is stored in F<etc/net.yml>.

=cut

sub net_file {
    my $self = shift;

    return _search_for_file('net.yml');
}

=head2 load_config TYPE NAME

Reloads one of the configuration files. You normally won't need to call this method, it will be called automatically.

=cut

sub load_config {
    my $self = shift;
    my $type = shift;
    my $name = shift;

    my $filename = $type eq 'net'    ? $self->net_file
                 : $type eq 'bot'    ? $self->bot_file($name)
                 : $type eq 'server' ? $self->server_file($name)
                 : die "I don't know how to load a $type config file.";

    my $config = LoadFile($filename);

    if ($type eq 'net') {
        $self->{$type} = $config;
    }
    else {
        $self->{$type}{$name} = $config;
    }
}

=head2 save_config

Saves a configuration file. This can be useful when making changes to the configuration from within a bot that you would liked saved for future use.

=cut

sub save_config {
    my $self = shift;
    my $type = shift;
    my $name = shift;

    my $config = $type eq 'net' ? $self->{$type}
               :                  $self->{$type}{$name}
               ;

    die "No configuration found for $type:$name."
        unless defined $config;

    my $filename = $type eq 'net'    ? $self->net_file
                 : $type eq 'bot'    ? $self->bot_file($name)
                 : $type eq 'server' ? $self->server_file($name)
                 : die "I don't know how to save a $type config file.";

    DumpFile($filename, $config);
}

=head2 server_file NAME

Returns the location of the configuration for the server named C<NAME>.

=cut

sub server_file {
    my $self = shift;
    my $name = shift;

    my @path = split /::/, $name;
    $path[ $#path ] .= '.yml';

    return _search_for_file('server', @path);
}

=head2 server NAME

Returns the configuration for the named server. 

=cut

sub server {
    my $self = shift;
    my $name = shift;

    $self->load_config( server => $name ) 
        unless defined $self->{server}{$name};

    return $self->{server}{$name};
}

=head2 bot_file NAME

Returns the location of the bot configuration file for the named bot.

=cut

sub bot_file {
    my $self = shift;
    my $name = shift;

    my @path = split /::/, $name;
    $path[ $#path ] .= '.yml';

    return _search_for_file('bot', @path);
}

=head2 bot NAME

Returns teh configuration for the named bot. This will include the default configuration and bot-specific overrides.

=cut

sub bot {
    my $self = shift;
    my $name = shift;

    $self->load_config( bot => $name ) 
        unless defined $self->{bot}{$name};

    return $self->{bot}{$name};
}

=head1 CONFIGURATION FILE LOCATIONS

=head2 CONFIGURATION DIRECTORIES

L<Bot::Net> will search for configuration files in the following places (and in the following order). The first file found according to this order will be used.

=over

=item 1.

If the environment variable C<BOT_NET_CONFIG_PATH> is set. It is assumed to be a list of one or more paths (separated by colons) containing the names of the directories to search for configuration files. The directories will be searched in the order given in the variable.

=item 2.

The program will look for the binary file (using L<FindBin>) that was executed (probably F<bin/botnet>) and find the F<etc> directory one level above the directory containing the script. For example, if you're running your bot net from F</home/sterling/MyNet/bin/botnet>, it would look in F</home/sterling/MyNet/etc> for your configuration files.

=back

=head2 CONFIGURATION FILES

Within the directory found, the files will be named as follows:

=head3 PRIMARY BOT NET CONFIGURATION

The F<net.yml> file must be found in this directory. 

=head3 SERVER CONFIGURATION

Server config files will be found in a subdirectory named F<server> and then subdirectories based upon the name of the server. 

For example, a server package named C<MyNet::Server::Foo::Bar::Master> would find it's configuration file under F<server/Foo/Bar/Master.yml>.

=head3 BOT CONFIGURATION

Bot configuration files are in the subdirectory named F<bot> and then subdirectories based upon the name of the bot. 

For example, a bot package named C<MyNet::Bot::Foo::Bar::ChanOp> would find it's configuration file under F<bot/Foo/Bar/ChanOp.yml>.

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
