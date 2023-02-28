package App::SeismicUnixGui::misc::write_LSU;

use Moose;
our $VERSION = '0.0.1';

my $on  = 'on';
my $off = 'off';
my $nu  = 'nu';
my ( @param, @values, @checkbutton_on_off );
my ( $i, $j, $k, $size, $ref_cfg );

my $files_LSU = {
    _note                => '',
    _outbound            => '',
    _ref_file            => '',
    _program_name        => '',
    _program_name_config => '',
    _Step                => '',

};

=head2 sub  sunix_params

  #print("self is $self prog name is $prog_name\n");

  #foreach  my $key (sort keys %$hash_ref){ 
  #   print("parameter $key is $hash_ref->{$key} \n\n");
  #}
    #print("param is $param[$k]\n");
    #print("values is $values[$k]\n");
   all chebutton values are turned on by default
   checkbutton_on_off options are only for the checkbuttons to be green
   or red
   sunix buttons ca n be either on or off

=cut

#sub sunix_params {
#  my ($self,$hash_ref) = @_;
#  my $prog_name  	= $hash_ref;
#  $ref_cfg 		= $read->defaults($prog_name);
#  $size 	  	= ((scalar @$ref_cfg) )/2;
#
#   for ($k=0,$i=0; $k < $size; $k++,$i=$i+2) {
#     $param[$k] 	= @$ref_cfg[$i];
#   $j 		=  $i + 1;
#     $values[$k] 	= @$ref_cfg[$j];
#     if($values[$k] eq $nu) {
#       $checkbutton_on_off[$k]     = $off;
#     }
#     else {
#       $checkbutton_on_off[$k]      = $on;
#     }
#   }
#  return(\@param,\@values,\@checkbutton_on_off);
#}

=head2 sub

=cut

sub sizes {
    $size = ( ( scalar @$ref_cfg ) ) / 2;
    return ($size);
}

=head2 sub tool_specs 

  Output parameters for superflows
  A Tool is also a superflow
  i/p $hash_ref to iobtain entry labels and
  values and paramters from widgets to build @CFG 

DB
  print("prog name $program_name\n");
  print(" save_button,save,configure,write_LSU,tool_specs $files_LSU->{_program_name_config}\n");
  print("save,superflow,write_LSU, key/value pairs:$CFG[$i], $CFG[$j]\n");
  #use Config::Simple;
  #my $cfg 		= Config::Simple(syntax=>'ini');
  #$cfg->write($files_LSU->{_program_name_config});   
  # print "@CFGpa\n";
     #$cfg->ram($CFG[$i] ,$CFG[$j]); 
	  #print "@CFG\n";

=cut

sub tool_specs {
    my ( $self, $hash_ref ) = @_;

    use App::SeismicUnixGui::misc::name;
    my $name = name->new();

    my $program_name = $hash_ref->{_prog_name};
    my $length;
    my @CFG;

    if ($program_name) {
        $files_LSU->{_program_name} = $program_name;
        $files_LSU->{_program_name_config} =
          $name->change_config($program_name);
        $length = scalar @{ $hash_ref->{_ref_values} };

        for ( my $i = 0, my $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {
            $CFG[$j] = @{ $hash_ref->{_ref_labels} }[$i];
            $CFG[ ( $j + 1 ) ] = @{ $hash_ref->{_ref_values} }[$i];
        }

   # print("write_LSU,tool_specs \nprog_name:${$files_LSU->{_program_name}}\n");
   # print("\n   prog_name_config: $files_LSU->{_program_name_config}\n");
   # print("  labels: @{$hash_ref->{_ref_labels}}\n");
   # print("  values: @{$hash_ref->{_ref_values}}\n");

        my $file = 'junk';
        open( OUT, ">$file" );

        printf OUT ("# ENVIRONMENT VARIABLES FOR THIS PROJECT\n");
        printf OUT (" # Notes:\n");
        printf OUT ("  # 1. Default DATE format is DAY MONTH YEAR\n");
        printf OUT ("  # 2. only change what lies between single\n");
        printf OUT ("  # inverted commas\n");
        printf OUT ("  # 3. the directory hierarchy is\n");
        printf OUT ("  # \$PROJECT_HOME/\$date/\$line\n");
        printf OUT ("  # Warning: Do not modify \$HOME\n");
        printf OUT ("  ");

        for ( my $i = 0, my $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {
            printf OUT ("   $CFG[$j] 			   = $CFG[($j+1)]\n");
        }
        close(OUT);

        return ();
    }
}

=head2 sub outbound

=cut 

sub outbound {

    my ( $self, $outbound ) = @_;

    $files_LSU->{_outbound} = $outbound;

}
1;
