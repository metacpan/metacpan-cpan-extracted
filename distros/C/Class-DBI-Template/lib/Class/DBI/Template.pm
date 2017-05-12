package Class::DBI::Template;
use strict;
use warnings;
use Template;
our $VERSION = '0.03';
use base qw/Class::Data::Inheritable Exporter/;
use Class::DBI::Template::Stash;
use Carp qw/cluck croak/;

our @EXPORT = qw/
	template_define
	template_configure
	template_data
	template_render
	template_build_data
/;

__PACKAGE__->mk_classdata("_template_$_") for qw/configure define data/;

sub _template_hash {
	my $item = shift;

	my $classdata = "_template_$item";
	my %data = %{__PACKAGE__->$classdata() || {}};
	if(@_ > 1) {
		my %new = @_;
		foreach(keys %new) { $data{$_} = $new{$_}; }
		__PACKAGE__->$classdata(\%data);
	} elsif(@_ == 1) {
		return $data{shift()};
	} else {
		return %data;
	}
}
sub template_define { shift; _template_hash('define',@_); }
sub template_data { shift; _template_hash('data',@_); }
my %configure_defaults = (
	stash_order		=> $Class::DBI::Template::Stash::default_order,
	stash_preload	=> $Class::DBI::Template::Stash::default_preload,
	stash_cache		=> 1,
);
sub template_configure {
	my $self = shift;

	my $data = __PACKAGE__->_template_configure();
	if(! $data) {
		$data = {%configure_defaults};
		__PACKAGE__->_template_configure($data);
	}
	if(@_ > 1) {
		my %new = @_;
		while(my($var,$val) = each %new) {
			$var =~ s/^\-//;
			$data->{lc($var)} = $val;
		}
		__PACKAGE__->_template_configure($data);
	} elsif(@_ == 1) {
		my $item = lc(shift());
		$item =~ s/^\-//;
		return $data->{$item};
	} else {
		return wantarray ? %{$data} : $data;
	}
}

sub template_render {
	my $self = shift;
	my $which = shift;
	my %args = @_;

	my %vars = ();
	my $tmpl = $self->template_define($which) || $which;

	my @stash_order = Class::DBI::Template::Stash::unfold(
		$self->template_configure('stash_order')
	);
	my %pre = ();
	foreach my $pre (@{$self->template_configure('stash_preload')}) {
		$pre{$pre}++;
		if($pre eq 'columns') {
			foreach($self->columns) { $vars{$_} = $self->get($_); }
		} elsif($pre eq 'template_data') {
			my %new = __PACKAGE__->template_data();
			@vars{keys %new} = values %new;
		} elsif($pre eq 'environment') {
			@vars{keys %ENV} = values %ENV;
		} elsif($pre eq 'arguments') {
			@vars{keys %args} = values %args;
		} else {
			die "Cannot preload $pre\n";
		}
		@stash_order = grep { $_ ne $pre } @stash_order;
	}
	$vars{_PRELOADED} = \%pre;

	my %opts = %{__PACKAGE__->template_configure('template_options') || {}};
	$opts{STASH} = Class::DBI::Template::Stash->new({});

	$vars{_SELF} = $self;
	$vars{_ARGS} = \%args;
	$vars{_CONF} = __PACKAGE__->_template_configure;

	my $out = '';
	eval {
		my $template = Template->new(\%opts);
		if($out = $self->template_configure('output')) {
			$template->process($tmpl, \%vars, \$out) || die $template->error;
			return;
		} else {
			$template->process($tmpl, \%vars, \$out) || die $template->error;
		}
	};
	if($@) {
		croak "Template processing failed: $@";
	}
	if($out) {
		return $out;
	} else {
		die "No output found\n";
	}
}

1;
__END__

=head1 NAME

Class::DBI::Template - Perl extension using Template Toolkit to render Class::DBI objects

=head1 SYNOPSIS

  package Music::DBI;
  use base 'Class::DBI';
  use Class::DBI::Template;
  Music::DBI->connection('dbi:mysql:dbname','username','password');
  Music::DBI->template_configure(
    INCLUDE_PATH       => '/search/path',
    PRE_CHOMP          => 1,
    POST_CHOMP         => 1,
  );

  package Music::Artist;
  use base 'Music::DBI';
  Music::Artist->table('artist');
  Music::Artist->columns(All => qw/artistid name/);
  Music::Artist->has_many(cds => 'Music::CD');
  Music::Artist->template_define(cd_listing => <<"END");
  [% INSERT header %]

  <h1>CD Listing for [% name %]</h1>

  [% FOR cd = cds %]
    [% cd.render_template('cd_mini_info') %]
  [% END %]

  [% INSERT footer %]
  END

  package Music::CD;
  use base 'Music::DBI';
  Music::CD->table('cd');
  Music::CD->columns(All => qw/cdid artist title year/);
  Music::CD->has_many(tracks => 'Music::Track');
  Music::CD->has_a(artist => 'Music::Artist');
  Music::CD->might_have(liner_notes => LinerNotes => qw/notes/);
  Music::CD->template_define(cd_mini_info => \*DATA);
  __DATA__
  <h1>[% title %]</h1>
  <hr>
  <h2><a href="artist.cgi?artist=[% artist.id %]">[% artist %]</a></h2>

  <ul>Tracks
  [% FOR track = tracks %]
    <li><a href="track.cgi?track=[% track.id %]">[% track.title %]</a>
  [% END %]
  </ul>

  [% IF liner_notes %]
    <blockquote>[% liner_notes %]</blockquote>
  [% END %]

  #-- Meanwhile, in a nearby piece of code! --#

  use strict;
  use CGI;
  my $cgi = new CGI;
  my $artist = Music::Artist->retrieve($cgi->param('artist'));
  print $cgi->header,$artist->template_render('cd_listing');

=head1 DESCRIPTION

This module provides a tie between Class::DBI and the Template Toolkit.  It
allows you to specify templates which can be used to render the data available
in the module in various ways.

=head1 EXPORT

=over 4

=item template_define($template_name, $template);

The template_define() method takes two arguments, the name of the template,
which will be used to refer to it when rendering, and the template data.  The
name is a simple string (or anything which can be used as a hash key), and the
value is any value that will be accepted by the Template module as a template
to be rendered.

=item template_configure(%template_configuration_options);

The template_configure method is used to pass configuration options to the
Template modules new() method.  It takes a hash of configuration options,
and these are passed verbatim to Template->new().

=item template_render($template_name, [$var1 => $value1, ...]);

The template_render method takes the name of the template to render, and
returns the template rendered with the data from the current form.  After
the template name you can pass a hash of additional data to be added
to the data available to the template and of configuration options for the
rendering.  Any arguments passed in the hash which contain a key that starts
with a - are considered to be configuration options.  Arguments starting with
anything else will be passed to the template.

Note that if the value you pass as a $template_name was not defined as the
name of a template using template_define(), $template_name will be passed
verbatim to the Template module for rendering.  This means that if you setup
your template configuration appropriately, you don't even need to predeclare
your templates.  For example, using the classes defined above, you could do
this:

  #!/usr/bin/perl -w
  use strict;
  use warnings;
  use Music::Artist;

  my $artist = Music::Artist->retrieve(1);
  $artist->render('artist_photograph');

Even though the template 'artist_photograph' was never defined, this will work
if a file called artist_photograph can be found in the template search path
that was defined.

=item template_data($key => $value[, $key2 => $value2 ...]);

The template_data method takes a hash of data to be added to the variables
that are passed to your template for rendering.  By default the data will
contain only the fields from the database, and some supporting variables.

As an example, if you want access to the environment variables from your
template, you could add:

  # not such a good example
  __PACKAGE__->template_data(ENV => \%ENV);

Beware of this practice in long-running or time sensitive applications
however.  This is probably not a good idea in a mod_perl environment, for
example, because the data you will get will be the environment that was
in effect at compile time, not at run time.  If you need to add data that
may change at run time, you are better off providing a subroutine reference
that can generate and return the data you need.  This also makes things a
bit faster, by not doing any of the work of generating that data until the
template actually uses it.

  # better example
  __PACKAGE__->template_data(ENV => sub { return \%ENV });

=back

=head1 CONFIGURATION

In addition to specifying configuration options for the Template module when
you call template_configure(), there are also some Class::DBI::Template
configuration options you can use.

=over 4

=item STASH_ORDER

The STASH_ORDER configuration option will be passed to the
Class::DBI::Template::Stash object being created.  Refer to the documentation
for that module for more details.

=item STASH_PRELOAD

=back

=head1 HINTS, TIPS, and TRICKS

=item * Rendering non-database templates

If you have generic templates that don't refer to any database data, you don't
need to create special classes to render them, you can just use your Class::DBI
subclass directly:

  #!/usr/bin/perl -w
  # index.cgi
  use Music::DBI;
  Music::DBI->template_render('main_index_page');

=item * Breaking up your templates

If you are creating templates for an object that has references to other
Class::DBI objects (has_a, has_many, might_have, etc), try to avoid including
rendering instructions for the related objects in the template for this object.
Instead, create a small template that renders the data for the subobject, then
you can simply render it in your larger template. For example...

  [%# This template is in the file artist_listing %]
  [% INCLUDE header title="Artist Listing" %]
  [% FOR artist = artists %]
    [% artist.template_render('artist_entry') %]
  [% END %]
  [% INCLUDE footer %]

  [%# This template is in the file artist_entry %]
  <h1>[% name %]</h1>
  <ul>
  [% FOR album = albums %]
    <li>[% album.template_render('album_oneline') %]
  [% END %]
  </ul>

  [%# This template is in the file album_oneline %]
  [% name %] ([% year %])

  #!/usr/bin/perl -w
  # artist-listing.cgi
  use Music::Artist;

  my @artists = Music::Artist->retrieve_all
  Music::Artist->template_render('artist_listing', artists => \@artists);

=item * Rendering disparate object types in a loop

On my home page, the main index shows a summary of recent activity on the site,
in a pseudo-blog style.  It summarizes actual blog entries, recent photos I've
taken, project activity, and several other interesting things.  In order to get
this summary, I added a function to my JSK::DB class that loops through the
different types of objects, collects the most recent from each type, and then
sorts them all by their timestamp and returns the X most recent.  The problem
I ran into was that this then gave me an array that was a jumble of different
objects.

I started out dealing with it like this:

  [% USE db = Class('JSK::DB') %]
  [% FOR entry = db.recent_activity(10) %]
    [% entry.template_render('blog_summary') IF entry.isa('JSK::Blog') %]
    [% entry.template_render('photo_summary') IF entry.isa('JSK::Photo') %]
    ... several more like that ...
  [% END %]

I quickly decided this was stupid, and I needed a better way, which this
module makes easy to do.  Anything you pass as the argument to template_define
will be passed verbatim as the template to Template when it renders.  So if
the argument is a filehandle, for example, the filehandle will be passed to
the Template module.  This also means that simple scalars (not scalar refs,
see 'perldoc Template' for what happens when you pass a scalar ref as a
template) will be passed as the name of the template.  So you can use
template_define to define a standard template name, and simply map it to
another template name, like so:

  # snip from JSK::Blog
  __PACKAGE__->template_define('summarizer' => 'blog_summary');

  # snip from JSK::Photo
  __PACKAGE__->template_define('summarizer' => 'photo_summary');

Now I had a standard template name, that knew which template to use to
summarize each of my object types.  This simplified the index template
greatly...

  [% USE db = Class('JSK::DB') %]
  [% FOR entry = db.recent_activity(10) %]
    [% entry.template_render('summarizer') %]
  [% END %]

=item * Automagic template finding with Apache

This is the setup I use on my own homepage (http://www.jasonkohles.com/),
which allows Apache to determine what pages on the site refer to templates
and render them automatically.

First I created an index.cgi that looks like this:

  #!/usr/bin/perl -w
  # index.cgi
  require 'lib/startup.pl';

  my $template = $ENV{PATH_INFO} || 'index';
  $template =~ s#^/##;

  print header(),JSK::DB->template_render($template);

My startup.pl is basically mod_perl configuration information, it lets Apache
find the data it needs, it basically looks like this:

  #!/usr/bin/perl -w
  # startup.pl
  use strict;
  use warnings;
  use lib '/var/www/jason/lib';
  use JSK::DB;
  use CGI qw/:standard/;

  our $cgi = new CGI;

My Class::DBI base class contains:

  package JSK::DB;
  use strict;
  use warnings;
  use Apache::Reload;
  use base 'Class::DBI::mysql';
  use Class::DBI::Template;

  __PACKAGE__->connection('dbi:mysql:jason','jason');
  __PACKAGE__->template_configure(
	-template_options => {
      INCLUDE_PATH => '/var/www/jason/templates',
      POST_CHOMP   => 1,
    },
    -stash_preload => [qw/arguments/],
    -stash_order   => [qw/columns environment/],
  );

  1;

Then, the automagic part.  In my Apache configuration, I have this rewrite rule:

  RewriteEngine On
  RewriteCond   /var/www/jason/templates/%{REQUEST_FILENAME}  -f
  RewriteRule   /var/www/jason/index.cgi/%{REQUEST_FILENAME}  [L]

This way, when a request is processed by Apache, it checks to see if the
requested filename refers to a template in my templates directory.  If it
does, then it passes it off to index.cgi for rendering.  If it doesn't, then
Apache will handle it as it normally does.  The reason I did it this way is
that most of the pages are simply information, and I can drop a template in
place to render them pretty easily.  For more complex stuff I can create a
custom CGI script similar to index.cgi, but that does more rendering, or
handles specific requirements for that data.

=item * Finding undefined variables in your templates

By default the Template module replaces unknown variables in your template
with an empty string.  This makes it tough sometimes to find errors in the
templates, because they silently fail.  Class::DBI::Template uses a more
robust Stash module, that you can configure to search for those unknown
variables in a variety of ways.  This also makes it very easy to find undefined
variables in your templates, by tacking a default subroutine handler onto
the end of the search order.

For example...

  # die when undefined variables are found:
  __PACKAGE__->template_configure(
    STASH_ORDER => ['+', sub { shift; die Dumper(\@_) }],
  );

  # replace unknown variables with HTML comments, then you can look for them
  # either by viewing the source, or by using automated tools to walk your
  # site and look for problems
  __PACKAGE__->template_configure(
    STASH_ORDER => ['+', sub {
		my $self = shift;
		my $var = shift;
		my $args = shift;
		if(ref($var)) {
			my @var = @{$var};
	
			my @parts = ();
			while(@var) {
				my($var,$arg) = splice(@var,0,2);
				if(ref $arg) {
					push(@parts,"$var(".join(', ',@{$arg}).")");
				} else {
					push(@parts,$var);
				}
			}
			$var = join('.',@parts);
		}
		return "<!-- Undefined Variable: $var -->";
	}],
  );

  # or just stuff the values into the page, making it ugly and obvious
  # that stuff is broken:
  __PACKAGE__->template_configure(
    STASH_ORDER => ['+', sub { return "<xmp>".Dumper(@_)."</xmp>"; }

=head1 SEE ALSO

=over 4

=item perldoc Class::DBI

=item perldoc Class::DBI::Template::Stash

=item perldoc Template

=item http://www.template-toolkit.org/

=item http://www.jasonkohles.com/

=back

=head1 AUTHOR

Jason Kohles E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
