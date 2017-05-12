package CatalystX::Eta::Controller::REST;

use Moose;
use namespace::autoclean;
use Data::Dumper;

use JSON::MaybeXS;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default => 'application/json',
    'map'   => {
        'application/json' => 'JSON',
        'text/x-json'      => 'JSON',
    },
);

sub end : Private {
    my ( $self, $c ) = @_;

    #... do things before Serializing ...
    my $code = $c->res->status;
    if ( scalar( @{ $c->error } ) ) {
        $code = 500;    # We default to 500 for errors unless something else has been set.

        my ( $an_error, @other_errors ) = @{ $c->error };

        if ( ref $an_error eq 'DBIx::Class::Exception'
            && $an_error->{msg} =~ /duplicate key value violates unique constraint/ ) {
            $code = 400;

            $c->stash->{rest} =
              { error => 'You violated an unique constraint! Please verify your input fields and try again.' };

            $c->log->info( "exception treated: " . $an_error->{msg} );
        }
        elsif ( ref $an_error eq 'DBIx::Class::Exception'
            && $an_error->{msg} =~ /is not present/ ) {
            $code = 400;

            my ( $match, $value ) = $an_error->{msg} =~ /Key \((.+?)\)=(\(.+?)\)/;

            $c->stash->{rest} =
              { form_error => ( { $match => 'value=' . $value . ') cannot be found on our database' } ) };

        }
        elsif ( ref $an_error eq 'HASH' && $an_error->{error_code} ) {

            $code = $an_error->{error_code};

            $c->stash->{rest} =
              { error => $an_error->{message} };
            $c->log->info( "exception treated: " . $an_error->{msg} );

        }
        elsif ( ref $an_error eq 'REF' && ref $$an_error eq 'ARRAY' && @$$an_error == 2 ) {
            $code = 400;

            $c->stash->{rest} =
              { form_error => ( { $$an_error->[0] => $$an_error->[1] } ) };

        }
        else {
            $c->log->error( Dumper $an_error, @other_errors );

            $c->stash->{rest} = { error => 'Internal Server Error' };
        }

        $c->clear_errors;

        $c->res->status($code);
    }

    $c->stash->{rest}{error} = 'form_error'
      if ref $c->stash->{rest} eq 'HASH'
      && !exists $c->stash->{rest}{error}
      && exists $c->stash->{rest}{form_error};

    $c->forward('serialize');

    #... do things after Serializing ...
}

sub serialize : ActionClass('Serialize') { }

1;

