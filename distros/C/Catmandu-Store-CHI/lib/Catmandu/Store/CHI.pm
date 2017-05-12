=head1 NAME

Catmandu::Store::CHI - a CHI backed caching store

=head1 SYNOPSIS

   # From the command line
   $ catmandu export CHI --driver File --root_dir /data to YAML
   $ catmandu import JSON to CHI --driver File --root_dir /data < data.json

   # From perl
   use Catmandu;

   my $store = Catmandu->store('CHI', driver => 'File' , root_dir => '/data');

   $store->bag->each(sub {
        my $item = shift;
        ...
   });

   $store->bag->add({ test => 123 });

=head1 METHODS

=head2 new()

=head2 new(driver => $chi_driver, [OPT => VAL, OPT2 => VAL])

Create a new Catmandu::Store::CHI with a $chi_driver and optional parameters. When no driver is given
then by default the 'Memory' driver will be used. See L<CHI> for more documentation on possible drivers.

=head2 bag($name)
 
Create or retieve a bag with name $name. Returns a L<Catmandu::Bag>.

=head1 SEE ALSO

L<CHI>, L<Catmandu> , L<Catmandu::Store> , L<Catmandu::Bag>

=head1 AUTHOR
 
Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>
 
=head1 LICENSE AND COPYRIGHT
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.
 
=cut
package Catmandu::Store::CHI;

{
  $Catmandu::Store::CHI::VERSION = '0.02';
}

use Moo;
use CHI;
use Catmandu::Store::CHI::Bag;

with 'Catmandu::Store';

has 'driver' => (is => 'ro' , required => 1 , default => sub { 'Memory' });
has 'opts'   => (is => 'rw');

sub BUILD {
    my ($self,$opts) = @_;

    if (keys %$opts == 0) {
        $opts->{global} = 1;
    }

    delete $opts->{driver};

    $self->opts($opts);
}

1; 
