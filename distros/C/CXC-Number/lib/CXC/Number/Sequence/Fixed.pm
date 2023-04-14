package CXC::Number::Sequence::Fixed;

# ABSTRACT: CXC::Number::Sequence with arbitrary values

use v5.28;

use Moo;

our $VERSION = '0.12';

use namespace::clean;

extends 'CXC::Number::Sequence';

has '+_raw_elements' => ( required => 1, );


1;

#
# This file is part of CXC-Number
#
# This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::Number::Sequence::Fixed - CXC::Number::Sequence with arbitrary values

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use CXC::Number::Sequence::Fixed;

  $sequence = CXC::Number::Sequence::Fixed->new( edges => \@edges, %options );

=head1 DESCRIPTION

This subclass of L<CXC::Number::Sequence> specifies the exact elements in a sequence.

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-number@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-number

and may be cloned from

  https://gitlab.com/djerius/cxc-number.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Number|CXC::Number>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
