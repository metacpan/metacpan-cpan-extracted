package Test::Rest;

use Moose;
use namespace::autoclean;

use LWP::UserAgent;
use Params::Validate qw(:all);

sub new {
    my $self = shift;
    my %p    = validate( @_, { 
            content_type => { type => SCALAR }, 
        }, 
    );
    my $ref  = {
        'ua'           => LWP::UserAgent->new,
        'content_type' => $p{'content_type'},
    };
    bless $ref, $self;
}

{
    my @non_data_methods = qw(HEAD GET DELETE OPTIONS);
    foreach my $method (@non_data_methods) {
        no strict 'refs';
        my $sub = lc($method);
        *$sub = sub {
            my $self = shift;
            my %p = validate(
                @_,
                {
                    url     => { type => SCALAR },
                    headers => { type => HASHREF, default => {} },
                },
            );
            my $req  = HTTP::Request->new( "$method" => $p{'url'} );
            $req->header( $_ => $p{headers}{$_} ) for keys %{ $p{headers} };
            $req->content_type( $self->{'content_type'} );
            return $req;
        };
    }

    my @data_methods = qw(PUT POST);
    foreach my $method (@data_methods) {
        no strict 'refs';
        my $sub = lc($method);
        *{$sub} = sub {
            my $self = shift;
            my %p    = validate(
                @_,
                {
                    url  => { type => SCALAR },
                    data => 1,
                    headers => { type => HASHREF, default => {} },
                },
            );
            my $req = HTTP::Request->new( "$method" => $p{'url'} );
            $req->header( $_ => $p{headers}{$_} ) for keys %{ $p{headers} };
            $req->content_type( $self->{'content_type'} );
            $req->content_length(
                do { use bytes; length( $p{'data'} ) }
            );
            $req->content( $p{'data'} );
            return $req;
        };
    }
}

1;

