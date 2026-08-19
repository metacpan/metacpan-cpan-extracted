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

package App::FuguWeb::Config;
our $VERSION = '0.1.1';

use App::FuguWeb;
use App::FuguWeb::Manual;
use File::Find ();
use Fugu::Config;

# App::FuguWeb::Config - the site description over Fugu::Config.
#
# The grammar, the quoting and the yes/no spellings come from
# Fugu::Config. This file holds what is true of a site: the settings
# and their defaults, the ordered navigation, the ordered pages, and
# the rules that a description must obey before a build reads it.
#
# The object is immutable once loaded. Two sites in one process
# therefore share nothing.

# The settings that a project may leave out, and what they mean when
# it does. 'site' has no default: a site with no name is a mistake,
# not a default.
use constant {
	DEFAULT_LANG        => 'en',
	DEFAULT_OUT_DIR     => 'web/build',
	DEFAULT_SOURCE_DIR  => 'web',
	DEFAULT_ENTRY       => 'index.html',
	DEFAULT_MODULE_ROOT => 'lib',
	DEFAULT_MANDOC_OS   => 'OpenBSD',
	DEFAULT_MAN_URL     => 'https://man.openbsd.org/',
};

# The settings that name a path inside the project. Each one is
# checked for a parent-directory step, because a build must write
# inside the project and read inside it.
my @PATH_SETTINGS = qw(out_dir source_dir module_root stylesheet);

# The three ways a page block names its content. Exactly one of them
# must appear.
my @PAGE_SOURCES = qw(body markdown index);

# App::FuguWeb::Config->load(%args):
#	root  => $dir		the project root (default: discover)
#	error => \$reason	where the failure message goes
#
#	Read and validate the description. The method returns the
#	object, or undef with the reason in $reason. Every message
#	names the file, and the block when a block is at fault.
#
#	The reason travels through a reference because the object that
#	would hold it does not exist when the load fails. The module
#	keeps no package state for it: two sites in one process must
#	not share a failure.
sub load ( $class, %args )
{
	my $reason = $args{error} // \my $ignored;

	my $root = $args{root}
	    // Fugu::Config->find_project_root(App::FuguWeb::CONFIG_FILE);
	unless ( defined $root ) {
		$$reason =
		      'Not in a FuguWeb project: no '
		    . App::FuguWeb::CONFIG_FILE
		    . ' above the working'
		    . " directory. Run 'fuguweb init' first.";
		return;
	}

	my $path = "$root/" . App::FuguWeb::CONFIG_FILE;
	unless ( -f $path ) {
		$$reason = "Cannot read $path: no such file";
		return;
	}

	my $file = Fugu::Config->new( file => $path );
	unless ( $file->load ) {
		$$reason = $file->error;
		return;
	}

	my $self = bless {
		root  => $root,
		path  => $path,
		file  => $file,
		nav   => [],
		page  => [],
		group => [],
	}, $class;

	$self->_apply_settings;
	$self->_read_nav($reason)    or return;
	$self->_read_pages($reason)  or return;
	$self->_read_groups($reason) or return;
	$self->_check_paths($reason) or return;
	$self->_check_pages($reason) or return;

	return $self;
}

# App::FuguWeb::Config->anonymous($root):
#	A description that names nothing but the project root.
#
#	'fuguweb clean --out <dir>' uses it. Removing a directory that
#	the caller named needs a project root and nothing else, and
#	clean is the command an operator reaches for when the
#	description is the thing that is broken.
sub anonymous ( $class, $root )
{
	return bless { root => $root }, $class;
}

# $self->root, $self->path:
#	The project root, and the description that this object read.
sub root ($self) { return $self->{root}; }
sub path ($self) { return $self->{path}; }

# The settings. Each one is a plain accessor over the merged value, so
# a caller never repeats a default.
sub site        ($self) { return $self->{site}; }
sub lang        ($self) { return $self->{lang}; }
sub out_dir     ($self) { return $self->{out_dir}; }
sub source_dir  ($self) { return $self->{source_dir}; }
sub entry       ($self) { return $self->{entry}; }
sub module_root ($self) { return $self->{module_root}; }
sub mandoc_os   ($self) { return $self->{mandoc_os}; }
sub man_url     ($self) { return $self->{man_url}; }
sub stylesheet  ($self) { return $self->{stylesheet}; }

# $self->source_path($name):
#	The path of a file in the source directory, or of the
#	directory itself when the caller names nothing.
sub source_path ( $self, $name = undef )
{
	my $dir = "$self->{root}/$self->{source_dir}";

	return defined $name ? "$dir/$name" : $dir;
}

# $self->nav:
#	The navigation, in file order. Each entry is a hashref with
#	href and label.
sub nav ($self)
{
	return @{ $self->{nav} };
}

# $self->pages:
#	The pages, in file order. Each entry is a hashref with file,
#	title, source, value and unlinked. The source is one of body,
#	markdown or index, and the value is what that source names.
sub pages ($self)
{
	return @{ $self->{page} };
}

# $self->assets:
#	The names of the files in the source directory that the build
#	copies as they stand, sorted. An asset is any file there that
#	the build does not render: not a body fragment, not Markdown,
#	and not a dot file.
#
#	Thus robots.txt and CNAME need no entry in the description, and
#	a CLAUDE.md beside them is not published. Markdown in the
#	source directory is either a page source, which a page block
#	names and lowdown renders, or notes for the maintainers.
#	Neither belongs in the output as it stands.
#
#	The build and the checks read the same list, so the two can
#	never disagree about what the site holds.
sub assets ($self)
{
	my $dir = $self->source_path;
	return () unless -d $dir;

	my $names = App::FuguWeb::list_dir($dir) or return ();

	return
	    grep { !/^\./ && !/\.body\.html$/ && !/\.md$/ && -f "$dir/$_" }
	    @$names;
}

# $self->inventory:
#	Every name that the output directory must hold after a build:
#	the pages of the description, one page for each manual of each
#	group, the stylesheet, and the assets. The build and the
#	checks read the same list, so the two can never disagree about
#	what the site holds.
sub inventory ($self)
{
	return ( map { $_->{file} } $self->pages ),
	    ( map { $_->page } map { $_->manuals } $self->groups ),
	    App::FuguWeb::STYLESHEET, $self->assets;
}

# $self->groups:
#	The manual groups, in file order. Each entry is an
#	App::FuguWeb::Config::Group.
sub groups ($self)
{
	return @{ $self->{group} };
}

# $self->_apply_settings:
#	Copy each setting out of the parse, with its default.
sub _apply_settings ($self)
{
	my $file = $self->{file};

	$self->{site}        = $file->get('site');
	$self->{lang}        = $file->get( 'lang',        DEFAULT_LANG );
	$self->{out_dir}     = $file->get( 'out_dir',     DEFAULT_OUT_DIR );
	$self->{source_dir}  = $file->get( 'source_dir',  DEFAULT_SOURCE_DIR );
	$self->{entry}       = $file->get( 'entry',       DEFAULT_ENTRY );
	$self->{module_root} = $file->get( 'module_root', DEFAULT_MODULE_ROOT );

	# A trailing slash would survive into the prefix that a module
	# name drops, and the name would then keep the whole path.
	$self->{module_root} =~ s{/+$}{};
	$self->{mandoc_os}  = $file->get( 'mandoc_os', DEFAULT_MANDOC_OS );
	$self->{man_url}    = $file->get( 'man_url',   DEFAULT_MAN_URL );
	$self->{stylesheet} = $file->get('stylesheet');

	return $self;
}

# $self->_read_nav($reason):
#	Collect the nav blocks in file order.
sub _read_nav ( $self, $reason )
{
	for my $block ( $self->{file}->blocks('nav') ) {
		my $href  = $block->{name};
		my $label = $block->{settings}{label};
		unless ( defined $label && length $label ) {
			return $self->_fail( $reason,
				"nav \"$href\" has no label" );
		}

		push @{ $self->{nav} }, { href => $href, label => $label };
	}

	return $self;
}

# $self->_read_pages($reason):
#	Collect the page blocks in file order. A block names exactly
#	one source, and no two blocks name the same output file.
sub _read_pages ( $self, $reason )
{
	my %seen;

	for my $block ( $self->{file}->blocks('page') ) {
		my $name     = $block->{name};
		my $settings = $block->{settings};

		my @named = grep { defined $settings->{$_} } @PAGE_SOURCES;
		unless ( @named == 1 ) {
			my $what =
			    @named
			    ? 'names ' . join ' and ', @named
			    : 'names no source (body, markdown or index)';
			return $self->_fail( $reason, "page \"$name\" $what" );
		}

		# The block name becomes a file in the output directory,
		# so it is a path and gets the same guard the sources
		# get. Without it a page block writes anywhere the
		# builder can write.
		if ( my $why = _unsafe_output_name($name) ) {
			return $self->_fail( $reason, "page \"$name\" $why" );
		}
		if ( $seen{$name}++ ) {
			return $self->_fail( $reason,
				"page \"$name\" is declared twice" );
		}

		my $source = $named[0];
		my $value  = $settings->{$source};
		if ( $source eq 'index' ) {
			unless ( $self->{file}->parse_bool( $value, 0 ) ) {
				return $self->_fail( $reason,
					      "page \"$name\" sets index to"
					    . " $value; the index source"
					    . ' needs yes' );
			}
			$value = undef;
		}
		elsif ( _has_parent_step($value) ) {
			return $self->_fail( $reason,
				      "page \"$name\" $source names $value,"
				    . ' which leaves the project' );
		}

		# A yes/no setting that does not parse is a typo, and a
		# typo that the parser swallows is a setting that
		# silently does not apply.
		my $unlinked =
		    $self->{file}->parse_bool( $settings->{unlinked}, 0 );
		if ( $self->{file}->error ) {
			return $self->_fail( $reason,
				      "page \"$name\" sets unlinked to"
				    . " $settings->{unlinked}; use yes or no" );
		}

		push @{ $self->{page} },
		    {
			file     => $name,
			title    => $settings->{title} // $name,
			source   => $source,
			value    => $value,
			unlinked => $unlinked,
		    };
	}

	return $self;
}

# The two block types that describe a manual group, and the kind that
# each one produces.
my %GROUP_BLOCK = ( manuals => 'manuals', modules => 'modules' );

# $self->_read_groups($reason):
#	Collect the manuals and modules blocks, in file order. A group
#	whose directory does not exist is an error: a silent empty
#	group hides a typo in a path, and a rename that nothing catches
#	is what this file exists to prevent.
sub _read_groups ( $self, $reason )
{
	# The two types interleave as the file wrote them, so the order
	# key decides and not the type.
	my @blocks =
	    sort { $a->{order} <=> $b->{order} }
	    map { $self->{file}->blocks($_) } sort keys %GROUP_BLOCK;

	for my $block (@blocks) {
		my $heading  = $block->{name};
		my $settings = $block->{settings};
		my $kind     = $GROUP_BLOCK{ $block->{type} };

		my $dir = $settings->{dir};
		unless ( defined $dir && length $dir ) {
			return $self->_fail( $reason,
				"$block->{type} \"$heading\" has no dir" );
		}
		if ( _has_parent_step($dir) ) {
			return $self->_fail( $reason,
				      "$block->{type} \"$heading\" dir is $dir,"
				    . ' which leaves the project' );
		}
		unless ( -d "$self->{root}/$dir" ) {
			return $self->_fail( $reason,
				      "$block->{type} \"$heading\" names $dir,"
				    . ' which is not a directory' );
		}

		my $anchor = $settings->{anchor};
		unless ( defined $anchor && length $anchor ) {
			return $self->_fail( $reason,
				"$block->{type} \"$heading\" has no anchor" );
		}

		# The namespace prefixes a manual name, and that name
		# becomes both the staged file and the published page.
		# It is a name, so it may not hold a path separator.
		my $namespace = $settings->{namespace};
		if ( defined $namespace && $namespace =~ m{/} ) {
			return $self->_fail( $reason,
				      "$block->{type} \"$heading\" namespace is"
				    . " $namespace, which holds a path"
				    . ' separator' );
		}

		# A modules group turns a path below the module root
		# into a Perl name. A directory outside that root has no
		# name to turn into, and the build would publish the
		# whole absolute path instead.
		if ( $kind eq 'modules'
			&& !App::FuguWeb::path_below( $dir,
				$self->{module_root} ) )
		{
			return $self->_fail( $reason,
				      "modules \"$heading\" names $dir, which"
				    . " is not below the module root"
				    . " $self->{module_root}" );
		}

		push @{ $self->{group} },
		    App::FuguWeb::Config::Group->new(
			kind        => $kind,
			heading     => $heading,
			anchor      => $anchor,
			dir         => "$self->{root}/$dir",
			namespace   => $settings->{namespace},
			module_root => "$self->{root}/$self->{module_root}",
		    );
	}

	return $self;
}

# $self->_check_pages($reason):
#	Refuse two manuals that would become the same page. The two
#	sources would overwrite each other in the staging directory and
#	in the output, and the index would show two entries that lead
#	to one page. A page block already gets this check; a manual
#	needs it as much.
sub _check_pages ( $self, $reason )
{
	my %source;

	for my $group ( $self->groups ) {
		for my $manual ( $group->manuals ) {
			my $page  = $manual->page;
			my $first = $source{$page};
			if ( defined $first ) {
				return $self->_fail( $reason,
					      "$first and "
					    . $manual->path
					    . " both become $page" );
			}
			$source{$page} = $manual->path;
		}
	}

	for my $page ( $self->pages ) {
		next unless defined $source{ $page->{file} };
		return $self->_fail( $reason,
			      "page \"$page->{file}\" and "
			    . $source{ $page->{file} }
			    . ' both become the same page' );
	}

	return $self;
}

# $self->_check_paths($reason):
#	Refuse a path setting that steps out of the project. A build
#	writes inside the output directory and reads inside the
#	checkout; a '..' in a setting breaks both promises at once.
sub _check_paths ( $self, $reason )
{
	unless ( defined $self->{site} && length $self->{site} ) {
		return $self->_fail( $reason, 'no site setting' );
	}

	for my $key (@PATH_SETTINGS) {
		next unless _has_parent_step( $self->{$key} );
		return $self->_fail( $reason,
			"$key is $self->{$key}, which leaves the project" );
	}

	return $self->_check_source_dir($reason);
}

# $self->_check_source_dir($reason):
#	Refuse a symlink in the source directory. Every file there
#	that the build does not render is copied into the site, and a
#	symlink would publish whatever it points at, from anywhere on
#	the machine. A content directory holds content.
sub _check_source_dir ( $self, $reason )
{
	my $dir = $self->source_path;
	return $self unless -d $dir;

	my $names = App::FuguWeb::list_dir($dir)
	    or return $self->_fail( $reason, "cannot read $dir: $!" );

	for my $name (@$names) {
		next unless -l "$dir/$name";
		return $self->_fail( $reason,
			      "$self->{source_dir}/$name is a symlink;"
			    . ' the build would publish what it points at' );
	}

	return $self;
}

# _has_parent_step($path):
#	Report whether a path holds a '..' component. A name that only
#	starts with two dots, such as '..config', is not a step out.
sub _has_parent_step ($path)
{
	return 0 unless defined $path;

	return scalar grep { $_ eq '..' } split m{/}, $path;
}

# _unsafe_output_name($name):
#	Report why a name may not become a file in the output
#	directory, or undef when it may. The name is one path below the
#	output: no step out, no absolute path, and no empty name.
sub _unsafe_output_name ($name)
{
	return 'is empty' unless defined $name && length $name;
	return 'is an absolute path'         if $name =~ m{^/};
	return 'leaves the output directory' if _has_parent_step($name);

	return;
}

# $self->_fail($reason, $message):
#	Record the reason, with the file that is at fault, and return
#	undef.
sub _fail ( $self, $reason, $message )
{
	$$reason = "$self->{path}: $message";

	return;
}

package App::FuguWeb::Config::Group;
our $VERSION = '0.1.1';

# App::FuguWeb::Config::Group - one group of the manual index.
#
# A group is a heading, an anchor, and a directory. It never holds a
# list of manuals: it reads the directory, so a manual that is added
# reaches the site with no edit anywhere.
#
# A manuals group globs mdoc sources. A modules group finds POD
# sidecars below the directory, and the file that names the directory
# itself: lib/App/FuguWeb.pod is the umbrella of lib/App/FuguWeb/.

# The sections that a manuals group globs, in the order the index
# shows them.
my @SECTIONS = qw(1 3p 5 8);

# App::FuguWeb::Config::Group->new(%args):
#	kind        => 'manuals'|'modules'
#	heading     => $string	the h2 of the group
#	anchor      => $string	the id of the h2
#	dir         => $path	the directory it reads
#	namespace   => $string	the prefix of a manuals name
#	module_root => $path	the prefix a module name drops
sub new ( $class, %args )
{
	return bless {
		kind        => $args{kind},
		heading     => $args{heading},
		anchor      => $args{anchor},
		dir         => $args{dir},
		namespace   => $args{namespace},
		module_root => $args{module_root},
	}, $class;
}

sub kind      ($self) { return $self->{kind}; }
sub heading   ($self) { return $self->{heading}; }
sub anchor    ($self) { return $self->{anchor}; }
sub namespace ($self) { return $self->{namespace}; }

# $self->manuals:
#	The manuals of the group, in the order the index shows them.
#	The method reads the directory once and keeps the answer.
sub manuals ($self)
{
	$self->{manuals} //=
	    $self->{kind} eq 'manuals'
	    ? [ $self->_mdoc_manuals ]
	    : [ $self->_pod_manuals ];

	return @{ $self->{manuals} };
}

# $self->_mdoc_manuals:
#	Every mdoc source in the directory, by section in the order 1,
#	3p, 5, 8, and then by file name. The sort compares bytes and
#	never reads the locale of the builder: a site must not depend
#	on the machine that built it.
#
#	The method reads the directory rather than globs it. Perl's
#	glob splits its pattern on whitespace and reads [ ] { } ? ~, so
#	a project whose path holds one of them would lose its manuals
#	or collect a sibling directory's. It also matches a directory,
#	and a directory named tool.1 is not a manual.
sub _mdoc_manuals ($self)
{
	my $names = App::FuguWeb::list_dir( $self->{dir} ) or return ();
	my @names = grep { !/^\./ } @$names;

	my @manuals;
	for my $section (@SECTIONS) {
		for my $name (@names) {
			next unless $name =~ /\.\Q$section\E$/;
			next unless -f "$self->{dir}/$name";

			push @manuals,
			    App::FuguWeb::Manual->from_mdoc(
				"$self->{dir}/$name", $self );
		}
	}

	return @manuals;
}

# $self->_pod_manuals:
#	Every POD sidecar below the directory, and the sidecar that
#	names the directory itself, by path. Sorting by the whole path
#	keeps Store.pod before Store/Memory.pod, because a dot sorts
#	before a slash.
sub _pod_manuals ($self)
{
	my @paths;
	push @paths, "$self->{dir}.pod" if -f "$self->{dir}.pod";

	File::Find::find( {
			no_chdir => 1,
			wanted   => sub {
				push @paths, $File::Find::name
				    if /\.pod$/ && -f $File::Find::name;
			},
		},
		$self->{dir} );

	return map {
		App::FuguWeb::Manual->from_pod( $_, $self,
			$self->{module_root} )
	} sort @paths;
}

1;
