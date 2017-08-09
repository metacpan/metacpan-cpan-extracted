#!/usr/bin/perl -w
use v5.14;

use App::Gallery;
use Getopt::Long;

my %args;

GetOptions (
	'out|o=s' => \$args{out},
	'tmpl=s' => \$args{tmpl},
	'title=s' => \$args{title},
	'width=i' => \$args{width},
	'height=i' => \$args{height},
);

die "Argument --out PATH is mandatory\n" unless $args{out};

App::Gallery->run(\%args, @ARGV);

__END__

=encoding utf-8

=head1 NAME

gallery.pl - very basic image gallery script

=head1 SYNOPSIS

  gallery.pl --out DIR [--tmpl TEMPLATE]
    [--width PIXELS] [--height PIXELS] [--title TITLE] IMAGE...

=head1 DESCRIPTION

gallery.pl creates basic image galleries. Pass an output directory and
a list of images to the script. The images will be hard linked into
the directory (or copied if hard linking fails), then thumbnails will
be created for the images, and finally an F<index.html> file linking
to all the images will be created in the directory.

=head1 OPTIONS

=over

=item B<--out> I<path>

Directory to create everything in. Created if it does not exist. Mandatory.

=item B<--tmpl> I<template>

Path to template file, in HTML::Template::Compiled format.

=item B<--width> I<width>

Maximum width of thumbnails, in pixels. Defaults to 600.

=item B<--height> I<height>

Maximum height of thumbnails, in pixels. Defaults to 600.

=item B<--title> I<title>

Title of HTML page. Defaults to 'Gallery'.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
