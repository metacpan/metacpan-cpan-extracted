package Data::Riak::Async::Request;
{
  $Data::Riak::Async::Request::VERSION = '2.0';
}

use Moose::Role;
use namespace::autoclean;

has cb => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has error_cb => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

1;

__END__

=pod

=head1 NAME

Data::Riak::Async::Request

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
