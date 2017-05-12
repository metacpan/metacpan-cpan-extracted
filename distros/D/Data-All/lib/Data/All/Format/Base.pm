package Data::All::Format::Base;

#   Base package for all format modules

#   $Id: Base.pm,v 1.1.1.1 2005/05/10 23:56:20 dmandelbaum Exp $

use strict;
use warnings;


use Data::All::Base;

use base 'Exporter';
our @EXPORT = qw(new internal attribute populate error init);

our $VERSION = 0.10;


sub init()
{
    my $self = shift;
    populate( $self => $_[0] );
    return $self;
}



1;

