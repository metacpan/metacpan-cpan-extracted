package Data::Format::Pretty::PHP;

use 5.010;
use strict;
use warnings;

use Data::Dump::PHP qw(dump_php);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

our $VERSION = '0.03'; # VERSION

sub content_type { "application/x-httpd-php-source" }

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};
    dump_php($data);
}

1;
# ABSTRACT: Pretty-print data structure as PHP code


=pod

=head1 NAME

Data::Format::Pretty::PHP - Pretty-print data structure as PHP code

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Data::Format::Pretty::PHP qw(format_pretty);
 print format_pretty($data);

Some example output:

=over 4

=item * format_pretty({a=>1, b=>2})

 array( "a" => 1, "b" => 2 )

=head1 DESCRIPTION

This module uses L<Data::Dump::PHP> to encode data as PHP code.

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure. Currently there are no known formatting
options.

=head1 SEE ALSO

L<Data::Format::Pretty>

L<Data::Format::Pretty::PHPSerialized>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


