package BGPmon::CPM::PList;

use 5.010001;
use strict;
use warnings;
use base qw(BGPmon::CPM::DBObject);
use BGPmon::CPM::Prefix;

our $VERSION = '1.03';
 
__PACKAGE__->meta->setup
(
 table => 'lists',
 columns => [ qw(dbid name) ],
 pk_columns => 'dbid',
 unique_key => 'name',
 relationships =>
    [
      prefixes =>{
          type       => 'one to many',
          class      => 'BGPmon::CPM::Prefix',
          column_map => { dbid => 'list_dbid' },
        },
      ],

);
__PACKAGE__->meta->error_mode('return');

sub add_or_edit_prefixes{
  my $self = shift;
  my $data = shift;

  my $exists = 0;
  my $existing = undef;
  foreach my $ex_pref ($self->prefixes){
    if($ex_pref->prefix =~ /$data->{'prefix'}/){
      $exists = 1;
      $existing = $ex_pref;
      last;
    }
  }
  if($exists){
    $existing->edit($data); 
  }else{
    $self->add_prefixes($data);
  } 
}
 

# Preloaded methods go here.

1;
__END__

=head1 NAME

BGPmon::CPM::PList - Perl extension to represent a database entry for a prefix list

=head1 SYNOPSIS

  use BGPmon::CPM::PList;

=head1 DESCRIPTION


=head2 EXPORT

None by default.


=head1 SEE ALSO


=head1 AUTHOR

Cathie Olschanowsky, <lt>bgpmon@netsec.colostate.edu<gt>

=head1 COPYRIGHT AND LICENSE

=cut
