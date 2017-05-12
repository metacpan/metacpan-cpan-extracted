package Config::IniSearch;

use 5.006;
use strict;
use warnings;
use Cwd;
use Config::IniHash;

require Exporter;
our @ISA = qw( Exporter );

our $VERSION = '0.03'; 
our $GLOBAL_INI = "global.ini";

=head1 NAME

Config::IniSearch - Wrapper class for Config::IniHash to search for INI files

=head1 SYNOPSIS

    use Config::IniSearch;
    $config = new Config::IniSearch( 'inisection' );
    $val = $config->{param_name};

    use Config::IniSearch;
    $config = new Config::IniSearch( 'inisection', ['/usr/local/share/myfile.ini'] );
    $val = $config->{param_name};

=head1 DESCRIPTION

This module is intended to relieve the developer from having to keep
track of the location and name of individual INI files.  An INI file
will be recognized by one of two names:   

=over 4

=item inisection.ini

=item $GLOBAL_INI.ini

=back

Either/both of these must contain the section [inisection].

The following methods are available:

=over 4

=item $config = new Config::IniSearch( $INISectionName, [$INIFileName, %IniHashOpts] );

The constructor requires one argument, a section name,
$INISectionName.  Optional arguments include a fully-qualified INI
filename ($INIFileName)  and options for Config::IniHash (see perldoc
Config::IniHash).  NOTE:  By default, case is preserved.  

$INIFileName must be set if passing in options for
Config::IniHash.  The section name does not need to be specified when
accessing elements in $INISectionName:

$val = $config->{param_name};

When the constructor is invoked, the following list of defaults is
searched for the appropriate INI file:

=cut

sub new {
    my $class = shift;
    return undef if( $#_ < 0 );
    my $self = bless {}, $class;
    my $section = $self->{__section__} = shift;
    $self->{__iniFile__} = shift;
    my %iniHashOpts = @_;
    $iniHashOpts{case} = 'preserve' if( ! $iniHashOpts{case} );
    _searchDirs $self if( ! $self->{__iniFile__} );
    return undef if( ! $self->{__iniFile__} );
    my $config = ReadINI( $self->{__iniFile__}, %iniHashOpts );
    %$self = map { $_, $config->{$section}->{$_} } keys %{$config->{$section}};
    return $self;
}

=over 4

=item $INIFileName.ini

=item $cwd/$INISectionName.ini

=item $cwd/$GLOBAL_INI

=item scriptdir/$INISectionName.ini

=item scriptdir/$GLOBAL_INI

=item /etc/$INISectionName.ini

=item /etc/$GLOBAL_INI

Notice that the first INI file found will be the one used for
subsequent lookups.

=back

=cut

sub _searchDirs {
    my $self = shift;
    return undef if( ! $self );
    my $cwd = cwd();
    return $self->{__iniFile__} = "$cwd/$self->{__section__}.ini"
        if( -r "$cwd/$self->{__section__}.ini" );
    return $self->{__iniFile__} = "$cwd/$GLOBAL_INI"
        if( -r "$cwd/$GLOBAL_INI" );
    my $baseDir = _getBaseDir( $0 );
    return undef if( ! $baseDir );
    return $self->{__iniFile__} = "$baseDir/$self->{__section__}.ini"
        if( -r "$baseDir/$self->{__section__}.ini" );
    return $self->{__iniFile__} = "$baseDir/$GLOBAL_INI"
        if( -r "$baseDir/$GLOBAL_INI" );
    return $self->{__iniFile__} = "/etc/$self->{__section__}.ini"
        if( -r "/etc/$self->{__section__}.ini" );
    return $self->{__iniFile__} = "/etc/$GLOBAL_INI"
        if( -r "/etc/$GLOBAL_INI" );
    return undef;
}

sub _getBaseDir {
    $_ = shift;
    return "./" if( ! /\/+/ );
    /(.*)\/(.*)/;
    return $1;
}

=over 4

=item $inifile = $config->getINIFilename;

Returns the name of the INI file currently accessed by the object.

=cut

sub getINIFilename {
    my $self = shift;
    return $self->{__iniFile__};
}

=item $section_name = $config->getSectionName;

Returns the name of the INI section name currently accessed by
$config.

=cut

sub getSectionName {
    my $self = shift;
    return $self->{__section__};
}

=back

=head1 EXPORT

None by default.

=head1 AUTHOR

Brian Koontz <brian@pongonova.net>

=head1 COPYRIGHT

Copyright (c) 2003 Brian Koontz <brian@pongonova.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
