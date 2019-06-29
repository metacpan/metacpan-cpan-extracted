package Data::TableReader::Decoder;
use Moo 2;

# ABSTRACT: Base class for table decoders
our $VERSION = '0.011'; # VERSION


has file_name   => ( is => 'ro', required => 1 );
has file_handle => ( is => 'ro', required => 1 );
has _log        => ( is => 'ro', required => 1 );
*log= *_log; # back-compat, but deprecated since it doesn't match ->log on TableReader

sub _first_sufficient_module {
	my ($name, $modules, $req_versions)= @_;
	require Module::Runtime;
	for my $mod (@$modules) {
		my ($pkg, $ver)= ref $mod eq 'ARRAY'? @$mod : ( $mod, 0 );
		return $pkg if eval { Module::Runtime::use_module($pkg, $ver) };
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

version 0.011

=head1 DESCRIPTION

This is an abstract base class describing the API for decoders.

A decoder's job is to iterate table rows of a file containing tabular data.
If a file provides multiple tables of data (such as worksheets, or <TABLE>
tags) then the decode should also support the "next_dataset" method.

=head1 ATTRIBUTES

=head2 filename

Set by TableReader.  Useful for logging.

=head2 file_handle

Set by TableReader.  This is what the iterator should parse.

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

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
