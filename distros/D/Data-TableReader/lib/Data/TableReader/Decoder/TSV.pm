package Data::TableReader::Decoder::TSV;
use Moo 2;
use Try::Tiny;
use Carp;
use Log::Any '$log';

# ABSTRACT: Access rows of a tab-delimited text file
our $VERSION = '0.011'; # VERSION


extends 'Data::TableReader::Decoder::CSV';

sub _build_parser {
	my $args= shift->_parser_args || {};
	Data::TableReader::Decoder::CSV->default_csv_module->new({
		binary => 1,
		allow_loose_quotes => 1,
		auto_diag => 2,
		sep_char => "\t",
		escape_char => undef,
		%$args,
	});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Decoder::TSV - Access rows of a tab-delimited text file

=head1 VERSION

version 0.011

=head1 DESCRIPTION

This module is a simple subclass of L<Data::TableReader::Decoder::CSV>
which supplies these defaults for the parser:

  parser => { 
    binary => 1,
    allow_loose_quotes => 1,
    sep_char => "\t",
    escape_char => undef,
    auto_diag => 2,
  }

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
