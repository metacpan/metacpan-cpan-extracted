#!/usr/bin/perl
use v5.16;
use strict;
use warnings;

package App::grepurl;

=encoding utf8

=head1 NAME

App::grepurl - print links in HTML

=head1 SYNOPSIS

	grepurl [-bdv] [-e extension[,extension] [-E extension[,extension]
		[-h host[,host]] [-H host[,host]] [-p regex] [-P regex]
		[-s scheme[,scheme]] [-s scheme[,scheme]] [-u URL]

=head1 DESCRIPTION

The grepurl program searches through the URL specified in the -u
switch and prints the URLs that satisfies the given set of options.
It applies the options roughly in order of which part of the URL
the option affects (scheme, host, path, extension).

So far, grepurl expects to search through HTML, although I want to add
other content types, especially plain text, RSS feeds, and so on.

=head1 OPTIONS

=over 4

=item -a

arrange (sort) links in ascending order

=item -A

arrange (sort) links in descending order

=item -b

turn relative URLs into absolute ones

=item -d

turn on debugging output

=item -e EXTENSION

select links with these extensions (comma separated)

=item -E EXTENSION

exclude links with these extensions (comma separated)

=item -h HOST

select links with these hosts (comma separated)

=item -H HOST

exclude links with these hosts (comma separated)

=item -p REGEX

select only paths that match this Perl regex

=item -P REGEX

exclude paths that match this Perl regex

=item -r REGEX

select only URLs that match this Perl regex (applies to entire URL)

=item -R REGEX

exclude URLs that match this Perl regex (applies to entire URL)

=item -s SCHEME

select only these schemes (comma separated)

=item -S SCHEME

exclude these schemes (comma separated)

=item -t FILE

extract URLs from plain text file (not implemented)

=item -u URL

extract URLs from URL (may be file://), expects HTML

=item -v

turn on verbose output

=item -1

print found URLs only once (print a unique list)

=back

=head2 Examples

=over 4

=item Print all the links

	grepurl -u http://www.example.com/

=item Print all the links, and resolve relative URLs

	grepurl -b -u http://www.example.com/

=item Print links with the edxtension .jpg

	grepurl -e jpg -u http://www.example.com/

=item Print links with the edxtension .jpg and .jpeg

	grepurl -e jpg,jpeg -u http://www.example.com/

=item Do not print links with the extension .cfm or .asp

	grepurl -E cfm,asp -u http://www.example.com/

=item Print only links to www.panix.com

	grepurl -h www.panix.com -u http://www.example.com/

=item Print only links to www.panix.com or www.perl.com

	grepurl -h www.panix.com,www.perl.com -u http://www.example.com/

=item Do not print links to www.microsoft.com

	grepurl -H www.microsoft.com -u http://www.example.com/

=item Print links with "perl" in the path

	grepurl -p perl -u http://www.example.com

=item Print links with "perl" or "pearl" in the path

	grepurl -p "pea?rl" -u http://www.example.com

=item Print links with "fred" or "barney" in the path

	grepurl -p "fred|barney" -u http://www.example.com

=item Do not print links with "SCO" in the path

	grepurl -P SCO -u http://www.example.com

=item Do not print links whose path matches "Micro.*"

	grepurl -P "Micro.*" -u http://www.example.com

=item Do not print links whose URL matches "Micro.*" anywhere

	grepurl -R "Micro.*" -u http://www.example.com

=item Print only web links

	grepurl -s http -u http://www.example.com/

=item Print ftp and gopher links

	grepurl -s ftp,gopher -u http://www.example.com/

=item Exclude ftp and gopher links

	grepurl -S ftp,gopher -u http://www.example.com/

=item Arrange the links in an ascending sort

	grepurl -a -u http://www.example.com/

=item Arrange the links in an descending sort

	grepurl -A -u http://www.example.com/

=item Arrange the links in an descending sort, and print unique URLs

	grepurl -A -1 -u http://www.example.com/

=back

=head1 TO DO

=over 4

=item Operate over an entire directory or website

=back

=head1 SEE ALSO

urifind by darren chamberlain E<lt>darren@cpan.orgE<gt>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/app-grepurl

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT

Copyright © 2004-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may use this program under the terms of the Artistic License 2.0.

=cut

use File::Basename;
use FindBin;
use Getopt::Std;
use Mojo::DOM;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw(dumper);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
our $VERSION = '1.013';

run(@ARGV) unless caller;

sub new {
	my $self = bless {}, $_[0];
	$self->init;
	$self;
	}

sub init {}

sub debug { warn join "\n", @_, '' }

sub run {
	my( $class, @args ) = @_;
	unless( @args ) {
		print "$FindBin::Script $VERSION\n";
		exit;
		}

	my %opts;
	{
	local @ARGV = @args;
	getopts( 'bdv1' . 'aAiIjJ' . 'e:E:f:h:H:p:P:s:S:t:u:', \%opts );
	}
#	print STDERR Dumper( \%opts ); use Data::Dumper;
#	print STDERR "Processed opts\n";

	my $obj = $class->new();
	$obj->{opts} = \%opts;

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	$obj->{Debug}         = $opts{d} || $ENV{GREPURL_DEBUG} || 0;
	{ no warnings 'redefine'; *debug = sub { 0 } unless $obj->{Debug} }

	$obj->{Verbose}       = $opts{v} || $ENV{GREPURL_VERBOSE} || 0;
	$obj->{Either}        = $obj->{Debug} || $obj->{Verbose} || 0;

	$obj->{Hosts}         = uncommify( $opts{h} );
	$obj->{No_hosts}      = uncommify( $opts{H} );

	$obj->{Schemes}       = uncommify( $opts{'s'} );
	$obj->{No_schemes}    = uncommify( $opts{S} );

	$obj->{Extensions}    = uncommify( $opts{e} );
	$obj->{No_extensions} = uncommify( $opts{E} );

	$obj->{Path}          = regex( $opts{p} );
	$obj->{No_path}       = regex( $opts{P} );

	$obj->{Regex}         = regex( $opts{r} );
	$obj->{No_regex}      = regex( $opts{R} );

	$obj->debug_summary if $obj->{Debug};

	debug( "Moving on\n" );

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	my $text = $obj->get_text;

	die "There is no text!\n" unless( defined $text && length $text > 0 );
	my $urls = $obj->extract_from_html( $text );
	debug( "Got URLs:\n" . dumper($urls) );

	@$urls = do {
		if( defined $opts{b} ) {
			my $base = Mojo::URL->new( $opts{b} );
			debug( "Base url is $base\n" );
			map { Mojo::URL->new( $_ )->base( $base )->to_abs } @$urls;
			}
		else {
			map { Mojo::URL->new( $_ ) } @$urls;
			}
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Filters
	#
	# To select things, only pass through those elements
	#
	# To not select things, pass through anything that does not match
	@$urls = map {
		my $s = eval { $_->scheme };
		defined $s ?
			exists $obj->{Schemes}{$s} ? $_ : ()
			:
			()
		} @$urls if defined $opts{'s'};

	@$urls = map {
		my $s = eval { $_->scheme };
		defined $s ?
			exists $obj->{No_schemes}{$s} ? () : $_
			:
			$_
		} @$urls if defined $opts{S};

	@$urls = map {
		my $h = eval { $_->host };
		defined $h ?
			exists $obj->{Hosts}{ $h } ? $_ : ()
			:
			()
		} @$urls if defined $opts{h};

	@$urls = map {
		my $h = eval { $_->host };
		defined $h ?
			exists $obj->{No_hosts}{ $h } ? () : $_
			:
			$_
		} @$urls if defined $opts{H};

	@$urls = map {
		my $p       = eval { $_->path };
		my( $file ) = basename( $p );
		my( $e )    = $file =~ /\.([^.]+)$/;
		$e ||= '';
		exists $obj->{Extensions}->{$e} ? $_ : ()
		} @$urls if defined $opts{e};

	@$urls = map {
		my $p       = eval { $_->path };
		my( $file ) = basename( $p );
		my( $e )    = $file =~ /\.([^.]+)$/;
		$e ||= '';
		exists $obj->{No_extensions}->{$e} ? () : $_
		} @$urls if defined $opts{E};

	@$urls = map {
		my $p = eval { $_->path } || ''; $p =~ m/$obj->{Path}/ ? $_ : ()
		} @$urls if defined $opts{p};

	@$urls = map {
		my $p = $_->path; $p =~ m/$obj->{No_path}/ ? () : $_
		} @$urls if defined $opts{P};

	@$urls = map {
		my $u = $_->abs; $u =~ m/$obj->{Regex}/ ? $_ : ()
		} @$urls if defined $opts{r};

	@$urls = map {
		my $u = $_->abs; $u =~ m/$obj->{No_regex}/ ? () : $_
		} @$urls if defined $opts{R};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Unique
	@$urls = do { my %u = map { $_, 1 } @$urls; keys %u } if defined $opts{1};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Sort
	@$urls = sort { $a cmp $b } @$urls if defined $opts{a};
	@$urls = sort { $b cmp $a } @$urls if defined $opts{A};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Sort
	$" = "\n";
	print "@$urls\n";
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub extract_from_html {
	my( $self, $text ) = @_;
	debug( "In extract_from_html" );

	require Mojo::DOM;

	my $dom = Mojo::DOM->new( $text );

	debug( "Made DOM" );
	my $links = [
		@{ $dom->find('a[href]')->map( attr => 'href' )->to_array },
		@{ $dom->find('img[src]')->map( attr => 'src' )->to_array },
		]
		;

	debug( "Found " . @$links . " links" );

	$links;
	}

sub get_text {
	my( $self ) = @_;
	my $opts = $self->{opts};

	if( defined $opts->{u} ) {
		my $url = Mojo::URL->new( $opts->{u} );
		die "Bad url [$opts->{u}]!\n" unless ref $url;
		if( $url->scheme ne 'file' ) {
			$self->read_from_url( $url );
			}
		else {
			( my $path = $url ) =~ s|\Afile://||;
			$self->read_from_text_file( $path );
			}
		}
	elsif( defined $opts->{t} ) {
		my $file = $opts->{t};
		die "Could not read file [$file]!\n" unless -r $file;
		$self->read_from_text_file( $file );
		}
	elsif( @ARGV > 0 ) {
		my $file = $opts->{t};
		die "Could not read file [$file]!\n" unless -r $file;
		$self->read_from_text_file( $file );
		}
	elsif( -t STDIN ) {
		read_from_stdin();
		}
	else {
		return;
		}
	}

sub read_from_url {
	my( $self, $url ) = @_;
	debug( "Reading from url" );

	my $data = Mojo::UserAgent->new->get( $url )->result->body;

	$data;
	}

sub read_from_text_file {
	my( $self, $file ) = @_;
	debug( "Reading from file <$file>" );

	my $data = do { local $/; open my($fh), $file; <$fh> };

	$data;
	}

sub read_from_stdin {
	my( $self ) = @_;
	print "Reading from standard input" if $self->{Either};

	my $data = do { local $/; <STDIN> };

	$data;
	}

sub regex {
	my( $self, $option ) = @_;

	return unless defined $option;

	my $regex = eval { qr/$option/ };

	$@ =~ s/at $FindBin::Script line \d+.*//;

	die "$FindBin::Script: $@" if $@;

	$regex;
	}

sub uncommify {
	my( $self, $option ) = @_;

	return {} unless defined $option;

	return { map { $_, 1 } split m/,/, $option };
	}

sub debug_summary {
	my( $self ) = @_;
	no warnings;

	local $" = "\n\t";

	my $opts = $self->{opts};

	debug( <<"DEBUG" );
Version:       $VERSION
Verbose:       $self->{Verbose}
Debug:         $self->{Debug}
Ascending:     $opts->{a}
Descending:    $opts->{A}
Unique:        $opts->{1}
Image:         $opts->{i}
Image(-):      $opts->{I}
Javascript:    $opts->{j}
Javascript(-): $opts->{j}
Hosts:         $opts->{h}
	@{ [ keys %{ $self->{Hosts} } ] }
Hosts(-):      $opts->{H}
	@{ [ keys %{ $self->{No_hosts} } ] }
Path:          $opts->{p}
	$self->{Path}
Path(-):       $opts->{P}
	$self->{No_path}
Regex:         $opts->{r}
	$self->{Regex}
Regex(-):      $opts->{R}
	$self->{No_regex}
Scheme:        $opts->{s}
	@{ [ keys %{ $self->{Schemes} } ] }
Scheme(-):     $opts->{S}
	@{ [ keys %{ $self->{No_schemes} } ] }
DEBUG
	}

1;
