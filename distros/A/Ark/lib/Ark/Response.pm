package Ark::Response;
use Mouse;
use Scalar::Util ();

extends 'Plack::Response';

has body => (
    is        => 'rw',
    predicate => 'has_body',
);

has status => (
    is      => 'rw',
    default => 200,
);

has binary => (
    is      => 'rw',
    default => 0,
);

has streaming => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'is_streaming',
);

has deferred => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'is_deferred',
);

has deferred_response => (
    is  => 'rw',
    isa => 'CodeRef',
);

no Mouse;

sub finalize {
    my $self = shift;

    if (!$self->is_deferred && !$self->is_streaming) {
        return $self->SUPER::finalize;
    }

    my $headers = $self->headers->clone;
    $self->_finalize_cookies($headers);

    if ($self->is_deferred) {
        if (my $cb = $self->deferred_response) {
            my $body = $self->_body;

            my $response = [
                $self->status,
                +[
                    map {
                        my $k = $_;
                        map { ( $k => $_ ) } $headers->header($_);
                    } $headers->header_field_names
                ],
                $body,
            ];

            $cb->($response);
        }
        else {
            my $r = sub {
                my $respond = shift;
                $self->deferred_response($respond);
                $self->deferred->($respond);
            };
            Scalar::Util::weaken($self);
            return $r;
        }
    }
    else { # streaming
        my $response = [
            $self->status,
            +[
                map {
                    my $k = $_;
                    # steal from Plack::Response
                    map {
                        my $v = $_;
                        $v =~ s/\015\012[\040|\011]+/chr(32)/ge; # replace LWS with a single SP
                        $v =~ s/\015|\012//g; # remove CR and LF since the char is invalid here

                        ( $k => $v )
                    } $headers->header($_);

                } $headers->header_field_names
            ],
        ];

        return sub {
            my $respond = shift;
            my $writer  = $respond->($response);
            $self->streaming->($writer);
        };
    }
}

__PACKAGE__->meta->make_immutable;
