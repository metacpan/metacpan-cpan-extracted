package Data::Library::OnePerFile;
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

Data::Library::OnePerFile - one-item-per-file repository support class

=head1 SYNOPSIS

Provides a general repository service.  This package
supports source data in files, where each file contains a
single source item.  A tag corresponds to a filename
(tag.EXTENSION where EXTENSION is specified at initialization).
Searching will be done through a list of directories.
The first matching file will be used.
Conflicts are not detected.

OnePerFile recognizes when a source file is changed.

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

  my $library = new Data::Library::OnePerFile
		  ({ name => "value" ... });

Supported Library::OnePerFile parameters:

  LIB         Search path for data files.  Defaults to current directory.

  EXTENSION   Filename extension for data files.  Defaults to "data".

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


=item B<lookup>

  $library->lookup($tag);

Returns cached data items.  If the source has changed since
it was cached, returns false.

=cut

sub lookup {
    my ($self, $tag) = @_;

    lblog "LOOKUP $tag\n";

    if (! $self->_cache_valid($tag)) {
	return;
    }

    return $self->{TAGS}->{$tag}->{CACHE};
}


sub _cache_valid {
    my ($self, $tag) = @_;

    return unless defined $self->{TAGS}->{$tag};
    return unless defined $self->{TAGS}->{$tag}->{CACHE};

    return unless ($self->{TAGS}->{$tag}->{LOADTS}
		   >= (stat($self->{TAGS}->{$tag}->{FILE}))[9]);

    return 1;
}


=item B<find>

  $library->find($tag);

Searches through the directory path in LIB for a file named
"$tag.EXTENSION".  Returns the contents of that file if successful,
and records the path for subsequent checking by lookup().

=cut

sub find {
    my ($self, $tag) = @_;

    lblog "FIND $tag\n";

    my $file;
    foreach my $lib (@{$self->{LIB}}) {
	$file = "$lib/$tag.$self->{EXTENSION}";
	next unless -r $file;
    }
    if (! -r $file) {
	# never found a matching readable file
	carp "Unable to read $tag.$self->{EXTENSION}";
	return;
    }

    open(INPUT, $file) or croak "open $file failed: $!";
    local $/ = undef;
    my $data = <INPUT>;
    close INPUT;

    lblog "FOUND $tag in $file\n";

    $self->{TAGS}->{$tag}->{FILE} = $file;
    $self->{TAGS}->{$tag}->{LOADTS} = (stat($self->{TAGS}->{$tag}->{FILE}))[9];

    return $data;
}


=item B<cache>

  $library->cache($tag, $data);

Caches data by tag for later fetching via lookup().

=cut

sub cache {
    my ($self, $tag, $data) = @_;

    lblog "CACHE $tag\n";

    $self->{TAGS}->{$tag}->{CACHE} = $data;
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
	opendir DIR, $lib or die "open $lib failed: $!";
	foreach my $file (readdir DIR) {
	    next unless $file =~ /\.$self->{EXTENSION}$/;
	    $file =~ s/\.$self->{EXTENSION}$//;
	    $items{$file}++;
	}
	closedir DIR;
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

Copyright (C) 2001,2002 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
