package App::ReorderGoProFiles;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";



1;
__END__

=encoding utf-8

=head1 NAME

App::ReorderGoProFiles - Reorder GoPro files

=head1 SYNOPSIS

    Usage:
          reorder-gopro-files [-c | --copy]
                              [-m | --move]
                              [-f | --force]
                              <files>...

=head1 DESCRIPTION

C<reorder-gopro-files> reorders (symlinks, copies or moves) GoPro video files
so it is easier to work with. For example:

    GOPR001.MP4
    GP01001.MP4

is renamed to

    GP001-00.MP4
    GP001-01.MP4

=head1 LICENSE

Copyright (C) vti.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

vti E<lt>viacheslav.t@gmail.comE<gt>

=cut

