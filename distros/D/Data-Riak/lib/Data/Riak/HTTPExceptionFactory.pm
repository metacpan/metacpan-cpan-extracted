package Data::Riak::HTTPExceptionFactory;
{
  $Data::Riak::HTTPExceptionFactory::VERSION = '2.0';
}

use Moose;
use HTTP::Throwable::Factory;
use namespace::autoclean;

sub throw {
    my ($factory, $exception) = @_;

    HTTP::Throwable::Factory->throw({
        status_code => $exception->transport_response->code,
        reason      => $exception->message,
    });
}

sub new_exception {
    my ($factory, $exception) = @_;

    HTTP::Throwable::Factory->new_exception({
        status_code => $exception->transport_response->code,
        reason      => $exception->message,
    });
}

1;

__END__

=pod

=head1 NAME

Data::Riak::HTTPExceptionFactory

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
