package Any::Template::ProcessDir;
use 5.006;
use File::Basename;
use File::Find::Wanted;
use File::Path qw(make_path remove_tree);
use File::Slurp qw(read_file write_file);
use File::Spec::Functions qw(catfile catdir);
use Moose;
use Moose::Util::TypeConstraints;
use Try::Tiny;
use strict;
use warnings;
our $VERSION = '0.08'; #VERSION

has 'dest_dir'             => ( is => 'ro' );
has 'dir'                  => ( is => 'ro' );
has 'dir_create_mode'      => ( is => 'ro', isa => 'Int', default => oct(775) );
has 'file_create_mode'     => ( is => 'ro', isa => 'Int', default => oct(444) );
has 'ignore_files'         => ( is => 'ro', isa => 'CodeRef', default => sub { sub { 0 } } );
has 'process_file'         => ( is => 'ro', isa => 'CodeRef', lazy_build => 1 );
has 'process_text'         => ( is => 'ro', isa => 'CodeRef', lazy_build => 1 );
has 'readme_filename'      => ( is => 'ro', default => 'README' );
has 'same_dir'             => ( is => 'ro', init_arg => undef );
has 'source_dir'           => ( is => 'ro' );
has 'template_file_regex'  => ( is => 'ro', lazy_build => 1 );
has 'template_file_suffix' => ( is => 'ro', default => '.src' );

sub BUILD {
    my ( $self, $params ) = @_;

    die "you must pass one of dir and source_dir/dest_dir"
      if (
        defined( $self->dir ) ==
        ( defined( $self->source_dir ) && defined( $self->dest_dir ) ) );
    if ( defined( $self->dir ) ) {
        $self->{same_dir} = 1;
        $self->{source_dir} = $self->{dest_dir} = $self->dir;
    }
}

sub _build_template_file_regex {
    my $self                 = shift;
    my $template_file_suffix = $self->template_file_suffix;
    return
      defined($template_file_suffix) ? qr/\Q$template_file_suffix\E$/ : qr/.|/;
}

sub process_dir {
    my ($self) = @_;

    my $source_dir = $self->source_dir;
    my $dest_dir   = $self->dest_dir;

    if ( !$self->same_dir ) {
        remove_tree($dest_dir);
        die "could not remove '$dest_dir'" if -d $dest_dir;
    }

    my $ignore_files = $self->ignore_files;
    my @source_files =
      find_wanted( sub { -f && !$ignore_files->($File::Find::name) },
        $source_dir );
    my $template_file_suffix = $self->template_file_suffix;

    foreach my $source_file (@source_files) {
        $self->generate_dest_file($source_file);
    }

    if ( !$self->same_dir ) {
        $self->generate_readme();
        try { $self->generate_source_symlink() };
    }
}

sub generate_dest_file {
    my ( $self, $source_file ) = @_;

    my $template_file_regex = $self->template_file_regex;
    substr( ( my $dest_file = $source_file ), 0, length( $self->source_dir ) ) =
      $self->dest_dir;

    my $dest_text;
    if ( $source_file =~ $template_file_regex ) {
        $dest_file =
          substr( $dest_file, 0,
            -1 * length( $self->template_file_suffix || '' ) );
        my $code = $self->process_file;
        $dest_text = $code->( $source_file, $self );
    }
    elsif ( !$self->same_dir ) {
        $dest_text = read_file($source_file);
    }
    else {
        return;
    }

    if ( $self->same_dir ) {
        unlink($dest_file);
    }
    else {
        make_path( dirname($dest_file) );
        chmod( $self->dir_create_mode(), dirname($dest_file) )
          if defined( $self->dir_create_mode() );
    }

    write_file( $dest_file, $dest_text );
    chmod( $self->file_create_mode(), $dest_file )
      if defined( $self->file_create_mode() );
}

sub _build_process_file {
    return sub {
        my ( $file, $self ) = @_;

        my $code = $self->process_text;
        return $code->( read_file($file), $self );
      }
}

sub _build_process_text {
    return sub { die "must specify one of process_file or process_text" }
}

sub generate_readme {
    my $self = shift;

    if ( defined( $self->readme_filename ) ) {
        my $readme_file = catfile( $self->dest_dir, $self->readme_filename );
        unlink($readme_file);
        write_file(
            $readme_file,
            "Files in this directory generated from "
              . $self->source_dir . ".\n",
            "Do not edit files here, as they will be overwritten. Edit the source instead!"
        );
    }
}

sub generate_source_symlink {
    my $self = shift;

    # Create symlink from dest dir back to source dir.
    #
    my $source_link = catdir( $self->dest_dir, "source" );
    unlink($source_link) if -e $source_link;
    symlink( $self->source_dir, $source_link );
}

1;

__END__

=pod

=head1 NAME

Any::Template::ProcessDir -- Process a directory of templates

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Any::Template::ProcessDir;

    # Process templates and generate result files in a single directory
    #
    my $pd = Any::Template::ProcessDir->new(
        dir => '/path/to/dir',
        process_text => sub {
            my $template = Any::Template->new( Backend => '...', String => $_[0] );
            $template->process({ ... });
        }
    );
    $pd->process_dir();

    # Process templates and generate result files to a separate directory
    #
    my $pd = Any::Template::ProcessDir->new(
        source_dir => '/path/to/source/dir',
        dest_dir   => '/path/to/dest/dir',
        process_file => sub {
            my $file = $_[0];
            # do something with $file, return content
        }
    );
    $pd->process_dir();

=head1 DESCRIPTION

Recursively processes a directory of templates, generating a set of result
files in the same directory or in a parallel directory. Each file in the source
directory may be template-processed, copied, or ignored depending on its
pathname.

=head1 CONSTRUCTOR

=head2 Specifying directory/directories

=over

=item *

If you want to generate the result files in the B<same> directory as the
templates, just specify I<dir>.

    my $pd = Any::Template::ProcessDir->new(
        dir => '/path/to/dir',
        ...
    );

=item *

If you want to generate the result files in a B<separate> directory from the
templates, specify I<source_dir> and I<dest_dir>.

    my $pd = Any::Template::ProcessDir->new(
        source_dir => '/path/to/source/dir',
        dest_dir => '/path/to/dest/dir',
        ...
    );

=back

=head2 Specifying how to process templates

=over

=item process_file

A code reference that takes the full template filename and the
C<Any::Template::ProcessDir> object as arguments, and returns the result
string. This can use L<Any::Template> or another method altogether. By default
it calls L</process_text> on the contents of the file.

=item process_text

A code reference that takes the template text and the
C<Any::Template::ProcessDir> object as arguments, and returns the result
string. This can use L<Any::Template> or another method altogether.

=back

=head2 Optional parameters

=over

=item dir_create_mode

Permissions mode to use when creating destination directories. Defaults to
0775. No effect if you are using a single directory.

=item file_create_mode

Permissions mode to use when creating destination files. Defaults to 0444
(read-only), so that destination files are not accidentally edited.

=item ignore_files

Coderef which takes a full pathname and returns true if the file should be
ignored. By default, all files will be considered.

=item readme_filename

Name of a README file to generate in the destination directory - defaults to
"README". No file will be generated if you pass undef or if you are using a
single directory.

=item template_file_suffix

Suffix of template files in source directory. Defaults to ".src". This will be
removed from the destination file name.

Any file in the source directory that does not have this suffix (or
L</ignore_file_suffix>) will simply be copied to the destination.

=back

=head1 METHODS

=over

=item process_dir

Process the directory. If using multiple directories, the destination directory
will be removed completely and recreated, to eliminate any old files from
previous processing.

=back

=head1 SEE ALSO

L<Any::Template>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
