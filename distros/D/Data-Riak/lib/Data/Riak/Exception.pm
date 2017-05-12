package Data::Riak::Exception;
{
  $Data::Riak::Exception::VERSION = '2.0';
}

use Moose;
use namespace::autoclean;

extends 'Throwable::Error' => { -version => '0.200003' };

has request => (
    is       => 'ro',
    does     => 'Data::Riak::Request',
    required => 1,
);

has transport_request => (
    is       => 'ro',
    does     => 'Data::Riak::Transport::Request',
    required => 1,
);

has transport_response => (
    is       => 'ro',
    does     => 'Data::Riak::Transport::Response',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Exception

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
