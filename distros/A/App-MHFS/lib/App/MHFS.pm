package App::MHFS v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Getopt::Long qw(GetOptions);
use MHFS::HTTP::Server;
Getopt::Long::Configure qw(gnu_getopt);
our $VERSION;

our $USAGE = "Usage: $0 ".<<'END_USAGE';
[-h|--help] [-v|--version] [--flush] [--cfgdir <directory>] [--appdir <directory>]
  [--fallback_data_root <directory>]
Media Http File Server - Stream your own music and video library via your
browser and standard media players.

All options are optional, provided to override settings.pl and defaults
--flush               turn on autoflush for STDOUT and STDERR
--cfgdir              location of configuration directory, will be created if
  it does not exist
--appdir              location of application static files
--fallback_data_root  location to fallback to if setting isn't found instead of
  $HOME or $APPDIR\mhfs
-h|--help             print this message
-v|--version          print version
END_USAGE

sub run {
    binmode(STDOUT, ":utf8");
    binmode(STDERR, ":utf8");

    # parse command line args into launchsettings
    my %launchsettings;
    my ($flush, $cfgdir, $fallback_data_root, $appdir, $help, $versionflag, $debug);
    if(!GetOptions(
        'flush' => \$flush,
        'cfgdir=s' => \$cfgdir,
        'fallback_data_root=s' => \$fallback_data_root,
        'appdir=s' => \$appdir,
        'help|h' =>\$help,
        'version|v' => \$versionflag,
        'debug|d' => \$debug,
    )) {
        print STDERR "$0: Invalid param\n";
        print STDERR $USAGE;
        exit(1);
    }

    if($help) {
        print $USAGE;
        exit 0;
    }
    elsif($versionflag) {
        print __PACKAGE__." $VERSION";
        exit 0;
    }
    say __PACKAGE__ .": parsed command line args";

    $launchsettings{flush} = $flush if($flush);
    $launchsettings{CFGDIR} = $cfgdir if($cfgdir);
    $launchsettings{FALLBACK_DATA_ROOT} = $fallback_data_root if($fallback_data_root);
    $launchsettings{APPDIR} = $appdir if($appdir);
    $launchsettings{debug} = $debug if ($debug);

    # start the server (blocks)
    say __PACKAGE__.": starting MHFS::HTTP::Server";
    my $server = MHFS::HTTP::Server->new(\%launchsettings,
    ['MHFS::Plugin::MusicLibrary',
    'MHFS::Plugin::GetVideo',
    'MHFS::Plugin::VideoLibrary',
    'MHFS::Plugin::Youtube',
    'MHFS::Plugin::BitTorrent::Tracker',
    'MHFS::Plugin::OpenDirectory',
    'MHFS::Plugin::Playlist',
    'MHFS::Plugin::Kodi',
    'MHFS::Plugin::BitTorrent::Client::Interface'],
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::MHFS - A Media HTTP File Server. Stream your own music and video
library via your browser and standard media players.

=head1 SYNOPSIS

    use App::MHFS;
    App::MHFS->run;

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc App::MHFS

Additional documentation, support, and bug reports can be found at the
MHFS repository L<https://github.com/G4Vi/MHFS>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
