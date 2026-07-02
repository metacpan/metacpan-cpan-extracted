package App::Project::Doctor::Context;

# Context is the filesystem helper that every check plugin receives.
# It encapsulates the distribution root path and provides safe, validated
# access to files underneath it.  Checks must NEVER access the filesystem
# directly -- they must always go through Context methods.

use strict;
use warnings;
use autodie qw(:all);

# croak dies with the caller's file/line so errors point at the plugin, not here.
use Carp qw(croak carp);
# Readonly makes constants truly immutable; mutation throws at runtime.
use Readonly;
# File::Spec builds cross-platform paths (handles Windows backslashes).
use File::Spec;
# File::Find is loaded without importing its 'find' function to avoid namespace pollution.
use File::Find ();
# validate_strict enforces parameter schemas and throws immediately on failure.
use Params::Validate::Strict qw(validate_strict);
# Params::Get normalises @_ so both hash and hashref calling styles work.
use Params::Get;

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# File extensions that identify Perl source files.
# Used by perl_files() to filter results from _collect_files().
Readonly::Array my @PERL_EXTENSIONS => qw(.pm .pl .t .PL);

# Standard build-system files; the first one found is returned by builder_file().
Readonly::Array my @BUILDER_FILES   => qw(Makefile.PL Build.PL dist.ini cpanfile);

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
	my $class = shift;
	# validate_strict normalises args, applies defaults, and throws on bad input.
	my $args = validate_strict(
		args => Params::Get::get_params(undef, \@_) || {},
		schema => {
			# root must be an existing directory; defaults to the current directory.
			root    => { type => 'scalar', optional => 1, default => '.' },
			# verbose is passed through to check plugins that want progress output.
			verbose => { type => 'scalar', optional => 1, default => 0   },
		},
	);

	# Confirm root is an actual directory before we store it.
	croak "root '$args->{root}' is not a directory"
		unless -d $args->{root};

	# Convert root to an absolute path so all downstream operations are stable.
	return bless {
		root    => File::Spec->rel2abs($args->{root}),
		verbose => $args->{verbose},
	}, $class;
}

# ---------------------------------------------------------------------------
# Accessors  (read-only after construction)
# ---------------------------------------------------------------------------

# The absolute path to the distribution root directory.
sub root    { $_[0]->{root}    }
# Whether verbose progress messages should be emitted.
sub verbose { $_[0]->{verbose} }

# ---------------------------------------------------------------------------
# Public methods
# ---------------------------------------------------------------------------

=head2 has_file( $rel_path )

Returns true when C<$rel_path> (relative to root) exists on disk.

=cut

sub has_file {
	my ($self, $rel_path) = @_;
	croak 'has_file requires a relative path' unless defined $rel_path;
	# Route through abs_path so the path-traversal security check is inherited.
	return -e $self->abs_path($rel_path);
}

=head2 abs_path( $rel_path )

Returns the absolute filesystem path for C<$rel_path>.
Croaks if C<$rel_path> contains C<..> as a path component (path traversal).

=cut

sub abs_path {
	my ($self, $rel_path) = @_;
	croak 'abs_path requires a relative path' unless defined $rel_path;
	# Security: reject any path component that is exactly '..'.
	# This prevents a crafted check name or filename from escaping the root.
	croak "Path traversal detected in '$rel_path'"
		if grep { $_ eq '..' } File::Spec->splitdir($rel_path);
	return File::Spec->catfile($self->root, $rel_path);
}

=head2 slurp( $rel_path )

Reads and returns the entire UTF-8 content of C<$rel_path>.
Croaks if the file does not exist.

=cut

sub slurp {
	my ($self, $rel_path) = @_;
	# autodie wraps open() in an eval internally; 'local $@' protects the caller's $@.
	local $@;
	croak 'slurp requires a relative path' unless defined $rel_path;
	my $abs = $self->abs_path($rel_path);
	# Provide a clear error if the caller asks for a file that isn't there.
	croak "File not found: $abs" unless -f $abs;
	open my $fh, '<:encoding(UTF-8)', $abs;
	# Undefine $/ to enable slurp mode (read the entire file in one operation).
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

=head2 perl_files( @dirs )

Returns an arrayref of paths (relative to root) for all Perl source files
(.pm .pl .t .PL) found recursively under the given directories.
Defaults to lib/, script/, bin/, t/.

=cut

sub perl_files {
	my ($self, @dirs) = @_;
	# Default to the standard Perl source directories when none are specified.
	@dirs = qw(lib script bin t) unless @dirs;
	return $self->_collect_files(\@dirs, sub {
		my $file = shift;
		# Extract the file extension and check it against our known Perl extensions.
		my ($ext) = $file =~ /(\.[^.]+)$/;
		return defined $ext && grep { $ext eq $_ } @PERL_EXTENSIONS;
	});
}

=head2 lib_modules

Returns an arrayref of .pm paths (relative to root) found under lib/.

=cut

sub lib_modules {
	my $self = shift;
	# Delegate to find_files with a suffix filter for .pm files.
	return $self->find_files('lib', '.pm');
}

=head2 test_files

Returns an arrayref of .t paths (relative to root) found under t/.

=cut

sub test_files {
	my $self = shift;
	# Delegate to find_files with a suffix filter for .t files.
	return $self->find_files('t', '.t');
}

=head2 git_root

Returns the git repository root, or undef if not in a git repo.

=cut

sub git_root {
	my $self = shift;
	my $root = $self->root;
	# Ask git for the repository root; 2>/dev/null suppresses the error when
	# the directory is not inside any git repository.
	my $out  = qx{git -C \Q$root\E rev-parse --show-toplevel 2>/dev/null};
	chomp $out;
	# Return undef rather than an empty string when outside a git repo.
	return (length $out) ? $out : undef;
}

=head2 builder_file

Returns the name (relative to root) of the first found builder file, or undef.

=cut

sub builder_file {
	my $self = shift;
	# Return the first builder file that actually exists in the distro root.
	for my $f (@BUILDER_FILES) {
		return $f if $self->has_file($f);
	}
	# None of the known builder files were found.
	return undef;
}

=head2 find_files( $dir, $pattern )

Returns an arrayref of all files under C<$dir> matching C<$pattern>
(a string suffix or a compiled regexp).

=cut

sub find_files {
	my ($self, $dir, $pattern) = @_;
	croak 'find_files requires a directory' unless defined $dir;
	return $self->_collect_files([$dir], sub {
		my $rel = shift;
		# No pattern means "match everything".
		return 1 unless defined $pattern;
		# Accept either a compiled regexp or a plain string suffix.
		return ref $pattern eq 'Regexp' ? $rel =~ $pattern : $rel =~ /\Q$pattern\E$/;
	});
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Recursively walk a list of directories, filtering files with $accept.
# Entry:      $dirs is an arrayref of directory paths (relative to root).
#             $accept is a coderef ($rel_path) -> bool that filters results.
# Exit:       Arrayref of relative paths that passed the $accept filter.
# Side effects: Reads the filesystem (no writes).
sub _collect_files {
	my ($self, $dirs, $accept) = @_;
	my @found;
	for my $dir (@{$dirs}) {
		my $abs_dir = $self->abs_path($dir);
		# Skip directories that don't exist rather than croaking.
		next unless -d $abs_dir;
		File::Find::find({
			no_chdir => 1,    # Stay in one place; $_ is always absolute.
			wanted   => sub {
				return unless -f $_;    # Skip directories and symlinks.
				my $rel = File::Spec->abs2rel($_, $self->root);
				# Normalize to forward slashes on Windows where abs2rel uses backslashes.
				$rel =~ s{\\}{/}g;
				push @found, $rel if $accept->($rel);
			},
		}, $abs_dir);
	}
	return \@found;
}

1;

__END__

=head1 NAME

App::Project::Doctor::Context - Distro filesystem context passed to all checks

=head1 VERSION

0.02

=head1 SYNOPSIS

  use App::Project::Doctor::Context;

  my $ctx = App::Project::Doctor::Context->new(
      root    => '/path/to/my-dist',
      verbose => 1,
  );

  my $modules = $ctx->lib_modules;
  my $content = $ctx->slurp('lib/My/Module.pm')
      if $ctx->has_file('lib/My/Module.pm');

=head1 DESCRIPTION

Encapsulates the distribution root path and provides filesystem helpers.
All C<Check::*> plugins receive an instance; they must not access the
filesystem directly.

=head1 CONSTRUCTOR

=head2 new( %args )

  my $ctx = App::Project::Doctor::Context->new(
      root    => '/path/to/dist',  # must be an existing directory
      verbose => 0,
  );

Croaks when C<root> is not an existing directory.

=head3 API SPECIFICATION

=head4 Input

  root    : String  -- existing directory path   default '.'
  verbose : Bool                                  default 0

=head4 Output

Blessed hashref of type C<App::Project::Doctor::Context>.

=head1 ACCESSORS

C<root>, C<verbose> -- read-only.

=head1 METHODS

=head2 has_file( $rel_path )

=head3 API SPECIFICATION

=head4 Input

  $rel_path : String

=head4 Output

Bool.

=head2 abs_path( $rel_path )

=head3 API SPECIFICATION

=head4 Input

  $rel_path : String

=head4 Output

String -- absolute path.

=head2 slurp( $rel_path )

=head3 API SPECIFICATION

=head4 Input

  $rel_path : String

=head4 Output

String -- UTF-8 file content.

=head2 perl_files( @dirs )

=head3 API SPECIFICATION

=head4 Input

  @dirs : List of String  (default: lib script bin t)

=head4 Output

ArrayRef[String] -- relative paths.

=head2 lib_modules

ArrayRef[String] -- .pm files under lib/.

=head2 test_files

ArrayRef[String] -- .t files under t/.

=head2 git_root

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

String | undef.

=head2 builder_file

=head3 API SPECIFICATION

=head4 Input

None.

=head4 Output

String | undef -- first found of Makefile.PL Build.PL dist.ini cpanfile.

=head2 find_files( $dir, $pattern )

=head3 API SPECIFICATION

=head4 Input

  $dir     : String
  $pattern : String | Regexp | undef

=head4 Output

ArrayRef[String] -- relative paths.

=head3 MESSAGES

  Code | Trigger | Resolution
  -----|---------|----------
  (none currently defined)

=head3 FORMAL SPECIFICATION

  Context == [ root : Path, verbose : Bool ]

  has_file : Context x RelPath -> Bool
  has_file ctx p == exists (root ctx / p)

  slurp : Context x RelPath -> String
  dom slurp == { (ctx, p) | has_file ctx p }

=head1 LIMITATIONS

C<git_root> shells out to C<git>; returns undef when git is not installed.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
