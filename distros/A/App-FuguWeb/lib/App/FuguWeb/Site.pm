# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::FuguWeb::Site;
our $VERSION = '0.11.2';

use App::FuguWeb;
use App::FuguWeb::Fragment;
use App::FuguWeb::Index;
use App::FuguWeb::Keys;
use App::FuguWeb::Page;
use App::FuguWeb::Render;
use File::Find ();
use File::Path qw(remove_tree);
use File::Spec;
use Fugu::File;
use Fugu::Log;
use POSIX ();

# App::FuguWeb::Site - the whole build.
#
# One method renders the site: probe the renderers, refuse an output
# directory that no build may own or that holds a source, hold every
# source to UTF-8, lint every manual source, stage the mdoc sources,
# copy the assets, render every page of each language tree and the
# pages of the top level, fit each fragment to its page through
# App::FuguWeb::Fragment, remove the staging, and remove what the site
# no longer holds. Each step reports its own failure and stops the
# build. A site that is half rendered must not look like a success.
#
# The build reads each source through the decode of App::FuguWeb, and
# writes each page through its encode, per WEB-SITE-5.
#
# The build reads nothing from the network, writes nothing outside the
# output directory, and gives the same bytes for the same checkout.

# The staging directory for the mdoc sources, inside the output
# directory. mandoc decides between a local link and a link to the
# manual host by looking for a file named %N.%S in its working
# directory, so every source has to sit in one place under the name
# that a cross-reference uses.
#
# App::FuguWeb holds the name, because the description must refuse a
# key directory that would collide with it.
use constant STAGING_DIR => App::FuguWeb::STAGING_DIR;

# The stylesheet that ships with the tool, under the share path.
use constant SHARE_STYLESHEET => 'share/fuguweb/style.css';

# App::FuguWeb::Site->new(%args):
#	config => $config	the site description (required)
#	out    => $dir		the output directory (required)
#	log    => $logger	default: Fugu::Log->default
#	render => $render	default: one over the same description
sub new ( $class, %args )
{
	my $config = $args{config};
	die 'config parameter required'
	    unless defined $config;

	my $log = $args{log} // Fugu::Log->default;

	# A trailing slash would break each path that this class cuts
	# out of a walk. File::Find writes the root without one, so
	# the substr that makes a relative path would run past the
	# end and answer undef. The clean reads that answer as 'no
	# stranger', and it would then remove a tree that it never
	# looked at.
	my $out = $args{out};
	$out =~ s{(?<=.)/+\z}{} if defined $out;

	return bless {
		config => $config,
		out    => $out,
		log    => $log,
		render => $args{render} // App::FuguWeb::Render->new(
			config => $config,
			log    => $log
		),
	}, $class;
}

# $self->config:
#	The site description.
sub config ($self) { return $self->{config}; }

# $self->staging($language):
#	The mdoc staging directory, or the directory of one language
#	inside it when the caller names one. It lives inside the
#	output directory and never reaches the published tree.
#
#	Each language stages its own sources in its own directory,
#	under the path of its tree, per WEB-OUTPUT-14. mandoc reads its
#	working directory to decide a link.
sub staging ( $self, $language = undef )
{
	my $staging = $self->{out} . '/' . STAGING_DIR;

	return defined $language ? "$staging/" . $language->path : $staging;
}

# $self->missing_tool:
#	The renderer that failed the probe of the last build, or
#	undef. The caller maps it to its own exit code without a
#	second probe.
sub missing_tool ($self)
{
	return $self->{missing_tool};
}

# $self->build:
#	Render the whole site. The method returns true on success, and
#	undef with a message in the log otherwise. The probe comes
#	first, so the failure names the tool that is missing and never
#	blames a manual source for it.
sub build ($self)
{
	$self->{missing_tool} = $self->{render}->probe;
	if ( defined $self->{missing_tool} ) {
		$self->{log}
		    ->error( '%s is not installed', $self->{missing_tool} );
		return;
	}

	$self->_check_target    or return;
	$self->_check_text      or return;
	$self->_lint            or return;
	$self->_prepare_output  or return;
	$self->_stage_mdoc      or return;
	$self->_copy_stylesheet or return;
	$self->_copy_assets     or return;
	$self->_write_keys      or return;
	$self->_render_pages    or return;
	$self->_render_manuals  or return;

	# Staging is a build detail. A published tree that carries it
	# would serve the mdoc sources beside the pages made from them.
	$self->_drop_staging or return;

	return $self->_prune_output;
}

# $self->clean:
#	Remove the output directory. The method returns true when the
#	directory is gone, whether or not it was there to begin with.
#
#	The method removes a built site and refuses anything else. It
#	deletes a tree without asking, so the one thing it must never
#	do is delete a tree the build did not make.
sub clean ($self)
{
	$self->_check_target or return;
	return 1 unless -d $self->{out};

	$self->_built_here or return;

	my $stranger = $self->_stranger;
	if ( defined $stranger ) {
		$self->{log}->error(
'%s holds %s, which no build made; refusing to remove it',
			$self->{out}, $stranger
		);
		return;
	}

	remove_tree( $self->{out}, { safe => 0 } );

	return -e $self->{out} ? undef : 1;
}

# $self->_built_here:
#	Whether the output directory can be the output of any build.
#
#	A description that did not load names nothing, so the rules
#	of _stranger fall back to "plain files of the top level and of
#	the declared language trees". A key directory reads exactly like that,
#	and so does a source directory. The clean is the command an operator reaches for
#	when a description is broken, so that fallback runs on the
#	real path and not on an edge.
#
#	Every build writes the stylesheet, whatever the description
#	holds. A target without it is therefore the output of no
#	build, and the clean refuses it.
sub _built_here ($self)
{
	return 1 if defined $self->{config}->path;

	my $sheet = App::FuguWeb::STYLESHEET;
	return 1 if -f "$self->{out}/$sheet";

	$self->{log}->error(
		'%s holds no %s, so no build made it; refusing to remove it',
		$self->{out}, $sheet );

	return;
}

# $self->_stranger:
#	The first entry of the output directory that no build makes,
#	or undef when every entry is one.
#
#	A build writes plain files: the top level, one flat directory
#	for each declared language tree, the key directory tree, and
#	the staging directory while it runs. A directory that the
#	description does not name, and that is no declared tree, is
#	therefore not part of a site, and so is anything below it. The
#	tree of a language that the description dropped is one such
#	directory, per WEB-OUTPUT-4.
#
#	The clean deletes the tree without asking, so it refuses
#	whatever it cannot account for. It reads the same predicate
#	that the prune reads, so a build can never remove a file that
#	the clean refuses.
sub _stranger ($self)
{
	my $named = $self->_named;

	my @found;
	File::Find::find( {
			no_chdir => 1,
			wanted   => sub { push @found, $File::Find::name },
		},
		$self->{out} );

	for my $path ( sort @found ) {
		next if $path eq $self->{out};

		my $relative = substr $path, 1 + length $self->{out};

		# A symlink is never something that a build wrote.
		return $relative if -l $path;

		# The staging directory is a build detail, and the
		# build writes one flat directory of sources into it for
		# each language. A tree of another shape is somebody
		# else's.
		if ( App::FuguWeb::path_below( $relative, STAGING_DIR ) ) {
			my $dir = -d $path;
			next
			    if $self->_staged( $relative, $dir )
			    && ( $dir || $self->_build_made($relative) );
			return $relative;
		}

		# A directory holds a name of the site, or a name of the
		# key directory tree, or it is a declared language tree.
		# Every other one holds the files of whoever made it.
		if ( -d $path ) {
			next if _holds( $named, $relative );
			next if $self->_key_dir($relative);
			next if $self->_tree_dir($relative);
			return $relative;
		}

		# A plain file that a build writes, and nothing else.
		# The prune reads the same two tests, so the build can
		# never remove a file that the clean refuses.
		return $relative
		    unless $self->_build_made($relative)
		    && $self->_owns( $relative, $named );
	}

	return;
}

# $self->_named:
#	Every path that the site holds, as a hash reference. The set
#	is empty for a description that did not load, so the clean
#	then accepts what _owns and _tree_dir take, and no more.
sub _named ($self)
{
	my $config = $self->{config};
	return {} unless defined $config->path;

	return { map { $_ => 1 } $config->inventory };
}

# $self->_owns($path, $named):
#	Report whether a build writes a path of the output.
#
#	A name of the top level is one that a build writes, whatever
#	the description names today. So is a name one level below the
#	tree of a declared language: a renamed manual leaves its old
#	page there. A name below the root is one that the site holds,
#	or one of the shape that the key directory takes.
#
#	The prune and the clean read this one predicate, so the build
#	can never remove a file that the clean refuses.
sub _owns ( $self, $path, $named )
{
	return 1 unless $path =~ m{/};
	return 1 if $named->{$path};
	return 1 if $self->_tree_file($path);

	return App::FuguWeb::Keys->shaped( $self->{config}, $path );
}

# $self->_tree_dir($path):
#	Report whether a path of the output is the tree of a declared
#	language, per WEB-OUTPUT-3. The path of a tree is the tag in
#	lowercase, per WEB-LANGUAGE-5.
#
#	The test reads the languages of the description, and not a
#	shape. A tree that the description dropped is then the
#	directory of whoever made it: the build keeps it and reports
#	it, and the clean refuses it, per WEB-OUTPUT-4. A description
#	that did not load names its language blocks all the same:
#	App::FuguWeb::Config reads the tags out of the file that
#	failed.
sub _tree_dir ( $self, $path )
{
	return scalar grep { $_->path eq $path } $self->{config}->languages;
}

# $self->_tree_file($path):
#	Report whether a path of the output is one name directly in the
#	tree of a declared language, per WEB-OUTPUT-10. A tree is one
#	flat directory of pages, so a deeper path is somebody else's.
sub _tree_file ( $self, $path )
{
	my @parts = split m{/}, $path, -1;
	return 0 unless @parts == 2 && length $parts[1];

	return $self->_tree_dir( $parts[0] );
}

# $self->_staged($path, $is_dir):
#	Report whether a path below the output takes a shape of the
#	staging directory: the directory itself, the directory of one
#	declared language inside it, or one file of that directory. The
#	caller tests for a plain file and a symlink, per WEB-OUTPUT-14.
sub _staged ( $self, $path, $is_dir )
{
	my ( $top, $tree, $name, @deeper ) = split m{/}, $path, -1;
	return 0 if @deeper || $top ne STAGING_DIR;

	return 1 if !defined $tree && $is_dir;
	return 0 unless defined $tree && $self->_tree_dir($tree);
	return $is_dir ? 1 : 0 unless defined $name;

	return length $name && !$is_dir ? 1 : 0;
}

# $self->_key_dir($path):
#	Report whether a path of the output is a directory of a key
#	directory tree. The tree stays after a description drops a
#	key, and the clean must still take it.
sub _key_dir ( $self, $path )
{
	# A description with no keys block publishes no key tree, so
	# it owns no directory of one. A .well-known directory alone
	# would otherwise make any tree read like a built site.
	#
	# A description that did not load names each block all the
	# same: App::FuguWeb::Config reads those names out of the file
	# that failed. The clean must still take the output of a
	# build, because it is the command an operator reaches for
	# when a description is broken.
	my @dirs = $self->{config}->keys_dirs;
	return 0 unless @dirs;

	return 1 if grep { $path eq $_ } @dirs;

	for my $known (
		App::FuguWeb::Keys::WELL_KNOWN,
		App::FuguWeb::Keys::WKD_DIR,
		App::FuguWeb::Keys::WKD_DIR . '/hu'
	    )
	{
		return 1 if $path eq $known;
	}

	return 0;
}

# _holds($named, $dir):
#	Report whether the site holds a name below the directory.
sub _holds ( $named, $dir )
{
	return scalar grep { App::FuguWeb::path_below( $_, $dir ) }
	    keys %$named;
}

# $self->_check_target:
#	Refuse an output directory that must never be written into or
#	removed. The build and the clean both go through here, because
#	--out reaches them both and the setting it overrides is checked
#	in the description.
#
#	The rule is not "inside the project": the tests and the CI both
#	build into a temporary directory outside it. The rule is that
#	the target may not be the root of the filesystem, the home
#	directory, the project root, or any directory that holds the
#	project, per WEB-OUTPUT-13. Nor may it meet a source of the
#	site, per WEB-OUTPUT-18.
sub _check_target ($self)
{
	my $out = $self->{out};
	unless ( defined $out && length $out ) {
		$self->{log}->error('No output directory');
		return;
	}

	my $config = $self->{config};

	# The output directory of the description, which the exception
	# of WEB-OUTPUT-13 reads as it stands.
	my $stands = _absolute($out);
	my $owned  = _absolute( $config->root . '/' . $config->out_dir );

	# Each refusal folds each path, per WEB-OUTPUT-17. On a file
	# system without case, --out WEB is the source directory web.
	my ( $target, $root, $home ) =
	    map { defined ? App::FuguWeb::fold_name( _absolute($_) ) : undef }
	    ( $out, $config->root, $ENV{HOME} );

	my $why;
	$why = 'is the root of the filesystem' if $target eq '/';
	$why = 'is the home directory'
	    if !$why && defined $home && $target eq $home;
	$why = 'is the project root' if !$why && $target eq $root;
	$why = 'is above the project'
	    if !$why && App::FuguWeb::path_below( $root, $target );
	$why //= $self->_meets_source( $target, $stands, $owned );

	return 1 unless $why;

	$self->{log}->error( 'The output directory %s %s', $out, $why );

	return;
}

# $self->_meets_source($target, $stands, $owned):
#	The reason to refuse a target that meets a source of the site,
#	or undef. The target is folded, and the two other paths stand
#	as they are.
#
#	The prune removes each plain file of the top level that the
#	site does not name, and the clean removes the whole target. A
#	target that holds a source would therefore lose it, per
#	WEB-OUTPUT-18. A target inside a directory of sources would
#	take the content of the project with it the same way. The key
#	directory is the worst case: its files are the trust anchor of
#	every release.
#
#	The output directory is the one exception, and it needs to be:
#	the default output directory is web/build, which sits inside
#	the default source directory web. The description names that
#	path, so a build owns it. The exception takes a target inside
#	the source directory alone, and never one that holds a source.
#	It compares the paths as they stand, per WEB-OUTPUT-17, so the
#	fold can only make the guard refuse more.
#
#	A description that did not load names its source directory and
#	its key directories all the same: App::FuguWeb::Config reads
#	those names out of the file that failed. The clean is the
#	command an operator reaches for when a description is broken,
#	so the guard has to answer for the real directories of that
#	project.
sub _meets_source ( $self, $target, $stands, $owned )
{
	my $config = $self->{config};

	my $source =
	    App::FuguWeb::fold_name( _absolute( $config->source_path ) );
	my @sources = map {
		my $path = _absolute($_);
		[ $path, App::FuguWeb::fold_name($path) ]
	} $config->sources;

	for my $pair (@sources) {
		my ( $path, $fold ) = @$pair;
		next unless App::FuguWeb::path_below( $fold, $target );

		return $fold eq $target
		    ? "is the source $path"
		    : "holds the source $path";
	}

	for my $pair (@sources) {
		my ( $path, $fold ) = @$pair;
		next unless App::FuguWeb::path_below( $target, $fold );
		next
		    if $fold eq $source
		    && App::FuguWeb::path_below( $stands, $owned );

		return "is inside the source $path";
	}

	return;
}

# $self->_prune_output:
#	Remove what the site no longer holds. A manual that was renamed
#	leaves its old page behind, and the next build would publish
#	both. The build owns the output directory, so it owns the
#	removal too.
sub _prune_output ($self)
{
	my %expected = map { $_ => 1 } $self->{config}->inventory;

	my $paths = App::FuguWeb::list_tree( $self->{out} );
	unless ($paths) {
		$self->{log}->error( 'Cannot read %s: %s', $self->{out}, $! );
		return;
	}

	my $named = $self->_named;

	for my $path (@$paths) {
		next if $expected{$path};

		# An empty directory is a leaf of the walk. The build
		# owns one of the key tree, and _prune_dirs removes
		# it, so a report here would name what the same run
		# removes. Every other one is somebody else's.
		if ( -d $self->{out} . "/$path" ) {
			next
			    if _holds( $named, $path )
			    || $self->_key_dir($path)
			    || $self->_tree_dir($path);

			$self->{log}->warning(
				'%s is in the output, and the site does not'
				    . ' name it',
				$path
			);
			next;
		}

		# A plain file that a build writes, and nothing else. A
		# file below a directory that the site does not hold
		# belongs to whoever made it, and the checks report it.
		unless (   $self->_owns( $path, $named )
			&& $self->_build_made($path) )
		{
			$self->{log}->warning(
				'%s is in the output, and the site does not'
				    . ' name it',
				$path
			);
			next;
		}

		$self->{log}
		    ->info( 'Removing %s, which the site no longer holds',
			$path );
		unlink "$self->{out}/$path"
		    or
		    $self->{log}->warning( 'Cannot remove %s: %s', $path, $! );
	}

	return $self->_prune_dirs;
}

# $self->_prune_dirs:
#	Remove each empty directory that the build owns: one that the
#	site holds a name below, one of the key tree, and the tree of a
#	declared language.
#
#	The first test reads the inventory, which is the rule. The key
#	tree reads a shape, because the inventory names what the site
#	holds today and not the directory that a dropped key left. The
#	tree of a dropped language is no tree of the description, so
#	the build keeps it and the checks report it, per WEB-OUTPUT-4.
#
#	A description that drops its keys block owns no directory of
#	the key tree any more, so the build keeps that tree and the
#	checks report it. Remove it by hand, or name the block again.
#
#	The clean reads the same three tests, so the build can never
#	remove a directory that the clean refuses. An operator
#	directory therefore stays, empty or not, and the checks report
#	it. An operator directory such as img/de stays.
#
#	rmdir refuses a directory that still holds a name, so the walk
#	needs no second test: a directory that the site still uses
#	stays. The deepest path comes last from the walk, so the
#	reverse order removes a tree from the leaves up.
sub _prune_dirs ($self)
{
	my @dirs;
	File::Find::find( {
			no_chdir => 1,
			wanted   => sub {
				push @dirs, $File::Find::name
				    if -d $File::Find::name
				    && !-l $File::Find::name;
			},
		},
		$self->{out} );

	# A directory that the site holds a name below, a directory of
	# the key tree, or a declared language tree. The clean reads the
	# same three tests. A directory of the operator therefore stays
	# here and the checks report it.
	#
	# rmdir refuses a directory that still holds a name, so the
	# walk needs no second test. The output directory itself
	# stays: a site with no page is a build that failed, and a
	# removed output directory would hide that from every check.
	my $named = $self->_named;

	for my $dir ( reverse sort @dirs ) {
		next if $dir eq $self->{out};

		my $relative = substr $dir, 1 + length $self->{out};
		next
		    unless _holds( $named, $relative )
		    || $self->_key_dir($relative)
		    || $self->_tree_dir($relative);

		# rmdir refuses a directory that still holds a name,
		# and that refusal is the test of this loop. Every
		# other failure is one the checks report, so the return
		# value goes to the log and never to the caller.
		next if rmdir $dir;
		next if $! == POSIX::ENOTEMPTY() || $! == POSIX::EEXIST();

		$self->{log}
		    ->warning( 'Cannot remove the directory %s: %s', $dir, $! );
	}

	return 1;
}

# $self->_build_made($name):
#	Report whether one entry of the output directory is something
#	a build makes: a plain file, and never a symlink. The clean
#	and the prune share this rule, so the two can never disagree
#	about what a build owns.
sub _build_made ( $self, $name )
{
	my $path = "$self->{out}/$name";

	return -f $path && !-l $path ? 1 : 0;
}

# _absolute($path):
#	The path with no trailing slash and no parent step, resolved
#	against the working directory when it is relative.
#
#	The function collapses '..' itself. File::Spec->canonpath
#	leaves it alone by design, and a guard that compared the
#	uncollapsed form would let '<project>/..' through as a
#	directory it had never seen.
#
#	The path need not exist, so no symlink is resolved. A symlink
#	is not a way around the guard: the build refuses to write
#	through one, and the clean removes the link and not its target.
sub _absolute ($path)
{
	my $absolute = File::Spec->canonpath( File::Spec->rel2abs($path) );

	my @parts;
	for my $part ( split m{/}, $absolute ) {
		next if $part eq '' || $part eq '.';
		if ( $part eq '..' ) {
			pop @parts;
			next;
		}
		push @parts, $part;
	}

	return @parts ? '/' . join '/', @parts : '/';
}

# $self->_mdoc_manuals($language):
#	Every mdoc manual of one language, in group order.
sub _mdoc_manuals ( $self, $language )
{
	return grep { !$_->is_pod }
	    map { $_->manuals( $language->tag ) } $self->{config}->groups;
}

# $self->_check_text:
#	Refuse a source that is not UTF-8 before anything is rendered,
#	per WEB-SITE-5. A renderer reads its own source, so the build
#	reads each one here: each manual and each Markdown page of each
#	language. The build reads a body fragment and a footer itself,
#	through the same decode, when it renders a page.
sub _check_text ($self)
{
	my $config = $self->{config};

	my @paths;
	for my $language ( $config->languages ) {
		push @paths, map { $_->path }
		    map { $_->manuals( $language->tag ) } $config->groups;
		push @paths, map { $config->root . "/$_->{value}" }
		    grep { $_->{source} eq 'markdown' }
		    $config->pages( $language->tag );
	}

	my %seen;
	for my $path ( grep { !$seen{$_}++ } @paths ) {
		$self->_read_source($path) // return;
	}

	return 1;
}

# $self->_read_source($path):
#	The characters of one source, or undef with a message in the
#	log. The message names the path of a source that is not UTF-8,
#	per WEB-SITE-5.
sub _read_source ( $self, $path )
{
	my $bytes = Fugu::File->read($path);
	unless ( defined $bytes ) {
		$self->{log}->error( 'Cannot read %s', $path );
		return;
	}

	my $text = App::FuguWeb::decode( $bytes, $path, \my $reason );
	$self->{log}->error( '%s', $reason ) unless defined $text;

	return $text;
}

# $self->_lint:
#	Refuse a malformed manual source before anything is rendered.
#	The lint reads the source of each language once.
sub _lint ($self)
{
	my %seen;
	my @paths = grep { !$seen{$_}++ }
	    map { $_->path }
	    map { $self->_mdoc_manuals($_) } $self->{config}->languages;

	return $self->{render}->lint(@paths);
}

# $self->_prepare_output:
#	Create the output directory, the directory of each language
#	tree, and the staging directory of each language. The output
#	directory is created on purpose. The recipe that this replaced
#	got it as a side effect of the staging mkdir, which would have
#	broken the moment the staging step moved.
sub _prepare_output ($self)
{
	Fugu::File->ensure_dir( $self->{out} ) or return;
	$self->_check_links                    or return;

	# A staging directory left by an interrupted build would leak
	# stale sources into this one.
	$self->_drop_staging or return;

	for my $language ( $self->{config}->languages ) {
		Fugu::File->ensure_dir( $self->{out} . '/' . $language->path )
		    or return;
		Fugu::File->ensure_dir( $self->staging($language) ) or return;
	}

	return 1;
}

# $self->_drop_staging:
#	Remove the staging directory, and refuse one that no build
#	made.
#
#	A build writes one flat directory of plain files there for each
#	language, so anything else is somebody else's. The clean
#	refuses such a tree, and WEB-OUTPUT-6 holds that the build must
#	never remove what the clean refuses.
#
#	_check_links runs first and refuses a link on this path, so
#	the link test here never fires today. It stays because this
#	method removes a tree, and a method that removes a tree reads
#	its own rule.
#
#	The whole removal goes through here. A build that ran to the
#	end calls it again, and the directory then holds what this
#	build itself staged.
sub _drop_staging ($self)
{
	my $staging = $self->staging;
	return 1 unless -d $staging && !-l $staging;

	my $paths = App::FuguWeb::list_tree($staging);
	unless ($paths) {
		$self->{log}->error( 'Cannot read %s: %s', $staging, $! );
		return;
	}

	# A build writes one flat directory of plain files for each
	# language, so the first entry of another kind is the whole
	# answer. The walk names each file and each empty directory. A
	# symlink is a leaf of it, and never a thing that a build made.
	my ($stranger) = grep {
		my $path = "$staging/$_";
		-l $path
		    || !$self->_staged( STAGING_DIR . "/$_", -d $path )
		    || !-d $path && !-f $path
	} @$paths;

	if ( defined $stranger ) {
		$self->{log}->error(
			'%s holds %s, which no build made; refusing to'
			    . ' remove it',
			$staging, $stranger
		);
		return;
	}

	remove_tree( $staging, { safe => 0 } );

	return 1;
}

# $self->_check_links:
#	Refuse a symlink on a path that the build writes, or on a
#	directory above one.
#
#	A build writes a file by name, and an open follows a link. A
#	link in the output would therefore send the bytes of the site
#	to whatever it points at. That is outside the output
#	directory, and outside the project. The key directory makes it
#	worse: a link at .well-known would take the published key
#	material with it.
#
#	The test comes before the first write, because a link that the
#	prune finds at the end has already served.
sub _check_links ($self)
{
	my $paths = App::FuguWeb::list_tree( $self->{out} );
	unless ($paths) {
		$self->{log}->error( 'Cannot read %s: %s', $self->{out}, $! );
		return;
	}

	# A link that the build never writes through is somebody
	# else's, and a build leaves it. The build writes the
	# inventory and the staging directory, and no more. A link on
	# one of those paths, or on a directory of one, is the whole
	# rule.
	#
	# The staging directory needs the test as much as a page does.
	# _prepare_output removes that path, so a link there goes
	# without a word, and the operator loses it to a build.
	#
	# The test folds each name, per WEB-OUTPUT-17. On a file system
	# without case, a link at INDEX.HTML is the page index.html, and
	# the build writes through it.
	my %named = map { App::FuguWeb::fold_name($_) => 1 }
	    ( $self->{config}->inventory, STAGING_DIR );
	my %above;
	for my $named ( keys %named ) {
		my @parts = split m{/}, $named;
		pop @parts;

		my $prefix = '';
		for my $part (@parts) {
			$prefix = length $prefix ? "$prefix/$part" : $part;
			$above{$prefix} = 1;
		}
	}

	for my $path (@$paths) {
		next unless -l $self->{out} . "/$path";
		my $fold = App::FuguWeb::fold_name($path);
		next unless $named{$fold} || $above{$fold};

		$self->{log}->error(
			'%s holds the symlink %s; a build writes no file'
			    . ' through a link',
			$self->{out}, $path
		);
		return;
	}

	return 1;
}

# $self->_copy($from, $to):
#	Copy one file, as bytes, through Fugu::File. The method
#	returns true on success, and undef with a message in the log
#	otherwise.
sub _copy ( $self, $from, $to )
{
	my $bytes = Fugu::File->read($from);
	unless ( defined $bytes ) {
		$self->{log}->error( 'Cannot read %s', $from );
		return;
	}

	return Fugu::File->write( $to, $bytes );
}

# $self->_stage_mdoc:
#	Copy the mdoc source of each language into the staging
#	directory of that language, under the name that a
#	cross-reference refers to it by. A source of a translation
#	takes the name of its namesake, so a cross-reference reads the
#	same in each language.
sub _stage_mdoc ($self)
{
	for my $language ( $self->{config}->languages ) {
		for my $manual ( $self->_mdoc_manuals($language) ) {
			$self->_copy( $manual->path,
				      $self->staging($language) . '/'
				    . $manual->staged_name )
			    or return;
		}
	}

	return 1;
}

# $self->_copy_stylesheet:
#	Copy the base stylesheet into the output. The sheet ships with
#	the tool, and the stylesheet setting overrides the search. The
#	search finds the file in a checkout through this module's
#	location, and under the share tree of an installed App-FuguWeb
#	distribution.
sub _copy_stylesheet ($self)
{
	my $named = $self->{config}->stylesheet;
	my $path =
	    defined $named
	    ? $self->{config}->root
	    . "/$named"
	    : Fugu::File->share_path(
		SHARE_STYLESHEET,
		from => __FILE__,
		dist => 'App-FuguWeb'
	    );

	unless ( defined $path && -f $path ) {

		# A site with no stylesheet must not look like a
		# success, so the message names the path that failed.
		$self->{log}->error(
			'Cannot find the stylesheet: %s',
			$named // SHARE_STYLESHEET
		);
		return;
	}

	return $self->_copy( $path,
		$self->{out} . '/' . App::FuguWeb::STYLESHEET );
}

# $self->_copy_assets:
#	Copy every asset of the source directory. The description
#	decides which files those are, so the build and the checks read
#	the same list.
sub _copy_assets ($self)
{
	my $dir = $self->{config}->source_path;

	for my $name ( $self->{config}->assets ) {
		$self->_copy( "$dir/$name", $self->{out} . "/$name" )
		    or return;
	}

	return 1;
}

# $self->_write_keys:
#	Write each key directory that the description names. The build
#	copies each key file and the manifest pair as they stand. It
#	generates the KEYS file, the human page, the Web Key Directory
#	tree and security.txt through the Fugu modules.
#
#	A description with no keys block writes no key directory, so
#	every site that predates it keeps its output.
#
#	The site build cannot sign, so the manifest pair is a source
#	file. A build that signed would prove that the builder holds
#	the key, and never that the release does.
sub _write_keys ($self)
{
	my $config = $self->{config};

	my @dirs = $config->keys_dirs;
	return 1 unless @dirs;

	# The generation of every directory comes first, because it
	# runs the guards of Fugu::KeyDir over every armored key. A
	# copy that ran first would leave a private key block in the
	# output of a build that then failed.
	my ( $generated, $reason ) =
	    App::FuguWeb::Keys->site_generated($config);
	unless ($generated) {
		$self->{log}
		    ->error( 'The key directory is not usable: %s', $reason );
		return;
	}

	for my $dir (@dirs) {
		my $keys =
		    App::FuguWeb::Keys->new( config => $config, dir => $dir );

		for my $copy ( $keys->copies ) {
			$self->_write_out(
				$copy->{to},
				sub {
					my $bytes =
					    Fugu::File->read( $copy->{from} );
					$self->{log}->error(
						'Cannot read %s',
						$copy->{from}
					) unless defined $bytes;
					return $bytes;
				} ) or return;
		}
	}

	for my $path ( sort keys %$generated ) {
		$self->_write_out( $path, sub { return $generated->{$path} } )
		    or return;
	}

	return 1;
}

# $self->_write_out($path, $bytes):
#	Write one file of the key directory, at a path below the
#	output directory. Fugu::File->write opens the file and creates
#	no parent, and the Web Key Directory sits three directories
#	down, so the parent comes first.
#
#	The bytes arrive through a code reference, so a read that
#	fails reports its own path and this method reports none.
sub _write_out ( $self, $path, $bytes )
{
	my $target = $self->{out} . "/$path";

	my $dir = $target =~ s{/[^/]+\z}{}r;
	Fugu::File->ensure_dir($dir) or return;

	my $data = $bytes->() // return;

	return Fugu::File->write( $target, $data );
}

# $self->_render_pages:
#	Render every page block into each language tree, from the
#	values of that language, and then the pages of the top level.
#	The default language comes first, and each page of another
#	language follows the outline of its namesake, per WEB-OUTLINE.
#	The body of the 404.html of each tree, as the tree holds it,
#	goes to the top-level 404.html too.
sub _render_pages ($self)
{
	my $config = $self->{config};
	my ( %outline, @not_found );

	for my $language ( $config->languages ) {
		my $page = $self->_page($language) // return;

		for my $entry ( $config->pages( $language->tag ) ) {
			my $fragment = $self->_fragment( $entry, $language )
			    // return;
			$fragment = $self->_follow(
				\%outline,      $language,
				$entry->{file}, $fragment
			) // return;
			my $lang =
			    App::FuguWeb::Page::body_lang( $entry, $language );

			push @not_found, [ $language, $lang, $fragment ]
			    if $entry->{file} eq App::FuguWeb::NOT_FOUND_PAGE;

			$page->write(
				$self->{out},
				$language->path . "/$entry->{file}",
				$entry->{title},
				$fragment,
				body_lang => $lang,
			) or return;
		}
	}

	my $top = App::FuguWeb::Page->new( config => $config );
	$self->_write_not_found( $top, @not_found ) or return;

	return Fugu::File->write(
		$self->{out} . '/' . App::FuguWeb::FORWARD_PAGE,
		App::FuguWeb::encode( $top->forward ) );
}

# $self->_page($language):
#	The chrome of the tree pages of one language, with the footer
#	fragment of that language, or undef with a message in the log.
#	A site with no footer gives a page with none, per WEB-CHROME-7.
sub _page ( $self, $language )
{
	my $footer;
	if ( defined $language->footer ) {
		$footer =
		    $self->_read_source(
			$self->{config}->source_path( $language->footer ) )
		    // return;
	}

	return App::FuguWeb::Page->new(
		config   => $self->{config},
		language => $language,
		footer   => $footer,
	);
}

# $self->_fragment($entry, $language):
#	The body fragment of one page of one language, as characters,
#	or undef with a message in the log. A body fragment is already
#	HTML, a Markdown file goes through lowdown, and the index comes
#	from App::FuguWeb::Index. The body of an index page opens it.
sub _fragment ( $self, $entry, $language )
{
	my $config = $self->{config};

	if ( $entry->{source} eq 'markdown' ) {
		return $self->{render}
		    ->markdown( $config->root . '/' . $entry->{value} );
	}

	my $body;
	if ( defined $entry->{value} ) {
		$body = $self->_read_source(
			$config->source_path( $entry->{value} ) ) // return;
	}
	return $body if $entry->{source} eq 'body';

	return App::FuguWeb::Index->new(
		config   => $config,
		language => $language
	)->body(
		$entry->{title}, $body,
		title_lang => $entry->{title_lang},
		body_lang  => $entry->{lang},
	);
}

# $self->_write_not_found($top, @bodies):
#	Write the top-level 404.html through the page of the top level,
#	when the description holds that page, per WEB-TOP-3. Each body
#	is an array reference of the language of its tree, the tag of
#	the language of its text, and the body as the tree holds it.
#
#	The page is a page of the default language, with its title, per
#	WEB-TOP-4. Its main holds the body of each language in its own
#	section, per WEB-TOP-5. App::FuguWeb::Fragment fits each body:
#	each id goes, and each relative link resolves against the
#	404.html of its tree, per WEB-TOP-6. The base of the page then
#	resolves each link from the site root.
sub _write_not_found ( $self, $top, @bodies )
{
	return 1 unless @bodies;

	my $not_found = App::FuguWeb::NOT_FOUND_PAGE;
	my ($entry) = grep { $_->{file} eq $not_found } $self->{config}->pages;

	my @sections = map {
		my ( $language, $lang, $body ) = @$_;
		[
			$lang,
			App::FuguWeb::Fragment::not_found(
				$body, $language->path
			) ]
	} @bodies;

	return $top->write( $self->{out}, $not_found, $entry->{title},
		$top->sections(@sections) );
}

# $self->_render_manuals:
#	Render one page for each manual of each group, into each
#	language tree, from the source of that language. mandoc runs in
#	the staging directory of the language, so a cross-reference
#	links a page of the same tree.
#
#	The fit of App::FuguWeb::Fragment removes the frame of mandoc,
#	and opens the page with its title, per WEB-MANUALS-9. Each
#	manual of another language then follows the outline of its
#	namesake, per WEB-OUTLINE.
sub _render_manuals ($self)
{
	my $config = $self->{config};
	my %outline;

	for my $language ( $config->languages ) {
		my $page = $self->_page($language) // return;

		for my $manual ( map { $_->manuals( $language->tag ) }
			$config->groups )
		{
			my $html =
			      $manual->is_pod
			    ? $self->{render}->pod( $manual->path )
			    : $self->{render}->mdoc(
				$manual->staged_name,
				$self->staging($language) );
			return unless defined $html;

			my $title = App::FuguWeb::as_text(
				$manual->name . '(' . $manual->section . ')' );
			my $fragment = $self->_follow(
				\%outline,
				$language,
				$manual->page,
				App::FuguWeb::Fragment::manual( $html, $title )
			) // return;

			$page->write(
				$self->{out},
				$language->path . '/' . $manual->page,
				$title,
				$fragment,
				body_lang => $manual->lang,
			) or return;
		}
	}

	return 1;
}

# $self->_follow($outlines, $language, $name, $fragment):
#	The fragment of the page of one name in the tree of one
#	language, or undef with a message in the log. The order of the
#	languages puts the default first, per D-05. Its page records
#	its outline under the name, and the fragment returns as it
#	stands. The page of each other language follows that outline,
#	and takes its ids, per WEB-OUTLINE-1 and WEB-OUTLINE-2. Each
#	link of the page to one of its headings names the new id, per
#	WEB-OUTLINE-4.
#
#	The message names the page, the language, and the position of
#	the first heading that differs.
sub _follow ( $self, $outlines, $language, $name, $fragment )
{
	my $default = $self->{config}->default_language;
	if ( $language->tag eq $default->tag ) {
		$outlines->{$name} = App::FuguWeb::Fragment::outline($fragment);
		return $fragment;
	}

	my $fitted = App::FuguWeb::Fragment::follow( $fragment,
		$outlines->{$name}, \my $at );
	return $fitted if defined $fitted;

	$self->{log}
	    ->error( '%s/%s: the outline of %s differs from %s at heading %d',
		$language->path, $name, $language->tag, $default->tag, $at );

	return;
}

1;
