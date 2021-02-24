# ABSTRACT: Embed a self-extracting tarball in a Perl module.
package App::FilePacker;
use Moo;
use Archive::Tar;
use File::Find;
use Cwd;

our $VERSION = '0.001';

# Name of the module to create,
# used in the package declaration.
# ex: Foo::Bar
has name => (
    is => 'ro',
);

# Name of the file to output to.
# ex: Bar.pm
has out => (
    is => 'ro',
);

# Directory to package
has dir => (
    is  => 'ro',
    isa => sub {
        die "$_[0] is not a directory" unless -d $_[0];
    },
);

has tarball => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build_tarball {
    my ( $self ) = @_;

    my $tarball = Archive::Tar->new;


    my $orig = getcwd;
    chdir $self->dir
        or die "Failed to chdir to " . $self->dir . ": $!";

    find({
        wanted => sub {
            return if $_ =~ m|/\.\.?$|; # Skip . and ..
            $tarball->add_files( $_ );
        },
        no_chdir => 1,
    }, '.' );

    chdir $orig
        or die "Failed to chdir to $orig after tarball creation: $!";

    return $tarball;
}

# Body of module to extract embedded tar file.
has module_body => (
    is => 'ro',
    default => sub { return join "\n",
        'use warnings;',
        'use strict;',
        'use Archive::Tar;',
        'use File::Path qw( make_path );',
        '',
        'sub extract {',
        '    my ( $path ) = @_;',
        '',
        '    make_path( $path );',
        '',
        '    chdir $path',
        '        or die "Failed to move into path $path to extract files.\n";',
        '',
        '    Archive::Tar->new( \*DATA, 0, { extract => 1 } );',
        '}';
    },
);

sub write {
    my ( $self ) = @_;

    open my $sf, ">", $self->out
        or die "Failed to open " . $self->out . " for writing: $!";

    print $sf "package " . $self->name . ";\n";
    print $sf $self->module_body;
    print $sf "\n1;\n";
    print $sf "__DATA__\n";
    $self->tarball->write( $sf );
    close $sf;

}

1;

__END__

=encoding utf8

=head1 NAME

App::FilePacker - Embed a self-extracting tarball in a Perl module.

=head1 DESCRIPTION

This program allows you to pack a directory structure into a Perl module as a
self-extracting tarball.  The newly-created module provides an C<extract> method
that will allow you to unpack the tarball into a target directory.

=head1 SYNOPSIS

Create a module called B<Template::MyTemplate> in the output file B<MyTemplate.pm>,
containing all of the files in B</var/www/project/templates/mytemplate>.

 #!/usr/bin/env perl
 use warnings;
 use strict;
 use App::FilePacker;

 App::FilePacker->new(
    name => 'Template::MyTemplate',
    out  => 'MyTemplate.pm',
    dir  => '/var/www/project/templates/mytemplate',
 )->write;

Do the same thing, from the command line:

 $ filepacker MyTemplate.pm Template::MyTemplate /var/www/project/templates/mytemplate

You can unpack the Template::MyTemplate in code:

 #!/usr/bin/env perl
 use warnings;
 use strict;
 use Template::MyTemplate;

 Template::MyTemplate::extract('./dev/templates/mytemplate');

or on the command line:

 $ perl -MTemplate::MyTemplate -e'Template::MyTemplate::extract("./dev/templates/mytemplate")'

=head1 CONSTRUCTOR

The constructor takes the following arguments:

=head2 name

The name of the module to create, used in the package declaration.

=head2 out (REQUIRED)

The file to write the module out to when C<write> is called.

=head2 dir (REQUIRED)

The directory that will be packed, all files and directories under this directory
will be packed into a tarball that is embedded in the data section of the module.

=head2 module_body

This attribute can be set to replace the body of the module if you'd like to
customize the created module.  Read the C<write> function before setting this.

=head1 METHODS

=head2 write

Create the Perl module.

=head1 AUTHOR

Kaitlyn Parkhurst (SymKat) I<E<lt>symkat@symkat.comE<gt>> ( Blog: L<http://symkat.com/> )

=head1 CONTRIBUTORS

=head1 SPONSORS

=head1 COPYRIGHT

Copyright (c) 2021 the App::FilePacker L</AUTHOR>, L</CONTRIBUTORS>, and L</SPONSORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head1 AVAILABILITY

The most current version of App::FilePacker can be found at L<https://github.com/symkat/App-FilePacker>

