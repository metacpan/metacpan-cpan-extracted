#!/opt/perl5.10/bin/perl

use strict;
use warnings;
use 5.010;

use Business::DPD::DBIC;

my $sourcedir = $ARGV[0] || 'data';
die "sourcedir missing or does not exist!" unless -d $sourcedir;

Business::DPD::DBIC->import_data_into_sqlite({source=>$sourcedir});

__END__

=head1 NAME

import_dpd_data.pl

=head1 SYNOPSIS

  import_dpd_data.pl path/to/dir/containing/routedbfiles

=head1 DESCRIPTION

Import the current DPD route DB into an sqlite DB

=head1 AUTHOR

Thomas Klausner C<< domm@cpan.org >>

RevDev E<lt>we {at} revdev.atE<gt>

=head1 SEE ALSO

Business::DPD

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

