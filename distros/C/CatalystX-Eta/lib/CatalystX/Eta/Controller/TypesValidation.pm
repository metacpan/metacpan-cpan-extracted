package CatalystX::Eta::Controller::TypesValidation;

use Moose::Role;
use Moose::Util::TypeConstraints;
use JSON::MaybeXS;

sub validate_request_params {
    my $self = shift;

    my ( $c, %fields ) = @_;

    foreach my $key ( keys %fields ) {

        my $me   = $fields{$key};
        my $type = $me->{type};
        my $data_from = $self->config->{data_from_body} ? 'data' : 'params';

        my $val  = $c->req->$data_from->{$key};

        $val = '' if !defined $val && $me->{clean_undef};

        if ( !defined $val && $me->{required} && !( $me->{undef_is_valid} && !defined $val ) ) {
            $c->stash->{rest} = { error => 'form_error', form_error => { $key => 'missing' } };
            $c->res->code(400);
            $c->detach;
        }

        if (
               defined $val
            && $val eq ''
            && (   $me->{empty_is_invalid}
                || $type eq 'Bool'
                || $type eq 'Int'
                || $type eq 'Num'
                || ref $type eq 'MooseX::Types::TypeDecorator' )
          ) {

            $c->stash->{rest} = { error => 'form_error', form_error => { $key => 'empty_is_invalid' } };
            $c->res->code(400);
            $c->detach;
        }

        next unless $val;

        my $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint($type);

        $self->status_bad_request( $c, message => "Unknown type constraint '$type'" ), $c->detach
          unless defined($cons);

        if ( !$cons->check($val) ) {
            $c->stash->{rest} = { error => 'form_error', form_error => { $key => 'invalid' } };
            $c->res->code(400);
            $c->detach;
        }

    }

}

1;

