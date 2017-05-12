package Algorithm::NCS;

use 5.020002;
use strict;
use warnings;

use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Algorithm::NCS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    ncs	
    );

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Algorithm::NCS', $VERSION);

# Preloaded methods go here.

sub ncs{
    return 0 unless defined $_[0] and defined $_[1] and  $_[0] ne "" and  $_[1] ne "" ;
    return xs_ncs ([unpack('U*', $_[0])], [unpack('U*', $_[1])] );
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Algorithm::NCS - Fast Perl extension for sequence alignment.

=head1 SYNOPSIS

  use Algorithm::NCS;
  Algorthm::NCS::ncs("ABC", "ADC");

=head1 DESCRIPTION

Number of Common Substrings (NCS) - A model and algorithm 
for sequence alignment.
The change detection problem is aimed at identifying common and
different strings and usually has non-unique solutions.  The identification of the
best alignment is canonically based on finding a
longest common subsequence
(LCS) and is widely used for various purposes.  However, many recent version
control systems prefer alternative heuristic algorithms which not only are faster
but also usually produce better alignment than finding an
LCS.
http://psta.psiras.ru/read/psta2015_1_189-197.pdf
http://elib.sfu-kras.ru/bitstream/handle/2311/19864/Znamenskij.pdf?sequence=1
http://dl.acm.org/citation.cfm?id=2977230

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://psta.psiras.ru/read/psta2015_1_189-197.pdf
http://elib.sfu-kras.ru/bitstream/handle/2311/19864/Znamenskij.pdf?sequence=1
http://dl.acm.org/citation.cfm?id=2977230

=head1 AUTHOR

Vladislav Dyachenko, E<lt>ddb@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Vladislav Dyachenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
