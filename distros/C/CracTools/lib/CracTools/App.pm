use strict;
use warnings;
package CracTools::App;

{
  $CracTools::App::DIST = 'CracTools';
}
# ABSTRACT: CracTools App::Cmd
$CracTools::App::VERSION = '1.251';
use App::Cmd::Setup -app;

sub global_opt_spec {
  return (
    [ "help", "log additional output" ],
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::App - CracTools App::Cmd

=head1 VERSION

version 1.251

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
