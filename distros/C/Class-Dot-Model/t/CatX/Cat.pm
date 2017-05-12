# $Id: Cat.pm 4 2007-09-13 10:16:35Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/t/CatX/Cat.pm $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
package CatX::Cat;

use strict;
use warnings;

use Class::Dot::Model::Table qw(:has_many);

Table       'cats';
Columns     qw( id gender dna action colour );
Primary_Key 'id';
Has_Many    'memories'
    => 'CatX::Cat::Memory';

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
