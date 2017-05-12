use 5.012; #package NAME VERSION
package Data::CompactDump 0.04;
# ABSTRACT: Perl extension for dumping xD structures in compact form
$Data::CompactDump::VERSION = '0.04';

use strict;
use base 'Exporter';

our @EXPORT = qw(compact);


sub compact {
        unless (defined (my $q = shift)) {
                return 'undef';
	} elsif (not ref $q) {
		if ($q =~ /^\d+$/) {
			return $q;
		} else {
			$q =~ s/\n/\\n/g;  $q =~ s/\r/\\r/g;  $q =~ s/'/\\'/g;
                	return "\'" . $q . "\'";
		}
        } elsif ((my $rr = ref $q) eq 'ARRAY') {
                return '[ ' . join(', ',map { compact($_); } @$q) . ' ]';  
        } elsif ($rr eq 'SCALAR') {   
                return '\\' . compact($$q);       
        } elsif ($rr eq 'HASH') {
                return  '{ ' . join(', ',map { $_ . ' => ' . compact($$q{$_}); }
				keys %$q) . ' }';
        } else { return '\?'; }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::CompactDump - Perl extension for dumping xD structures in compact form

=head1 VERSION

version 0.04

=head1 SYNOPSIS

	use Data::CompactDump qw/compact/;

	my $xd_structure = [ [ 1, 2 ], [ 3, [ 4, 5 ] ] ];
	my $dump = compact( $xd_structure );

=head1 DESCRIPTION

Module provides some functions for dumping xD structures (like L<Data::Dump> or
L<Data::Dumper>) but in compact form.

=head1 FUNCTIONS

=head2 compact( xD )

Make eval-compatible form of xD structure for saving and restoring data
(compact form)

	my $xd_structure = [ [ 1, 2 ], [ 3, [ 4, 5 ] ] ];
	my $dump = compact($xd_structure);

=head1 SEE ALSO

L<Data::Dump>
L<Data::Dumper>

=head1 AUTHOR

Milan Sorm <sorm@is4u.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Milan Sorm.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
