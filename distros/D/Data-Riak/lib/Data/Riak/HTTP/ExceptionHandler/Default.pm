package Data::Riak::HTTP::ExceptionHandler::Default;
{
  $Data::Riak::HTTP::ExceptionHandler::Default::VERSION = '2.0';
}

use Moose;
use HTTP::Status 'is_client_error', 'is_server_error';
use Data::Riak::Exception::ClientError;
use Data::Riak::Exception::ServerError;
use namespace::autoclean;

extends 'Data::Riak::HTTP::ExceptionHandler';

sub _build_honour_request_specific_exceptions { 1 }

sub _build_fallback_handler {
    [[\&is_client_error, Data::Riak::Exception::ClientError::],
     [\&is_server_error, Data::Riak::Exception::ServerError::]]
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::HTTP::ExceptionHandler::Default

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
