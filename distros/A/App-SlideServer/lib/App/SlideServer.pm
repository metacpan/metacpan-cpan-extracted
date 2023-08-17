package App::SlideServer;
use v5.36;
use Mojo::Base 'Mojolicious';
use Mojo::WebSocket 'WS_PING';
use Mojo::File 'path';
use Mojo::DOM;
use Scalar::Util 'looks_like_number';
use File::stat;
use Text::Markdown::Hoedown;
use Carp;

our $VERSION = '0.002'; #VERSION
#ABSTRACT: Mojo web server that serves slides and websocket


# Files supplied by the user to override the distribution
has serve_dir => sub { path(shift->home) };


# Choose the first of 
sub slides_source_file($self, $value=undef) {
	$self->{slides_source_file}= $value if defined $value;
	$self->{slides_source_file} // do {
		my ($src)= grep -f $_,
			$self->serve_dir->child('slides.html'),
			$self->serve_dir->child('slides.md'),
			$self->serve_dir->child('public','slides.html'),
			$self->serve_dir->child('public','slides.md');
		$src;
	};
}

has 'slides_source_monitor';


# Files that ship with the distribution
has share_dir => sub {
	if (-f path(__FILE__)->sibling('..','..','share','public','slides.js')) {
		return path(__FILE__)->sibling('..','..','share')->realpath;
	} else {
		require File::ShareDir;
		return path(File::ShareDir::dist_dir('App-SlideServer'));
	}
};


# A secret known only to whoever starts the server
# Clients must send this to gain presenter permission.
has presenter_key => sub($self) {
	my $key= sprintf "%06d", rand 1000000;
	$self->log->info("Auto-generated presenter key: $key");
	return $key;
};


# Hashref of { ID => $context } for every connected websocket
has viewers => sub { +{} };


# Hashref of data to be pushed to all clients
has published_state => sub { +{} };


has ['cache_token', 'page_dom', 'slides_dom'];


sub build_slides($self, %opts) {
	my ($html, $token)= $self->load_slides_html(if_changed => $self->cache_token);
	return 0 unless defined $html; # undef if source file unchanged
	my ($page, @slides)= $self->extract_slides_dom($html);
	$self->log->info("Loaded ".@slides." slides from ".$self->slides_source_file);
	$page= $self->merge_page_assets($page);
	$self->cache_token($token);
	my $page_diff= !$self->page_dom || $self->page_dom ne $page;
	my @slides_diff= !$self->slides_dom? (0..$#slides)
		: grep { ($self->slides_dom->[$_]//'') ne ($slides[$_]//'') } 0..$#slides;
	$self->page_dom($page);
	$self->slides_dom(\@slides);
	$self->on_page_changed() if $page_diff;
	$self->on_slides_changed(\@slides_diff) if @slides_diff;
	return \@slides;
}


sub load_slides_html($self, %opts) {
	my $srcfile= $self->slides_source_file;
	defined $srcfile
		or croak "No source file; require slides.md or slides.html in serve_dir '".$self->serve_dir."'\n";
	# Allow literal data with a scalar ref
	my ($content, $change_token);
	if (ref $srcfile eq 'SCALAR') {
		return undef
			if defined $opts{if_changed} && 0+$srcfile == $opts{if_changed};
		$content= $$srcfile;
		$change_token= 0+$srcfile;
		# Assume markdown unless first non-whitespace is the start of a tag
		$content= $self->markdown_to_html($content, %opts)
			unless $srcfile =~ /^\s*</;
	}
	elsif (ref $srcfile eq 'GLOB' || (ref($srcfile) && ref($srcfile)->isa('IO::Handle'))) {
		return undef
			if defined $opts{if_changed} && (0+$srcfile) .'_'. tell($srcfile) eq $opts{if_changed};
		seek($srcfile, 0, 0) || die "seek: $!"
			unless tell($srcfile) <= 0;
		$content= do { local $/= undef; <$srcfile> };
		utf8::decode($content) unless PerlIO::get_layers($srcfile) =~ /encoding|utf8/i;
		# Assume markdown unless first non-whitespace is the start of a tag
		$content= $self->markdown_to_html($content, %opts)
			unless $srcfile =~ /^\s*</;
		$change_token= (0+$srcfile) .'_'. tell($srcfile);
	}
	else {
		my $st= stat($srcfile)
			or croak "Can't stat '$srcfile'";
		return undef
			if defined $opts{if_changed} && $st->mtime == $opts{if_changed};
		
		$content= path($srcfile)->slurp;
		utf8::decode($content); # Could try to detect encoding, but people should just use utf-8

		$content= $self->markdown_to_html($content, %opts)
			if $srcfile =~ /[.]md$/;
		$change_token= $st->mtime;
	}
	return wantarray? ($content, $change_token) : $content;
}

sub monitor_source_changes($self, $enable=1) {
	if ($enable) {
		my $f= $self->slides_source_file;
		-f $f or croak "No such file '$f'";
		# TODO: wrap inotify in an object with a more convenient API and detect things like file renames
		$self->{_inotify} //= do {
			require Linux::Inotify2;
			my $inotify= Linux::Inotify2->new;
			my $i_fh= IO::Handle->new_from_fd($inotify->fileno, 'r');
			Mojo::IOLoop->singleton->reactor
				->io( $i_fh, sub($reactor, $writable) { $inotify->poll if $inotify && !$writable })
				->watch($i_fh, 1, 0);
			{ inotify => $inotify, inotify_fh => $i_fh }
		};
		Scalar::Util::weaken( my $app= $self );
		my $watch= $self->{_inotify}{inotify}->watch("$f", Linux::Inotify2::IN_MODIFY(), sub { $app->build_slides });
		$self->slides_source_monitor($watch);
	} else {
		$self->slides_source_monitor(undef);
	}
}


sub markdown_to_html($self, $md, %opts) {
	return markdown($md, extensions => (
		HOEDOWN_EXT_TABLES | HOEDOWN_EXT_FENCED_CODE | HOEDOWN_EXT_AUTOLINK | HOEDOWN_EXT_STRIKETHROUGH
		| HOEDOWN_EXT_UNDERLINE | HOEDOWN_EXT_QUOTE | HOEDOWN_EXT_SUPERSCRIPT | HOEDOWN_EXT_NO_INTRA_EMPHASIS
		)
	);
}


sub _node_is_slide($self, $node, $tag) {
	return $tag eq 'div' && ($node->{class}//'') =~ /\bslide\b/;
}
sub _node_starts_slide($self, $node, $tag) {
	return $tag eq 'h1' || $tag eq 'h2' || $tag eq 'h3';
}
sub _node_splits_slide($self, $node, $tag) {
	return $tag eq 'hr';
}

sub extract_slides_dom($self, $html, %opts) {
	my $dom= Mojo::DOM->new($html);
	my @head_tags= qw( head title script link style base meta );
	my @move_to_head;
	my $slide_root= $dom->at('div.slides') || $dom->at('body') || $dom;
	for my $tag (@head_tags) {
		for my $el ($slide_root->find("$tag")->each) {
			push @move_to_head, $el;
			# The markdown processor puts <p> tags on any raw html it wasn't expecting,
			my $parent= $el->parent;
			$el->remove;
			$parent->remove if $parent && $parent->tag && $parent->tag eq 'p' && $parent =~ m|^<p>\s*</p>|;
		}
	}
	for my $el ($slide_root->find('notes')->each) {
		$el->tag('pre');
		$el->{class}= 'notes';
		my $parent= $el->parent;
		$parent->strip if $parent->tag eq 'p'; # markdown processor adds <p> tags
	}
	
	# Find each element that is an immediate child of body, and add it to
	# the current slide until the next <h1> <h2> <h3> <hr> or <div class="slide">
	# at which point, move to the next slide.
	my (@slides, $cur_slide);
	for my $node ($slide_root->@*) {
		$node->remove;
		my $tag= $node->tag // '';
		# is it a whole pre-defined slide?
		if ($self->_node_is_slide($node, $tag)) {
			$cur_slide= undef;
			push @slides, $node;
		}
		elsif ($self->_node_splits_slide($node, $tag)) {
			$cur_slide= undef;
		}
		else {
			# Ignore whitespace nodes when not in a current slide
			next if !defined $cur_slide && $node->type eq 'text' && $node->text !~ /\S/;
			push @slides, ($cur_slide= Mojo::DOM->new_tag('div', class => 'slide')->[0])
				if !defined $cur_slide
					|| $self->_node_starts_slide($node, $tag);
			# Add "auto-step" to any <UL> tags
			if (($tag eq 'ul' || $tag eq 'ol') && !$node->{class}) {
				$node->{class}= "auto-step";
				# Now apply auto-step recursively to <ol> and <ul>
				$node->find('ol')->map(sub{ $_->{class}= $_->{class}? "$_->{class} auto-step" : 'auto-step' });
				$node->find('ul')->map(sub{ $_->{class}= $_->{class}? "$_->{class} auto-step" : 'auto-step' });
			}
			$cur_slide->append_content($node);
		}
	}
	
	# Re-add things that belong in <head>
	($dom->at('html') || $dom)->prepend_content('<head></head>')
		unless $dom->at('head');
	for my $el (@move_to_head) {
		if ($el->tag eq 'head') {
			$el->child_nodes->each(sub{ $dom->at('head')->append_content($_) });
		} else {
			$dom->at('head')->append_content($el);
		}
	}
	return ($dom, @slides);
}	


sub merge_page_assets($self, $srcdom, %opts) {
	my $page= Mojo::DOM->new($self->share_dir->child('page_template.html')->slurp);
	if (my $srchead= $srcdom->at('head')) {
		my $pagehead= $page->at('head');
		# Prevent conflicting tags (TODO, more...)
		if (my $title= $srchead->at('title')) {
			$pagehead->at('title')->remove;
		}
		$pagehead->append_content($_) for $srchead->@*;
	}
	if (my $srcbody= $srcdom->at('body')) {
		if ($srcbody->child_nodes->size) {
			$page->at('body')->replace($srcbody);
			if (!$page->at('body div.slides')) {
				$page->at('body')->append_content('<div class="slides"></div>');
			}
		} else {
			$page->at('body')->%*= $srcbody->%*;
		}
	}
	return $page;
}


sub update_published_state($self, @new_attrs) {
	$self->published_state->%* = ( $self->published_state->%*, @new_attrs );
	$_->send({ json => { state => $self->published_state } })
		for values $self->viewers->%*;
}


sub startup($self) {
	$self->build_slides;
	$self->presenter_key;
	$self->static->paths([ $self->serve_dir->child('public'), $self->share_dir->child('public') ]);
	$self->routes->get('/' => sub($c){ $c->app->serve_page($c) });
	$self->routes->websocket('/slidelink.io' => sub($c){ $c->app->init_slidelink($c) });
}

sub serve_page($self, $c, %opts) {
	if (!defined $self->page_dom || $self->cache_token) {
		eval { $self->build_slides; 1 }
			or $self->log->error($@);
	}
	# Merge the empty page with all currently-visible slides,
	# which saves the client from needing a second request to fetch them.
	# TODO: implement slide-by-slide loading
	my $slide_max= $#{$self->slides_dom}; # $self->published_state->{slide_max} || 0;
	my @slides= $self->slides_dom->@[0..$slide_max];
	my $combined= Mojo::DOM->new($self->page_dom);
	$combined->at('div.slides')->append_content(join '', @slides);

	# If this is for the presenter, set the config variable for that
	if ($opts{presenter} || defined $c->req->param('presenter')) {
		$combined->at('head')->append_content(
			'<script>window.slides.config.mode="presenter";</script>'."\n"
		);
	}

	$c->render(text => ''.$combined);
}

sub init_slidelink($self, $c) {
	my $id= $c->req->request_id;
	$self->viewers->{$id}= $c;
	my $mode= $c->req->param('mode');
	my $key= $c->req->param('key');
	my %roles= ( follow => 1 );
	if ($mode eq 'presenter') {
		if (($key||'') eq $self->presenter_key) {
			$roles{lead}= 1;
			$roles{navigate}= 1;
			$self->update_published_state(viewer_count => scalar keys $self->viewers->%*);
		}
		elsif (defined $key) {
			$c->send({ json => { key_incorrect => 1 } });
		}
	}
	$c->stash('roles', join ',', keys %roles);
	$self->log->info(sprintf "%s (%s) connected as %s", $id, $c->tx->remote_address, $c->stash('roles'));
	$c->send({ json => { roles => [ keys %roles ] } });
	
	$c->on(json => sub($c, $msg, @) { $c->app->on_viewer_message($c, $msg) });
	$c->on(finish => sub($c, @) { $c->app->on_viewer_disconnect($c) });
	$c->inactivity_timeout(3600);
	#my $keepalive= Mojo::IOLoop->recurring(60 => sub { $viewers{$id}->send([1, 0, 0, 0, WS_PING, '']); });
	#$c->stash(keepalive => $keepalive);
}


sub on_viewer_message($self, $c, $msg) {
	my $id= $c->req->request_id;
	$self->log->debug(sprintf "client %s %s msg=%s", $id, $c->tx->original_remote_address//'', $msg//'');
	if ($c->stash('roles') =~ /\blead\b/) {
		if (defined $msg->{extern}) {
		}
		if (defined $msg->{slide_num}) {
			$self->update_published_state(
				slide_num => $msg->{slide_num},
				step_num => $msg->{step_num},
				($msg->{slide_num} > ($self->published_state->{slide_max}//0)?
					( slide_max => $msg->{slide_num} ) : ()
				)
			);
		}
	}
#	if ($c->stash('roles') =~ /\b
}

sub on_viewer_disconnect($self, $c) {
	my $id= $c->req->request_id;
	#Mojo::IOLoop->remove($keepalive);
	delete $self->viewers->{$id};
	$self->update_published_state(viewer_count => scalar keys $self->viewers->%*);
}

sub on_page_changed($self) {
	$_->send({ json => { page_changed => 1 } })
		for values $self->viewers->%*;
}

sub on_slides_changed($self, $changed) {
	my @changes= map +{ idx => $_, html => $self->slides_dom->[$_] }, @$changed;
	for my $viewer (values $self->viewers->%*) {
		$viewer->send({ json => { slides_changed => \@changes } })
	}
}


use Exporter 'import';
our @EXPORT_OK= qw( mojo2logany );

# Utility method to create a Mojo logger that logs to Log::Any
sub mojo2logany($logger= undef) {
	require Mojo::Log;
	require Log::Any;
	if (defined $logger && !ref $logger) {
		$logger= Log::Any->get_logger(category => $logger);
	} elsif (!defined $logger) {
		$logger= Log::Any->get_logger;
	}
	my $mlog= Mojo::Log->new;
	$mlog->unsubscribe('message');
	$mlog->on(message => sub($app, $level, @lines) { $logger->$level(join ' ', @lines) });
	$mlog;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SlideServer - Mojo web server that serves slides and websocket

=head1 VERSION

version 0.002

=head1 SYNOPSIS

   use App::SlideServer;
   my $app= App::SlideServer->new(\%opts);
   $app->start(qw( daemon -l http://*:2000 ));

=head1 DESCRIPTION

This class is a fairly simple Mojo web application that serves a small
directory of files, one of which is a Markdown or HTML document containing
your slides.  The slides then use the provided JavaScript to create a
presentation similar to other popular software, and a user interface for
the presenter.  As a bonus, you can make any number of connections to the
server and synchronize the slide show over a websocket, allowing viewers
to follow the presenter, or the presenter to flip slides from a different
device than is connected to the projector (like a tablet or phone).

On startup, the application upgrades your slides to a proper HTML structure
(see L<HTML SPECIFICATION>) possibly by first running it through a Markdown
renderer if you provided the slides as markdown instead of HTML.  It then
inspects the HTML and breaks it apart into one or more slides.

You may then start the Mojo application as a webserver, or whatever else you
wanted to do with the Mojo API.

The application comes with a collection of web assets that render your HTML
to fit fullscreen in a browser window, and to provide a user interface to the
presenter that shows navigation buttons and private notes for giving the
presentation.

=head1 CONSTRUCTOR

This is a standard Mojolicious object with a Mojo::Base C<< ->new >> constructor.

=head1 ATTRIBUTES

=head2 serve_dir

This is a Mojo::File object of the diretory containing templates and public
files.  Public files live under C<< $serve_dir/public >>.
See L</slides_source_file> for the location of your slides.

The default is C<< $self->home >> (Mojolicious project root dir)

=head2 slides_source_file

Specify the actual path to the file containing your slides.  The default is
to use the first existing file of:

   * $serve_dir/slides.html
   * $serve_dir/slides.md
   * $serve_dir/public/slides.html
   * $serve_dir/public/slides.md

Note that files in public/ can be downloaded as-is by the public at any time.
...but maybe that's what you want.

=head2 share_dir

This is a Mojo::File object of the directory containing the web assets that
come with App::SlideServer.  The default uses File::ShareDir and should
'just work' for you.

=head2 presenter_key

This is a secret string that only you (the presenter) should know.
It is your password to let the server know that your browser is the one that
should be controlling the presentation.

If you don't initialize this, it defaults to a random value which will be
printed on STDOUT where (presumably) only you can see it.

=head2 viewers

A hashref of C<< ID => $context >> where C<$context> is the Mojo context
object for the client's websocket connection, and ID is the request ID for
that websocket.  This is updated as clients connect or disconnect.

=head2 published_state

A hashref of various data which has been broadcast to all viewers.
This keeps track of things like the current slide, but you can extend it
however you like if you want to add features to the client javascript.
Use L</update_published_state> to make changes to it.

=head2 page_dom

This is a Mojo::DOM object holding the page that is served as "/" containing
the client javascript and css (but not any of the slides).
This is a cached output of L</build_slides> and may be rebuilt at any time.

=head2 slides_dom

This is an arrayref of the individual slides (Mojo::DOM objects) that the
application serves.  This is a cached output of L</build_slides> and may be
rebuilt at any time.

=head2 cache_token

A value (usually an mtime) that is used by L</load_slides_html> to determine
if the source content has changed.  You can clear this value to force
L</build_slides> to perform a rebuild.

=head1 METHODS

=head2 build_slides

This calls L</load_slides_html> (which calls C<markdown_to_html> if your
source is markdown) then calls L</extract_slides_dom> to break the HTML into
Mojo::DOM objects (and restructure shorthand notations into proper HTML),
then calls L</merge_page_assets> to augment the top-level page with the web
assets like javascript and css needed for the client slide UI, then stores
this result in L</page_dom> and L</slides_dom> and returns C<$self>.
It throws exceptions if it fails, leaving previous results intact.

You can override any of those methods in a subclass to customize this process.

This method is called automatically at startup and any time the mtime of your
source file changes. (detected lazily when serving '/')  

=head2 load_slides_html

  $html= $app->load_slides_html;
  ($html, $token)= $app->load_slides_html(if_changed => $token)

Reads L</slides_source_file>, calls L</markdown_to_html> if it was markdown,
and returns the content as a string I<of characters>, not bytes.

In list context, this returns both the content and a token value that can be
used to test if the content changed (usually file mtime) on the next call
using the 'if_changed' option.  If you pass the 'if_chagned' value and the
content has I<not> changed, this returns undef.

=head2 markdown_to_html

  $html= $app->markdown_to_html($md);

This is a simple wrapper around Markdown::Hoedown with most of the syntax
options enabled.  You can substitute any markdown processor you like by
overriding this method in a subclass.

=head2 extract_slides_dom

This function takes loose shorthand HTML (or full HTML) and splits out the
slides content while also upgrading them to full HTML structure according to
L<HTML SPECIFICATION>.  It returns one Mojo::DOM object for the top-level
page, and one Mojo::DOM object for each detected slide, as a list.

=head2 merge_page_assets

  $merged_dom= $app->merge_page_assets($src_dom);

This starts with the page_template.html shipped with the module, then adds
any <head> tags from the source file, then merges the body or div.slides tags
from the source file.  It is assumed the slides have already been removed
from C<$src_dom>.

=head2 update_published_state

  $app->update_published_state( $k => $v, ...)

Apply any number of key/value pairs to the L</published_state>, and then
push it out to all L</viewers>.

=head1 EVENT METHODS

=head2 serve_page

  GET /

Returns the root page, without any slides.

=head2 serve_slides

  GET /slides
  GET /slides?i=5

Returns HTML for one or more slides.

=head2 init_slidelink

  GET /slidelink.io

Open a websocket connection.  This method determines whether the
new connection is a presenter or not, and then sets up the events and adds it
to L</viewers> and pushes out a copy of L</published_state> to the new client.

=head2 on_viewer_message

Handle an incoming message from a websocket.

=head2 on_viewer_disconnect

Handle a disconnect event form a websocket.

=head1 EXPORTS

=head2 mojo2logany

  ->new(log => mojo2logany);
  ->new(log => mojo2logany("channel::name"));
  ->new(log => mojo2logany($logger));

This is a convenience function that returns a L<Mojo::Log> object which passes
all logging events to a Log::Any logging channel.  I like the L<Log::Any>
ecosystem and it's a little messy to redirect the logs without a utility
function.

=head1 HTML SPECIFICATION

The page must contain a C<< <div class="slides"> >> somewhere inside the C<< <body> >>.
All slides are C<< <div class="slide"> >> and must occur as direct children of the
C<div.slides> element.

Inside a C<div.slide> element, the elements may belong to iterative steps.
This is indicated using the C<< data-step="..." >> attribute.  The notation
for that attribute can be a single integer, meaning the element becomes visible
at that step C<< data-step="2" >>, or a list of ranges of integers indicating
which exact steps the element will be visible C<< data-step="2-3,5-5" >>.
Step number 0 is initially visible when the slide comes up (so you don't need
to specify number 0 anywhere, because it's already visible).

To ease the common scenario of assigning steps to a bullet list, you may
put the C< .auto-step > class on any element, and its child elements will
receive sequential step numbers starting from the C<step> value of that
element, defaulting to 1.

Each C<div.slide> may contain a C<div.notes>, which is only visible to the
presenter.  (TODO: currently this is only enforced with css, but should be
handled in the back-end)

=head2 Convenient Translations

If you don't provide a C<div.slides> element, one will be added under C<body>.
If you don't have a C<body> tag, one will be added for you as well.

If you put elements other than C<div.slide> under the C<div.slides> element
in your source file, they will be automatically broken into slides as follows:

=over

=item C<< <h1> <h2> <h3> >>

These each trigger the start of a new slide

=item C<< <hr> >>

This begins a new slide while deleting the C<< <hr> >> element,
useful when you have slides without headers.

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
