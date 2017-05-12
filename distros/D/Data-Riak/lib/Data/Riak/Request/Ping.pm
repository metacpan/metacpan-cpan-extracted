package Data::Riak::Request::Ping;
{
  $Data::Riak::Request::Ping::VERSION = '2.0';
}

use Moose;
use Data::Riak::Result::SingleValue;
use namespace::autoclean;

sub as_http_request_args {
    my ($self) = @_;

    return {
        method => 'GET',
        uri    => 'ping',
    };
}

sub _build_http_exception_classes {
    return {
        # This is a bit of a hack. Maybe we want to allow predicate functions to
        # be provided, or at least regexen or some such.
        (map { ($_ => undef) } 500 .. 599),
    };
}

sub _mangle_retval {
    my ($self, $res) = @_;
    $res->status_code == 200 ? 1 : 0
}

with 'Data::Riak::Request',
     'Data::Riak::Request::WithHTTPExceptionHandling';

has '+result_class' => (
    default => Data::Riak::Result::SingleValue::,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::Ping

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
