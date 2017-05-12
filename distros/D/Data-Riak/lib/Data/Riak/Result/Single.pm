package Data::Riak::Result::Single;
{
  $Data::Riak::Result::Single::VERSION = '2.0';
}
# ABSTRACT: Results without the need of a ResultSet

use Moose::Role;
use namespace::autoclean;


1;

__END__

=pod

=head1 NAME

Data::Riak::Result::Single - Results without the need of a ResultSet

=head1 VERSION

version 2.0

=head1 DESCRIPTION

Normally, requests to Riak can return more than one result. That set of results
is usually wrapped up in a L<Data::Riak::ResultSet> before being returned to the
user.

However, some requests will only ever result in a single result. This result
role indicates that and will prevent the returned result from being wrapped in a
ResultSet.

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
