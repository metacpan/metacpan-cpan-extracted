package Dancer2::Plugin::Path::Class;

# ABSTRACT: list a directory using Path::Class

use strict;
use warnings;

our $VERSION = 0.08;

use Dancer2::Plugin;
use MIME::Types;
use Path::Class;
use Format::Human::Bytes;

sub _decorate_dirs {
    my ($dir, $dirs) = @_;
    my @ls_dirs = ();
    for my $basename (@{$dirs}) {
        my $subdir = $dir->subdir($basename);
        my @subdirs = (); # the subdirs of this subdir
        my $file_count = 0; # the number of files in this subdir
        while (my $ent = $subdir->next) {
            my $subsubname = $ent->basename;
            next if $subsubname =~ /^\./; # hidden
            next if $subsubname =~ /~$/; # ignore
            next unless -r $ent; # can read
            if ($ent->is_dir) {
                push @subdirs, $subsubname;
            } else {
                $file_count++;
            }
        }
        @subdirs = sort {$a cmp $b} @subdirs;
        push @ls_dirs, {
            name => $basename,
            subdirs => \@subdirs,
            file_count => $file_count,
        };
    }
    return \@ls_dirs;
}

sub _ymd {
    my $stamp = shift;
    my ($mday, $mon, $year) = (localtime($stamp))[3..5];
    my $date = sprintf("%4d-%02d-%02d", $year + 1900, $mon + 1, $mday);
    return $date;
}

sub _decorate_files {
    my ($dir, $files) = @_;
    my @ls_files = ();
    my $mt = MIME::Types->new;
    for my $basename (@{$files}) {
        my $file = $dir->file($basename);
        next unless -r $file; # can read
        my $st = $file->stat;
        next unless $st; # can stat
        my $type = $mt->mimeTypeOf($basename);
        push @ls_files, {
            name => $basename,
            type => "$type",
            size => Format::Human::Bytes::base2($st->size),
            date => _ymd($st->mtime),
        };
    }
    return \@ls_files;
}

register ls => sub {
    my ($dsl, @args) = @_;
    my $dir = dir(@args);
    my $ls_name = $dir->basename;
    my @dirs = ();
    my @files = ();
    my $ls_dirs;
    my $ls_files;
    
    if (-d $dir) {
        while (my $ent = $dir->next) {
            my $basename = $ent->basename;
            next if $basename =~ /^\./; # hidden
            next if $basename =~ /~$/; # ignore
            if ($ent->is_dir) {
                next unless -r $ent; # can read
                push @dirs, $basename;
            } else {
                push @files, $basename;
            }
        }
        @dirs = sort {$a cmp $b} @dirs;
        $ls_dirs = _decorate_dirs($dir, \@dirs);
        @files = sort {$a cmp $b} @files;
        $ls_files = _decorate_files($dir, \@files);
    } else {
        push @files, $dir->basename;
        $ls_files = _decorate_files($dir->parent, \@files);
    }

    my $ls_cdup = $dsl->app->request->path;
    $ls_cdup =~ s{/[^/]*$}{};

    $dsl->app->request->var( ls_name  => $ls_name );
    $dsl->app->request->var( ls_cdup  => $ls_cdup );
    $dsl->app->request->var( ls_dirs  => $ls_dirs );
    $dsl->app->request->var( ls_files => $ls_files );
    
    return $dir;

};

register_plugin;
1;
__END__


=head1 NAME

Dancer2::Plugin::Path::Class - list a directory using Path::Class

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use Dancer2::Plugin::Path::Class;
  
  get '/img' => sub {
      my $dir = ls(config->{public}, '/img');
      template 'dirlisting';
  };
  
  get '/img/**' => sub {
      my ($path) = splat;
      my @splat = @{$path};
      my $dir = ls(config->{public}, '/img', @splat);
      return template 'dirlisting' if -d $dir;
      send_file("$dir", system_path =>1);
  };
  
  In your template:
  
  <div><a href="[% vars.ls_cdup %]">
  [% vars.ls_cdup %]</a>/[% vars.ls_name %]</div>
  
  [% FOREACH dir IN vars.ls_dirs %] ...
  
  [% FOREACH file IN vars.ls_files %] ...

=head1 DESCRIPTION

C<Dancer2::Plugin::Path::Class> exports the C<ls> function
returning a C<Path::Class> object. The C<ls> function also
sets the following vars:

=over

=item ls_name

The basename of the path.

=item ls_cdup

The parent of the request path.

=item ls_dirs

A list of subdirectories if the path is a directory object.
The subdirs are decorated with C<name>, C<file_count>
and a list of (sub) C<subdirs>. 

=item ls_files

A list of files or just one file if the path is a file object.
The files are decorated with C<name>, C<date>, C<size> and C<type>.

=back

All objects must be readable. Names starting with a dot ('.')
or ending with a tilde ('~') are ignored.

=head1 AUTHOR

Henk van Oers, HVOERS@cpan.org

=head1 CONTRIBUTORS

    Peter Mottram

=head1 COPYRIGHT and LICENSE

Copyright (c) Henk van Oers.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Path::Class>, L<Dancer2>

=cut
