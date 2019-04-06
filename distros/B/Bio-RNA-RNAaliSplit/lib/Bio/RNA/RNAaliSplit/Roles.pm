# -*-CPerl-*-
# Last changed Time-stamp: <2019-04-05 22:36:35 mtw>

package Bio::RNA::RNAaliSplit::Roles;

use version; our $VERSION = qv('0.10');
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
