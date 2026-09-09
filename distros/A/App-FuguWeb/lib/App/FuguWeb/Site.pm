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
our $VERSION = '0.5.0';

use App::FuguWeb;
use App::FuguWeb::Index;
use App::FuguWeb::Keys;
use App::FuguWeb::Page;
use App::FuguWeb::Render;
use File::Find ();
use File::Path qw(remove_tree);
use File::Spec;
use Fugu::File;
use Fugu::Log;
use Fugu::Process;
use POSIX ();

# App::FuguWeb::Site - the whole build.
#
# One method renders the site: probe the renderers, refuse an output
# directory that no build may own, lint every manual source, stage the
# mdoc sources, copy the assets, render every page, remove the staging,
# and remove what the site no longer holds. Each step reports its own
# failure and stops the build. A site that is half rendered must not
# look like a success.
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

# $self->staging:
#	The mdoc staging directory. It lives inside the output
#	directory and never reaches the published tree.
sub staging ($self)
{
	return $self->{out} . '/' . STAGING_DIR;
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
#	of _stranger fall back to "a flat directory of plain files".
#	A key directory reads exactly like that, and so does a source
#	directory. The clean is the command an operator reaches for
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
#	A build writes plain files: one flat directory of them, the
#	key directory tree below it, and the staging directory while
#	it runs. A directory that the description does not name is
#	therefore not part of a site, and so is anything below it.
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
		# build writes one flat directory of sources into it.
		# A tree below it is somebody else's.
		if ( App::FuguWeb::path_below( $relative, STAGING_DIR ) ) {
			next if $relative eq STAGING_DIR;
			next
			    if $relative =~ m{\A\Q@{[STAGING_DIR]}\E/[^/]+\z}
			    && $self->_build_made($relative);
			return $relative;
		}

		# A directory holds a name of the site, or a name of the
		# key directory tree, or it holds the files of whoever
		# made it.
		if ( -d $path ) {
			next if _holds( $named, $relative );
			next if $self->_key_dir($relative);
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
#	then accepts one flat directory of files and no more.
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
#	the description names today. A renamed manual leaves its old
#	page there. A name below the root is one that the site holds,
#	or one of the shape that the key directory takes.
#
#	The prune and the clean read this one predicate, so the build
#	can never remove a file that the clean refuses.
sub _owns ( $self, $path, $named )
{
	return 1 unless $path =~ m{/};
	return 1 if $named->{$path};

	return App::FuguWeb::Keys->shaped( $self->{config}, $path );
}

# $self->_key_dir($path):
#	Report whether a path of the output is a directory of the key
#	directory tree. The tree stays after a description drops a
#	key, and the clean must still take it.
sub _key_dir ( $self, $path )
{
	# A description with no keys block publishes no key tree, so
	# it owns no directory of one. A .well-known directory alone
	# would otherwise make any tree read like a built site.
	#
	# A description that did not load names the block all the
	# same: App::FuguWeb::Config reads that one name out of the
	# file that failed. The clean must still take the output of a
	# build, because it is the command an operator reaches for
	# when a description is broken.
	my $dir = $self->{config}->keys_dir;
	return 0 unless defined $dir;

	return 1 if $path eq $dir;

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
#	project.
sub _check_target ($self)
{
	my $out = $self->{out};
	unless ( defined $out && length $out ) {
		$self->{log}->error('No output directory');
		return;
	}

	my $target = _absolute($out);
	my $root   = _absolute( $self->{config}->root );
	my $home   = defined $ENV{HOME} ? _absolute( $ENV{HOME} ) : undef;

	# The source directory holds the files of the project, and a
	# flat directory of files reads like a built site. A clean of
	# it, or of any directory of it, would take the content of the
	# project with it. The key directory is the worst case: its
	# files are the trust anchor of every release.
	#
	# The output directory is the one exception, and it needs to
	# be: the default output directory is web/build, which sits
	# inside the default source directory web. The description
	# names that path, so a build owns it. Nothing else below the
	# source is a build's.
	#
	# A description that did not load names both directories all
	# the same: App::FuguWeb::Config reads the two settings out of
	# the file that failed. The clean is the command an operator
	# reaches for when a description is broken, so the guard has
	# to answer for the real directories of that project.
	my $config = $self->{config};

	my $source = _absolute( $config->source_path );
	my $owned  = _absolute( "$root/" . $config->out_dir );

	my $why;
	$why = 'the root of the filesystem' if $target eq '/';
	$why = 'the home directory'
	    if !$why && defined $home && $target eq $home;
	$why = 'the project root' if !$why && $target eq $root;
	$why = 'the source directory, or a directory of it'
	    if !$why
	    && App::FuguWeb::path_below( $target,  $source )
	    && !App::FuguWeb::path_below( $target, $owned );
	$why = 'above the project'
	    if !$why && App::FuguWeb::path_below( $root, $target );

	return 1 unless $why;

	$self->{log}->error( 'The output directory %s is %s', $out, $why );

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
			    || $self->_key_dir($path);

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
#	site holds a name below, and one of the key tree.
#
#	The two tests answer alike today. Every name of the inventory
#	is one path segment but a key path, so the key tree holds
#	every directory that the inventory implies. The first test
#	reads the inventory, which is the rule, and it stays right if
#	a deeper name ever reaches the list.
#
#	A description that drops its keys block owns no directory of
#	the key tree any more, so the build keeps that tree and the
#	checks report it. Remove it by hand, or name the block again.
#
#	The clean reads the same two tests, so the build can never
#	remove a directory that the clean refuses. An operator
#	directory therefore stays, empty or not, and the checks report
#	it.
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

	# A directory that the site holds a name below, or a directory
	# of the key tree. The clean reads the same two tests, so a
	# directory of the operator stays here and the checks report
	# it.
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
		    || $self->_key_dir($relative);

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

# $self->pod_date:
#	The date that every POD page carries: the date of the last
#	commit, and today when git does not answer. git does not
#	preserve file times, so a build that read one would give
#	different bytes on every checkout.
sub pod_date ($self)
{
	my $result = Fugu::Process->run(
		cmd => [
			'git', '-C', $self->{config}->root,
			'log', '-1', '--format=%cs'
		],
	);
	my $date = $result->{success} ? $result->{stdout} : '';
	$date =~ s/\s+//g;

	return length $date ? $date : POSIX::strftime( '%Y-%m-%d', localtime );
}

# $self->_mdoc_manuals:
#	Every mdoc source of the site, in group order.
sub _mdoc_manuals ($self)
{
	return grep { !$_->is_pod }
	    map { $_->manuals } $self->{config}->groups;
}

# $self->_lint:
#	Refuse a malformed manual source before anything is rendered.
sub _lint ($self)
{
	my @paths = map { $_->path } $self->_mdoc_manuals;

	return $self->{render}->lint(@paths);
}

# $self->_prepare_output:
#	Create the output directory and the staging directory inside
#	it. The output directory is created on purpose. The recipe that
#	this replaced got it as a side effect of the staging mkdir,
#	which would have broken the moment the staging step moved.
sub _prepare_output ($self)
{
	Fugu::File->ensure_dir( $self->{out} ) or return;
	$self->_check_links                    or return;

	# A staging directory left by an interrupted build would leak
	# stale sources into this one.
	$self->_drop_staging or return;

	return Fugu::File->ensure_dir( $self->staging );
}

# $self->_drop_staging:
#	Remove the staging directory, and refuse one that no build
#	made.
#
#	A build writes one flat directory of plain files there, so
#	anything else is somebody else's. The clean refuses such a
#	tree, and WEB-OUTPUT-6 holds that the build must never remove
#	what the clean refuses.
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

	my $names = App::FuguWeb::list_dir($staging);
	unless ($names) {
		$self->{log}->error( 'Cannot read %s: %s', $staging, $! );
		return;
	}

	# A build writes one flat directory of plain files, so the
	# first entry of another kind is the whole answer.
	my ($stranger) =
	    grep { !-f "$staging/$_" || -l "$staging/$_" } @$names;

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
	my %named = map { $_ => 1 } ( $self->{config}->inventory, STAGING_DIR );
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
		next unless $named{$path} || $above{$path};

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
#	Copy every mdoc source into the staging directory, under the
#	name that a cross-reference refers to it by.
sub _stage_mdoc ($self)
{
	for my $manual ( $self->_mdoc_manuals ) {
		$self->_copy( $manual->path,
			$self->staging . '/' . $manual->staged_name )
		    or return;
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
#	Write the key directory. The build copies each key file and
#	the manifest pair as they stand. It generates the KEYS file,
#	the human page, the Web Key Directory tree and security.txt
#	through the Fugu modules.
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
	return 1 unless defined $config->keys_dir;

	my $keys = App::FuguWeb::Keys->new( config => $config );

	# The generation comes first, because it runs the guards of
	# Fugu::KeyDir over every armored key. A copy that ran first
	# would leave a private key block in the output of a build
	# that then failed.
	my $generated = $keys->generated;
	unless ($generated) {
		$self->{log}->error( 'The key directory is not usable: %s',
			$keys->error );
		return;
	}

	for my $copy ( $keys->copies ) {
		$self->_write_out(
			$copy->{to},
			sub {
				my $bytes = Fugu::File->read( $copy->{from} );
				$self->{log}
				    ->error( 'Cannot read %s', $copy->{from} )
				    unless defined $bytes;
				return $bytes;
			} ) or return;
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
#	Render every page block. A body fragment is already HTML, a
#	Markdown file goes through lowdown, and the index comes from
#	App::FuguWeb::Index.
sub _render_pages ($self)
{
	my $config = $self->{config};
	my $page   = App::FuguWeb::Page->new( config => $config );
	my $index  = App::FuguWeb::Index->new( config => $config );

	for my $entry ( $config->pages ) {
		my $fragment;

		if ( $entry->{source} eq 'body' ) {
			my $path = $config->source_path( $entry->{value} );
			$fragment = Fugu::File->read($path);
			unless ( defined $fragment ) {
				$self->{log}->error( 'Cannot read %s', $path );
				return;
			}
		}
		elsif ( $entry->{source} eq 'markdown' ) {
			$fragment =
			    $self->{render}
			    ->markdown( $config->root . '/' . $entry->{value} );
			return unless defined $fragment;
		}
		else {
			$fragment = $index->body;
		}

		$page->write( $self->{out} . '/' . $entry->{file},
			$entry->{title}, $fragment )
		    or return;
	}

	return 1;
}

# $self->_render_manuals:
#	Render one page for each manual of each group.
sub _render_manuals ($self)
{
	my $config = $self->{config};
	my $page   = App::FuguWeb::Page->new( config => $config );
	my $date   = $self->pod_date;

	for my $group ( $config->groups ) {
		for my $manual ( $group->manuals ) {
			my $fragment =
			      $manual->is_pod
			    ? $self->{render}
			    ->pod( $manual->path, $manual->name, $date )
			    : $self->{render}
			    ->mdoc( $manual->staged_name, $self->staging );
			return unless defined $fragment;

			$page->write(
				$self->{out} . '/' . $manual->page,
				$manual->name . '(' . $manual->section . ')',
				$fragment
			) or return;
		}
	}

	return 1;
}

1;
