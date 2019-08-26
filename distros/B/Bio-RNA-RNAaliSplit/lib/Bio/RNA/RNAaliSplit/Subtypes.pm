# -*-CPerl-*-
# Last changed Time-stamp: <2019-04-09 14:05:30 mtw>

package Bio::RNA::RNAaliSplit::Subtypes;

use Moose::Util::TypeConstraints;
use Bio::AlignIO;
use Params::Coerce;
use version; our $VERSION = qv('0.11');

subtype 'Bio::RNA::RNAaliSplit::AliIO' => as class_type('Bio::AlignIO');

coerce 'Bio::RNA::RNAaliSplit::AliIO'
    => from 'HashRef'
    => via { Bio::AlignIO->new( %{ $_ } ) };
