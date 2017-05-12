package Bryar;

use Bryar::Config;
use Time::Local;
use Bryar::Comment;
use Calendar::Simple;
use DateTime;
use List::Util;

use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '4.0';

=head1 NAME

Bryar -  A modular, extensible weblog tool

=head1 SYNOPSIS

	Bryar->go();

=head1 DESCRIPTION

Bryar is a piece of blog production software, similar in style to (but
considerably more complex than) Rael Dornfest's "blosxom". The main
difference is extensibility, in terms of data collection and output
formatting. For instance, data can be acquired via DBD from a database,
or from the filesystem, or from any other source you can think of;
documents can be specified in HTML, or some other format which gets
turned into HTML; pages can be rendered with Template Toolkit,
HTML::Template, or any other template engine of your choice.

=head1 INSTALLING BRYAR

The short answer: run F<bryar-newblog> in a directory served by your
web server. Then do what it tells you.

The long answer:

The only front-end working in this release is the CGI one; please don't
try this in mod_perl yet.

You'll need to write a little driver script which sets some parameters.
For instance, my F<bryar.cgi> looks like this:

    #!/usr/bin/perl
    use Bryar;
    Bryar->go(
	 name => "Themes, Dreams and Crazy Schemes",
	 description => "Simon Cozens' weblog",
	 baseurl => "http://blog.simon-cozens.org/bryar.cgi"
    );

You can get away without any configuration options, but it's probably
wise to set something like the above up. Bryar will look in its current
directory for data files and templates, so if you're keeping your data
somewhere else, you'll want to set the F<datadir> option too:

    use Bryar;
    Bryar->go( datadir => "/home/simon/blog" );

If Bryar finds a file called F<bryar.conf> in the data directory,
(which as noted above, defaults to the current directory if not
specified explicitly) then it'll parse that as a colon-separated file
full of other options. I could, for instance, get away with

    name: Themes, Dreams and Crazy Schemes
    description: Simon Cozens' weblog
    baseurl: http://blog.simon-cozens.org/bryar.cgi
    email: something@example.com

in a F<bryar.conf>, and then would be able to use C<< Bryar->go() >>
with no further parameters.

For details of interesting parameters, look in L<Bryar::Config>.
See also L<Bryar::DataSource::DBI> for how to database-back the blog.

Now you will need some templates to make your new blog look nice and
shiny. You can copy in the F<template.rss> and F<template.html> which
come with Bryar, and edit those. The F<bryar-newblog> program which
comes with Bryar will set all this up for you. Look at
L<Bryar::Renderer::TT> for hints as to how to customize the
look-and-feel of the blog.

Once you're all up and running, (and your web server knows about
F<bryar.cgi>) then you can start blogging! Just dump F<.txt> files into
your data directory. If you used F<bryar-newblog>, you should even have
a sample blog entry there for you.

=head1 USING BRYAR

This section describes Bryar from the end-users point of view - that is,
what do all those URLs do? If you're familiar with blosxom, this section
should be a breeze.

    http://your.blog.com/

will return the most recent 20 posts. The default of 20 can be changed
by setting the C<recent> configuration option.

    http://your.blog.com/something

will try to find a sub-blog - in blosxom terms, this is a subdirectory
underneath the main data directory. Sub-blogs can have their own
templates, but by default inherit the templates from the main blog.

(Oh, and another thing - you can stick templates either in the
F<template> subdirectory or the main directory for your blog/sub-blog.
Bryar looks in both.)

If you want your main blog to contain things from sub-blogs, you can
change the value of the C<depth> option, which defaults to one - no
descent into subblogs.

You can also export your blog as RSS:

    http://your.blog.com/bryar.cgi/xml

And combine subblogging with RSS:

    http://your.blog.com/bryar.cgi/otherblog/xml

These are actually blosxom backwardly-compatible versions of the Bryar:

    http://your.blog.com/bryar.cgi?format=xml

There's also an Atom feed:

    http://your.blog.com/bryar.cgi?format=atom

And you can write your own formats; see the renderer class documentation for
how.

Each blog post will have a unique ID; you can get to an individual post
by specifying its ID:

    http://your.blog.com/bryar.cgi/id_1234

And finally you can retrieve blog entries for a specific period of time:

    http://your.blog.com/bryar.cgi/2003/May/    # All entries in May
    http://your.blog.com/bryar.cgi/2003/May/14/ # All entries on the 14th

Of course, you can combine all these components:

    http://your.blog.com/bryar.cgi/otherblog/2003/May/xml

=head1 METHODS

Now for the programmer's interface to Bryar.

=head2 new

    $self->new(%params)

Creates a new Bryar instance. You probably don't need to use this unless
you're programming your blog to do clever stuff. Use C<go> instead.

=cut

sub new {
    my $class = shift;
	my %args = (configclass => 'Bryar::Config', @_);
	eval "require $args{configclass}" or die $@;
    bless {
	config => $args{configclass}->new(@_)
    }, $class;
}

=head2 go

    $self->go()
    Bryar->go(%params)

Does all the work of producing the blog. For parameters you might be
interested in setting, see C<Bryar::Config>.

=cut

sub go {
    my $self = shift;
    if (not ref $self) {
	# We need to acquire a Bryar object.
	my %args = @_;

	# If we're running under mod_perl, then we want to check to see
	# if a datadir or config file has been specified.
	if (exists $ENV{GATEWAY_INTERFACE} and 
	    $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl\//) {
	    require Apache;
	    my $r = Apache->request;
	    my $x;
	    $args{datadir} = $x if $x = $r->dir_config("BryarDatadir");
	    $args{config}  = $x if $x = $r->dir_config("BryarConfig");
	}
	$self = Bryar->new(%args);
    }
    my $frontend = $self->config->frontend();
    $frontend->init($self->config) if $frontend->can("init");
    
	$self->_doit;
}

sub _doit {
    my $self = shift;
    my %args = $self->config->frontend->parse_args($self->config, @_);
    $self->{arguments} = \%args;

    # The HTTP headers must be reset to allow re-using the Bryar object
    # (e.g. when using FastCGI).
    $self->{http_headers} = { };

    my $cache = $self->config->cache;
    my ($cache_key, @output);

    # try to fetch a complete formatted answer from the cache, if one exists
    if ($cache) {
        $cache_key = $self->cache_key;
        my $object = $cache->get($cache_key);
        @output = @$object if $object;
    }

    # if there is no cached answer we need to collect the data and generate one
    if (not @output) {
        my @documents = $self->config->collector->collect($self->config, %args);

        my $last_modified = 0;
        if (@documents) {
            $last_modified = List::Util::max(map { $_->{epoch} } @documents);
        } else {
            $self->{http_headers}->{Status} = '404 Not Found';
        }

        $args{format} ||= 'html';

        @output = (
            $self->config->renderer->generate(
                $self->{arguments}{format},
                $self,
                @documents
            ),
            $last_modified,
            $self->{http_headers}
        );

        $cache->set($cache_key, \@output) if $cache;
    }

    $self->config->frontend->output(@output);
}

# create the key used to index the cache
sub cache_key {
    my $self = shift;

    return 'Bryar: ' . join(' | ', map {
        $_ . ' => ' . $self->{arguments}->{$_}
    } sort keys %{$self->{arguments}});
}

=head2 posts_calendar

TODO:  Move this out to something that is more flexible.

Return a data structure containing the days and weeks of a given month and
year with blog posts attached. See the C<calendar> template for an example.

=cut

sub posts_calendar {
	my ($self, $month, $year) = @_;

    my $today = DateTime->today( time_zone => $self->config->{time_zone} );

	$month ||= $today->month(); 
	$year  ||= $today->year(); 

	my $this_month = DateTime->new( month => $month, year => $year,  time_zone => $self->config->{time_zone} );

	my @documents = $self->config->collector->collect(
		$self->config,
		since => $this_month->epoch()
	);

	# make an hash with keys the days with a post
	my %posts = map { DateTime->from_epoch( epoch => $_->{epoch},  time_zone => $self->config->{time_zone} )->day() => $_->{id} } @documents;

	my @m = calendar($month, $year);
	my @month;
	foreach my $week (@m) {
		my @weekdays;
		foreach my $day (@$week) {
			my $d = { day => $day };
			if ($day and exists $posts{$day}) {
				$d->{idlink} = $posts{$day};
				$d->{link} = "$year/" . $this_month->month_abbr() . "/$day";
			}
			push(@weekdays, $d);
		}

		# mark the first day of the week, if it exists
		$weekdays[0]{sunday} = 1 if defined $weekdays[0]{day};

		push(@month, \@weekdays);
	}

	return { year => $year, month => $month, monthname => $this_month->month_name(), calendar => \@month };
}

=head2 config

Returns the L<Bryar::Config|Bryar::Config> object for this blog. This is
useful as the blog object is passed into the templates by default.

=cut

sub config { return $_[0]->{config} }
sub arguments {return $_[0]->{arguments} }

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 THANKS

Steve Peters provided Atom support.
Marco d'Itri contributed the calendar, HTTP validators, caching, FastCGI,
sitemaps, non-ASCII charsets, bug fixes and optimizations.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@cpan.org>

some parts Copyright 2007 David Cantrell C<david@cantrell.org.uk>

some parts Copyright 2009 Marco d'Itri C<md@linux.it>

=cut

1;
