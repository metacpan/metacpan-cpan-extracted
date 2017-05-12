package CPAN::Metrics;

=pod

=head1 NAME

CPAN::Metrics - Create and maintain a Perl::Metrics database for all of CPAN

=head1 SYNOPSIS

  # Do a CPAN::Metrics run
  my $metrics = CPAN::Metrics->new(
      remote  => 'http://mirrors.kernel.org/cpan/',
      local   => '/home/adam/.minicpan',
      extract => '/home/adam/.cpanmetrics',
      metrics => '/home/adam/.cpanmetrics/metrics.sqlite',
  )->run;

=head1 DESCRIPTION

C<CPAN::Metrics> is a combination of L<CPAN::Mini> and L<Perl::Metrics>.

It lets you pull out all of CPAN (for various definitions of "all") and
run L<Perl::Metrics> on it to generate massive amounts of metrics data
on the 16,000,000 lines of code in CPAN.

=head2 Resource Usage

While it might make it relatively easy to write the B<code> to "process
all of CPAN", make no mistake that it's going to take you LOT of
computing resources to do it. And especially so the first time.

To do a single run should require 1-10 gigabytes of disk space, up to
several hundred megabytes of memory, and hours (or days) of CPU time.

The result will be a SQLite database containing somewhere between several
hundred thousand and several million rows of metrics data.

What you do with the metrics after B<that> is up to you.

=head1 METHODS

=cut

use 5.005;
use strict;
use base 'CPAN::Mini::Extract';
use Carp 'croak';
use Perl::Metrics ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.08';
}





#####################################################################
# Constructor

=pod

=head1 new

The C<new> constructor creates a new CPAN metrics processor.

Although it is created as an object, due to L<Perl::Metrics> you can
only create a single object within a single process. (I think)

It takes a variety of different parameters.

=over

=item minicpan arguments

=back

Returns a new C<CPAN::Metrics> object, or dies on error.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	# Call up to get the base object
	my $self = $class->SUPER::new(
		force          => 1,
		skip_perl      => 1,
		extract_check  => 1,
		path_filters   => [
			qr/\bAcme\b/i,
			qr/\bPDF\-API2\b/i,
			qr/\bPerl6\b/i,
			],
		# Remove some known troublemakers
		module_filters => [
			qr/^Acme::/i,
			qr/^Meta::/i,
			qr/\bPerl6\b/i,
			],
	        extract_filter =>
	        	sub {
				return 0 if /\:/;
	        		return 0 if /\binc\b/;
	        		return 1 if /\.pl$/;
				return 0 if /\bexamples?\b/;
	        		if ( /\bt\b/ ) {
		        		return 1 if /\.t$/;
	        		} else {
		        		return 1 if /\.pm$/;
	        		}
	        		return 0;
	        	},
		@_,
		);

	# Check and set the metrics database
	unless ( $self->{metrics} ) {
		croak("Metrics database param 'metrics' was not provided");
	}
	Perl::Metrics->import( $self->{metrics} );

	$self;
}

=pod

=head2 run

The C<run> method launches the CPAN metrics processor. It will
syncronize its L<minicpan> mirror from the remote server, expanding
any new archives, and removing old ones. Once updated, the directory
will be reindexed at update it in the metricsdatabase, and any required
processing done to add the resulting metrics needed.

And then (a C<very> long time later) it will stop. :)

Oh, and return true. Any errors will cause an exception (i.e. die)

=cut

sub run {
	my $self = shift;
	$self->SUPER::run( @_ );
	$self->process_index;
}

sub process_index {
	my $self = shift;

	# Process the extraction directory
	local $Perl::Metrics::TRACE = 1;
	$self->trace("Indexing and processing documents in $self->{extract}...\n");
	Perl::Metrics->process_index( $self->{extract} );

	return 1;
}

1;

=pod

=head1 TO DO

- Improve Perl::Metrics to add needed things

- Improve CPAN::Metrics::Extract to add needed things

- Improve CPAN::Metrics to add needed things

- Get all three of the above to use accessors

- Possibly consider intentionally B<disabling> caching so that
we don't end up with a multi-multi-gigabyte parse cache.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Metrics>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
