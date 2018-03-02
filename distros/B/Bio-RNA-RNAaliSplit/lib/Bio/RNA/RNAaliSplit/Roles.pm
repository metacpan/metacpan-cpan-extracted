# -*-CPerl-*-
# Last changed Time-stamp: <2018-02-28 18:08:23 mtw>

package Bio::RNA::RNAaliSplit::Roles;

use version; our $VERSION = qv('0.06');
use Moose::Util::TypeConstraints;
use Moose::Role;
use Path::Class::Dir;
use namespace::autoclean;

has 'dirnam' => ( # custom output dir name
		  is => 'rw',
		  isa => 'Path::Class::Dir',
		  predicate => 'has_dirnam',
		 );

1;
