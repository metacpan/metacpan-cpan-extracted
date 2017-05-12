package Data::PackageName;
use Moose;

=head1 NAME

Data::PackageName - OO handling of package name transformations

=head1 VERSION

0.01

=cut

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:PHAYLON';

use Scalar::Util        qw( blessed );
use Path::Class::File   ();
use Path::Class::Dir    ();
use Class::Inspector;
use namespace::clean    -except => [qw( meta )];

=head1 SYNOPSIS

  use Data::PackageName;

  my $foo = Data::PackageName->new('Foo');
  print "$foo\n";               # prints 'Foo'

  my $foo_bar = $foo->append('Bar');
  print "$foo_bar\n";           # prints 'Foo::Bar'

  my $quuxbaz_foo_bar = $foo_bar->prepend('QuuxBaz');
  print "$quuxbaz_foo_bar\n";   # prints 'QuuxBaz::Foo::Bar'

  my $bar = $quuxbaz_foo_bar->after_start(qw( QuuxBaz ));
  print "$bar\n";               # prints 'Bar'

  # prints QuuxBaz/Foo/Bar
  print join('/', $quuxbaz_foo_bar->parts), "\n";

  # prints quux_baz/foo/bar
  print join('/', $quuxbaz_foo_bar->parts_lc), "\n";

  # create a Path::Class::File and a Path::Class::Dir
  my $file = $quuxbaz_foo_bar->filename('.yml');
  my $dir  = $quuxbaz_foo_bar->dirname;
  print "$file\n";              # prints quux_baz/foo/bar.yml
  print "$dir\n";               # prints quux_baz/foo/bar

=head1 DESCRIPTION

This module provides the mostly simple functionality of transforming package 
names in common ways. I didn't write it because it is complicated, but rather
because I have done it once too often.

C<Data::PackageName> is a L<Moose> class. 

=cut

use overload
    q("")       => 'package',
    fallback    => 1;

=head1 ATTRIBUTES

=head2 package

A C<Str> representing the package name, e.g. C<Foo::Bar>. This attribute is
required and must be specified at creation time.

=cut

has package => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

=head1 METHODS

=head2 new

This method is inherited from L<Moose> and only referenced here for 
completeness. Please consult the Moose documentation for a complete
description of the object model.

  my $foo_bar = Data::PackageName->new(package => 'Foo::Bar');

The L</package> attribute is required.

=head2 meta

This method is imported from L<Moose> and only referenced here for
completeness. Please consult the Moose documentation for a complete
description of the object model.

The C<meta> method returns the Moose meta class.

=head2 append

  # Foo::Bar::Baz
  my $foo_bar_baz      = $foo_bar->append('Baz');

  # Foo::Bar::Baz::Qux
  my $foo_bar_baz_qux  = $foo_bar->append('Baz::Qux'); 

  # same as above
  my $foo_bar_baz_qux2 = $foo_bar->append(qw( Baz Qux ));

This method returns a new C<Data::PackageName> instance with its 
arguments appended as name parts. This means that C<qw( Foo Bar )> is
equivalent to C<Foo::Bar>.

=cut

sub append {
    my ($self, @parts) = @_;
    return blessed($self)->new(package => join '::', $self->package, @parts);
}

=head2 prepend

Does the same as L</append>, but rather than appending its arguments it
prepends the new package with them.

=cut

sub prepend {
    my ($self, @parts) = @_;
    return blessed($self)->new(package => join '::', @parts, $self->package);
}

=head2 after_start

You often want to get to the part of a module name that is under a 
specific namespace, for example to remove the project's root namespace
from the front.

  my $p = Data::PackageName->new(package => 'MyProject::Foo::Bar');
  print $p->after_start('MyProject'), "\n";     # prints 'Foo::Bar'

This method accepts values exactly as L</append> and L</prepend> do. The
argument list will be joined with C<::> as separator, so it doesn't 
matter how you pass the names in.

=cut

sub after_start {
    my ($self, @parts) = @_;

    my $start =  join '::', @parts;
    my $tail  =  $self->package;
    $tail     =~ s/^\Q$start\E:://;

    return blessed($self)->new(package => $tail);
}

=head2 parts

This splits up the namespace in parts.

  my $p = Data::PackageName->new(package => 'Foo::Bar::Baz');
  print join(', ', $p->parts), "\n"; # prints 'Foo, Bar, Baz'

=cut

sub parts {
    my ($self) = @_;
    return split /::/, $self->package;
}

=head2 transform_to_lc

This module uses a simple algorithm to transform namespace parts into
their lowercase representations. For example, C<Foo> would of course
become C<foo>, but C<FooBar> would result in C<foo_bar>.

  # prints 'foo'
  print Data::PackageName->transform_to_lc('Foo'), "\n";

  # prints 'foo_bar'
  print Data::PackageName->transform_to_lc('FooBar'), "\n";

=cut

sub transform_to_lc {
    my ($proto, $value) = @_;
    $value =~ s/\b ( \p{IsUpper} )/\l$1/gx;
    $value =~ s/   ( \p{IsUpper} )/_\l$1/gx;
    return $value;
}

=head2 parts_lc

The same as L</parts>, but each part will be transformed to lowercase
with L</transform_to_lc> first.

=cut

sub parts_lc {
    my ($self) = @_;
    return map { $self->transform_to_lc($_) } $self->parts;
}

=head2 filename_lc

This returns a L<Path::Class::File> object with a path containing the
lower-cased parts of the package name.

  # prints 'foo/bar_baz'
  my $p = Data::PackageName->new(package => 'Foo::BarBaz');
  print $p->filename_lc, "\n";

You can optionally specify a file extension that will be appended
to the filename.

  # prints 'foo/bar_baz.yml'
  my $p = Data::PackageName->new(package => 'Foo::BarBaz');
  print $p->filename_lc('.yml'), "\n";

=cut

sub filename_lc {
    my ($self, $ext) = @_;
    $ext ||= '';
    my ($file, @dirs_rev) = reverse $self->parts_lc;
    return Path::Class::File->new(reverse(@dirs_rev), $file . $ext);
}

=head2 dirname

Returns a L<Path::Class::Dir> object containing the lower-cased parts of
the package name.

  # prints 'foo/bar'
  my $p = Data::PackageName->new(package => 'Foo::Bar');
  print $p->dirname, "\n";

=cut

sub dirname {
    my ($self) = @_;
    return Path::Class::Dir->new($self->parts_lc);
}

=head2 package_filename

This will return a C<Path::Class::File> object containing the filename
the package corresponds to, e.g. C<Foo::Bar> would be an object with the
value C<Foo/Bar.pm>.

=cut

sub package_filename {
    my ($self) = @_;
    return Path::Class::File->new(Class::Inspector->filename($self->package));
}

=head2 require

This will try to load the package via Perl's C<require> builtin. It will
return true if it loaded the file, false if it was already loaded. 
Exceptions raised by C<require> will not be intercepted.

=cut

sub require {
    my ($self) = @_;
    return 0 if $self->is_loaded;
    require ''. $self->package_filename;
    return 1;
}

=head2 is_loaded

Returns true if the package is already loaded, false if it's not.

=cut

sub is_loaded {
    my ($self) = @_;
    return (Class::Inspector->loaded($self->package) ? 1 : 0);
}

1;

=head1 SEE ALSO

L<Moose> (Underlying object system),
L<Path::Class> (L</filename_lc> and L</dirname> methods)

=head1 REQUIREMENTS

L<Moose> (Underlying object system),
L<Scalar::Util> (C<blessed> for object recreation),
L<Path::Class::File> (Filenames),
L<Path::Class::Dir> (Dirnames),
L<Class::Inspector> (L</package_filename> transition and loaded-class detection)

=head1 AUTHOR AND COPYRIGHT

Robert 'phaylon' Sedlacek C<E<lt>rs@474.atE<gt>>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

