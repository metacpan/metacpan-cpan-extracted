package Data::Riak::Transport::Response;
{
  $Data::Riak::Transport::Response::VERSION = '2.0';
}

use Moose::Role;
use namespace::autoclean;

requires qw(is_error parts);

1;

__END__

=pod

=head1 NAME

Data::Riak::Transport::Response

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
