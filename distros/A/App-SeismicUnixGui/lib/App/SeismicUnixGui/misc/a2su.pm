package App::SeismicUnixGui::misc::a2su;

=head2 SYNOPSIS

PERL PACKAGE NAME: a2su.pm

AUTHOR: Juan Lornzo (for Perl)

DATE: Sat Nov  4 14:28:52 2023 

DESCRIPTION:

Built using Version: SeismicUnixGui V0.85.5 


=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.01';

use App::SeismicUnixGui::misc::SeismicUnix qw($bin $go $in 
$su $suffix_bin $suffix_segd $suffix_segy 
$suffix_su $suffix_segd $suffix_txt $suffix_bin $to $out $txt );

use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::par::a2b';
use aliased 'App::SeismicUnixGui::sunix::data::data_in';
use aliased 'App::SeismicUnixGui::sunix::data::data_out';
use aliased 'App::SeismicUnixGui::sunix::header::suaddhead';
use aliased 'App::SeismicUnixGui::sunix::header::sushw';

my $manage_files_by2 = manage_files_by2->new();
my $log              = message->new();
my $run              = flow->new();
my $data_in          = data_in->new();
my $a2b              = a2b->new();
my $data_out         = data_out->new();
my $suaddhead        = suaddhead->new();
my $sushw            = sushw->new();

=head2 Declare

	local variables

=cut

my (@flow);
my (@items);
my (@data_in);
my (@data_out);
my (@a2b);
my (@suaddhead);
my (@sushw);

my $fmt = '%10.6f';

=head2 Declare 

private hash

=cut

my $a2su = {
	  _path_in           => '',
	  _si_us             => '',
	  _base_file_name_in => '',
};

=head2 sub clear

private hash

delete $hash{$_} for (keys %hash)

=cut

sub clear {

	  $a2su->{_path_in}           = ''; 
	  $a2su->{_si_us}             = '';
	  $a2su->{_base_file_name_in} = '';

}

=head2 sub _set_pathNfile_in

=cut

sub _set_pathNfile_in {

	  my ($self) = @_;
	  if (    length $a2su->{_path_in}
		  and length $a2su->{_base_file_name_in} )
	  {

		  $a2su->{_pathNfile_in} =
			$a2su->{_path_in} . '/' . $a2su->{_base_file_name_in};

	  }
	  else {

		  print("a2su,_get_pathNfile_in,missing variables\n");
	}
}


sub _go {
	
	  my ($self) = @_;

	  my $base_file               = $a2su->{_base_file_name_in} . '_amp_only';
	  my $base_file_txt           = $a2su->{_base_file_name_in} . '_amp_only' . $suffix_txt;
	  my $pathNfile_base_file_txt_in = $a2su->{_pathNfile_in}.$suffix_txt;
	  my $pathNfile_base_file_txt_out = $a2su->{_pathNfile_in}.'_amp_only'.$suffix_txt;
	  	  
=head2 Convert

a two-column time-Amplitude text file 
into
a single-column Amplitude text file

=cut

	  $manage_files_by2->clear();
	  $manage_files_by2->set_pathNfile( $pathNfile_base_file_txt_in );
	  my ( $time_ref, $amplitude_ref, $num_rows ) =
		$manage_files_by2->read_2cols();
	  $manage_files_by2->write_1col_aref( $amplitude_ref, 
	  			\$pathNfile_base_file_txt_out, \$fmt );

=head2 Set up

	  data_in parameter values

=cut

	  $data_in->clear();
	  $data_in->base_file_name( quotemeta($base_file) );
	  $data_in->suffix_type( quotemeta($txt) );
	  $data_in[1] = $data_in->Step();

=head2 Set up

	data_in parameter values

=cut

	  $data_in->clear();
	  $data_in->base_file_name( quotemeta($base_file) );
	  $data_in->suffix_type( quotemeta($bin) );
	  $data_in[2] = $data_in->Step();

=head2 Set up

	data_out parameter values

=cut

	  $data_out->clear();
	  $data_out->base_file_name( quotemeta($base_file) );
	  $data_out->suffix_type( quotemeta($bin) );
	  $data_out[1] = $data_out->Step();

=head2 Set up

	data_out parameter values

=cut

	  $data_out->clear();
	  $data_out->base_file_name( quotemeta($base_file) );
	  $data_out->suffix_type( quotemeta($su) );
	  $data_out[2] = $data_out->Step();

=head2 Set up

	a2b parameter values

=cut

	  $a2b->clear();
	  $a2b->floats_per_line( quotemeta('1') );
	  $a2b->outpar('/dev/null');
	  $a2b[1] = $a2b->Step();

=head2 Set up

	suaddhead parameter values

=cut

	  $suaddhead->clear();
	  $suaddhead->ftn( quotemeta(0) );
	  $suaddhead->ns( quotemeta($num_rows) );
	  $suaddhead->ntrpr( quotemeta(1) );
	  $suaddhead->tsort( quotemeta(1) );
	  $suaddhead[1] = $suaddhead->Step();

=head2 Set up

	sushw parameter values

=cut

	  $sushw->clear();
	  $sushw->first_value( quotemeta( $a2su->{_si_us} ) );
	  $sushw->gather_size( quotemeta(0) );
	  $sushw->header_bias( quotemeta(0) );
	  $sushw->headerwords( quotemeta('dt') );
	  $sushw->intra_gather_inc( quotemeta(0) );
	  $sushw->inter_gather_inc( quotemeta(0) );
	  $sushw[1] = $sushw->Step();

=head2 DEFINE FLOW(s) 


=cut

	  @items = ( $a2b[1], $in, $data_in[1], $out, $data_out[1], $go );
	  $flow[1] = $run->modules( \@items );

	  @items = (
		  $suaddhead[1], $in,  $data_in[2],  $to,
		  $sushw[1],     $out, $data_out[2], $go
	  );
	  $flow[2] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

	  $run->flow( \$flow[1] );
	  $run->flow( \$flow[2] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

	  $log->screen( $flow[1] );
	  $log->screen( $flow[2] );
	  $log->time();

	  $log->file( $flow[1] );
	  $log->file( $flow[2] );

	  return ();

}

=head2 error check

=cut 

sub go {

	  my ($self) = @_;

	  if (    length $a2su->{_si_us}
		  and length $a2su->{_base_file_name_in}
		  and length $a2su->{_path_in} )
	  {

		  _set_pathNfile_in();
		  _go();

	  }
	  else {

		  print("a2su,go, missing variables\n");
	  }

	  return ();

}

=head2 sub set_base_file_name_in

=cut

sub set_base_file_name_in {

	  my ( $self, $file_name ) = @_;

	  if ( length($file_name) ) {

		  $a2su->{_base_file_name_in} = $file_name;

#		print("a2su, set_base_file_name_in, dir=$a2su->{_base_file_name_in} \n");

	  }
	  else {
		  print("a2su, set_base_file_name_in, missing value\n");
	  }

	  return ();
}

=head2 sub set_path_in

=cut

sub set_path_in {

	  my ( $self, $path_in ) = @_;

	  if ( length($path_in) ) {

		  $a2su->{_path_in} = $path_in;

	  #		print("a2su, set_path_in, dir=$a2su-->{_path_in} \n");

	  }
	  else {
		  print("a2su, set_path_in, missing value\n");
	  }

	  return ();
}

=head2 sub set_si_us

=cut

sub set_si_us {

	  my ( $self, $si_us ) = @_;

	  if ( length $si_us ) {

		  $a2su->{_si_us} = $si_us;

#	      print("a2su, set_si_us, si_us =$a2su->{_si_us} \n");

	  }
	  else {
		  print("a2su-, set_si_us, missing value\n");
	  }

	  return ();
}
1;
