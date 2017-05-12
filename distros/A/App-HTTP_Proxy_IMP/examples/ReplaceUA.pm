
use strict;
use warnings;
package ReplaceUA;
use base 'Net::IMP::HTTP::Request';
use fields qw(ua);

use Net::IMP;
use Net::IMP::Debug;

my $UA = 'Mozilla/5.0 (Windows NT 5.1; rv:10.0.2) Gecko/20100101 Firefox/10.0.20';

sub RTYPES { ( IMP_PASS,IMP_REPLACE ) }

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
    delete $cfg{ua};
    return $class->SUPER::validate_cfg(%cfg);
}

sub request_hdr {
    my ($self,$hdr) = @_;
    my $len = length($hdr) or return;
    $hdr =~s{^User-Agent:\s*(.*\n( .*\n)*)}{}sg;
    my $ua = $self->{factory_args}{ua} || $UA;
    $hdr =~s{\n}{\nUser-Agent: $ua\r\n}img;
    #warn $hdr;
    $self->run_callback( 
	[ IMP_REPLACE,0,$len,$hdr ],  # replace header
	[ IMP_PASS,0,IMP_MAXOFFSET ], # pass thru everything else
    );
}

# will not be called
sub request_body {}
sub response_hdr {}
sub response_body {}
sub any_data {}

1;

__END__

=head1 NAME

ReplaceUA - replace User-Agent in Request with fixed string

=head1 SYNOPSIS

    perl bin/http_proxy_imp --filter ReplaceUA=ua=Fake-User-Agent ip:port
