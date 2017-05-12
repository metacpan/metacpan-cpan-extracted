
use strict;
use warnings;
package DelayRequest;
use base 'Net::IMP::HTTP::Request';
use fields qw(delayed);

use Net::IMP;
use Net::IMP::HTTP;
use Net::IMP::Debug;
use Scalar::Util 'weaken';

sub RTYPES { ( IMP_PASS ) }

sub new_analyzer {
    my ($class,%args) = @_;
    my $self = $class->SUPER::new_analyzer(%args);
    $self->run_callback(
	# we don't need to look at response
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
    return $self;
}

sub validate_cfg {
    my ($class,%cfg) = @_;
    delete $cfg{delay};
    return $class->SUPER::validate_cfg(%cfg);
}

sub data {
    my ($self,$dir,$data,$offset,$type) = @_;
    if ( $dir == 0                             # request
	&& $type == IMP_DATA_HTTPRQ_HEADER     # header
	&& $data =~m{\AGET ((http://[^/]+/)[^\s]*)}
    ) {
	if(0) {
	    my ($base,$path) = ($2,$1);
	    if (
		$data =~m{^Referer:\s*\Q$base}mi       # same origin
		|| $data =~m{^Referer:\s*https?://}mi  # at least from another site
	    ) {
		# no delay
		$self->run_callback([ IMP_PASS,0,IMP_MAXOFFSET ]);
		return;
	    }
	}

	weaken(my $wself = $self);
	$self->{delayed} = $self->{factory_args}{eventlib}->timer(
	    $self->{factory_args}{delay} || 0.5,
	    sub {
		# pass thru everything 
		$wself or return;
		$wself->{delayed} = undef;
		$wself->run_callback([ IMP_PASS,0,IMP_MAXOFFSET ]);
	    }
	);
    }
}

1;

__END__

=head1 NAME

DelayRequest - delays sending of request 

=head1 SYNOPSIS

   perl bin/http_proxy_imp --filter DelayRequest=delay=0.5 ip:port
