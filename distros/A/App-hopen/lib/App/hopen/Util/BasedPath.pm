# App::hopen::Util::BasedPath - A path relative to a specified base
package App::hopen::Util::BasedPath;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use Exporter qw(import);
our @EXPORT; BEGIN { @EXPORT = qw(based_path); }

use Class::Tiny qw(path base),
{
    orig_cwd => undef,
};
    # TODO add custom accessors for `path` and `base` to enforce the
    # type of object instances.

# What we use
use Cwd;
use Getargs::Mixed;
use Path::Class;

# Docs {{{1

=head1 NAME

App::hopen::Util::BasedPath - A path relative to a specified base

=head1 SYNOPSIS

A C<BasedPath> represents a path to a file or directory, plus a directory with
respect to which that path is defined.  That means you can rebase the file or
dir while retaining the relative path.  Usage example:

    my $based = based_path(path => file('foo'), base => dir('bar'));
    $based->orig;                   # Path::Class::File for bar/foo
    $based->path_on(dir('quux'));   # Path::Class::File for quux/foo

=cut

# }}}1

=head1 MEMBERS

=head2 path

The path, as a L<Path::Class::File> or L<Path::Class::Dir> instance.
May not be specified as a string when creating a new object, since there's
no reliable way to tell whether a file or directory would be intended.

This must be a relative path, since the whole point of this module is to
combine partial paths!

=head2 base

A L<Path::Class::Dir> to which the L</path> is relative.
May be specified as a string for convenience; however, C<''> (the empty string)
is forbidden (to avoid confusion).  Use C<dir()> for the current directory
or C<dir('')> for the root directory.

=head2 orig_cwd

The working directory at the time the BasedPath instance was created.
This is an absolute path.

=head1 FUNCTIONS

=head2 is_file

Convenience function returning whether L</path> is a L<Path::Class::File>.

=cut

sub is_file {
    my ($self) = @_;    # NOTE: can't use `my $self = shift` because
                        # that invokes stringification, which causes an
                        # infinite loop when _stringify() calls this.
    croak 'Need an instance' unless ref $self;
    return $self->path->DOES('Path::Class::File');
} #is_file()

=head2 orig

Returns a C<Path::Class::*> representing L</path> relative to L</base>, i.e.,
the original location.

=cut

sub orig {
    my ($self) = @_;
    croak 'Need an instance' unless ref $self;

    my $classname = $self->is_file ?  'Path::Class::File' : 'Path::Class::Dir';
    return $classname->new(
            $self->base->components,
            $self->path->components
        );
} #orig()

=head2 path_wrt

Returns a C<Path::Class::*> representing the relative path from a given
directory to the original location.  (C<wrt> = With Respect To)  Example:

    # In directory "project"
    my $based = based_path(path => file('foo'), base => dir('bar'));
    $based->orig;                   # Path::Class::File for bar/foo
    $based->path_wrt('..');         # Path::Class::File for project/bar/foo

=cut

sub path_wrt {
    my ($self, %args) = parameters('self',['whence'], @_);
    return $self->orig->relative($args{whence});
} #path_wrt()

=head2 path_on

    my $new_path = $based_path->path_on($new_base);

Given a L<Path::Class::Dir>, return a C<Path::Class::*> instance representing
L</path>, but relative to C<$new_base> instead of to L</base>.

This is in some ways the opposite of C<Path::Class::File::relative()>:

    # in directory 'dir'
    my $file = file('foo.txt');     # The foo.txt in dir/
    say $file->relative('..');      # "dir/foo.txt" - same file, but
                                    # accessed from "..".

    my $based = based_path(path=>file('foo.txt'), base=>'');
        # Name foo.txt, based off dir
    say $based->path_on(dir('..')); # dir/../foo.txt - a different file

=cut

sub path_on {
    my ($self, $new_base) = @_;
    croak 'Need an instance' unless ref $self;
    croak 'Need a new base path' unless ref($new_base) &&
                                        $new_base->DOES('Path::Class::Dir');

    my $classname = $self->is_file ?  'Path::Class::File' : 'Path::Class::Dir';
    return $classname->new(
            $new_base->components,
            $self->path->components
        );
} #path_on()

=head2 _stringify

Stringify the instance in a way that is human-readable, but NOT suitable
for machine consumption.

=cut

sub _stringify {
    my ($self, $other, $swap) = @_;
    return ('``' . ($self->base) . "'' hosting " .
            ($self->is_file ? 'file ``': 'dir ``') .
            ($self->path) . "''"
    );
} #_stringify()

use overload
    '""' => '_stringify',
    fallback => 1;

=head2 BUILD

Sanity-check the arguments.

=cut

sub BUILD {
    my ($self) = @_;
    die 'Need an instance' unless ref $self;

    # --- path ---
    croak "path must be a Path::Class::*" unless $self->path &&
        ($self->path->DOES('Path::Class::Dir') ||
        $self->path->DOES('Path::Class::File'));
    croak "path must be relative" unless $self->path->is_relative;

    # --- base ---
    # Accept strings as base for convenience
    $self->base( dir($self->base) ) if !ref($self->base) && $self->base ne '';

    croak "base must be a Path::Class::Dir" unless $self->base &&
        $self->base->DOES('Path::Class::Dir');
    # TODO? make base absolute??

    # --- orig_cwd ---
    $self->orig_cwd(dir()->absolute);

} #BUILD()

=head1 STATIC FUNCTIONS

=head2 based_path

A synonym for C<< App::hopen::Util::BasedPath->new() >>.  Exported by default.

=cut

sub based_path {
    return __PACKAGE__->new(@_);
} #based_path()

1;
__END__
# vi: set fdm=marker: #
