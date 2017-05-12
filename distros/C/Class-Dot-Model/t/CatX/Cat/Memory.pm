# $Id: Memory.pm 4 2007-09-13 10:16:35Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/t/CatX/Cat/Memory.pm $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
package CatX::Cat::Memory;

use strict;
use warnings;

use Class::Dot::Model::Table qw(:belongs_to);

Table           'memory';
Columns         qw(id cat content);
Primary_Key     'id';
Belongs_To      'cat'
    => 'CatX::Cat';

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
