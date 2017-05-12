package CPANDB::Author;

use 5.008;
use strict;
use CPANDB::Distribution ();

our $VERSION = '0.18';

sub distributions {
	CPANDB::Distribution->select('WHERE author = ?', $_[0]->author);
}

1;
