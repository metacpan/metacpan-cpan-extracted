package Audio::DB::Factory;

use strict 'vars';
use Carp 'croak';
use vars '@ISA';

use Audio::DB::Util::Rearrange;

# Objects can either be created with a pre-fetched jasj reference
# or with an object id (like an album id).

sub new {
  my ($self,@p) = @_;
  my ($class,$data) = rearrange([qw/CLASS DATA/],@p);
  
  # Yuck - I need to transform the class (which is really a table name) into
  # a package name.  Stupidity reins supreme
  # THIS MIGHT BE DEPRECATED NOW BUT LEAVE IN PLACE SO THAT PEOPLE
  # can call the Factory with artist or artists.

  $class =~ s/s$//;
  my $package = "Audio::DB::DataTypes::" . ucfirst $class;

  my $this = bless {},$package;
  foreach (keys %$data) {
    $this->{$_} = $data->{$_}
  }
  return $this;
}


1;

