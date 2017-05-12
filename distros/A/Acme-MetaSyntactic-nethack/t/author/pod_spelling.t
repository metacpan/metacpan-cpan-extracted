#!perl

# Taken from http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

use strict;
use warnings;

use Test::More;
use Test::Spelling;

set_spell_cmd('aspell -l en list');
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
=cut

# setup nethack: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup nethack: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup nethack: set foldmethod=indent foldlevel=0 :
