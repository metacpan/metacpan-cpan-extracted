# App::GitFind::PathClassMicro.pm: Only the bits of Path::Class used in App::GitFind
# Licensed Artistic 1.

package App::GitFind::PathClassMicro;

our $VERSION = '0.000002';

##############################################################################
# Overall docs {{1

=head1 NAME

App::GitFind::PathClassMicro.pm - Only the bits of Path::Class used in App::GitFind

=head1 SYNOPSIS

This combines pieces of L<Path::Class::Entity>, L<Path::Class::File>, and
L<Path::Class::Dir> by Ken Williams.  Those are licensed under the same terms
as Perl itself.  This file is licensed under the Artistic license, and these
modifications are believed to be permissible under clause 3(a) of the
Artistic License.  This file is available for use and modification under the
terms of the Artistic License.

B<Modifications>: This file was modified by Christopher White
C<< <cxw@cpan.org> >> to combine files and remove functions I don't use in
L<App::GitFind>.

The remainder of the documentation comes from the individual modules.
Multiple packages are combined in this file.

=cut

# Path::Class is not included - we use the functions directly

# }}}1
##############################################################################
# Entity {{1

package App::GitFind::PathClassMicro::Entity;
use strict;
{
  $App::GitFind::PathClassMicro::Entity::VERSION = '0.37';
}

use File::Spec 3.26;
#use File::stat ();
use Cwd;
#use Carp();
sub croak { require Carp; goto &Carp::croak; }

use overload
  (
   q[""] => 'stringify',
   'bool' => 'boolify',
   fallback => 1,
  );

sub new {
  my $from = shift;
  my ($class, $fs_class) = (ref($from)
          ? (ref $from, $from->{file_spec_class})
          : ($from, $App::GitFind::PathClassMicro::Foreign));
  return bless {file_spec_class => $fs_class}, $class;
}

sub is_dir { 0 }

sub _spec_class {
  my ($class, $type) = @_;

  die "Invalid system type '$type'" unless ($type) = $type =~ /^(\w+)$/;  # Untaint
  my $spec = "File::Spec::$type";
  ## no critic
  eval "require $spec; 1" or die $@;
  return $spec;
}

sub new_foreign {
  my ($class, $type) = (shift, shift);
  local $App::GitFind::PathClassMicro::Foreign = $class->_spec_class($type);
  return $class->new(@_);
}

sub _spec { (ref($_[0]) && $_[0]->{file_spec_class}) || 'File::Spec' }

sub boolify { 1 }

sub is_absolute {
  # 5.6.0 has a bug with regexes and stringification that's ticked by
  # file_name_is_absolute().  Help it along with an explicit stringify().
  $_[0]->_spec->file_name_is_absolute($_[0]->stringify)
}

sub is_relative { ! $_[0]->is_absolute }

sub cleanup {
  my $self = shift;
  my $cleaned = $self->new( $self->_spec->canonpath("$self") );
  %$self = %$cleaned;
  return $self;
}

sub resolve {
  my $self = shift;
  croak($! . " $self") unless -e $self;  # No such file or directory
  my $cleaned = $self->new( scalar Cwd::realpath($self->stringify) );

  # realpath() always returns absolute path, kind of annoying
  $cleaned = $cleaned->relative if $self->is_relative;

  %$self = %$cleaned;
  return $self;
}

sub absolute {
  my $self = shift;
  return $self if $self->is_absolute;
  return $self->new($self->_spec->rel2abs($self->stringify, @_));
}

sub relative {
  my $self = shift;
  return $self->new($self->_spec->abs2rel($self->stringify, @_));
}

sub stat  { [stat("$_[0]")] }
sub lstat { [lstat("$_[0]")] }

sub PRUNE { return \&PRUNE; }

1;
# End of App::GitFind::PathClassMicro::Entity

=head1 NAME

App::GitFind::PathClassMicro::Entity - Base class for files and directories

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This class is the base class for C<App::GitFind::PathClassMicro::File> and
C<App::GitFind::PathClassMicro::Dir>, it is not used directly by callers.

=head1 AUTHOR

Ken Williams, kwilliams@cpan.org

=head1 SEE ALSO

L<Path::Class>

=cut

# }}}1
##############################################################################
# File {{{1

package App::GitFind::PathClassMicro::File;
{
  $App::GitFind::PathClassMicro::File::VERSION = '0.37';
}

use strict;

#use App::GitFind::PathClassMicro::Dir;
  # In the same file and has no import() - don't need to `use` it
use parent -norequire, qw(App::GitFind::PathClassMicro::Entity);
#use Carp;
sub croak { require Carp; goto &Carp::croak; }

use IO::File ();

sub new {
  my $self = shift->SUPER::new;
  my $file = pop();
  my @dirs = @_;

  my ($volume, $dirs, $base) = $self->_spec->splitpath($file);

  if (length $dirs) {
    push @dirs, $self->_spec->catpath($volume, $dirs, '');
  }

  $self->{dir}  = @dirs ? $self->dir_class->new(@dirs) : undef;
  $self->{file} = $base;

  return $self;
}

sub dir_class { "App::GitFind::PathClassMicro::Dir" }

sub as_foreign {
  my ($self, $type) = @_;
  local $App::GitFind::PathClassMicro::Foreign = $self->_spec_class($type);
  my $foreign = ref($self)->SUPER::new;
  $foreign->{dir} = $self->{dir}->as_foreign($type) if defined $self->{dir};
  $foreign->{file} = $self->{file};
  return $foreign;
}

sub stringify {
  my $self = shift;
  return $self->{file} unless defined $self->{dir};
  return $self->_spec->catfile($self->{dir}->stringify, $self->{file});
}

sub dir {
  my $self = shift;
  return $self->{dir} if defined $self->{dir};
  return $self->dir_class->new($self->_spec->curdir);
}
BEGIN { *parent = \&dir; }

sub volume {
  my $self = shift;
  return '' unless defined $self->{dir};
  return $self->{dir}->volume;
}

sub components {
  my $self = shift;
  croak "Arguments are not currently supported by File->components()" if @_;
  return ($self->dir->components, $self->basename);
}

sub basename { shift->{file} }
sub open  { IO::File->new(@_) }

sub openr { $_[0]->open('r') or croak "Can't read $_[0]: $!"  }
sub openw { $_[0]->open('w') or croak "Can't write to $_[0]: $!" }
sub opena { $_[0]->open('a') or croak "Can't append to $_[0]: $!" }

sub touch {
  my $self = shift;
  if (-e $self) {
    utime undef, undef, $self;
  } else {
    $self->openw;
  }
}

sub slurp {
  my ($self, %args) = @_;
  my $iomode = $args{iomode} || 'r';
  my $fh = $self->open($iomode) or croak "Can't read $self: $!";

  if (wantarray) {
    my @data = <$fh>;
    chomp @data if $args{chomped} or $args{chomp};

    if ( my $splitter = $args{split} ) {
      @data = map { [ split $splitter, $_ ] } @data;
    }

    return @data;
  }


  croak "'split' argument can only be used in list context"
    if $args{split};


  if ($args{chomped} or $args{chomp}) {
    chomp( my @data = <$fh> );
    return join '', @data;
  }


  local $/;
  return <$fh>;
}

sub spew {
    my $self = shift;
    my %args = splice( @_, 0, @_-1 );

    my $iomode = $args{iomode} || 'w';
    my $fh = $self->open( $iomode ) or croak "Can't write to $self: $!";

    if (ref($_[0]) eq 'ARRAY') {
        # Use old-school for loop to avoid copying.
        for (my $i = 0; $i < @{ $_[0] }; $i++) {
            print $fh $_[0]->[$i]
                or croak "Can't write to $self: $!";
        }
    }
    else {
        print $fh $_[0]
            or croak "Can't write to $self: $!";
    }

    close $fh
        or croak "Can't write to $self: $!";

    return;
}

sub spew_lines {
    my $self = shift;
    my %args = splice( @_, 0, @_-1 );

    my $content = $_[0];

    # If content is an array ref, appends $/ to each element of the array.
    # Otherwise, if it is a simple scalar, just appends $/ to that scalar.

    $content
        = ref( $content ) eq 'ARRAY'
        ? [ map { $_, $/ } @$content ]
        : "$content$/";

    return $self->spew( %args, $content );
}

sub remove {
  my $file = shift->stringify;
  return unlink $file unless -e $file; # Sets $! correctly
  1 while unlink $file;
  return not -e $file;
}

sub copy_to {
  my ($self, $dest) = @_;
  if ( eval{ $dest->isa("App::GitFind::PathClassMicro::File")} ) {
    $dest = $dest->stringify;
    croak "Can't copy to file $dest: it is a directory" if -d $dest;
  } elsif ( eval{ $dest->isa("App::GitFind::PathClassMicro::Dir") } ) {
    $dest = $dest->stringify;
    croak "Can't copy to directory $dest: it is a file" if -f $dest;
    croak "Can't copy to directory $dest: no such directory" unless -d $dest;
  } elsif ( ref $dest ) {
    croak "Don't know how to copy files to objects of type '".ref($self)."'";
  }

  require Perl::OSType;
  if ( !Perl::OSType::is_os_type('Unix') ) {

      require File::Copy;
      return unless File::Copy::cp($self->stringify, "${dest}");

  } else {

      return unless (system('cp', $self->stringify, "${dest}") == 0);

  }

  return $self->new($dest);
}

sub move_to {
  my ($self, $dest) = @_;
  require File::Copy;
  if (File::Copy::move($self->stringify, "${dest}")) {

      my $new = $self->new($dest);

      $self->{$_} = $new->{$_} foreach (qw/ dir file /);

      return $self;

  } else {

      return;

  }
}

sub traverse {
  my $self = shift;
  my ($callback, @args) = @_;
  return $self->$callback(sub { () }, @args);
}

sub traverse_if {
  my $self = shift;
  my ($callback, $condition, @args) = @_;
  return $self->$callback(sub { () }, @args);
}

1;
# End of App::GitFind::PathClassMicro::File

=head1 NAME

App::GitFind::PathClassMicro::File - Objects representing files

=head1 VERSION

version 0.37

=head1 SYNOPSIS

  use App::GitFind::PathClassMicro;  # Exports file() by default

  my $file = file('foo', 'bar.txt');  # App::GitFind::PathClassMicro::File object
  my $file = App::GitFind::PathClassMicro::File->new('foo', 'bar.txt'); # Same thing

  # Stringifies to 'foo/bar.txt' on Unix, 'foo\bar.txt' on Windows, etc.
  print "file: $file\n";

  if ($file->is_absolute) { ... }
  if ($file->is_relative) { ... }

  my $v = $file->volume; # Could be 'C:' on Windows, empty string
                         # on Unix, 'Macintosh HD:' on Mac OS

  $file->cleanup; # Perform logical cleanup of pathname
  $file->resolve; # Perform physical cleanup of pathname

  my $dir = $file->dir;  # A App::GitFind::PathClassMicro::Dir object

  my $abs = $file->absolute; # Transform to absolute path
  my $rel = $file->relative; # Transform to relative path

=head1 DESCRIPTION

The C<App::GitFind::PathClassMicro::File> class contains functionality for manipulating
file names in a cross-platform way.

=head1 METHODS

=over 4

=item $file = App::GitFind::PathClassMicro::File->new( <dir1>, <dir2>, ..., <file> )

=item $file = file( <dir1>, <dir2>, ..., <file> )

Creates a new C<App::GitFind::PathClassMicro::File> object and returns it.  The
arguments specify the path to the file.  Any volume may also be
specified as the first argument, or as part of the first argument.
You can use platform-neutral syntax:

  my $file = file( 'foo', 'bar', 'baz.txt' );

or platform-native syntax:

  my $file = file( 'foo/bar/baz.txt' );

or a mixture of the two:

  my $file = file( 'foo/bar', 'baz.txt' );

All three of the above examples create relative paths.  To create an
absolute path, either use the platform native syntax for doing so:

  my $file = file( '/var/tmp/foo.txt' );

or use an empty string as the first argument:

  my $file = file( '', 'var', 'tmp', 'foo.txt' );

If the second form seems awkward, that's somewhat intentional - paths
like C</var/tmp> or C<\Windows> aren't cross-platform concepts in the
first place, so they probably shouldn't appear in your code if you're
trying to be cross-platform.  The first form is perfectly fine,
because paths like this may come from config files, user input, or
whatever.

=item $file->stringify

This method is called internally when a C<App::GitFind::PathClassMicro::File> object is
used in a string context, so the following are equivalent:

  $string = $file->stringify;
  $string = "$file";

=item $file->volume

Returns the volume (e.g. C<C:> on Windows, C<Macintosh HD:> on Mac OS,
etc.) of the object, if any.  Otherwise, returns the empty string.

=item $file->basename

Returns the name of the file as a string, without the directory
portion (if any).

=item $file->components

Returns a list of the directory components of this file, followed by
the basename.

Note: unlike C<< $dir->components >>, this method currently does not
accept any arguments to select which elements of the list will be
returned.  It may do so in the future.  Currently it throws an
exception if such arguments are present.


=item $file->is_dir

Returns a boolean value indicating whether this object represents a
directory.  Not surprisingly, C<App::GitFind::PathClassMicro::File> objects always
return false, and L<App::GitFind::PathClassMicro::Dir> objects always return true.

=item $file->is_absolute

Returns true or false depending on whether the file refers to an
absolute path specifier (like C</usr/local/foo.txt> or C<\Windows\Foo.txt>).

=item $file->is_relative

Returns true or false depending on whether the file refers to a
relative path specifier (like C<lib/foo.txt> or C<.\Foo.txt>).

=item $file->cleanup

Performs a logical cleanup of the file path.  For instance:

  my $file = file('/foo//baz/./foo.txt')->cleanup;
  # $file now represents '/foo/baz/foo.txt';

=item $dir->resolve

Performs a physical cleanup of the file path.  For instance:

  my $file = file('/foo/baz/../foo.txt')->resolve;
  # $file now represents '/foo/foo.txt', assuming no symlinks

This actually consults the filesystem to verify the validity of the
path.

=item $dir = $file->dir

Returns a C<App::GitFind::PathClassMicro::Dir> object representing the directory
containing this file.

=item $dir = $file->parent

A synonym for the C<dir()> method.

=item $abs = $file->absolute

Returns a C<App::GitFind::PathClassMicro::File> object representing C<$file> as an
absolute path.  An optional argument, given as either a string or a
L<App::GitFind::PathClassMicro::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $rel = $file->relative

Returns a C<App::GitFind::PathClassMicro::File> object representing C<$file> as a
relative path.  An optional argument, given as either a string or a
C<App::GitFind::PathClassMicro::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $foreign = $file->as_foreign($type)

Returns a C<App::GitFind::PathClassMicro::File> object representing C<$file> as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

Any generated objects (subdirectories, files, parents, etc.) will also
retain this type.

=item $foreign = App::GitFind::PathClassMicro::File->new_foreign($type, @args)

Returns a C<App::GitFind::PathClassMicro::File> object representing a file as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

The arguments in C<@args> are the same as they would be specified in
C<new()>.

=item $fh = $file->open($mode, $permissions)

Passes the given arguments, including C<$file>, to C<< IO::File->new >>
(which in turn calls C<< IO::File->open >> and returns the result
as an L<IO::File> object.  If the opening
fails, C<undef> is returned and C<$!> is set.

=item $fh = $file->openr()

A shortcut for

 $fh = $file->open('r') or croak "Can't read $file: $!";

=item $fh = $file->openw()

A shortcut for

 $fh = $file->open('w') or croak "Can't write to $file: $!";

=item $fh = $file->opena()

A shortcut for

 $fh = $file->open('a') or croak "Can't append to $file: $!";

=item $file->touch

Sets the modification and access time of the given file to right now,
if the file exists.  If it doesn't exist, C<touch()> will I<make> it
exist, and - YES! - set its modification and access time to now.

=item $file->slurp()

In a scalar context, returns the contents of C<$file> in a string.  In
a list context, returns the lines of C<$file> (according to how C<$/>
is set) as a list.  If the file can't be read, this method will throw
an exception.

If you want C<chomp()> run on each line of the file, pass a true value
for the C<chomp> or C<chomped> parameters:

  my @lines = $file->slurp(chomp => 1);

You may also use the C<iomode> parameter to pass in an IO mode to use
when opening the file, usually IO layers (though anything accepted by
the MODE argument of C<open()> is accepted here).  Just make sure it's
a I<reading> mode.

  my @lines = $file->slurp(iomode => ':crlf');
  my $lines = $file->slurp(iomode => '<:encoding(UTF-8)');

The default C<iomode> is C<r>.

Lines can also be automatically split, mimicking the perl command-line
option C<-a> by using the C<split> parameter. If this parameter is used,
each line will be returned as an array ref.

    my @lines = $file->slurp( chomp => 1, split => qr/\s*,\s*/ );

The C<split> parameter can only be used in a list context.

=item $file->spew( $content );

The opposite of L</slurp>, this takes a list of strings and prints them
to the file in write mode.  If the file can't be written to, this method
will throw an exception.

The content to be written can be either an array ref or a plain scalar.
If the content is an array ref then each entry in the array will be
written to the file.

You may use the C<iomode> parameter to pass in an IO mode to use when
opening the file, just like L</slurp> supports.

  $file->spew(iomode => '>:raw', $content);

The default C<iomode> is C<w>.

=item $file->spew_lines( $content );

Just like C<spew>, but, if $content is a plain scalar, appends $/
to it, or, if $content is an array ref, appends $/ to each element
of the array.

Can also take an C<iomode> parameter like C<spew>. Again, the
default C<iomode> is C<w>.

=item $file->traverse(sub { ... }, @args)

Calls the given callback on $file. This doesn't do much on its own,
but see the associated documentation in L<App::GitFind::PathClassMicro::Dir>.

=item $file->remove()

This method will remove the file in a way that works well on all
platforms, and returns a boolean value indicating whether or not the
file was successfully removed.

C<remove()> is better than simply calling Perl's C<unlink()> function,
because on some platforms (notably VMS) you actually may need to call
C<unlink()> several times before all versions of the file are gone -
the C<remove()> method handles this process for you.

=item $st = $file->stat()

Invokes C<< File::stat::stat() >> on this file and returns a
L<File::stat> object representing the result.

MODIFIED: returns an arrayref of C<stat()> results.

=item $st = $file->lstat()

Same as C<stat()>, but if C<$file> is a symbolic link, C<lstat()>
stats the link instead of the file the link points to.

MODIFIED: returns an arrayref of C<lstat()> results.

=item $class = $file->dir_class()

Returns the class which should be used to create directory objects.

Generally overridden whenever this class is subclassed.

=item $copy = $file->copy_to( $dest );

Copies the C<$file> to C<$dest>. It returns a L<App::GitFind::PathClassMicro::File>
object when successful, C<undef> otherwise.

=item $moved = $file->move_to( $dest );

Moves the C<$file> to C<$dest>, and updates C<$file> accordingly.

It returns C<$file> is successful, C<undef> otherwise.

=back

=head1 AUTHOR

Ken Williams, kwilliams@cpan.org

=head1 SEE ALSO

L<Path::Class>, L<Path::Class::Dir>, L<File::Spec>

=cut

# }}}1
##############################################################################
# Dir {{{1

package App::GitFind::PathClassMicro::Dir;
{
  $App::GitFind::PathClassMicro::Dir::VERSION = '0.37';
}

use strict;

#use App::GitFind::PathClassMicro::File;
  # In the same file and has no import() - don't need to `use` it
#use Carp();
sub croak { require Carp; goto &Carp::croak; }
use parent -norequire, qw(App::GitFind::PathClassMicro::Entity);

#use IO::Dir ();
#use File::Path ();
#use File::Temp ();
use Scalar::Util ();

# updir & curdir on the local machine, for screening them out in
# children().  Note that they don't respect 'foreign' semantics.
my $Updir  = __PACKAGE__->_spec->updir;
my $Curdir = __PACKAGE__->_spec->curdir;

sub new {
  my $self = shift->SUPER::new();

  # If the only arg is undef, it's probably a mistake.  Without this
  # special case here, we'd return the root directory, which is a
  # lousy thing to do to someone when they made a mistake.  Return
  # undef instead.
  return if @_==1 && !defined($_[0]);

  my $s = $self->_spec;

  my $first = (@_ == 0     ? $s->curdir :
          !ref($_[0]) && $_[0] eq '' ? (shift, $s->rootdir) :
          shift()
        );

  $self->{dirs} = [];
  if ( Scalar::Util::blessed($first) && $first->isa("App::GitFind::PathClassMicro::Dir") ) {
    $self->{volume} = $first->{volume};
    push @{$self->{dirs}}, @{$first->{dirs}};
  }
  else {
    ($self->{volume}, my $dirs) = $s->splitpath( $s->canonpath("$first") , 1);
    push @{$self->{dirs}}, $dirs eq $s->rootdir ? "" : $s->splitdir($dirs);
  }

  push @{$self->{dirs}}, map {
    Scalar::Util::blessed($_) && $_->isa("App::GitFind::PathClassMicro::Dir")
      ? @{$_->{dirs}}
      : $s->splitdir( $s->canonpath($_) )
  } @_;


  return $self;
}

sub file_class { "App::GitFind::PathClassMicro::File" }

sub is_dir { 1 }

sub as_foreign {
  my ($self, $type) = @_;

  my $foreign = do {
    local $self->{file_spec_class} = $self->_spec_class($type);
    $self->SUPER::new;
  };

  # Clone internal structure
  $foreign->{volume} = $self->{volume};
  my ($u, $fu) = ($self->_spec->updir, $foreign->_spec->updir);
  $foreign->{dirs} = [ map {$_ eq $u ? $fu : $_} @{$self->{dirs}}];
  return $foreign;
}

sub stringify {
  my $self = shift;
  my $s = $self->_spec;
  return $s->catpath($self->{volume},
          $s->catdir(@{$self->{dirs}}),
          '');
}

sub volume { shift()->{volume} }

sub file {
  local $App::GitFind::PathClassMicro::Foreign = $_[0]->{file_spec_class} if $_[0]->{file_spec_class};
  return $_[0]->file_class->new(@_);
}

sub basename { shift()->{dirs}[-1] }

sub dir_list {
  my $self = shift;
  my $d = $self->{dirs};
  return @$d unless @_;

  my $offset = shift;
  if ($offset < 0) { $offset = $#$d + $offset + 1 }

  return wantarray ? @$d[$offset .. $#$d] : $d->[$offset] unless @_;

  my $length = shift;
  if ($length < 0) { $length = $#$d + $length + 1 - $offset }
  return @$d[$offset .. $length + $offset - 1];
}

sub components {
  my $self = shift;
  return $self->dir_list(@_);
}

sub subdir {
  my $self = shift;
  return $self->new($self, @_);
}

sub parent {
  my $self = shift;
  my $dirs = $self->{dirs};
  my ($curdir, $updir) = ($self->_spec->curdir, $self->_spec->updir);

  if ($self->is_absolute) {
    my $parent = $self->new($self);
    pop @{$parent->{dirs}} if @$dirs > 1;
    return $parent;

  } elsif ($self eq $curdir) {
    return $self->new($updir);

  } elsif (!grep {$_ ne $updir} @$dirs) {  # All updirs
    return $self->new($self, $updir); # Add one more

  } elsif (@$dirs == 1) {
    return $self->new($curdir);

  } else {
    my $parent = $self->new($self);
    pop @{$parent->{dirs}};
    return $parent;
  }
}

sub relative {
  # File::Spec->abs2rel before version 3.13 returned the empty string
  # when the two paths were equal - work around it here.
  my $self = shift;
  my $rel = $self->_spec->abs2rel($self->stringify, @_);
  return $self->new( length $rel ? $rel : $self->_spec->curdir );
}

#sub open  { IO::Dir->new(@_) }
#sub mkpath { File::Path::mkpath(shift()->stringify, @_) }
#sub rmtree { File::Path::rmtree(shift()->stringify, @_) }

sub remove {
  rmdir( shift() );
}

sub traverse {
  my $self = shift;
  my ($callback, @args) = @_;
  my @children = $self->children;
  return $self->$callback(
    sub {
      my @inner_args = @_;
      return map { $_->traverse($callback, @inner_args) } @children;
    },
    @args
  );
}

sub traverse_if {
  my $self = shift;
  my ($callback, $condition, @args) = @_;
  my @children = grep { $condition->($_) } $self->children;
  return $self->$callback(
    sub {
      my @inner_args = @_;
      return map { $_->traverse_if($callback, $condition, @inner_args) } @children;
    },
    @args
  );
}

sub recurse {
  my $self = shift;
  my %opts = (preorder => 1, depthfirst => 0, @_);

  my $callback = $opts{callback}
    or croak( "Must provide a 'callback' parameter to recurse()" );

  my @queue = ($self);

  my $visit_entry;
  my $visit_dir =
    $opts{depthfirst} && $opts{preorder}
    ? sub {
      my $dir = shift;
      my $ret = $callback->($dir);
      unless( ($ret||'') eq $self->PRUNE ) {
          unshift @queue, $dir->children;
      }
    }
    : $opts{preorder}
    ? sub {
      my $dir = shift;
      my $ret = $callback->($dir);
      unless( ($ret||'') eq $self->PRUNE ) {
          push @queue, $dir->children;
      }
    }
    : sub {
      my $dir = shift;
      $visit_entry->($_) foreach $dir->children;
      $callback->($dir);
    };

  $visit_entry = sub {
    my $entry = shift;
    if ($entry->is_dir) { $visit_dir->($entry) } # Will call $callback
    else { $callback->($entry) }
  };

  while (@queue) {
    $visit_entry->( shift @queue );
  }
}

sub children {
  my ($self, %opts) = @_;

  my $dh = $self->open or croak( "Can't open directory $self: $!" );

  my @out;
  while (defined(my $entry = $dh->read)) {
    next if !$opts{all} && $self->_is_local_dot_dir($entry);
    next if ($opts{no_hidden} && $entry =~ /^\./);
    push @out, $self->file($entry);
    $out[-1] = $self->subdir($entry) if -d $out[-1];
  }
  return @out;
}

sub _is_local_dot_dir {
  my $self = shift;
  my $dir  = shift;

  return ($dir eq $Updir or $dir eq $Curdir);
}

sub next {
  my $self = shift;
  unless ($self->{dh}) {
    $self->{dh} = $self->open or croak( "Can't open directory $self: $!" );
  }

  my $next = $self->{dh}->read;
  unless (defined $next) {
    delete $self->{dh};
    ## no critic
    return undef;
  }

  # Figure out whether it's a file or directory
  my $file = $self->file($next);
  $file = $self->subdir($next) if -d $file;
  return $file;
}

sub subsumes {
  croak "Too many arguments given to subsumes()" if $#_ > 2;
  my ($self, $other) = @_;
  croak( "No second entity given to subsumes()" ) unless defined $other;

  $other = $self->new($other) unless eval{$other->isa( "App::GitFind::PathClassMicro::Entity")};
  $other = $other->dir unless $other->is_dir;

  if ($self->is_absolute) {
    $other = $other->absolute;
  } elsif ($other->is_absolute) {
    $self = $self->absolute;
  }

  $self = $self->cleanup;
  $other = $other->cleanup;

  if ($self->volume || $other->volume) {
    return 0 unless $other->volume eq $self->volume;
  }

  # The root dir subsumes everything (but ignore the volume because
  # we've already checked that)
  return 1 if "@{$self->{dirs}}" eq "@{$self->new('')->{dirs}}";

  # The current dir subsumes every relative path (unless starting with updir)
  if ($self eq $self->_spec->curdir) {
    return $other->{dirs}[0] ne $self->_spec->updir;
  }

  my $i = 0;
  while ($i <= $#{ $self->{dirs} }) {
    return 0 if $i > $#{ $other->{dirs} };
    return 0 if $self->{dirs}[$i] ne $other->{dirs}[$i];
    $i++;
  }
  return 1;
}

sub contains {
  croak "Too many arguments given to contains()" if $#_ > 2;
  my ($self, $other) = @_;
  croak "No second entity given to contains()" unless defined $other;
  return unless -d $self and (-e $other or -l $other);

  # We're going to resolve the path, and don't want side effects on the objects
  # so clone them.  This also handles strings passed as $other.
  $self= $self->new($self)->resolve;
  $other= $self->new($other)->resolve;

  return $self->subsumes($other);
}

=for comment

sub tempfile {
  my $self = shift;
  return File::Temp::tempfile(@_, DIR => $self->stringify);
}

=cut

1;
# End of App::GitFind::PathClassMicro::Dir

=head1 NAME

App::GitFind::PathClassMicro::Dir - Objects representing directories

=head1 VERSION

version 0.37

=head1 SYNOPSIS

  use App::GitFind::PathClassMicro;  # Exports dir() by default

  my $dir = dir('foo', 'bar');       # App::GitFind::PathClassMicro::Dir object
  my $dir = App::GitFind::PathClassMicro::Dir->new('foo', 'bar');  # Same thing

  # Stringifies to 'foo/bar' on Unix, 'foo\bar' on Windows, etc.
  print "dir: $dir\n";

  if ($dir->is_absolute) { ... }
  if ($dir->is_relative) { ... }

  my $v = $dir->volume; # Could be 'C:' on Windows, empty string
                        # on Unix, 'Macintosh HD:' on Mac OS

  $dir->cleanup; # Perform logical cleanup of pathname
  $dir->resolve; # Perform physical cleanup of pathname

  my $file = $dir->file('file.txt'); # A file in this directory
  my $subdir = $dir->subdir('george'); # A subdirectory
  my $parent = $dir->parent; # The parent directory, 'foo'

  my $abs = $dir->absolute; # Transform to absolute path
  my $rel = $abs->relative; # Transform to relative path
  my $rel = $abs->relative('/foo'); # Relative to /foo

  print $dir->as_foreign('Mac');   # :foo:bar:
  print $dir->as_foreign('Win32'); #  foo\bar

  # Iterate with IO::Dir methods:
  my $handle = $dir->open;
  while (my $file = $handle->read) {
    $file = $dir->file($file);  # Turn into App::GitFind::PathClassMicro::File object
    ...
  }

  # Iterate with App::GitFind::PathClassMicro methods:
  while (my $file = $dir->next) {
    # $file is a App::GitFind::PathClassMicro::File or App::GitFind::PathClassMicro::Dir object
    ...
  }


=head1 DESCRIPTION

The C<App::GitFind::PathClassMicro::Dir> class contains functionality for manipulating
directory names in a cross-platform way.

=head1 METHODS

=over 4

=item $dir = App::GitFind::PathClassMicro::Dir->new( <dir1>, <dir2>, ... )

=item $dir = dir( <dir1>, <dir2>, ... )

Creates a new C<App::GitFind::PathClassMicro::Dir> object and returns it.  The
arguments specify names of directories which will be joined to create
a single directory object.  A volume may also be specified as the
first argument, or as part of the first argument.  You can use
platform-neutral syntax:

  my $dir = dir( 'foo', 'bar', 'baz' );

or platform-native syntax:

  my $dir = dir( 'foo/bar/baz' );

or a mixture of the two:

  my $dir = dir( 'foo/bar', 'baz' );

All three of the above examples create relative paths.  To create an
absolute path, either use the platform native syntax for doing so:

  my $dir = dir( '/var/tmp' );

or use an empty string as the first argument:

  my $dir = dir( '', 'var', 'tmp' );

If the second form seems awkward, that's somewhat intentional - paths
like C</var/tmp> or C<\Windows> aren't cross-platform concepts in the
first place (many non-Unix platforms don't have a notion of a "root
directory"), so they probably shouldn't appear in your code if you're
trying to be cross-platform.  The first form is perfectly natural,
because paths like this may come from config files, user input, or
whatever.

As a special case, since it doesn't otherwise mean anything useful and
it's convenient to define this way, C<< App::GitFind::PathClassMicro::Dir->new() >> (or
C<dir()>) refers to the current directory (C<< File::Spec->curdir >>).
To get the current directory as an absolute path, do C<<
dir()->absolute >>.

Finally, as another special case C<dir(undef)> will return undef,
since that's usually an accident on the part of the caller, and
returning the root directory would be a nasty surprise just asking for
trouble a few lines later.

=item $dir->stringify

This method is called internally when a C<App::GitFind::PathClassMicro::Dir> object is
used in a string context, so the following are equivalent:

  $string = $dir->stringify;
  $string = "$dir";

=item $dir->volume

Returns the volume (e.g. C<C:> on Windows, C<Macintosh HD:> on Mac OS,
etc.) of the directory object, if any.  Otherwise, returns the empty
string.

=item $dir->basename

Returns the last directory name of the path as a string.

=item $dir->is_dir

Returns a boolean value indicating whether this object represents a
directory.  Not surprisingly, L<App::GitFind::PathClassMicro::File> objects always
return false, and C<App::GitFind::PathClassMicro::Dir> objects always return true.

=item $dir->is_absolute

Returns true or false depending on whether the directory refers to an
absolute path specifier (like C</usr/local> or C<\Windows>).

=item $dir->is_relative

Returns true or false depending on whether the directory refers to a
relative path specifier (like C<lib/foo> or C<./dir>).

=item $dir->cleanup

Performs a logical cleanup of the file path.  For instance:

  my $dir = dir('/foo//baz/./foo')->cleanup;
  # $dir now represents '/foo/baz/foo';

=item $dir->resolve

Performs a physical cleanup of the file path.  For instance:

  my $dir = dir('/foo//baz/../foo')->resolve;
  # $dir now represents '/foo/foo', assuming no symlinks

This actually consults the filesystem to verify the validity of the
path.

=item $file = $dir->file( <dir1>, <dir2>, ..., <file> )

Returns a L<App::GitFind::PathClassMicro::File> object representing an entry in C<$dir>
or one of its subdirectories.  Internally, this just calls C<<
App::GitFind::PathClassMicro::File->new( @_ ) >>.

=item $subdir = $dir->subdir( <dir1>, <dir2>, ... )

Returns a new C<App::GitFind::PathClassMicro::Dir> object representing a subdirectory
of C<$dir>.

=item $parent = $dir->parent

Returns the parent directory of C<$dir>.  Note that this is the
I<logical> parent, not necessarily the physical parent.  It really
means we just chop off entries from the end of the directory list
until we cain't chop no more.  If the directory is relative, we start
using the relative forms of parent directories.

The following code demonstrates the behavior on absolute and relative
directories:

  $dir = dir('/foo/bar');
  for (1..6) {
    print "Absolute: $dir\n";
    $dir = $dir->parent;
  }

  $dir = dir('foo/bar');
  for (1..6) {
    print "Relative: $dir\n";
    $dir = $dir->parent;
  }

  ########### Output on Unix ################
  Absolute: /foo/bar
  Absolute: /foo
  Absolute: /
  Absolute: /
  Absolute: /
  Absolute: /
  Relative: foo/bar
  Relative: foo
  Relative: .
  Relative: ..
  Relative: ../..
  Relative: ../../..

=item @list = $dir->children

Returns a list of L<App::GitFind::PathClassMicro::File> and/or C<App::GitFind::PathClassMicro::Dir>
objects listed in this directory, or in scalar context the number of
such objects.  Obviously, it is necessary for C<$dir> to
exist and be readable in order to find its children.

Note that the children are returned as subdirectories of C<$dir>,
i.e. the children of F<foo> will be F<foo/bar> and F<foo/baz>, not
F<bar> and F<baz>.

Ordinarily C<children()> will not include the I<self> and I<parent>
entries C<.> and C<..> (or their equivalents on non-Unix systems),
because that's like I'm-my-own-grandpa business.  If you do want all
directory entries including these special ones, pass a true value for
the C<all> parameter:

  @c = $dir->children(); # Just the children
  @c = $dir->children(all => 1); # All entries

In addition, there's a C<no_hidden> parameter that will exclude all
normally "hidden" entries - on Unix this means excluding all entries
that begin with a dot (C<.>):

  @c = $dir->children(no_hidden => 1); # Just normally-visible entries


=item $abs = $dir->absolute

Returns a C<App::GitFind::PathClassMicro::Dir> object representing C<$dir> as an
absolute path.  An optional argument, given as either a string or a
C<App::GitFind::PathClassMicro::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $rel = $dir->relative

Returns a C<App::GitFind::PathClassMicro::Dir> object representing C<$dir> as a
relative path.  An optional argument, given as either a string or a
C<App::GitFind::PathClassMicro::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $boolean = $dir->subsumes($other)

Returns true if this directory spec subsumes the other spec, and false
otherwise.  Think of "subsumes" as "contains", but we only look at the
I<specs>, not whether C<$dir> actually contains C<$other> on the
filesystem.

The C<$other> argument may be a C<App::GitFind::PathClassMicro::Dir> object, a
L<App::GitFind::PathClassMicro::File> object, or a string.  In the latter case, we
assume it's a directory.

  # Examples:
  dir('foo/bar' )->subsumes(dir('foo/bar/baz'))  # True
  dir('/foo/bar')->subsumes(dir('/foo/bar/baz')) # True
  dir('foo/..')->subsumes(dir('foo/../bar))      # True
  dir('foo/bar' )->subsumes(dir('bar/baz'))      # False
  dir('/foo/bar')->subsumes(dir('foo/bar'))      # False
  dir('foo/..')->subsumes(dir('bar'))            # False! Use C<contains> to resolve ".."


=item $boolean = $dir->contains($other)

Returns true if this directory actually contains C<$other> on the
filesystem.  C<$other> doesn't have to be a direct child of C<$dir>,
it just has to be subsumed after both paths have been resolved.

=item $foreign = $dir->as_foreign($type)

Returns a C<App::GitFind::PathClassMicro::Dir> object representing C<$dir> as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

Any generated objects (subdirectories, files, parents, etc.) will also
retain this type.

=item $foreign = App::GitFind::PathClassMicro::Dir->new_foreign($type, @args)

Returns a C<App::GitFind::PathClassMicro::Dir> object representing C<$dir> as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

The arguments in C<@args> are the same as they would be specified in
C<new()>.

=item @list = $dir->dir_list([OFFSET, [LENGTH]])

Returns the list of strings internally representing this directory
structure.  Each successive member of the list is understood to be an
entry in its predecessor's directory list.  By contract, C<<
App::GitFind::PathClassMicro->new( $dir->dir_list ) >> should be equivalent to C<$dir>.

The semantics of this method are similar to Perl's C<splice> or
C<substr> functions; they return C<LENGTH> elements starting at
C<OFFSET>.  If C<LENGTH> is omitted, returns all the elements starting
at C<OFFSET> up to the end of the list.  If C<LENGTH> is negative,
returns the elements from C<OFFSET> onward except for C<-LENGTH>
elements at the end.  If C<OFFSET> is negative, it counts backward
C<OFFSET> elements from the end of the list.  If C<OFFSET> and
C<LENGTH> are both omitted, the entire list is returned.

In a scalar context, C<dir_list()> with no arguments returns the
number of entries in the directory list; C<dir_list(OFFSET)> returns
the single element at that offset; C<dir_list(OFFSET, LENGTH)> returns
the final element that would have been returned in a list context.

=item $dir->components

Identical to C<dir_list()>.  It exists because there's an analogous
method C<dir_list()> in the C<App::GitFind::PathClassMicro::File> class that also
returns the basename string, so this method lets someone call
C<components()> without caring whether the object is a file or a
directory.

=item (REMOVED) $fh = $dir->open()

Passes C<$dir> to C<< IO::Dir->open >> and returns the result as an
L<IO::Dir> object.  If the opening fails, C<undef> is returned and
C<$!> is set.

=item (REMOVED) $dir->mkpath($verbose, $mode)

Passes all arguments, including C<$dir>, to C<< File::Path::mkpath()
>> and returns the result (a list of all directories created).

=item (REMOVED) $dir->rmtree($verbose, $cautious)

Passes all arguments, including C<$dir>, to C<< File::Path::rmtree()
>> and returns the result (the number of files successfully deleted).

=item $dir->remove()

Removes the directory, which must be empty.  Returns a boolean value
indicating whether or not the directory was successfully removed.
This method is mainly provided for consistency with
C<App::GitFind::PathClassMicro::File>'s C<remove()> method.

=item (REMOVED) $dir->tempfile(...)

An interface to L<File::Temp>'s C<tempfile()> function.  Just like
that function, if you call this in a scalar context, the return value
is the filehandle and the file is C<unlink>ed as soon as possible
(which is immediately on Unix-like platforms).  If called in a list
context, the return values are the filehandle and the filename.

The given directory is passed as the C<DIR> parameter.

Here's an example of pretty good usage which doesn't allow race
conditions, won't leave yucky tempfiles around on your filesystem,
etc.:

  my $fh = $dir->tempfile;
  print $fh "Here's some data...\n";
  seek($fh, 0, 0);
  while (<$fh>) { do something... }

Or in combination with a C<fork>:

  my $fh = $dir->tempfile;
  print $fh "Here's some more data...\n";
  seek($fh, 0, 0);
  if ($pid=fork()) {
    wait;
  } else {
    something($_) while <$fh>;
  }


=item $dir_or_file = $dir->next()

A convenient way to iterate through directory contents.  The first
time C<next()> is called, it will C<open()> the directory and read the
first item from it, returning the result as a C<App::GitFind::PathClassMicro::Dir> or
L<App::GitFind::PathClassMicro::File> object (depending, of course, on its actual
type).  Each subsequent call to C<next()> will simply iterate over the
directory's contents, until there are no more items in the directory,
and then the undefined value is returned.  For example, to iterate
over all the regular files in a directory:

  while (my $file = $dir->next) {
    next unless -f $file;
    my $fh = $file->open('r') or die "Can't read $file: $!";
    ...
  }

If an error occurs when opening the directory (for instance, it
doesn't exist or isn't readable), C<next()> will throw an exception
with the value of C<$!>.

=item $dir->traverse( sub { ... }, @args )

Calls the given callback for the root, passing it a continuation
function which, when called, will call this recursively on each of its
children. The callback function should be of the form:

  sub {
    my ($child, $cont, @args) = @_;
    # ...
  }

For instance, to calculate the number of files in a directory, you
can do this:

  my $nfiles = $dir->traverse(sub {
    my ($child, $cont) = @_;
    return sum($cont->(), ($child->is_dir ? 0 : 1));
  });

or to calculate the maximum depth of a directory:

  my $depth = $dir->traverse(sub {
    my ($child, $cont, $depth) = @_;
    return max($cont->($depth + 1), $depth);
  }, 0);

You can also choose not to call the callback in certain situations:

  $dir->traverse(sub {
    my ($child, $cont) = @_;
    return if -l $child; # don't follow symlinks
    # do something with $child
    return $cont->();
  });

=item $dir->traverse_if( sub { ... }, sub { ... }, @args )

traverse with additional "should I visit this child" callback.
Particularly useful in case examined tree contains inaccessible
directories.

Canonical example:

  $dir->traverse_if(
    sub {
       my ($child, $cont) = @_;
       # do something with $child
       return $cont->();
    },
    sub {
       my ($child) = @_;
       # Process only readable items
       return -r $child;
    });

Second callback gets single parameter: child. Only children for
which it returns true will be processed by the first callback.

Remaining parameters are interpreted as in traverse, in particular
C<traverse_if(callback, sub { 1 }, @args> is equivalent to
C<traverse(callback, @args)>.

=item $dir->recurse( callback => sub {...} )

Iterates through this directory and all of its children, and all of
its children's children, etc., calling the C<callback> subroutine for
each entry.  This is a lot like what the L<File::Find> module does,
and of course C<File::Find> will work fine on L<App::GitFind::PathClassMicro> objects,
but the advantage of the C<recurse()> method is that it will also feed
your callback routine C<App::GitFind::PathClassMicro> objects rather than just pathname
strings.

The C<recurse()> method requires a C<callback> parameter specifying
the subroutine to invoke for each entry.  It will be passed the
C<App::GitFind::PathClassMicro> object as its first argument.

C<recurse()> also accepts two boolean parameters, C<depthfirst> and
C<preorder> that control the order of recursion.  The default is a
preorder, breadth-first search, i.e. C<< depthfirst => 0, preorder => 1 >>.
At the time of this writing, all combinations of these two parameters
are supported I<except> C<< depthfirst => 0, preorder => 0 >>.

C<callback> is normally not required to return any value. If it
returns special constant C<App::GitFind::PathClassMicro::Entity::PRUNE()> (more easily
available as C<< $item->PRUNE >>),  no children of analyzed
item will be analyzed (mostly as if you set C<$File::Find::prune=1>). Of course
pruning is available only in C<preorder>, in postorder return value
has no effect.

=item $st = $file->stat()

Invokes C<< File::stat::stat() >> on this directory and returns a
C<File::stat> object representing the result.

MODIFIED: returns an arrayref of C<stat()> results.

=item $st = $file->lstat()

Same as C<stat()>, but if C<$file> is a symbolic link, C<lstat()>
stats the link instead of the directory the link points to.

MODIFIED: returns an arrayref of C<lstat()> results.

=item $class = $file->file_class()

Returns the class which should be used to create file objects.

Generally overridden whenever this class is subclassed.

=back

=head1 AUTHOR

Ken Williams, kwilliams@cpan.org

=head1 SEE ALSO

L<Path::Class>, L<Path::Class::File>, L<File::Spec>

=cut


# }}}1
# vi: set fdm=marker: #
