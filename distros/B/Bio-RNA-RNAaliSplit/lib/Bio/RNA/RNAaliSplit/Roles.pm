# -*-CPerl-*-
# Last changed Time-stamp: <2017-05-28 16:58:05 mtw>

package Bio::RNA::RNAaliSplit::Roles;

use version; our $VERSION = qv('0.05');
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
