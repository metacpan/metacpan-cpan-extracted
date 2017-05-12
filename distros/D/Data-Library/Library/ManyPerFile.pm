package Data::Library::ManyPerFile;
use base qw(Data::Library);

$VERSION = '0.2';

my @missing = __PACKAGE__->missing_methods;
die __PACKAGE__ . ' forgot to implement ' . join ', ', @missing 
  if @missing;

use Log::Channel;
{
    my $lblog = new Log::Channel;
    sub lblog { $lblog->(@_) }
}

=head1 NAME

Data::Library::ManyPerFile - multiple-queries-per-file
support class for Data

=head1 SYNOPSIS

Provides repository service to Data.  This package
supports SQL in template files, where each file contains one
or more query blocks.

=head1 DESCRIPTION

Format of queries in a template file is as follows:

queryname1:

[One or more SQL statements]

;;

Query name must start at beginning of line and end with a colon.
Terminate is a pair of semicolons on a line by itself.

When searching through the repository for a matching tag, the first
match will be used.  Conflicts are not detected.

ManyPerFile recognizes when a query file is changed, and will
instruct Data to reload the query from the file.

=head1 METHODS

=cut

require 5.004;
use strict;
use Carp;

my %parameters = (
		  "LIB"	=> ".",
		  "EXTENSION" => "data",
		 );

=item B<new>

  my $library = new Data::Library::ManyPerFile
		  ({ name => "value" ... });

Supported Library::ManyPerFile parameters:

  LIB         Search path for SQL files.  Defaults to [ "sql" ]

  EXTENSION   Filename extension for SQL files.  Defaults to ".sql"

=cut

sub new {
    my ($proto, $config) = @_;
    my $class = ref ($proto) || $proto;

    my $self  = $config || {};

    bless ($self, $class);

    $self->_init;

    return $self;
}


sub _init {
    my ($self) = shift;

    # verify input params and set defaults
    # dies on any unknown parameter
    # fills in the default for anything that is not provided

    foreach my $key (keys %$self) {
	if (!exists $parameters{$key}) {
	    croak "Undefined ", __PACKAGE__, " parameter $key";
	}
    }

    foreach my $key (keys %parameters) {
	$self->{$key} = $parameters{$key} unless defined $self->{$key};
    }

    if ($self->{LIB} && !ref $self->{LIB}) {
	$self->{LIB} = [ $self->{LIB} ];
    }
}


sub lookup {
    my ($self, $tag) = @_;

    lblog "LOOKUP $tag\n";

    if (! $self->_cache_valid($tag)) {
	return;
    }

    return $self->{TAGS}->{$tag}->{STMTS};
}


sub _cache_valid {
    my ($self, $tag) = @_;

    return unless defined $self->{TAGS}->{$tag};
    return unless defined $self->{TAGS}->{$tag}->{STMTS};

    return unless ($self->{TAGS}->{$tag}->{LOADTS}
		   >= (stat($self->{TAGS}->{$tag}->{FILE}))[9]);

    return 1;
}


sub find {
    my ($self, $tag) = @_;

    lblog "FIND $tag\n";

    my $data;
    my $thefile;
    foreach my $lib (@{$self->{LIB}}) {
	opendir (DIR, $lib) or croak "opendir $lib failed: $!";
	my @files = sort grep { /^[^\.]/ && /\.$self->{EXTENSION}$/ && -r "$lib/$_" } readdir(DIR);
	closedir (DIR);

	foreach my $file (@files) {
	    open (FILE, "$lib/$file") or croak "open $file failed: $!";
	    local $/ = undef;
	    my $body = <FILE>;
	    if ($body =~ /^$tag:/ms) {
		($data) = $body =~ /^$tag:\s*(.*?)\s*^;;/ms;
		$thefile = "$lib/$file";
	    }
	    close (FILE);
	    last if $data;
	}
	last if $data;
    }
    if (! $data) {
	# never found the tag in any file
	carp "Unable to find tag $tag";
	return;
    }

    lblog "FOUND $tag in $thefile\n";

    $self->{TAGS}->{$tag}->{FILE} = $thefile;
    $self->{TAGS}->{$tag}->{LOADTS} = (stat($self->{TAGS}->{$tag}->{FILE}))[9];

    return $data;
}


=item B<cache>

  $library->cache($tag, $data);

Caches statement handles for later fetching via lookup().

=cut

sub cache {
    my ($self, $tag, $data) = @_;

    lblog "CACHE $tag\n";

    $self->{TAGS}->{$tag}->{STMTS} = $data;
}


=item B<toc>

  my @array = $library->toc();

Search through the library and return a list of all available entries.
Does not import any of the items.

=cut

sub toc {
    my ($self) = @_;

    my %items;
    foreach my $lib (@{$self->{LIB}}) {
	opendir (DIR, $lib) or croak "opendir $lib failed: $!";
	my @files = sort grep { /^[^\.]/ && /\.$self->{EXTENSION}$/ && -r "$lib/$_" } readdir(DIR);
	closedir (DIR);

	foreach my $file (@files) {
	    open (FILE, "$lib/$file") or croak "open $file failed: $!";
	    local $/ = undef;
	    my $body = <FILE>;
	    close FILE;
	    foreach my $tag ($body =~ /^(\w+):/msg) {
		$items{$tag}++;
	    }
	}
    }

    return sort keys %items;
}


=item B<reset>

  $library->reset;

Erase all entries from the cache.

=cut

sub reset {
    my ($self) = @_;

    foreach my $tag (keys %$self) {
	delete $self->{TAGS};
    }
}


1;

=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2001 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
