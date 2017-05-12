# BioPerl module for Bio::Community::Types
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Types - Data type definitions

=head1 DESCRIPTION

This module defines useful data types for use in Moose-based modules.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


package Bio::Community::Types;

use Moose;
use Moose::Util::TypeConstraints;
use Method::Signatures;
use namespace::autoclean;


# Numbers

subtype 'PositiveNum'
   => as 'Num'
   => where { $_ >= 0 }
   => message { _gen_err_msg('a positive number', $_) };


subtype 'StrictlyPositiveNum'
   => as 'PositiveNum'
   => where { $_ > 0 }
   => message { _gen_err_msg('a strictly positive number', $_) };


subtype 'PositiveInt'
   => as 'Int'
   => where { $_ >= 0 }
   => message { _gen_err_msg('a positive integer', $_) };


subtype 'StrictlyPositiveInt'
   => as 'PositiveInt'
   => where { $_ > 0 }
   => message { _gen_err_msg('a strictly positive integer', $_) };


# A Count should be a positive integer. Sometimes, however, we only have access
# to the relative abundance (a float), and use it as a proxy for a count.
subtype 'Count'
   => as 'PositiveNum';


# Number of ticks (at least three)
subtype 'NumTicks'
   => as 'PositiveNum'
   => where { $_ > 2 }
   => message { _gen_err_msg('an integer greater than two', $_) };


# Sort numerically
subtype 'NumericSort'
   => as enum( [ qw(-1 0 1) ] )
   => message { _gen_err_msg('0 (off), 1 (increasing) or -1 (decreasing)', $_) };


# Abundance representation
my @AbundanceRepr = qw(count absolute percentage fraction);
subtype 'AbundanceRepr'
   => as enum( \@AbundanceRepr )
   => message { _gen_err_msg(\@AbundanceRepr, $_) };


# Rank: a strictly positive integer
subtype 'AbundanceRank'
   => as 'StrictlyPositiveInt';


# Type of distance
my @DistanceType = qw(1-norm 2-norm euclidean p-norm infinity-norm hellinger
                      bray-curtis morisita-horn jaccard sorensen
                      shared permuted maxiphi unifrac);
subtype 'DistanceType'
   => as enum( \@DistanceType )
   => message { _gen_err_msg(\@DistanceType, $_) };


# Type of alpha diversity
my @AlphaType = qw(
   observed  menhinick   chao1  margalef   ace       jack1     jack2
   shannon_e brillouin_e hill_e mcintosh_e simpson_e buzas     heip  camargo
   shannon   brillouin   hill   mcintosh   simpson   simpson_r
   simpson_d berger
);
subtype 'AlphaType'
   => as enum( \@AlphaType )
   => message { _gen_err_msg(\@AlphaType, $_) };


# Type of gamma diversity
my @GammaType = ( qw(
      chao2 jack1_i jack2_i ice
   ), @AlphaType
);
subtype 'GammaType'
   => as enum( \@GammaType )
   => message { _gen_err_msg(\@GammaType, $_) };


# Type of transformation
my @TransformationType = qw(identity binary relative hellinger chord);
subtype 'TransformationType'
   => as enum( \@TransformationType )
   => message { _gen_err_msg(\@TransformationType, $_) };


# Type of accumulation curve
my @AccumulationType = qw(rarefaction collector);
subtype 'AccumulationType'
   => as enum( \@AccumulationType )
   => message { _gen_err_msg(\@AccumulationType, $_) };


# Type of spacing
my @SpacingType = qw(linear logarithmic);
subtype 'SpacingType'
   => as enum( \@SpacingType )
   => message { _gen_err_msg(\@SpacingType, $_) };


# Members identification method
my @IdentifyMembersByType = qw(id desc);
subtype 'IdentifyMembersByType'
   => as enum( \@IdentifyMembersByType )
   => message { _gen_err_msg(\@IdentifyMembersByType, $_) };


# Duplicates identification method
my @IdentifyDupsByType = qw(desc taxon);
subtype 'IdentifyDupsByType'
   => as enum( \@IdentifyDupsByType )
   => message { _gen_err_msg(\@IdentifyDupsByType, $_) };


# Weight assignment method: a number, 'average', 'median', 'taxonomy'
my @WeightAssignStr = qw(file_average community_average ancestor);
subtype 'WeightAssignStr'
   => as enum( \@WeightAssignStr )
   => message { _gen_err_msg(\@WeightAssignStr, $_) };
subtype 'WeightAssignType'
   => as 'WeightAssignStr | Num'
   => message { _gen_err_msg( ['a number', @WeightAssignStr], $_) };


# Biom matrix type
my @BiomMatrixType = qw(sparse dense);
subtype 'BiomMatrixType'
   => as enum( \@BiomMatrixType )
   => message { _gen_err_msg(\@BiomMatrixType, $_) };


# ID Conversion type
my @IdConversionType = qw(replace prepend append);
subtype 'IdConversionType'
   => as enum( \@IdConversionType )
   => message { _gen_err_msg(\@IdConversionType, $_) };


# A readable file
subtype 'ReadableFile'
   => as 'Str'
   => where { (-e $_) && (-r $_) }
   => message { _gen_err_msg([], $_) };

subtype 'ArrayRefOfReadableFiles'
   => as 'ArrayRef[ReadableFile]';


# A readable filehandle (and coercing it from a readable file)
subtype 'ReadableFileHandle'
   => as 'FileHandle';

coerce 'ReadableFileHandle'
   => from 'Str'
   => via { _read_file($_) };

subtype 'ArrayRefOfReadableFileHandles'
   => as 'ArrayRef[ReadableFileHandle]';

coerce 'ArrayRefOfReadableFileHandles'
   => from 'ArrayRefOfReadableFiles'
   => via { [ map { _read_file($_) } @{$_} ] };


func _read_file ($file) {
   open my $fh, '<', $file or die "Could not open file '$_': $!\n";
                   # $self->throw("Could not open file '$_': $!")
   return $fh;
}


func _gen_err_msg ($accepts, $got = '') {
   # Generate an error message. The input is:
   #  * an arrayref of the values accepted, or a string describing valid input
   #  * the value obtained instead of the
   my $accept_str;
   if (ref($accepts) eq 'ARRAY') {
      if (scalar @$accepts > 1) {
         $accept_str = join(', ', @$accepts[0 .. scalar @$accepts - 2]);
      }
      $accept_str = $accept_str.' or '.$accepts->[-1];
   } else {
      $accept_str = $accepts;
   }
   return "'$got' was given, but valid input can only be $accept_str";
}


__PACKAGE__->meta->make_immutable;

1;

