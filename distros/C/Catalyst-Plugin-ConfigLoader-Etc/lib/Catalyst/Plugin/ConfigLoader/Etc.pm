package Catalyst::Plugin::ConfigLoader::Etc;
use strict;
use warnings;
use base qw/Catalyst::Plugin::ConfigLoader/;
use Config::Any;
use Catalyst::Utils;
use DirHandle;
use NEXT;

our $VERSION = 0.02;

=head1 NAME

Catalyst::Plugin::ConfigLoader::Etc - Load etc config files

=head1 SYNOPSIS

    package MyApp;

    use Catalyst qw/ConfigLoader::Etc/;

    __PACKAGE__->config(
        'Plugin::ConfigLoader::Etc' => {
            files => [
                "$FindBin::Bin/etc/conf/test1.yml",
            ]
        }
    );

  In the file, assuming it's in YAML format:

    foo: bar

  Accessible through the context object, or the class itself

   $c->config->{foo}    # bar
   MyApp->config->{foo} # bar

=head1 DESCRIPTION

config via env, for instance, $ENV{APPNAME_CONFIG_ETC} = "$FindBin::Bin/etc/conf/local.yml";
config('Plugin::ConfigLoader::Etc' => { files => [ '/path/to/config_file', '/path/to/xx_config' ] }


=head1 METHODS

=head2 find_files

This method determines the potential file paths to be used for config loading
It returns an array of paths (up to the filename less the extension),
It is then passed to  L<Catalyst::Plugin::ConfigLoader> for actual configuration loading and processing.

=cut

sub find_files {
    my $c = shift;
    my ( $path, $extension ) = $c->get_config_path;
    my $suffix     = $c->get_config_local_suffix;
    my @extensions = @{ Config::Any->extensions };

    my $prefix = Catalyst::Utils::appprefix( ref $c || $c );
    my $config_key_name = uc($prefix) . '_CONFIG_ETC';

    my @files;
    if ( $extension ) {
        die "Unable to handle files with the extension '${extension}'"
            unless grep { $_ eq $extension } @extensions;
        ( my $local = $path ) =~ s{\.$extension}{_$suffix.$extension};
        push @files, $path, $local;
    }
    else {
        # do not append lcoal suffix
        if ($ENV{ $config_key_name } ) {
            @files = map { ( "$path.$_" ) } @extensions;
        }
        else {
            @files = map { ( "$path.$_", "${path}_${suffix}.$_" ) } @extensions;
        }
    }

    my @etc_files = $c->_find_etc_files( $config_key_name );

    return @etc_files, @files;
}

=head2 _find_etc_files

Loading custom config files

=cut

sub _find_etc_files {
    my $c       = shift;
    my $cfg_key = shift;

    my @etc_files;
    push @etc_files , $ENV{$cfg_key} if $ENV{$cfg_key};

    my $config = $c->config->{'Plugin::ConfigLoader::Etc'};

    return @etc_files unless ref $config eq 'HASH' and
                             ref $config->{files} eq 'ARRAY';

    push @etc_files, $_ for @{ $config->{files} };

    return @etc_files;
}

=head1 AUTHOR

zdk (Warachet Samtalee), C<< <zdk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 zdk (Warachet Samtalee), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

If you'd like to use it under a different license, that's probably OK.
Please contact the author.

=cut


1; #End of Plugin::ConfigLoader::Etc
