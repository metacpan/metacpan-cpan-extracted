package Bio::DOOP::Util::Sort;

use strict;
use warnings;

=head1 NAME

Bio::DOOP::Util::Sort - Sort an array of arrays

=head1 VERSION

Version 0.3

=cut

our $VERSION = '0.3';

=head1 SYNOPSIS

  @result = $mofext->get_results;
  $sorting = Bio::DOOP::Util::Sort->new($db,\results);
  @sorted_result = $sorting->sort_by_column(1,"asc"); 

=head1 DESCRIPTION

This class can sort any type of array of arrays. It can be used to sort the
mofext or fuzznuc results, but can sort other data.

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 METHODS

=head2 new

Creates a Sort class from an array of arrays type data structure.

  $mofext_sort = Bio::DOOP::Util::Sort->new($db,\@mofext_result);

=cut

sub new {
   my $self                = {};
   my $dummy               = shift;
   my $db                  = shift;
   my $array               = shift;

   $self->{ARRAY}          = $array;
   $self->{DB}             = $db;

   bless $self;
   return($self);
}

=head2 sort_by_column

Sort a given array by column. (Warning, the first column is zero!)

Return type: sorted array of arrays

  @ret = $mofext_sort->sort_by_column(0,"asc");

=cut

sub sort_by_column {
   my $self                = shift;
   my $column              = shift;
   my $orient              = shift;
   my @ret;
   
   if( ($orient eq "1") || ($orient eq "asc") || ($orient eq "ascending")){
       @ret = sort { $$a[$column] <=> $$b[$column] } @{$self->{ARRAY}};
   }
   else{
       @ret = sort { $$b[$column] <=> $$a[$column] } @{$self->{ARRAY}};
   }

   
}
1;
