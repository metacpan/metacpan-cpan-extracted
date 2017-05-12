package Business::Mondo::Currency;

=head1 NAME

Business::Mondo::Currency

=head1 DESCRIPTION

A role containing currency attributes / methods

=cut

use strict;
use warnings;

use Moo::Role;
use Types::Standard qw/ :all /;
use Data::Currency;

has [ qw/ currency local_currency / ] => (
    is      => 'ro',
    isa     => Maybe[InstanceOf['Data::Currency']],
    coerce  => sub {
        my ( $args ) = @_;

        return undef if ! $args;

        if ( ! ref( $args ) ) {

            $args = Data::Currency->new({
                code => $args,
            });
        }

        return $args;
    },
);

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;

# vim: ts=4:sw=4:et
