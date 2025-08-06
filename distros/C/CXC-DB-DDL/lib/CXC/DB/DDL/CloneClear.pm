package CXC::DB::DDL::CloneClear;

# ABSTRACT: Provide attribute tags and a method for Moo objects to indicate they should be cloned

use v5.26;

use Moo::Role;

use MooX::TaggedAttributes -propagate, -tags => 'cloneclear';
use experimental 'signatures', 'postderef';

use namespace::clean -except => [ '_tag_list', '_tags' ];

our $VERSION = '0.21';









sub clone ( $self ) {
    require Clone;
    Clone::clone( $self );
}














sub clone_simple ( $self ) {
    my $clone = $self->clone;
    $clone->$_ for map { "clear_$_" } keys $self->_tags->{cloneclear}->%*;
    return $clone;
}

1;

#
# This file is part of CXC-DB-DDL
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::CloneClear - Provide attribute tags and a method for Moo objects to indicate they should be cloned

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  package Class {
    use Moo;
    with "CXC::DB::DDL::CloneClear';

    has attr1 => ( is => 'rw', default => 'A1', cloneclear => 1 );
    has attr2 => ( is => 'rw', default => 'A2' );
  }

  my $obj =  Class->new( attr1 => 'B1', attr2 => 'B2' );
  my $clone = $obj->clone_simple;

  say $clone->attr1; # A1
  say $clone->attr2; # B2

=head1 METHODS

=head2 clone

  $clone = $obj->clone;

Clone the object.  Uses L<Clone>.

=head2 clone_simple

   $clone = $obj->clone_simple;

Return a clone of the object without any external constraints or auto
increment properties.  Primary key constraints remain.

The clear attribute method is run on object attributes which have a
C<cloneclear> tag.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-db-ddl@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-DB-DDL>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-db-ddl

and may be cloned from

  https://gitlab.com/djerius/cxc-db-ddl.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::DB::DDL|CXC::DB::DDL>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
