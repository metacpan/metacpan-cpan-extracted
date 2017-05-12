package CatalystX::CMS::Page;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Object );
use Carp;
use Data::Dump qw( dump );
use CatalystX::CMS::File;
use MRO::Compat;
use mro 'c3';

use overload(
    q[""]    => sub { shift->delegate },
    fallback => 1,
);

our $VERSION = '0.011';

__PACKAGE__->mk_accessors(qw( cms_root file copy url has_unsaved_changes ));
__PACKAGE__->delegate_class('CatalystX::CMS::File');

=head1 NAME

CatalystX::CMS::Page - content storage class

=head1 SYNOPSIS

 my $page = $c->model('CMS')->fetch(file => 'foo/bar');
 # $page isa CatalystX::CMS::Page
 
=head1 DESCRIPTION

CatalystX::CMS::Page is a subclass of CatalystX::CRUD::Object.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 new( file => I<path/to/file> )

Returns new CatalystX::CMS::Page object.

=cut

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    my $file  = $self->{file} or $self->throw_error("file param required");
    $self->{delegate} ||= $self->delegate_class->new( path => $file );
    return $self;
}

=head2 create

Calls create() on the delegate(), passing all params.

=cut

sub create { shift->{delegate}->create(@_) }

=head2 read

Calls read() on the delegate(), passing all params.

=cut

sub read { shift->{delegate}->read(@_) }

=head2 update

Calls update() on the delegate(), passing all params.

=cut

sub update { shift->{delegate}->update(@_) }

=head2 delete

Calls delete() on the delegate(), passing all params.

=cut

sub delete { shift->{delegate}->delete(@_) }

=head2 url

Returns file() stringified.

=cut

=head2 calc_url

Determines the url value based on file(), type()
and flavour(). Sets the url() value and returns the value.

=cut

sub calc_url {
    my $self = shift;
    my $file = $self->file;
    my $type = $self->type;
    my $flav = $self->flavour;
    my $ext  = $self->delegate->ext;
    $file =~ s!^$type[\/\\]!!;
    $file =~ s!^$flav[\/\\]!!;
    $file =~ s!\Q$ext\E$!!;
    $self->url($file);
    return $file;
}

=head2 title

Returns the C<title> from attrs().

=cut

sub title {
    shift->attrs->{title};
}

=head2 type

Returns the C<type> from attrs() or the local type if overriden in the I<page>.

=cut

sub type {
    $_[0]->attrs->{type} || $_[0]->{type};
}

=head2 flavour

Returns the C<flavour> from attrs() or the local flavour if overriden in the I<page>.

=cut

sub flavour {
    $_[0]->attrs->{flavour} || $_[0]->{flavour};
}

sub _parent_dir {
    my $self = shift;
    my $file = shift or croak 'file required';
    my $dir  = $file->parent;
    return $dir->relative( $dir->parent );
}

=head2 bare_file

Returns the delegate basename() without any file extension (as indicated
by the delegate ext() value).

=cut

sub bare_file {
    my $self = shift;
    my $file = $self->delegate->file->basename;
    my $ext  = $self->delegate->ext;
    $file =~ s/\Q$ext\E$//;
    return $file;
}

=head2 tree

Returns array suitable for templating. The array data
are the related URLs for the wrapper set for this Page.

=cut

sub tree {
    my $self = shift;

    #carp dump $self;

    my $file  = $self->delegate;
    my $class = $self->delegate_class;

    # for any given page, we can't easily discover
    # which other pages might be INCLUDEing it,
    # so don't even try. Maybe make that a different
    # feature.
    # instead, just include the wrappers/* files
    # along with the current $file and its immediate
    # descendents.

    my @tree;

    for my $t (qw( wrapper header footer body )) {
        next if $self->url eq $t;
        my %item = (
            url     => $t,
            text    => $t,
            type    => $self->type,
            flavour => $self->flavour,
        );
        push( @tree, \%item );
    }

    my $children = $self->_parse_tt_includes( $file->content );

    my @subtree;
    for my $f (@$children) {

        # TODO better way to get type and flavour
        # for $f. could be an attr in the file,
        # could be determined from path, etc.
        # for now, we just assume the parent's attrs
        my $type    = $self->type;
        my $flavour = $self->flavour;
        my %item    = (
            url     => $f,
            text    => $f,
            type    => $type,
            flavour => $flavour,
        );
        push( @subtree, \%item );
    }

    push( @tree,
        { url => $self->url, text => $self->url, tree => \@subtree } );

    return \@tree;
}

sub _parse_tt_includes {
    my $self = shift;
    my $buf  = shift;
    my $ext  = $self->ext;
    my @files;
    my $depth = 100;
    my $count = 0;
    while ( $buf =~ m/(PROCESS|INCLUDE|INSERT) (\S+)/g ) {
        last if $count++ > $depth;
        my $f = $2;
        unless ( $buf =~ m/BLOCK\ +$f/ ) {
            $f =~ s/$ext$//;
            $f =~ s/\s*;$//;
            next if $f =~ m/[\$'"]/;
            push( @files, $f );
        }
    }
    return \@files;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-cms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

