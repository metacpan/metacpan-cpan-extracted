package Data::Riak::HTTP::ExceptionHandler;
{
  $Data::Riak::HTTP::ExceptionHandler::VERSION = '2.0';
}

use Moose;
use namespace::autoclean;

has honour_request_specific_exceptions => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    builder  => '_build_honour_request_specific_exceptions',
);

has fallback_handlers => (
    traits   => ['Array'],
    isa      => 'ArrayRef[ArrayRef]', # ArrayRef[Tuple[CodeRef,ClassName]]
    required => 1,
    builder  => '_build_fallback_handler',
    handles  => {
        fallback_handlers => 'elements',
    },
);

sub try_handle_exception {
    my $e = shift->try_build_exception(@_);
    die $e if $e;
    return;
}

sub try_build_exception {
    my ($self, $request, $http_request, $http_response) = @_;

    my ($handled, $expt) = $self->try_build_request_specific_exception(
        $request, $http_request, $http_response,
    ) if $self->honour_request_specific_exceptions;

    return $expt if $expt;
    return if $handled;

    return $self->try_build_exception_fallback(
        $request, $http_request, $http_response,
    );
}

sub try_build_request_specific_exception {
    my ($self, $request, $http_request, $http_response) = @_;

    return unless $request->does('Data::Riak::Request::WithHTTPExceptionHandling');
    return unless $request->has_exception_class_for_http_status(
        $http_response->code,
    );

    my $expt_class = $request->exception_class_for_http_status(
        $http_response->code,
    );

    # this status code isn't fatal for this request
    return (1, undef) if !defined $expt_class;

    return (0, $expt_class->new({
        request            => $request,
        transport_request  => $http_request,
        transport_response => $http_response,
    }));
}

sub try_build_exception_fallback {
    my ($self, $request, $http_request, $http_response) = @_;

    for my $h ($self->fallback_handlers) {
        my ($matcher, $expt_class) = @{ $h };

        return $expt_class->new({
            request            => $request,
            transport_request  => $http_request,
            transport_response => $http_response,
        }) if $matcher->($http_response->code);
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::HTTP::ExceptionHandler

=head1 VERSION

version 2.0

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
