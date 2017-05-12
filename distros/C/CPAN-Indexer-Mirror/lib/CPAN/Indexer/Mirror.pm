package CPAN::Indexer::Mirror;

=pod

=head1 NAME

CPAN::Indexer::Mirror - Creates the mirror.yml and mirror.json files

=head1 SYNOPSIS

  use CPAN::Indexer::Mirror ();
  
  CPAN::Indexer::Mirror->new(
      root => '/cpan/root/directory',
  )->run;

=head1 DESCRIPTION

This module is used to implement a small piece of functionality inside the
CPAN/PAUSE indexer which generates F<mirror.yml> and F<mirror.json>.

These files are used to allow CPAN clients (via the L<Mirror::YAML> or
L<Mirror::JSON> modules) to implement mirror validation and automated
selection.

=head1 METHODS

Anyone who needs to know more detail than the SYNOPSIS should read the
(fairly straight forward) code.

=cut

use 5.006;
use strict;
use File::Spec              ();
use File::Remove            ();
use YAML::Tiny              ();
use JSON                    ();
use URI                     ();
use URI::http               ();
use IO::AtomicFile          ();
use Parse::CPAN::MirroredBy ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}





#####################################################################
# Constructor and Accessor Methods

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply defaults
	$self->{name} ||= 'Comprehensive Perl Archive Network';
	$self->{master}  ||= 'http://www.cpan.org/';

	return $self;
}

sub root {
	$_[0]->{root};
}

sub name {
	$_[0]->{name};
}

sub master {
	$_[0]->{master};
}

sub timestamp {
	$_[0]->{timestamp} || $_[0]->now;
}

sub mirrored_by {
	File::Spec->catfile( $_[0]->root, 'MIRRORED.BY' );
}

sub mirror_yml {
	File::Spec->catfile( $_[0]->root, 'mirror.yml' );
}

sub mirror_json {
	File::Spec->catfile( $_[0]->root, 'mirror.json' );
}





#####################################################################
# Process Methods

sub run {
	my $self = ref $_[0] ? shift : shift->new(@_);

	# Always randomise the mirror order, to protect against
	# weak programmers on the other end scanning them in
	# sequential order.
	my @mirrors = sort { rand() <=> rand() }
                      $self->parser->parse_file( $self->mirrored_by );

	# Generate the data structure for the files
	my $data    = {
		version   => '1.0',
		name      => $self->name,
		master    => $self->master,
		timestamp => $self->timestamp,
		mirrors   => \@mirrors,
	};

	# Write the mirror.yml and mirror.json file.
	# Make sure the closes (and thus commits) are as close together
	# as we can possibly get them, minimising race conditions.
	SCOPE: {
		local $!;
		my $yaml_file = $self->mirror_yml;
		my $json_file = $self->mirror_json;
		my $yaml_fh   = IO::AtomicFile->open($yaml_file, "w")     or die "open: $!";
		my $json_fh   = IO::AtomicFile->open($json_file, "w")     or die "open: $!";
		$yaml_fh->print( YAML::Tiny::Dump($data) )           or die "print: $!";
		$json_fh->print(  JSON->new->pretty->encode($data) ) or die "print: $!";
		$yaml_fh->close                                      or die "close: $!";
		$json_fh->close                                      or die "close: $!";
	}

	return 1;
}

sub parser {
	my $parser = Parse::CPAN::MirroredBy->new;
	$parser->add_map(  sub { $_[0]->{dst_http} } );
	$parser->add_grep( sub {
		defined $_[0]
		and
		$_[0] =~ /\/$/
	} );
	$parser->add_map( sub { URI->new( $_[0], 'http' )->canonical->as_string } );
	return $parser;
}

sub now {
	my @t = gmtime time;
	return sprintf( "%04u-%02u-%02uT%02u:%02u:%02uZ",
		$t[5] + 1900,
		$t[4] + 1,
		$t[3],
		$t[2],
		$t[1],
		$t[0],
	);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Indexer-Mirror>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Parse::CPAN::Authors>, L<Parse::CPAN::Packages>,
L<Parse::CPAN::Modlist>, L<Parse::CPAN::Meta>,
L<Parse::CPAN::MirroredBy>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
