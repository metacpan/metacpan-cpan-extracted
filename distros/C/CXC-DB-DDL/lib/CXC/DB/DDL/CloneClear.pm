package CXC::DB::DDL::CloneClear;

use v5.26;

use Moo::Role;

use MooX::TaggedAttributes -propagate, -tags => 'cloneclear';
use experimental 'signatures', 'postderef';

use namespace::clean -except => [ '_tag_list', '_tags' ];

our $VERSION = '0.13';









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

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::CloneClear

=head1 VERSION

version 0.13

=head1 SUBROUTINES

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
