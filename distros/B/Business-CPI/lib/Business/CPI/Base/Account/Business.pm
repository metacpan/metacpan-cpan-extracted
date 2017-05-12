package Business::CPI::Base::Account::Business;
# ABSTRACT: General implementation of Account::Business role
use utf8;
use Moo;
with 'Business::CPI::Role::Account::Business';

our $VERSION = '0.924'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Base::Account::Business - General implementation of Account::Business role

=head1 VERSION

version 0.924

=head1 DESCRIPTION

This is the most generic implementation of the
L<Business::CPI::Role::Account::Business> role. If your driver needs something
more specific, it can create a new class which uses
L<< Account::Business | Business::CPI::Role::Account::Business >>.

=head1 SEE ALSO

L<Business::CPI::Role::Account::Business>

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
