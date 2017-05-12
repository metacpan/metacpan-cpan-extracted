package CatalystX::CRUD::Object::File;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Object );
use Path::Class::File;
use Carp;
use mro 'c3';
use overload(
    q[""]    => sub { shift->delegate },
    fallback => 1,
);

__PACKAGE__->mk_accessors(qw( content file ));
__PACKAGE__->delegate_class('Path::Class::File');

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Object::File - filesystem CRUD instance

=head1 SYNOPSIS

 package My::File;
 use base qw( CatalystX::CRUD::Object::File );
  
 1;

=head1 DESCRIPTION

CatalystX::CRUD::Object::File delegates to Path::Class:File.

=head1 METHODS

Only new or overridden methods are documented here.

=cut

=head2 new( file => I<path/to/file> )

Returns new CXCO::File object.

=cut

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    my $file  = $self->{file} or $self->throw_error("file param required");
    $self->{delegate} ||= $self->delegate_class->new(
        ref $file eq 'ARRAY' ? @$file : $file );
    return $self;
}

=head2 content

The contents of the delegate() file object. Set when you call read().
Set it yourself and call create() or update() as appropriate to write to the file.

=cut

=head2 create

Writes content() to a file. If the file already exists, will throw_error(), so
call it like:

 -s $file ? $file->update : $file->create;

Returns the number of bytes written.

=cut

sub create {
    my $self = shift;

    # write only if file does not yet exist
    if ( -s $self->delegate ) {
        return $self->throw_error(
            $self->delegate . " already exists. cannot create()" );
    }

    return $self->_write;
}

=head2 read

Slurp contents of file into content(). No check is performed as to whether
the file exists, so call like:

 $file->read if -s $file;

=cut

sub read {
    my $self = shift;
    $self->{content} = $self->delegate->slurp;
    return $self;
}

=head2 update

Just like create() only no check is made if the file exists prior to writing
to it. Returns the number of bytes written.

=cut

sub update {
    my $self = shift;
    return $self->_write;
}

=head2 delete

Remove the file from the filesystem.

=cut

sub delete {
    my $self = shift;
    return $self->delegate->remove;
}

=head2 is_new

Returns true if the file does not yet exist.

=cut

sub is_new {
    my $self = shift;
    return defined -s $self->delegate ? 0 : 1;
}

sub _write {
    my $self = shift;
    my $dir  = $self->delegate->dir;
    $dir->mkpath;
    my $fh = $self->delegate->openw();
    print {$fh} $self->content;
    $fh->close;

    #warn length($self->content) . " bytes written to $self";

    return -s $self->delegate;
}

=head2 serialize

Returns the File object as a hashref with 2 keys: file and content.

=cut

sub serialize {
    my $self = shift;
    return { file => $self->file, content => $self->content };
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
