package Aw::Adapter;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.3';

	use Aw;
}


sub new
{
my $class = shift;
my $version = "4.0.2-Perl";  # AW_VERSION.".0.2";


	unless ( $#_ ) {
		if ( ref ($_[0]) eq "ARRAY" ) {
			#
			# must be an array ref
			#
			unshift ( @{$_[0]}, "$0" );
			Aw::Adapter::_new ( $class, $version, $_[0] );
			#
		}
		else {
			#
			# must be a HASH
			#
			$version = ${$_[0]}{version} if ( ${$_[0]}{version} );
			if ( exists ${$_[0]}{configFile} ) {
				Aw::Adapter::_new ( $class, $version, _hashToArgs ( $_[0] ) );
			}
			else {
				Aw::Adapter::_new ( $class, $version, $_[0] );
			}
		}
	}
	else {
		unshift ( @_, "$0" );
		Aw::Adapter::_new ( $class, $version, \@_ );
	}

}



sub loadProperties
{
my $self = shift;

	if ( ref ($_[0]) ) {
		if ( ref ($_[0]) eq "ARRAY" ) {
			unshift ( @{$_[0]}, "$0" );
			$self->_loadProperties ( $_[0] );
		}
		else {
			if ( exists ${$_[0]}{configFile} ) {
				$self->_loadProperties ( _hashToArgs ( $_[0] ) );
			}
			else {
				$self->_loadProperties ( $_[0] );
			}
		}
	}
	else {
		unshift ( @_, "$0" );
		$self->_loadProperties ( \@_ );
	}

}


sub _hashToArgs
{
my $data = shift;
my @args = ();

	$args[0] = $0;
	$args[1] = $data->{clientId};
	           delete ( $data->{clientId} );
	$args[2] = $data->{broker};
	           delete ( $data->{broker} );
	$args[3] = $data->{adapterId};
	           delete ( $data->{adapterId} );
	$args[4] = $data->{configFile};
	           delete ( $data->{configFile} );

	my $i = 5;
	for my $key (keys %{$data}) {
		$args[$i++] = "$key=$data->{$key}";
	}

	\@args;
}


sub getStringSeqInfo
{
	my $result = Aw::Adapter::getStringSeqInfoRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCStringSeqInfoAsA
{
	my $result = Aw::Adapter::getUCStringSeqInfoAsARef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getUCStringSeqInfoAsUTF8
{
	my $result = Aw::Adapter::getUCStringSeqInfoAsUTF8Ref ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getStructSeqInfo
{
	my $result = Aw::Adapter::getStructSeqInfoRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getEventDefs
{
	my $result = Aw::Adapter::getEventDefsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub adapterType
{
	Aw::Adapter::getAdapterType ( @_ );
}



sub adapterVersion
{
	Aw::Adapter::getAdapterVerion ( @_ );
}



sub broker
{
	Aw::Adapter::getBroker ( @_ );
}



sub brokerClient
{
	Aw::Adapter::getBrokerClient ( @_ );
}



sub brokerName
{
	Aw::Adapter::getBrokerName ( @_ );
}



sub clientGroup
{
	Aw::Adapter::getClientGroup ( @_ );
}



sub clientId
{
	Aw::Adapter::getClientId ( @_ );
}



sub clientName
{
	Aw::Adapter::getClientName ( @_ );
}



sub eventDefs
{
	getEventDefs ( @_ );
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Adapter - ActiveWorks Adapter Module.

=head1 SYNOPSIS

require Aw::Adapter;

my $adapter = new Aw::Adapter;


=head1 DESCRIPTION

Enhanced interface for the Aw.xs Adapter methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wmUsers.Com|mailto:Yacob@wmUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
