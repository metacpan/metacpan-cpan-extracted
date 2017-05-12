#
# This file is part of CPAN-Local-Role-MetaCPAN-API
#
# This software is Copyright (c) 2013 by White-Point Star, LLC <http://whitepointstarllc.com>.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package CPAN::Local::Role::MetaCPAN::API;
{
  $CPAN::Local::Role::MetaCPAN::API::VERSION = '0.001';
}

# ABSTRACT: A role for plugins needing to access or query MetaCPAN's API

use common::sense;

use Moose::Role;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use Moose::Util::TypeConstraints;

use MetaCPAN::API;

with 'MooseX::RelatedClasses' => {
    name      => 'MetaCPAN::API',
    namespace => undef,
};


has metacpan => (
    is      => 'lazy',
    isa     => class_type('MetaCPAN::API'),
    builder => sub {
        my $self = shift @_;

        my $v = $self->VERSION // 'dev';
        return $self->meta_cpan__api_class->new(
            ua_args => [
                agent => "CPAN::Local::Role::MetaCPAN::API-$v / ",
            ],
        );
    },
);

!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl White-Point Star, LLC <http://whitepointstarllc.com> metacpan
MetaCPAN's

=head1 NAME

CPAN::Local::Role::MetaCPAN::API - A role for plugins needing to access or query MetaCPAN's API

=head1 VERSION

This document describes version 0.001 of CPAN::Local::Role::MetaCPAN::API - released April 15, 2013 as part of CPAN-Local-Role-MetaCPAN-API.

=head1 SYNOPSIS

    # in your plugin
    with 'CPAN::Local::Role::MetaCPAN::API';

    # and later somewhere...
    my $foo = $self->metacpan->...

=head1 DESCRIPTION

This is a role for L<CPAN::Local> plugins that want to access the MetaCPAN
API, by providing a L</metacpan> attribute granting easy access to a
L<MetaCPAN::API> instance.

=head1 ATTRIBUTES

=head2 metacpan

This attribute contains a read-only, lazily constructed L<MetaCPAN::API>
instance.

=head1 METHODS

=head2 metacpan

Returns our L<MetaCPAN::API> instance.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MetaCPAN::API|MetaCPAN::API>

=item *

L<CPAN::Local|CPAN::Local>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/WhitePointStarLLC/cpan-local-role-metacpan-api>
and may be cloned from L<git://github.com/WhitePointStarLLC/cpan-local-role-metacpan-api.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/WhitePointStarLLC/cpan-local-role-metacpan-api/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by White-Point Star, LLC <http://whitepointstarllc.com>.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
