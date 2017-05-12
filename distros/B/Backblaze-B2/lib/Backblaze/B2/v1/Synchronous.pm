package Backblaze::B2::v1::Synchronous;
use strict;
use vars qw($AUTOLOAD $VERSION);
use Carp qw(croak);

$VERSION = '0.02';

sub isAsync { 0 }
sub api { $_[0]->{api} }
sub asyncApi { $_[0]->api }

=head1 METHODS

=head2 C<< ->new >>

Creates a new synchronous instance.

=cut

sub new {
    my( $class, %options ) = @_;
    
    require Backblaze::B2;

    $options{ api_base } //= $Backblaze::B2::v1::API_BASE
                           = $Backblaze::B2::v1::API_BASE;
    
    $options{ api } ||= do {
        require Backblaze::B2::v1::AnyEvent;
        Backblaze::B2::v1::AnyEvent->new(
            api_base => $Backblaze::B2::v1::API_BASE,
            %options
        );
    };
    
    bless \%options => $class;
}

sub read_credentials {
    my( $self, @args ) = @_;
    $self->api->read_credentials(@args)
}

sub downloadUrl { $_[0]->api->downloadUrl };
sub apiUrl { $_[0]->api->apiUrl };

sub await($) {
    my $promise = $_[0];
    my @res;
    if( $promise->is_unfulfilled ) {
        require AnyEvent;
        my $await = AnyEvent->condvar;
        $promise->then(sub{ $await->send(@_)});
        @res = $await->recv;
    } else {
        @res = @{ $promise->result }
    }
    @res
};

sub AUTOLOAD {
    my( $self, @arguments ) = @_;
    $AUTOLOAD =~ /::([^:]+)$/
        or croak "Invalid method name '$AUTOLOAD' called";
    my $method = $1;
    $self->api->can( $method )
        or croak "Unknown method '$method' called on $self";

    # Install the subroutine for caching
    my $namespace = ref $self;
    no strict 'refs';
    my $new_method = *{"$namespace\::$method"} = sub {
        my $self = shift;
        warn "In <$namespace\::$method>";
        my( $ok, $msg, @results) = await $self->api->$method( @_ );
        if( ! $ok ) {
            croak $msg;
        } else {
            return wantarray ? @results : $results[0]
        };
    };

    # Invoke the newly installed method
    goto &$new_method;
};

1;