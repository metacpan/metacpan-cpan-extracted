package Bryar::Config;
use UNIVERSAL::require;
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.1';

=head1 NAME

Bryar::Config - A set of configuration settings for Bryar

=head1 SYNOPSIS

	Bryar::Config->new(...);
	Bryar::Config->load(...);

=head1 DESCRIPTION

This encapsulates a Bryar configuration. It can be used to load a new
configuration from a file, or provide a reasonable set of defaults.

=head1 METHODS

=head2 new

    Bryar::Config->new(...)

Creates a new Bryar configuration instance.

=cut

our %default_args = (
        source => "Bryar::DataSource::FlatFile",
        name => "My web log",
        description => "Put a better description here",
        baseurl =>  "",
        datadir => ".",
        email => 'someone@example.com',
        depth => 1,
        recent => 20,
        renderer => "Bryar::Renderer::TT",
        collector => "Bryar::Collector",
        frontend => ((exists $ENV{GATEWAY_INTERFACE} and 
                      $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl\//)
                    ? "Bryar::Frontend::Mod_perl"
                    : "Bryar::Frontend::CGI")
);

sub new {
    my $class = shift;
    my %args = (%default_args, @_); # This does need to happen in stages
    my $self = bless { %args, %_ }, $class;
    # Because setting datadir above may affect where the config file is.

    %args = (%args, $self->load($args{config} || "bryar.conf"));
    @{$self}{keys %args} = values %args;

    foreach my $module (qw(renderer source collector frontend)) {
        $self->$module->require or die $@;
        $self->$module($self->$module->new(config => $self))
            if $self->$module->can('new') or ref $self->$module;
    }

    return $self;
}

=head2 load

    $self->load($file)

Load the configuration file from somewhere and return the arguments as a
hash.

=cut

sub load {
    my ($self, $file) = @_;
    my %args;
    my $datadir = $self->{datadir};
    if (!-r $file) {
        if (-r "$datadir/$file") { $file = "$datadir/$file"; }
        else                     { return () }
    }
    open(my $config, '<:utf8', $file) or return ();
    while (<$config>) {
        chomp;
        next if /^#/ or /^$/;
        my ($k, $v) = split /\s*:\s*/, $_, 2;
        $args{$k} = $v;
    }
    close $config;
    return %args;
}

=head2 renderer

	$self->renderer();    # Get renderer
	$self->renderer(...); # Set renderer

The class used to render this blog; defaults to "Bryar::Renderer::TT", 
the Template Toolkit renderer.

=cut

sub renderer {
    my $self = shift;
    if (@_) { $self->{renderer} = shift };

    return $self->{renderer};
}


=head2 frontend

	$self->frontend();    # Get frontend
	$self->frontend(...); # Set frontend

The class used to handle input and output from the blog; defaults to
L<Bryar::Frontend::CGI> if run via the CGI, L<Bryar::Frontend::mod_perl>
from inside Apache.

=cut

sub frontend {
    my $self = shift;
    if (@_) { $self->{frontend} = shift };

    return $self->{frontend};
}

=head2 collector

	$self->collector();    # Get collector
	$self->collector(...); # Set collector

The class used to select which documents to output. You probably don't
want to mess with this.

=cut

sub collector {
    my $self = shift;
    if (@_) { $self->{collector} = shift };

    return $self->{collector};
}

=head2 source

	$self->source();    # Get source
	$self->source(...); # Set source

The class which finds the blog posts. Defaults to
C<Bryar::DataSource::FlatFile>, the blosxom-compatible data source.

=cut

sub source {
    my $self = shift;
    if (@_) { $self->{source} = shift };

    return $self->{source};
}


=head2 cache

	$self->cache();    # Get cache object
	$self->cache(new Cache::FileCache()); # Set cache object

An instance of a C<Cache::Cache> subclass which will be used to cache
the formatted pages.

=cut

sub cache {
    my $self = shift;
    if (@_) { $self->{cache} = shift };

    return $self->{cache};
}


=head2 datadir

	$self->datadir();    # Get datadir
	$self->datadir(...); # Set datadir

Where the templates (and in the case of the flat-file data source, the
blog posts) live.

=cut

sub datadir {
    my $self = shift;
    if (@_) { $self->{datadir} = shift};

    return $self->{datadir};
}


=head2 name

	$self->name();    # Get name

The name of this blog.

=cut

sub name {
    my $self = shift;
    return $self->{name};
}

=head2 description

	$self->description();    # Get description

A description for the blog.

=cut

sub description {
    my $self = shift;
    return $self->{description};
}


=head2 depth

	$self->depth();    # Get depth
	$self->depth(...); # Set depth

How far to recurse into sub-blogs. Default is 1, stay in the current
directory.

=cut

sub depth {
    my $self = shift;
    if (@_) { $self->{depth} = shift };

    return $self->{depth};
}

=head2 email

    $self->email();     # Get email

Get the owner's email address.  This is used for spam reporting.

=cut

sub email {
    my $self = shift;
    return $self->{email};
}

=head2 recent

    $self->recent();    # Get recent
    $self->recent(...); # Set recent

The number of entries to display if there are no other parameters given.
Defaults to 20 entries.

=cut

sub recent {
    my $self = shift;
    if (@_) { $self->{recent} = shift };

    return $self->{recent};
}

=head2 baseurl

	$self->baseurl();    # Get baseurl

The base URL of this blog. (Needed for setting up links to archived
posts, etc.)

=cut

sub baseurl {
    my $self = shift;
    return $self->{baseurl};
}


=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.


=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>

some parts Copyright 2007 David Cantrell C<david@cantrell.org.uk>


=cut

1;
