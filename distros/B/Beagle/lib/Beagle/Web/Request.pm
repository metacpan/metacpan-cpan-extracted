package Beagle::Web::Request;
use Encode;
use base 'Plack::Request';
use Hash::MultiValue;

sub query_parameters {
    my $self = shift;

    return $self->env->{'beagle.request.query'}
      if $self->env->{'beagle.request.query'};

    my $params = $self->SUPER::query_parameters()->mixed;
    for my $key ( keys %$params ) {
        $params->{$key} =
          ref $params->{$key}
          ? [ map { decode_utf8 $_ } @{ $params->{$key} } ]
          : decode_utf8( $params->{$key} );
    }
    return $self->env->{'beagle.request.query'} =
      Hash::MultiValue->from_mixed($params);
}

sub body_parameters {
    my $self = shift;

    return $self->env->{'beagle.request.body'}
      if $self->env->{'beagle.request.body'};

    return $self->_parse_request_body;

}

sub content {
    my $self = shift;
    return $self->env->{'beagle.request.content'} ||=
      decode_utf8( $self->SUPER::content() );
}

sub _parse_request_body {
    my $self = shift;
    my $ret  = $self->SUPER::_parse_request_body;
    return $ret unless $self->env->{'plack.request.body'};

    my $body = $self->env->{'plack.request.body'}->mixed;
    for my $key ( keys %$body ) {
        $body->{$key} =
          ref $body->{$key}
          ? [ map { decode_utf8 $_ } @{ $body->{$key} } ]
          : decode_utf8( $body->{$key} );
    }
    return $self->env->{'beagle.request.body'} =
      Hash::MultiValue->from_mixed($body);
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


