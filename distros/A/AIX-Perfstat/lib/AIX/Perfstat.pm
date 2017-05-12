#
#
# Copyright (C) 2006 by Richard Holden
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#######################################################################

package AIX::Perfstat;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04.1';

our @METHODS = qw( 
	cpu_total disk_total netinterface_total memory_total
	cpu_count disk_count netinterface_count
	cpu       disk       netinterface
);

require XSLoader;
XSLoader::load('AIX::Perfstat', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

AIX::Perfstat - Perl wrapper for C<perfstat()> functions.

=head1 SYNOPSIS

use AIX::Perfstat;

$cput = AIX::Perfstat::cpu_total();

$diskt = AIX::Perfstat::disk_total();

$netift = AIX::Perfstat::netinterface_total();

$memoryt = AIX::Perfstat::memory_total();

$num_cpus = AIX::Perfstat::cpu_count();

$num_disks = AIX::Perfstat::disk_count();

$num_netifs = AIX::Perfstat::netinterface_count();

$cpu_data = AIX::Perfstat::cpu(desired_number = 1, name = "");

$disk_data = AIX::Perfstat::disk(desired_number = 1, name = "");

$netif_data = AIX::Perfstat::netinterface(desired_number = 1, name = "");



=head1 DESCRIPTION

This Perl module lets you call all of the perfstat functions defined on
AIX 5.1 and returns system data in Perl data structures.

The C<AIX::Perfstat::cpu_total>, C<AIX::Perfstat::disk_total>,
C<AIX::Perfstat::netinterface_total>, and C<AIX::Perfstat::memory_total>
functions each return a hashref containing all of the respective C
structures.

The C<AIX::Perfstat::cpu_count>, C<AIX::Perfstat::disk_count>, and
C<AIX::Perfstat::netinterface_count> functions each return a count
of how many structures are available from the C<AIX::Perfstat::cpu>,
C<AIX::Perfstat::disk>, and C<AIX::Perfstat::netinterface> functions
respectively.

The C<AIX::Perfstat::cpu>, C<AIX::Perfstat::disk>, and 
C<AIX::Perfstat::netinterface> functions each take up to
two arguments and return a reference to an array of hashes. The
arguments specify the number of records to return, and the name
of the record to start with. These arguments are equivalent to the
C<desired_number> and C<name> parameters to the C<perfstat> functions.
Only valid data is returned (Example: If you call 
C<AIX::Perfstat::netinterface(5)> on a machine with only 2 network
interfaces, the returned array will only contain two entries.) When
these functions are called with a variable for the name parameter
the variable will be modified in place to contain the name of the next
available record, or "" if no more records are available.


=head2 EXPORT

None by default.



=head1 SEE ALSO

/usr/include/libperfstat.h



=head1 AUTHOR

Richard Holden, E<lt>aciddeath@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Richard Holden

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
