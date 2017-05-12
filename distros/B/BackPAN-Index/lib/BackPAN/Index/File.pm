use utf8;
package BackPAN::Index::File;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("files");
__PACKAGE__->add_columns(
  "path",
  { data_type => "text", is_nullable => 0 },
  "date",
  { data_type => "integer", is_nullable => 0 },
  "size",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("path");
__PACKAGE__->might_have(
  "release",
  "BackPAN::Index::Release",
  { "foreign.path" => "self.path" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-27 01:39:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gqi9QR+IxPMmdduz2/1BHA

use Mouse;
with 'BackPAN::Index::Role::AsHash';

use URI;
use File::Basename qw(basename);

use overload
  q[""]         => sub { $_[0]->path },
  fallback      => 1;

sub backpan_root {
    return URI->new("http://backpan.perl.org/");
}

sub data_methods {
    return qw(path date size);
}

sub url {
    my $self = shift;
    my $url = $self->backpan_root;
    $url->path($self->path);
    return $url;
}

sub filename {
    my $self = shift;
    return basename $self->path;
}

# Backwards compatibility with PBP
sub prefix {
    my $self = shift;
    return $self->path;
}

sub release {
    my $self = shift;

    my $schema = $self->result_source->schema;
    my($release) = $schema->resultset("Release")
                          ->search({ file => $self->path }, { rows => 1 })
                          ->first;

    return $release;
}

1;

__END__

=head1 NAME

BackPAN::Index::File - Represent a file on BackPAN

=head1 SYNOPSIS

  my $b = BackPAN::Index->new();
  my $file = $b->file("authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz");
  print "  Date: " . $file->date . "\n";
  print "  Path: " . $file->path . "\n";
  print "  Size: " . $file->size . "\n";
  print "   URL: " . $file->url . "\n";

=head1 DESCRIPTION

BackPAN::Index::File objects represent files on BackPAN.  It may
represent a release, a readme or meta file or just some random stuff
on BackPAN.

=head1 METHODS

=head2 date

    my $date = $file->date;

Returns the upload date of the file, in UNIX epoch seconds.

=head2 path

    my $path = $file->path;

Returns the full path to the file on CPAN.

=head2 size

    my $size = $file->size;

Returns the size of the file in bytes.

=head2 url

    my $url = $file->url;

Returns a URL to the file on a BackPAN mirror.

=head2 filename

    my $filename = $file->filename;

Returns the filename part of the path.

=head2 release

    my $release = $file->release;

Returns the release associated with this file, if any, as a
L<BackPAN::Index::Release> instance.

=head2 as_hash

    my $data = $file->as_hash;

Returns a hash ref containing the data inside C<$file>.


=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2005-2009, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<BackPAN::Index>, L<BackPAN::Index::Release>
