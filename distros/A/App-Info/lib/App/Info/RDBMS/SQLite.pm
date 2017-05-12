package App::Info::RDBMS::SQLite;

=head1 NAME

App::Info::RDBMS::SQLite - Information about SQLite

=head1 SYNOPSIS

  use App::Info::RDBMS::SQLite;

  my $sqlite = App::Info::RDBMS::SQLite->new;

  if ($sqlite->installed) {
      print "App name: ", $sqlite->name, "\n";
      print "Version:  ", $sqlite->version, "\n";
      print "Bin dir:  ", $sqlite->bin_dir, "\n";
  } else {
      print "SQLite is not installed. :-(\n";
  }

=head1 DESCRIPTION

App::Info::RDBMS::SQLite supplies information about the SQLite application
installed on the local system. It implements all of the methods defined by
App::Info::RDBMS. Methods that trigger events will trigger them only the first
time they're called (See L<App::Info|App::Info> for documentation on handling
events). To start over (after, say, someone has installed SQLite) construct a
new App::Info::RDBMS::SQLite object to aggregate new meta data.

Some of the methods trigger the same events. This is due to cross-calling of
shared subroutines. However, any one event should be triggered no more than
once. For example, although the info event "Executing `pg_config --version`"
is documented for the methods C<name()>, C<version()>, C<major_version()>,
C<minor_version()>, and C<patch_version()>, rest assured that it will only be
triggered once, by whichever of those four methods is called first.

=cut

##############################################################################

use strict;
use App::Info::RDBMS;
use App::Info::Util;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::RDBMS);
$VERSION = '0.57';
use constant WIN32 => $^O eq 'MSWin32';

my $u = App::Info::Util->new;

=head1 INTERFACE

=head2 Constructor

=head3 new

  my $sqlite = App::Info::RDBMS::SQLite->new(@params);

Returns an App::Info::RDBMS::SQLite object. See L<App::Info|App::Info> for a
complete description of argument parameters.

When it called, C<new()> searches the directories returned by
F<search_bin_dirs> for an executable with a name returned by
C<search_exe_names>. If found, it will be called by the object methods below
to gather the data necessary for each. If it cannot be found, then C<new()>
will attempt to load L<DBD::SQLite|DBD::SQLite> or
L<DBD::SQLite2|DBD::SQLite2>. These DBI drivers have SQLite embedded in them
but do not install the application. If these fail, then SQLite is assumed not
to be installed, and each of the object methods will return C<undef>.

B<Events:>

=over 4

=item info

Looking for SQLite.

=item confirm

Path to SQLite executable?

=item unknown

Path to SQLite executable?

=back

=cut

sub new {
    # Construct the object.
    my $self = shift->SUPER::new(@_);

    # Find pg_config.
    $self->info("Looking for SQLite");

    my @exes = $self->search_exe_names;
    if (my $cfg = $u->first_cat_exe(\@exes, $self->search_bin_dirs)) {
        # We found it. Confirm.
        $self->{executable} = $self->confirm(
            key      => 'path to sqlite',
            prompt   => "Path to SQLite executable?",
            value    => $cfg,
            callback => sub { -x },
            error    => 'Not an executable'
        );
    } else {
        $self->info("Looking for DBD::SQLite");
        # Try using DBD::SQLite, which includes SQLite.
        for my $dbd ('SQLite', 'SQLite2') {
            eval "use DBD::$dbd";
            next if $@;
            # Looks like DBD::SQLite is installed. Set up a temp database
            # handle so we can get information from it.
            require DBI;
            $self->{dbfile} = $u->catfile($u->tmpdir, 'tmpdb');
            $self->{dbh} = DBI->connect("dbi:$dbd:dbname=$self->{dbfile}","","");
            # I don't think there's any way to really confirm, so just return.
            return $self;
        }

        # Handle an unknown value.
        $self->{executable} = $self->unknown(
            key      => 'path to sqlite',
            prompt   => "Path to SQLite executable?",
            callback => sub { -x },
            error    => 'Not an executable'
        );
    }

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->{dbh}->disconnect if $self->{dbh};
    unlink $self->{dbfile} if $self->{dbfile};
}

##############################################################################

=head2 Class Method

=head3 key_name

  my $key_name = App::Info::RDBMS::SQLite->key_name;

Returns the unique key name that describes this class. The value returned is
the string "SQLite".

=cut

sub key_name { 'SQLite' }

##############################################################################

=head2 Object Methods

=head3 installed

  print "SQLite is ", ($sqlite->installed ? '' : 'not '), "installed.\n";

Returns true if SQLite is installed, and false if it is not.

App::Info::RDBMS::SQLite determines whether SQLite is installed based on the
presence or absence of the F<sqlite3> or F<sqlite> application on the file
system as found when C<new()> constructed the object. If SQLite does not
appear to be installed, then all of the other object methods will return empty
values.

=cut

sub installed { return $_[0]->{executable} || $_[0]->{dbh} ? 1 : undef }

##############################################################################

=head3 name

  my $name = $sqlite->name;

Returns the name of the application. App::Info::RDBMS::SQLite simply returns
the value returned by C<key_name> if SQLite is installed, and C<undef> if
it is not installed.

=cut

sub name { $_[0]->installed ? $_[0]->key_name : undef }

# This code reference is used by version(), major_version(),  minor_version(),
# and patch_version() to aggregate the data they need.
my $get_version = sub {
    my $self = shift;
    $self->{'--version'} = 1;
    my $version;

    if ($self->{executable}) {
        # Get the version number from the executable.
        $self->info(qq{Executing `"$self->{executable}" -version`});
        $version = `"$self->{executable}" -version`;
        unless ($version) {
            $self->error("Failed to find SQLite version with ".
                         "`$self->{executable} -version`");
            return;
        }
        chomp $version;

    } elsif ($self->{dbh}) {
        # Get the version number from the database handle.
        $self->info('Grabbing version from DBD::SQLite');
        $version = $self->{dbh}->{sqlite_version};
        unless ($version) {
            $self->error("Failed to retrieve SQLite version from DBD::SQLite");
            return;
        }

    } else {
        # No dice.
        return;
    }

    # Parse the version number.
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
    if (defined $x and defined $y and defined $z) {
        # Beta/devel/release candidates are treated as patch level "0"
        @{$self}{qw(version major minor patch)} =
          ($version, $x, $y, $z);
    } elsif ($version =~ /(\d+)\.(\d+)/) {
        # New versions, such as "3.0", are treated as patch level "0"
        @{$self}{qw(version major minor patch)} =
          ($version, $1, $2, 0);
    } else {
        $self->error("Failed to parse SQLite version parts from " .
                     "string '$version'");
    }
};

##############################################################################

=head3 version

  my $version = $sqlite->version;

Returns the SQLite version number. App::Info::RDBMS::SQLite parses the version
number from the system call C<`sqlite -version`> or retrieves it from
DBD::SQLite.

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retrieve SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

sub version {
    my $self = shift;
    return unless $self->installed;

    # Get data.
    $get_version->($self) unless $self->{'--version'};

    # Handle an unknown value.
    unless ($self->{version}) {
        # Create a validation code reference.
        my $chk_version = sub {
            # Try to get the version number parts.
            my ($x, $y, $z) = /^(\d+)\.(\d+).(\d+)$/;
            # Return false if we didn't get all three.
            return unless $x and defined $y and defined $z;
            # Save all three parts.
            @{$self}{qw(major minor patch)} = ($x, $y, $z);
            # Return true.
            return 1;
        };
        $self->{version} = $self->unknown( key      => 'sqlite version number',
                                           callback => $chk_version);
    }
    return $self->{version};
}

##############################################################################

=head3 major version

  my $major_version = $sqlite->major_version;

Returns the SQLite major version number. App::Info::RDBMS::SQLite parses the
version number from the system call C<`sqlite -version`> or retrieves it from
DBD::SQLite. For example, if C<version()> returns "3.0.8", then this method
returns "3".

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retrieve SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

# This code reference is used by major_version(), minor_version(), and
# patch_version() to validate a version number entered by a user.
my $is_int = sub { /^\d+$/ };

sub major_version {
    my $self = shift;
    return unless $self->installed;
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{major} = $self->unknown( key      => 'sqlite major version number',
                                     callback => $is_int)
      unless $self->{major};
    return $self->{major};
}

##############################################################################

=head3 minor version

  my $minor_version = $sqlite->minor_version;

Returns the SQLite minor version number. App::Info::RDBMS::SQLite parses the
version number from the system call C<`sqlite -version`> or retrieves it from
DBD::SQLite. For example, if C<version()> returns "3.0.8", then this method
returns "0".

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retrieve SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

sub minor_version {
    my $self = shift;
    return unless $self->installed;
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{minor} = $self->unknown( key      => 'sqlite minor version number',
                                     callback => $is_int)
      unless defined $self->{minor};
    return $self->{minor};
}

##############################################################################

=head3 patch version

  my $patch_version = $sqlite->patch_version;

Returns the SQLite patch version number. App::Info::RDBMS::SQLite parses the
version number from the system call C<`sqlite -version`> or retrieves it from
DBD::SQLite. For example, if C<version()> returns "3.0.8", then this method
returns "8".

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retrieve SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

sub patch_version {
    my $self = shift;
    return unless $self->installed;
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{patch} = $self->unknown( key      => 'sqlite patch version number',
                                     callback => $is_int)
      unless defined $self->{patch};
    return $self->{patch};
}

##############################################################################

=head3 executable

  my $executable = $sqlite->executable;

Returns the path to the SQLite executable, usually F<sqlite3> or F<sqlite>,
which will be defined by one of the names returned byC<search_exe_names()>.
The executable is searched for in C<new()>, so there are no events for this
method.

=cut

sub executable { shift->{executable} }

##############################################################################

=head3 bin_dir

  my $bin_dir = $sqlite->bin_dir;

Returns the SQLite binary directory path. App::Info::RDBMS::SQLite simply
retrieves it as the directory part of the path to the SQLite executable.

=cut

sub bin_dir {
    my $self = shift;
    return unless $self->{executable};
    unless (exists $self->{bin_dir} ) {
        my @parts = $u->splitpath($self->{executable});
        $self->{bin_dir} = $u->catdir(
            ($parts[0] eq '' ? () : $parts[0]),
            $u->splitdir($parts[1])
        );
    }
    return $self->{bin_dir};
}

##############################################################################

=head3 lib_dir

  my $lib_dir = $expat->lib_dir;

Returns the directory path in which an SQLite library was found. The directory
path will be one of the values returned by C<search_lib_dirs()>, where a file
with a name as returned by C<search_lib_names()> was found. No search is
performed if SQLite is not installed or if only DBD::SQLite is installed.

B<Events:>

=over 4

=item info

Searching for shared object library directory

=item error

Cannot find shared object library directory

=item unknown

Enter a valid Expat shared object library directory

=back

=cut

my $lib_dir = sub {
    my ($self, $key, $label) = (shift, shift, shift);
    return unless $self->{executable};
    $self->info("Searching for $label directory");
    my $dir;
    unless ($dir = $u->first_cat_dir(\@_, $self->search_lib_dirs)) {
        $self->error("Cannot find $label directory");
        $dir = $self->unknown(
            key      => "sqlite $key dir",
            callback => sub { $u->first_cat_dir(\@_, $_) },
            error    => "No $label found in directory "
        );
    }
    return $dir;

};

sub lib_dir {
    my $self = shift;
    return unless $self->{executable};
    $self->{lib_dir} = $self->$lib_dir('lib', 'library', $self->search_lib_names)
      unless exists $self->{lib_dir};
    return $self->{lib_dir};
}

##############################################################################

=head3 so_lib_dir

  my $so_lib_dir = $expat->so_lib_dir;

Returns the directory path in which an SQLite shared object library was
found. The directory path will be one of the values returned by
C<search_lib_dirs()>, where a file with a name as returned by
C<search_so_lib_names()> was found. No search is performed if SQLite is not
installed or if only DBD::SQLite is installed.

B<Events:>

=over 4

=item info

Searching for shared object library directory

=item error

Cannot find shared object library directory

=item unknown

Enter a valid Expat shared object library directory

=back

=cut

sub so_lib_dir {
    my $self = shift;
    return unless $self->{executable};
    $self->{so_lib_dir} = $self->$lib_dir('so', 'shared object library',
                                          $self->search_so_lib_names)
      unless exists $self->{so_lib_dir};
    return $self->{so_lib_dir};
}

##############################################################################

=head3 inc_dir

  my $inc_dir = $sqlite->inc_dir;

Returns the directory path in which an SQLite include file was found. The
directory path will be one of the values returned by C<search_inc_dirs()>,
where a file with a name as returned by C<search_inc_names()> was found. No
search is performed if SQLite is not installed or if only DBD::SQLite is
installed.

B<Events:>

=over 4

=item info

Searching for include directory

=item error

Cannot find include directory

=item unknown

Enter a valid SQLite include directory

=back

=cut

sub inc_dir {
    my $self = shift;
    return unless $self->{executable};
    unless (exists $self->{inc_dir}) {
        $self->info("Searching for include directory");
        # Should there be more paths than this?
        my @incs = $self->search_inc_names;

        if (my $dir = $u->first_cat_dir(\@incs, $self->search_inc_dirs)) {
            $self->{inc_dir} = $dir;
        } else {
            $self->error("Cannot find include directory");
            $self->{inc_dir} = $self->unknown(
                key      => 'sqlite inc dir',
                callback => sub { $u->first_cat_dir(\@incs, $_) },
                error    => "File 'sqlite.h' not found in directory"
            );
        }
    }
    return $self->{inc_dir};
}

##############################################################################

=head3 home_url

  my $home_url = $pg->home_url;

Returns the PostgreSQL home page URL.

=cut

sub home_url { "http://www.sqlite.org/" }

##############################################################################

=head3 download_url

  my $download_url = $pg->download_url;

Returns the PostgreSQL download URL.

=cut

sub download_url { "http://www.sqlite.org/download.html" }

##############################################################################

=head3 search_exe_names

  my @search_exe_names = $sqlite->search_exe_names;

Returns a list of possible names for the SQLite executable. The names are
F<sqlite3> and F<sqlite> by default (F<sqlite3.exe> and F<sqlite.exe> on
Win32).

=cut

sub search_exe_names {
    my $self = shift;
    my @exes = qw(sqlite3 sqlite);
    if (WIN32) { $_ .= ".exe" for @exes }
    return ($self->SUPER::search_exe_names, @exes);
}

##############################################################################

=head3 search_bin_dirs

  my @search_bin_dirs = $sqlite->search_bin_dirs;

Returns a list of possible directories in which to search an executable. Used
by the C<new()> constructor to find an executable to execute and collect
application info. The found directory will also be returned by the C<bin_dir>
method.

=cut

sub search_bin_dirs { (shift->SUPER::search_bin_dirs, $u->path) }

##############################################################################

=head3 search_lib_names

  my @seach_lib_names = $self->search_lib_nams

Returns a list of possible names for library files. Used by C<lib_dir()> to
search for library files. By default, the list is:

=over

=item libsqlite3.a

=item libsqlite3.la

=item libsqlite3.so

=item libsqlite3.so.0

=item libsqlite3.so.0.0.1

=item libsqlite3.dylib

=item libsqlite3.0.dylib

=item libsqlite3.0.0.1.dylib

=item libsqlite.a

=item libsqlite.la

=item libsqlite.so

=item libsqlite.so.0

=item libsqlite.so.0.0.1

=item libsqlite.dylib

=item libsqlite.0.dylib

=item libsqlite.0.0.1.dylib

=back

=cut

sub search_lib_names {
    my $self = shift;
    (my $exe = $u->splitpath($self->{executable})) =~ s/\.[^.]+$//;
    return $self->SUPER::search_lib_names,
      map { "lib$exe.$_"} qw(a la so so.0 so.0.0.1 dylib 0.dylib 0.0.1.dylib);
}

##############################################################################

=head3 search_so_lib_names

  my @seach_so_lib_names = $self->search_so_lib_nams

Returns a list of possible names for shared object library files. Used by
C<so_lib_dir()> to search for library files. By default, the list is:

=over

=item libsqlite3.so

=item libsqlite3.so.0

=item libsqlite3.so.0.0.1

=item libsqlite3.dylib

=item libsqlite3.0.dylib

=item libsqlite3.0.0.1.dylib

=item libsqlite.so

=item libsqlite.so.0

=item libsqlite.so.0.0.1

=item libsqlite.dylib

=item libsqlite.0.dylib

=item libsqlite.0.0.1.dylib

=back

=cut

sub search_so_lib_names {
    my $self = shift;
    (my $exe = $u->splitpath($self->{executable})) =~ s/\.[^.]+$//;
    return $self->SUPER::search_so_lib_names,
      map { "lib$exe.$_"}
        qw(so so.0 so.0.0.1 dylib 0.dylib 0.0.1.dylib);
}

##############################################################################

=head3 search_lib_dirs

  my @search_lib_dirs = $sqlite->search_lib_dirs;

Returns a list of possible directories in which to search for libraries. By
default, it returns all of the paths in the C<libsdirs> and C<loclibpth>
attributes defined by the Perl L<Config|Config> module -- plus F</sw/lib> (in
support of all you Fink users out there).

=cut

sub search_lib_dirs { shift->SUPER::search_lib_dirs, $u->lib_dirs, '/sw/lib' }

##############################################################################

=head3 search_inc_names

  my @search_inc_names = $sqlite->search_inc_names;

Returns a list of include file names to search for. Used by C<inc_dir()> to
search for an include file. By default, the names are F<sqlite3.h> and
F<sqlite.h>.

=cut

sub search_inc_names {
    my $self = shift;
    (my $exe = $u->splitpath($self->{executable})) =~ s/\.[^.]+$//;
    return $self->SUPER::search_inc_names, "$exe.h";
}

##############################################################################

=head3 search_inc_dirs

  my @search_inc_dirs = $sqlite->search_inc_dirs;

Returns a list of possible directories in which to search for include files.
Used by C<inc_dir()> to search for an include file. By default, the
directories are:

=over 4

=item /usr/local/include

=item /usr/include

=item /sw/include

=back

=cut

sub search_inc_dirs {
    shift->SUPER::search_inc_dirs,
      qw(/usr/local/include
         /usr/include
         /sw/include);
}

1;
__END__

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/app-info/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/app-info/issues/> or by sending mail to
L<bug-App-Info@rt.cpan.org|mailto:bug-App-Info@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<App::Info|App::Info> documents the event handling interface.

L<App::Info::RDBMS|App::Info::RDBMS> is the App::Info::RDBMS parent class from
which App::Info::RDBMS::SQLite inherits.

L<DBD::SQLite|DBD::SQLite> is the L<DBI|DBI> driver for connecting to SQLite
databases.

L<http://www.sqlite.org/> is the SQLite home page.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
