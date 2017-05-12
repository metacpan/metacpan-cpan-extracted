package Catalyst::Model::Oryx;

use strict;
use base qw(Catalyst::Base Oryx);
use Oryx;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Model::Oryx - Oryx model component for Catalyst

=head1 SYNOPSIS

 # with the helper
 script/create.pl model Oryx Oryx

 # define your storage class by hand
 package CMS::M::Oryx;
  
 use base qw(Catalyst::Model::Oryx);
  
 __PACKAGE__->config(
    dsname => 'dbi:Pg:dbname=mydb',
    usname => 'jrandom'
    passwd => '70p53cr37'
 );
  
 1;
  
 # define a persistent class
 package CMS::M::Document;
  
 use base qw(Oryx::Class);
  
 our $schema = {
     attributes => [{
         name => 'author',
         type => 'String',
     }],
     associations => [{
         role => 'paragraphs',
         type => 'Array',
     }]
 };
  
 1;
 
 # use your persistent class
 use CMS::M::Document (auto_deploy => 1); # create tables as needed
 
 $doc = CMS::M::Document->create({
     author  => 'Some Clever Guy',
 });
  

=head1 DESCRIPTION

This module implements an L<Oryx> object persistence model component for the 
L<Catalyst> application framework.
See L<Oryx> and L<Oryx::Class> for details on how to use L<Oryx>.

=head1 METHODS

=over

=item new

Constructor and calls the C<connect> method which it inherits from L<Oryx>.
If you've used the helper script to install the Oryx model, then L<DBM::Deep>
will be used by default with the C<datapath> set to '/tmp' - this can be
useful for easily testing your persistent objects without the need to do
any RDBMS setup.

=back

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_);

    $self->connect([
        $self->{dsname},
        $self->{usname},
        $self->{passwd},
    ]);

    return $self;
}

1;

=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 SEE ALSO

L<Catalyst>, L<Oryx>

=head1 LICENCE

This module is free software and may be used under the same terms
as Perl itself.

=cut
