package Data::Riak::Request::WithHTTPExceptionHandling;
{
  $Data::Riak::Request::WithHTTPExceptionHandling::VERSION = '2.0';
}

use Moose::Role;
use namespace::autoclean;

with 'Data::Riak::Request';

has http_exception_classes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[ClassName|Undef]',
    builder => '_build_http_exception_classes',
    handles => {
        has_exception_class_for_http_status => 'exists',
        exception_class_for_http_status     => 'get',
    },
);

requires '_build_http_exception_classes';

1;

__END__

=pod

=head1 NAME

Data::Riak::Request::WithHTTPExceptionHandling

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
