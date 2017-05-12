use strict;
use warnings;
package App::HTTP_Proxy_IMP::Debug;
use Time::HiRes 'gettimeofday';

# let Net::Inspect::Debug output via local _out function
use Net::Inspect::Debug 
    output => \&_out, 
    qw($DEBUG $DEBUG_RX);

my @context;
{
    package App::HTTP_Proxy_IMP::Debug::Context;
    sub new { return bless {},shift };
    sub DESTROY { pop @context }
}

sub debug {
    if (@context) {
	my $msg = shift;
	$msg = do { no warnings; sprintf($msg,@_) } if @_;
	my %args;
	%args = ( %args, @$_ ) for(@context);
	if ( my $id = delete $args{id} ) {
	    $msg = "$id $msg";
	}
	$msg .= " $_=$args{$_}" for( sort keys %args );
	@_ = $msg;
    }
    goto &Net::Inspect::Debug::debug;
}

sub debug_context { 
    push @context, \@_;
    App::HTTP_Proxy_IMP::Debug::Context->new;
}


# let Net::IMP::Debug use debugging from Net::Inspect::Debug
use Net::IMP::Debug 
    var => \$DEBUG, 
    sub => \&debug;

# re-export $DEBUG debug $DEBUG_RX we got from Net::Inspect::Debug
use base 'Exporter';
our @EXPORT = qw($DEBUG debug);
our @EXPORT_OK = qw($DEBUG_RX debug_context);

# local output 
sub _out {
    my ($prefix,$msg) = @_;
    $msg =~s{\n}{\n | }g;  # prefix continuation lines
    $msg =~s{(\\|[^[:print:][:space:]])}{ sprintf("\\%03o",ord($1)) }esg;
    printf STDERR "%.2f %s %s\n", 0+gettimeofday(), $prefix,$msg;
}

1;
