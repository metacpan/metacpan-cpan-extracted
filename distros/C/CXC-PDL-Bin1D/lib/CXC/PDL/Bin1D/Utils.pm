package CXC::PDL::Bin1D::Utils;

use v5.10;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.27';

our @EXPORT_OK = qw[ _bitflags _flags ];

sub _bitflags {
    my $bit = 1;
    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
    return shift(), 1, map { $bit <<= 1; $_ => $bit; } @_;
}

sub _flags {
    my $bits = shift;
    croak( "unknown flag: $_ " ) for grep { !defined $bits->{$_} } @_;
    my $mask;
    $mask |= $_ for @{$bits}{@_};
    return $mask;
}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::PDL::Bin1D::Utils

=head1 VERSION

version 0.27

=head1 INTERNALS

=head1 CXC::PDL::Bin1D::Utils - internal routines for CXC::PDL::Bin1D

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-pdl-bin1d@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-PDL-Bin1D>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-pdl-bin1d

and may be cloned from

  https://gitlab.com/djerius/cxc-pdl-bin1d.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::PDL::Bin1D.pd|CXC::PDL::Bin1D.pd>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
