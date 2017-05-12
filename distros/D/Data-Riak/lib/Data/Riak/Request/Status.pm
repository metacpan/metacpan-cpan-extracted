package Data::Riak::Request::Status;
{
  $Data::Riak::Request::Status::VERSION = '2.0';
}

use Moose;
use Data::Riak::Result::SingleJSONValue;
use Data::Riak::Exception::StatsNotEnabled;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => 'stats',
        accept => 'application/json',
    };
}

sub _build_http_exception_classes {
    return {
        404 => Data::Riak::Exception::StatsNotEnabled::,
    };
}

sub _mangle_retval {
    my ($self, $ret) = @_;
    return $ret->json_value;
}

with 'Data::Riak::Request',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::SingleJSONValue::,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::Status

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
