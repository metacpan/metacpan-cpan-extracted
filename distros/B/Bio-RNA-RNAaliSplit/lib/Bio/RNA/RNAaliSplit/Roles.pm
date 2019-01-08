# -*-CPerl-*-
# Last changed Time-stamp: <2019-01-07 00:38:54 mtw>

package Bio::RNA::RNAaliSplit::Roles;

use version; our $VERSION = qv('0.09');
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
