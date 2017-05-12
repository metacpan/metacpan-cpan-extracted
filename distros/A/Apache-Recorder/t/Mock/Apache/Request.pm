package Mock::Apache::Request;
use strict;
use CGI::Cookie;

sub new {
    my ( $class ) = shift;
    my ( $self ) = {};
    bless( $self, $class );
    $self->_init( @_ );
    return $self;
}

sub _init {
    my ( $self ) = shift;

    my ( %args ) = (@_);
    $self->{uc($_)} = $args{$_} foreach (keys %args);
}

sub header_in {
    my $self = shift;
    my $requested_param = shift;
    if ( $requested_param eq 'Cookie' ) {
	my $cookie = new CGI::Cookie(
	    -name=>'HTTPRecorderID',
	    -value=>$self->{ 'COOKIE_ID' } 
	    );
        return $cookie;
    }
    else {
        die "Mock::Apache::Request does not support $requested_param: $!";
    }
}

1;
__END__

=pod

=head1 NAME

Mock::Apache::Request -- mock Apache::Request class for testing

=head1 DESCRIPTION

Mock::Apache::Request imitates a real Apache::Request object just long enough to 
allow for a simple test during the installation of Apache::Recorder.

=head1 USAGE

my $cookie_id = '12345';

my $mock_r = new Mock::Apache:Request( 'cookie_id' => $cookie_id );

my $cookie = $mock_r->header_in( 'Cookie' );

use Data::Dumper;

print Dumper( $cookie );

=head1 AUTHOR

Chris Brooks <cbrooks@organiccodefarm.com>

=cut
