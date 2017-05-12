package Catmandu::Blacklight;

=head1 NAME

Catmandu::Blacklight - Catmandu modules for working with Blacklight catalogs

=head1 SYNOPSIS

  # From the command line
  $ catmandu convert Blacklight --url http://lib.ugent.be/catalog -q Schopenhauer
  
  # From Perl
  use Catmandu;

  my $importer = Catmandu->importer('Blacklight',
                      url => 'http://lib.ugent.be/catalog' , 
                      q   => 'Schopenhauer');

  $importer->each(sub {
	   my $item = shift;
	   print "%s %s\n", $item->{_id} , $item->{title}->[0];
  });

=cut

our $VERSION = '0.03';

=head1 MODULES

=over

=item * L<Catmandu::Importer::Blacklight>

=back

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Patrick Hochstenbach

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;