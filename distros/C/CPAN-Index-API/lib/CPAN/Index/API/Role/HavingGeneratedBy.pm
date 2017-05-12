package CPAN::Index::API::Role::HavingGeneratedBy;
{
  $CPAN::Index::API::Role::HavingGeneratedBy::VERSION = '0.007';
}

# ABSTRACT: Provides 'generated_by' and 'last_generated' attributes

use strict;
use warnings;

use Moose::Role;

has generated_by => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

has last_generated => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_generated_by {
    my $package = blessed shift;
    return $package . " " . $package->VERSION;
}

sub _build_last_generated {
    return scalar gmtime() . " GMT";
}

1;


__END__
=pod

=head1 NAME

CPAN::Index::API::Role::HavingGeneratedBy - Provides 'generated_by' and 'last_generated' attributes

=head1 VERSION

version 0.007

=head1 PROVIDES

=head2 generated_by

Name of software that generated the file.

=head2 last_generated

Date and time when the file was last generated.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

