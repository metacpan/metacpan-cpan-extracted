use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package App::datasection 0.01 {

    # ABSTRACT: Work with __DATA__ section files from the command line
    # VERSION

    use App::Cmd::Setup -app;

}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::datasection - Work with __DATA__ section files from the command line

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 datasection extract t/foo.t
 datasection diff t/foo.t
 datasection insert t/foo.t

=head1 DESCRIPTION

This tool is for working with C<__DATA__> section files, and lets you
extract, manipulate and re-insert into the C<__DATA__> section of Perl
source files.  This tool provides these subcommands:

=over 4

=item L<extract|App::datasection::Command::extract>

 datasection extract [ -d DIRECTORY ] SOURCE [ SOURCE ... ]

Extract files from a C<__DATA__> section into the filesystem.

=item L<diff|App::datasection::Command::diff>

 datasection diff [ -d DIRECTORY ] SOURCE [ SOURCE ... ]

See the differences between the filesystem and the C<__DATA__>
section in the Perl source file.

=item L<insert|App::datasection::Command::insert>

 datasection insert [ -d DIRECTORY ] SOURCE [ SOURCE ... ]

Insert the files from the filesystem into Perl source C<__DATA__>
section.

=back

=head1 SEE ALSO

=over 4

=item L<Data::Section::Writer>

=item L<Data::Section::Pluggable>

=back

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
