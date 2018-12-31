# -*-CPerl-*-
# Last changed Time-stamp: <2018-12-28 12:20:58 mtw>

package Bio::RNA::RNAaliSplit::Roles;

use version; our $VERSION = qv('0.07');
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
