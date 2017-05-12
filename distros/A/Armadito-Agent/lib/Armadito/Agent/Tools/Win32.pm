package Armadito::Agent::Tools::Win32;

use strict;
use warnings;
use base 'Exporter';
use utf8;
use Data::Dumper;

use Readonly;
Readonly my $KEY_WOW64_64 => 0x100;
Readonly my $KEY_WOW64_32 => 0x200;

sub KEY_WOW64_64 { return $KEY_WOW64_64 }
sub KEY_WOW64_32 { return $KEY_WOW64_32 }

use UNIVERSAL::require;
use English qw(-no_match_vars);
use File::Temp qw(:seekable tempfile);
use File::Basename qw(basename);
use File::Basename qw(basename);

BEGIN {
	if ( $OSNAME ne "MSWin32" ) {

		# Test ::Compile exception
		exit(0);
	}
}

use Win32::EventLog;
use Win32::OLE;
use Win32::OLE qw(in);
use Win32::TieRegistry (
	Delimiter   => '/',
	ArrayValues => 0,
	qw/KEY_READ/
);

our @EXPORT_OK = qw(
	getRegistryValue
	getRegistryKey
	getWMIObjects
);

Win32::OLE->Option( CP => Win32::OLE::CP_UTF8 );

sub getWMIObjects {
	my (%params) = @_;

	$params{moniker} = 'winmgmts:{impersonationLevel=impersonate,(security)}!//./';

	my $WMIService = Win32::OLE->GetObject( $params{moniker} )
		or return;    #die "WMI connection failed: " . Win32::OLE->LastError();

	my @objects;
	foreach my $instance ( in( $WMIService->InstancesOf( $params{class} ) ) ) {
		my $object;
		foreach my $property ( @{ $params{properties} } ) {
			if ( defined $instance->{$property} && !ref( $instance->{$property} ) ) {

				# string value
				$object->{$property} = $instance->{$property};

				# despite CP_UTF8 usage, Win32::OLE downgrades string to native
				# encoding, if possible, ie all characters have code <= 0x00FF:
				# http://code.activestate.com/lists/perl-win32-users/Win32::OLE::CP_UTF8/
				utf8::upgrade( $object->{$property} );
			}
			elsif ( defined $instance->{$property} ) {

				# list value
				$object->{$property} = $instance->{$property};
			}
			else {
				$object->{$property} = undef;
			}
		}
		push @objects, $object;
	}

	return @objects;
}

sub getRegistryValue {
	my (%params) = @_;

	my ( $root, $keyName, $valueName );
	if ( $params{path} =~ m{^(HKEY_\S+)/(.+)/([^/]+)} ) {
		$root      = $1;
		$keyName   = $2;
		$valueName = $3;
	}
	else {
		$params{logger}->error("Failed to parse '$params{path}'. Does it start with HKEY_?") if $params{logger};
		return;
	}

	my $key = _getRegistryKey(
		logger  => $params{logger},
		root    => $root,
		keyName => $keyName
	);

	return unless ( defined($key) );

	if ( $valueName eq '*' ) {
		my %ret;
		foreach ( keys %$key ) {
			s{^/}{};
			$ret{$_} = $params{withtype} ? [ $key->GetValue($_) ] : $key->{"/$_"};
		}
		return \%ret;
	}
	else {
		return $params{withtype} ? [ $key->GetValue($valueName) ] : $key->{"/$valueName"};
	}
}

sub getRegistryKey {
	my (%params) = @_;

	my ( $root, $keyName );
	if ( $params{path} =~ m{^(HKEY_\S+)/(.+)} ) {
		$root    = $1;
		$keyName = $2;
	}
	else {
		$params{logger}->error("Failed to parse '$params{path}'. Does it start with HKEY_?") if $params{logger};
		return;
	}

	return _getRegistryKey(
		logger  => $params{logger},
		root    => $root,
		keyName => $keyName
	);
}

sub _getRegistryKey {
	my (%params) = @_;

	## no critic (ProhibitBitwise)
	my $rootKey
		= is64bit()
		? $Registry->Open( $params{root}, { Access => KEY_READ | KEY_WOW64_64 } )
		: $Registry->Open( $params{root}, { Access => KEY_READ } );

	if ( !$rootKey ) {
		$params{logger}->error("Can't open $params{root} key: $EXTENDED_OS_ERROR") if $params{logger};
		return;
	}
	my $key = $rootKey->Open( $params{keyName} );

	return $key;
}

sub getUsersFromRegistry {
	my (%params) = @_;

	my $logger = $params{logger};

	# ensure native registry access, not the 32 bit view
	my $flags = is64bit() ? KEY_READ | KEY_WOW64_64 : KEY_READ;
	my $machKey = $Registry->Open(
		'LMachine',
		{
			Access => $flags
		}
	) or $logger->error("Can't open HKEY_LOCAL_MACHINE key: $EXTENDED_OS_ERROR");
	if ( !$machKey ) {
		$logger->error("getUsersFromRegistry() : Can't open HKEY_LOCAL_MACHINE key: $EXTENDED_OS_ERROR");
		return;
	}
	$logger->debug2('getUsersFromRegistry() : opened LMachine registry key');
	my $profileList = $machKey->{"SOFTWARE/Microsoft/Windows NT/CurrentVersion/ProfileList"};
	next unless $profileList;

	my $userList;
	foreach my $profileName ( keys %$profileList ) {
		$params{logger}->debug2( 'profileName : ' . $profileName );
		next unless $profileName =~ m{/$};
		next unless length($profileName) > 10;
		my $profilePath = $profileList->{$profileName}{'/ProfileImagePath'};
		my $sid         = $profileList->{$profileName}{'/Sid'};
		next unless $sid;
		next unless $profilePath;
		my $user = basename($profilePath);
		$userList->{$profileName} = $user;
	}

	if ( $params{logger} ) {
		$params{logger}->debug2( 'getUsersFromRegistry() : retrieved ' . scalar( keys %$userList ) . ' users' );
	}
	return $userList;
}

sub parseEventLog {
	my ($journal_name) = @_;

	my $recs;
	my $base;
	my $hashRef;
	my $handle = Win32::EventLog->new( $journal_name, $ENV{ComputerName} )
		or die "Can't open Application EventLog\n";
	$handle->GetNumber($recs)
		or die "Can't get number of EventLog records\n";
	$handle->GetOldest($base)
		or die "Can't get number of oldest EventLog record\n";

	my $x = 0;
	while ( $x < $recs ) {
		$handle->Read( EVENTLOG_FORWARDS_READ | EVENTLOG_SEEK_READ, $base + $x, $hashRef )
			or die "Can't read EventLog entry #$x\n";

		print Dumper($hashRef) . "\n";

		$x++;
	}
}

1;
__END__

=head1 NAME

Armadito::Agent::Tools::Win32 - Windows generic functions

=head1 DESCRIPTION

This module provides some Windows-specific generic functions.

=head1 FUNCTIONS

=head2 getWMIObjects(%params)

Returns the list of objects from given WMI class or from a query, with given
properties, properly encoded.

=over

=item moniker a WMI moniker (default: winmgmts:{impersonationLevel=impersonate,(security)}!//./)

=item class a WMI class, not used if query parameter is also given

=item properties a list of WMI properties

=item query a WMI request to execute, if specified, class parameter is not used

=item method an object method to call, in that case, you will also need the
following parameters:

=item params a list ref to the parameters to use fro the method. This list contains
string as key to other parameters defining the call. The key names should not
match any exiting parameter definition. Each parameter definition must be a list
of the type and default value.

=item binds a hash ref to the properties to bind to the returned object

=back

=head2 getRegistryValue(%params)

Returns a value from the registry.

=over

=item path a string in hive/key/value format

E.g: HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/ProductName

=item logger

=back

=head2 getRegistryKey(%params)

Returns a key from the registry. If key name is '*', all the keys of the path are returned as a hash reference.

=over

=item path a string in hive/key format

E.g: HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion

=item logger

=back
