package Bio::SCF::Arrays;

use strict;

require DynaLoader;
use constant WHAT => {
		      index     => 0,
		      A		=> 1,
		      C		=> 2,
		      G		=> 3,
		      T		=> 4,
		      bases	=> 5,
		      spare1    => 6,
		      spare2    => 7,
		      spare3    => 8,
		      sample_A  => 11,
		      sample_C  => 12,
		      sample_G  => 13,
		      sample_T  => 14
};

sub TIEARRAY {
  my $class = shift;
  my $scf_pointer = shift;
  my $what_str = shift;
  my $ret_val = {
		 scf_pointer => $scf_pointer,
		 what        => WHAT->{$what_str},
		};
  return bless $ret_val, $class;
}

sub FETCH {
  my ($self, $index) = @_;
  return Bio::SCF::get_at($self->{scf_pointer}, $index, $self->{what});
}

sub STORE {
  my ($self, $index, $value) = @_;
  if ( $self->{what} == WHAT->{bases} ){
    Bio::SCF::set_base_at($self->{scf_pointer}, $index, $self->{what}, $value);
  }else{
    Bio::SCF::set_at($self->{scf_pointer}, $index, $self->{what}, $value);
  }
}

sub FETCHSIZE {
  my $self = shift;
  my $field = $self->{what} >= WHAT->{sample_A} 
    ? Bio::SCF::HEADER_FIELDS()->{samples_length}
    : Bio::SCF::HEADER_FIELDS()->{bases_length};
  return Bio::SCF::get_from_header($self->{scf_pointer}, $field);
}

1;

__END__
