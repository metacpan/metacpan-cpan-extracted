package Audio::DB::DataTypes::GenreList;

use strict 'vars';
use vars '@ISA';
use Audio::DB::Util::Rearrange;


sub new {
  my ($self,@p) = @_;
  my ($summary,$adaptor) = rearrange([qw/SUMMARY ADAPTOR/],@p);
  
  my $genrelist = bless { class=>'GenreList' },$self;
  $genrelist = $adaptor->fetch_all_genres($genrelist);
  return $genrelist;
}

1;
