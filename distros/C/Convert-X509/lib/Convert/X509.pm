package Convert::X509;

=head1 NAME

Convert::X509 - interface module to help analizing X509 data

=cut

require Convert::X509::CRL;
require Convert::X509::Certificate;
require Convert::X509::Request;

use strict;
use warnings;
use Convert::X509::Parser;

our $VERSION = '0.3';

my $SubClasses = {
	'Certificate' => {
		'asn'=>'CERT',
		'cdp'=>'2.5.29.31',
		'methods'=>{ map{ $_ => undef }
			qw(subject issuer from to serial eku keyusage cdp expired)
		},
	},
	'Request' => {
		'asn'=>'REQ',
		'methods'=>{ map{ $_ => undef }
			qw(subject eku keyusage)
		},
	},
	'CRL' => {
		'asn'=>'CRL',
		'cdp'=>'1.3.6.1.4.1.311.21.14',
		'methods'=>{ map{ $_ => undef }
			qw(issuer from to serial cdp expired)
		},
	}
};

sub new
{
	my ($ClassName, $pdata, $SubClass, $debug) = @_;
	return undef unless ref($pdata) eq 'SCALAR';
	return undef unless $$pdata;
	my $Self = {};
	Convert::X509::Parser::_prepare($pdata, $debug);
	unless ($$pdata){
		warn ("BASE64 preparing error\n") if $debug;
		return undef;
	}
	$SubClass =~ s/^.+\:\://; # Convert::X509::SubClass
	$SubClass = $SubClasses->{$SubClass}{'asn'} || 'Any';
	$Self->{'data'} = Convert::X509::Parser::_decode($SubClass=>$$pdata);
	unless ($Self->{'data'}){
		warn ($SubClass, " decoding error\n") if $debug;
		return undef;
	}
	return bless($Self, $ClassName);
} 

sub subject {
	return NotImplemented($_[0]) unless Check($_[0]);
	my $self = shift;
	my %subj = Convert::X509::Parser::_rdn2hash($self->{'subject'},@_);
	return (wantarray ?
	 map { my $k=$_; map {$k . '=' . $_} @{$subj{$_}} } sort keys %subj
	 :
	 \%subj);
}

sub issuer {
	return NotImplemented($_[0]) unless Check($_[0]);
	my $self = shift;
	my %subj = Convert::X509::Parser::_rdn2hash($self->{'issuer'},@_);
	return (wantarray ?
	 map { my $k=$_; map {$k . '=' . $_} @{$subj{$_}} } sort keys %subj
	 :
	 \%subj);
}

sub serial {
	return NotImplemented($_[0]) unless Check($_[0]);
	return $_[0]->{'serial'};
}

sub eku {
	return NotImplemented($_[0]) unless Check($_[0]);
	return Convert::X509::Parser::_eku($_[0]);
}

sub keyusage {
	return NotImplemented($_[0]) unless Check($_[0]);
	return Convert::X509::Parser::_keyusage($_[0]);
}

sub localize {
	my ($self,$pair,$cp1,$cp2) = @_;
	# data-type pair {type=>data}, CodePage from/to
	return ($pair ? Convert::X509::Parser::_localize($pair,$cp1,$cp2) : undef);
}

sub from {
	return NotImplemented($_[0]) unless Check($_[0]);
	return Convert::X509::Parser::_ansi_now($_[0]->{'from'}{'utcTime'});
}

sub to {
	return NotImplemented($_[0]) unless Check($_[0]);
	return Convert::X509::Parser::_ansi_now($_[0]->{'to'}{'utcTime'});
}

sub expired {
	return NotImplemented($_[0]) unless Check($_[0]);
	return (
	 $_[0]->{'to'}{'utcTime'} < time() or $_[0]->{'from'}{'utcTime'} > time()
	);
}

sub cdp {
	return NotImplemented($_[0]) unless Check($_[0]);
	(my $SubClass = ref($_[0])) =~ s/^.+\:\://;
	my $cdpext = $SubClasses->{$SubClass}{'cdp'};
	return (
	exists $_[0]->{'extensions'}{$cdpext} ?
	 map {values %$_}
	 @{ $_[0]->{'extensions'}{$cdpext}{'value'}[0]{'distributionPoint'}{'fullName'} }
	: undef
	);
}

sub NotImplemented {
	my (undef,$code,$line,$method) = caller(1);
	warn ( "Method $method called at line $line of script $code",
		' is not implemented for class ', ref($_[0]), "\n");
	return undef;
}

sub Check {
	( my $SubClass = ref($_[0]) ) =~ s/^.+\:\://;
	( my $method = ( caller(1) )[3] ) =~ s/^.+\:\://;
	return 
		exists $SubClasses->{$SubClass}{'methods'}{$method};
}

sub oid2txt {
	shift;
	return Convert::X509::Parser::_oid2txt(@_);
}

1;
