package Data::ULID::XS;
$Data::ULID::XS::VERSION = '0.005';
use strict;
use warnings;

use Exporter qw(import);
use Data::ULID qw(:all);

use Time::HiRes qw();
use Crypt::PRNG qw();

our @EXPORT = @Data::ULID::EXPORT;
our @EXPORT_OK = @Data::ULID::EXPORT_OK;
our %EXPORT_TAGS = %Data::ULID::EXPORT_TAGS;

our $RNG = Crypt::PRNG->new('Sober128');

require XSLoader;
XSLoader::load('Data::ULID::XS', $Data::ULID::XS::VERSION);

1;
__END__

=head1 NAME

Data::ULID::XS - XS backend for ULID generation

=head1 SYNOPSIS

  use Data::ULID::XS qw(ulid binary_ulid);

  # use like Data::ULID

=head1 DESCRIPTION

This module replaces some parts of L<Data::ULID> that are performance-critical
with XS counterparts. Its interface is the same as Data::ULID, but you get free
XS speedups.

B<Beta quality>: while this module works well in general cases, it may also
contain errors common to C code like memory leaks or access violations. Please
do report if you encounter any problems.

=head1 FUNCTIONS

Same as L<Data::ULID>. All functions should work exactly the same, but C<ulid>
and C<binary_ulid> called with no arguments are reimplemented in XS.

=head1 BENCHMARK

Comparing speeds of Perl and XS implementations:

	                                 Rate Data::ULID::ulid Data::ULID::binary_ulid Data::ULID::XS::ulid Data::ULID::XS::binary_ulid
	Data::ULID::ulid              97342/s               --                    -68%                 -88%                        -91%
	Data::ULID::binary_ulid      301501/s             210%                      --                 -62%                        -71%
	Data::ULID::XS::ulid         793885/s             716%                    163%                   --                        -24%
	Data::ULID::XS::binary_ulid 1043509/s             972%                    246%                  31%                          --

Benchmark ran on Thinkpad T480 (i7-8650U) and FreeBSD 12.3.

=head1 SEE ALSO

L<Data::ULID>

L<Types::ULID>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

