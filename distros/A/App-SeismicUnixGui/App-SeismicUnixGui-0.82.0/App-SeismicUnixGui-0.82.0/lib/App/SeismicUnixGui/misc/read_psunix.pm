package App::SeismicUnixGui::misc::read_psunix;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: read_psunix 
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017 

 DESCRIPTION  Parse perl scripts written by L_SU
     

 BASED ON:


=cut

=head2 USE

=head3 NOTES

=head4 Examples


=head2 CHANGES and their DATES 

 
=cut 

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::sunix_pl';

#use write_psunix;

my @file_in;
my @file_out;
my $i;
my $read_psunix = {

    _all_prog_versions_aref  => '',
    _all_prog_names_aref     => '',
    _good_prog_names_aref    => '',
    _good_prog_versions_aref => '',
    _labels_aref2            => '',
    _values_aref2            => '',
};

$file_in[0]  = 'Xamine.pl';
$file_out[0] = 'out.pl';

my $sunix_pl = sunix_pl->new();
$sunix_pl->set_file_in( \@file_in );
$sunix_pl->set_file_out( \@file_out );

=pod

 read perl file line by line
 $sunix_pl->get_good_sunix_names(); # always AFTER get_good_sunix_params
 
=cut

$sunix_pl->whole();
$sunix_pl->set_progs_start_with('clear');
$sunix_pl->set_progs_end_with('Step()');
$sunix_pl->set_num_progs();
$read_psunix->{_all_prog_names_aref}    = $sunix_pl->get_all_sunix_names();
$read_psunix->{_all_prog_versions_aref} = $sunix_pl->get_all_versions();

my $length = $sunix_pl->get_num_progs;

my $hash_ref = $sunix_pl->get_good_sunix_params();
$read_psunix->{_good_prog_names_aref}    = $sunix_pl->get_good_sunix_names();
$read_psunix->{_good_prog_versions_aref} = $sunix_pl->get_good_prog_versions();

print("main,all prog versions: @{$read_psunix->{_all_prog_versions_aref}}\n");
print("main,all program names: @{$read_psunix->{_all_prog_names_aref}}\n");
print("main, $length programs have been found in $file_in[0]\n");
print("main,good program names: @{$read_psunix->{_good_prog_names_aref}}\n");
print(
    "main,good program versions: @{$read_psunix->{_good_prog_versions_aref}}\n"
);

$read_psunix->{_labels_aref2} = $hash_ref->{_labels_aref2};
$read_psunix->{_values_aref2} = $hash_ref->{_values_aref2};

my $new_num_progs = sunix_pl->get_num_good_progs();
print("main,o/p num_progs: $new_num_progs\n");

for ( my $i = 0 ; $i < $new_num_progs ; $i++ ) {

    my $num_params         = scalar @{ @{ $read_psunix->{_values_aref2} }[$i] };
    my @good_prog_names    = @{ $read_psunix->{_good_prog_names_aref} };
    my $good_prog_name     = $good_prog_names[$i];
    my @good_prog_versions = @{ $read_psunix->{_good_prog_versions_aref} };
    my $good_prog_version  = $good_prog_versions[$i];

    print("main,good_prog_name: $good_prog_name\n");
    print("main,good_prog_version: $good_prog_version\n");

    for ( my $j = 0 ; $j < $num_params ; $j++ ) {

        my @labels = @{ @{ $read_psunix->{_labels_aref2} }[$i] };
        my @values = @{ @{ $read_psunix->{_values_aref2} }[$i] };
        my $label  = $labels[$j];
        my $value  = $values[$j];

        print("sunix_pl,get_good_sunix_params,label: $label\n");
        print("sunix_pl,get_good_sunix_params,value: $value\n");
    }
}

