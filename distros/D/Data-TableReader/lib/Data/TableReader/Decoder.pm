package Data::TableReader::Decoder;
use Moo 2;

# ABSTRACT: Base class for table decoders
our $VERSION = '0.022'; # VERSION


has file_handle      => ( is => 'ro', required => 1 );
has real_file_name   => ( is => 'rw' );
has client_file_name => ( is => 'rw' );
*file_name= *real_file_name; # back-compat

has _log             => ( is => 'ro', required => 1 );
*log= *_log; # back-compat, but deprecated since it doesn't match ->log on TableReader

sub BUILD {
	my ($self, $args)= @_;
	# Previous attribute name was 'file_name'
	$self->real_file_name($args->{file_name})
		if defined $args->{file_name} && !defined $self->real_file_name;
}

sub _first_sufficient_module {
	my ($name, $modules, $req_versions)= @_;
	require Module::Runtime;
	for my $mod (@$modules) {
		my ($pkg, $ver)= ref $mod eq 'ARRAY'? @$mod : ( $mod, 0 );
		next unless eval { Module::Runtime::use_module($pkg, $ver) };
		# Special case for Excel modules that use Archive::Zip and don't declare proper
		# version requirements for it:
		# https://github.com/MichaelDaum/spreadsheet-parsexlsx/pull/12
		if ($pkg =~ /XLSX/ && !eval { Module::Runtime::use_module('Archive::Zip', 1.34) }) {
			Carp::carp("Your version of Archive::Zip is not new enough to make use of $pkg");
			next;
		}
		return $pkg
	}
	require Carp;
	Carp::croak "No $name available (or of sufficient version); install one of: "
		.join(', ', map +(ref $_ eq 'ARRAY'? "$_->[0] >= $_->[1]" : $_), @$modules);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Decoder - Base class for table decoders

=head1 VERSION

version 0.022

=head1 DESCRIPTION

This is an abstract base class describing the API for decoders.

A decoder's job is to iterate table rows of a file containing tabular data.
If a file provides multiple tables of data (such as worksheets, or <TABLE>
tags) then the decode should also support the "next_dataset" method.

=head1 ATTRIBUTES

=head2 file_handle

This is what the iterator should parse.  Streams should work, but for best results use a
seekable file handle.

=head2 real_file_name

Indicates real filename of C<file_handle>, or C<undef> if that can't be determined.

=head2 client_file_name

Indicates a client-side file name which should be used in client-facing log messages.

=head1 METHODS

=head2 iterator

This must be implemented by the subclass, to return an instance of
L<Data::TableReader::Iterator>.  The iterator should return an arrayref each time it is called,
and accept one optional argument of a "slice" needed from the record.
All decoder iterators return arrayrefs, so the slice should be an arrayref of column indicies
equivalent to the perl syntax

  @row[@$slice]

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
