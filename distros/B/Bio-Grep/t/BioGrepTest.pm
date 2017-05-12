package BioGrepTest;

# base class for all tests

use English qw( -no_match_vars );
use File::Spec;
use BioGrepSkip;

use base 'ToolSet';

ToolSet->set_strict(1);
ToolSet->set_warnings(1);

ToolSet->export(
    'Data::Dumper' => undef,
    'English'      => '-no_match_vars',
    'Test::More'   => undef,
    'Bio::Perl'   => undef,
    'Bio::Grep'   => undef,
); 

our @EXPORT = qw(delete_files next_be register_backend_tests
number_backend_tests skip_backend_test current_backend_name);

our $backends;
our $current_be = -1;

sub delete_files {
    # delete everything in this directory, otherwise we fail the test
    foreach my $file ( <t/tmp/*> ) {
        my ( $filename ) = $file =~ m{\A t/tmp/ ([\d\w\.\-]+) \z}xms;
        warn $file if !defined $filename;
        unlink "t/tmp/$filename";
    }
    foreach my $file ( <t/data/*> ) {
        my ( $filename ) = $file =~ m{\A t/data/ ([\d\w\.\-]+) \z}xms;
        warn $file if !defined $filename;
        unlink "t/data/$filename";
    }
    foreach my $file ( <t/data2/*> ) {
        my ( $filename ) = $file =~ m{\A t/data2/ ([\d\w\.\-]+) \z}xms;
        warn $file if !defined $filename;
        unlink "t/data2/$filename";
    }
    return 1;
}        

sub register_backend_tests {
    $backends = shift;
    $current_be = -1;
    return;
}    

sub next_be {
    my @sbes = sort keys %$backends;
    $current_be++;
    if ($current_be <= $#sbes) {
        my $backendname = $sbes[$current_be];
        BioGrepSkip::set_path( ( map { lc($_) } keys %$backends ), 'needle');
        my $sbe = 1;
        if (BioGrepSkip::find_binary_in_path(lc($backendname)) ne '' ||
            $backendname eq 'RE') {
            $sbe = Bio::Grep->new($backendname);
            $sbe->settings->tmppath('t/tmp');
            $sbe->settings->datapath('t/data');
            mkdir("t/tmp");
            mkdir("t/data");
        }
        delete_files;
        return $sbe;
    }
    else {
        return 0;
    }    
}   

sub current_backend_name {
    my @sbes = sort keys %$backends;
        my $backendname = $sbes[$current_be];
}

sub number_backend_tests {
    my $number_tests = 0;

    for my $be (keys %$backends) {
        $number_tests += $backends->{$be};
    }
    return $number_tests;
}    

sub skip_backend_test {
    my $backendname = current_backend_name;
        if ( $backendname ne 'RE' && BioGrepSkip::find_binary_in_path( lc($backendname) ) eq '' ) {
            return ($backends->{$backendname},
                "$backendname not found in path");
        }    
        return (0,'');
}    

sub get_sorted_result_ids {
    my ( $sbe ) = @_;
    my @results;
    while (my $res = $sbe->next_res) {
        push @results, $res->sequence->id;
    }   
    @results = sort @results;
    return @results;
}    
1;
