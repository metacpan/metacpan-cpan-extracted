
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Collection::Chem::Interface;

  our @ISA = qw(Data::Type::Object::Interface);

  our $VERSION = '0.01.25';

  sub prefix : method { 'Chem::' }

  sub pkg_prefix : method { 'chem_' }

package Data::Type::Object::chem_atom;

  our @ISA = qw(Data::Type::Collection::Chem::Interface Data::Type::Collection::Std::Interface::Logic);

  our $VERSION = '0.05.18';

  sub export { ('ATOM') }

  sub desc : method { 'atom symbol fom the period system' }

  sub info : method { q{two char atom symbol} }

  sub usage : method { 'sequence of [\c\c]' }

# See CPAN Chemistry::Atom

our @_elements = qw(
    h                                                                   he
    li  be                                          b   c   n   o   f   ne
    na  mg                                          al  si  p   s   cl  ar
    k   ca  sc  ti  v   cr  mn  fe  co  ni  cu  zn  ga  ge  as  se  br  kr
    rb  sr  y   zr  nb  mo  tc  ru  rh  pd  ag  cd  in  sn  sb  te  i   xe
);

  sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ], [ 'lc' ] ) }

  sub _test : method
  {
      my $this = shift;
      
      #warn "dt test \$Data::Type::value '$Data::Type::value'";
      
      Data::Type::ok( 1, Data::Type::Facet::exists( \@_elements ) );
  }

1;

=head1 NAME

Data::Type::Collection::Chem - datatypes for chemistry

=head1 SYNOPSIS

 $_ = 'Xe'; # Xenon

 die unless is Chem::Atom;

=head1 DESCRIPTION

Everything that is related to chemical matters.

=head1 TYPES


=head2 CHEM::ATOM (since 0.05.18)

atom symbol fom the period system

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

sequence of [\c\c]



=head1 INTERFACE


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

