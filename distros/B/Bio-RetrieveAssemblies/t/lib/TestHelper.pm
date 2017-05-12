package TestHelper;
use Moose::Role;
use Test::Most;
use Data::Dumper;
use File::Slurp::Tiny qw(read_file write_file read_lines);


sub mock_execute_script {
    my ( $script_name, $scripts_and_expected_files, $columns_to_exclude ) = @_;
    
    system('touch empty_file');
    
    open OLDOUT, '>&STDOUT';
    open OLDERR, '>&STDERR';
    eval("use $script_name ;");
    my $returned_values = 0;
    {
        local *STDOUT;
        open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
        local *STDERR;
        open STDERR, '>/dev/null' or warn "Can't open /dev/null: $!";

        for my $script_parameters ( sort keys %$scripts_and_expected_files ) {
            my $full_script = $script_parameters;
            my @input_args = split( " ", $full_script );

            my $cmd = "$script_name->new(args => \\\@input_args, script_name => '$script_name')->download;";
            eval($cmd); warn $@ if $@;
            
            # Check the file has been created
            ok(-e $scripts_and_expected_files->{$script_parameters}, "Expected file for command ".$script_parameters." exists: ".$scripts_and_expected_files->{$script_parameters});
            
            unlink($scripts_and_expected_files->{$script_parameters});
        }
        close STDOUT;
        close STDERR;
    }
  
    ## Restore stdout.
    open STDOUT, '>&OLDOUT' or die "Can't restore stdout: $!";
    open STDERR, '>&OLDERR' or die "Can't restore stderr: $!";
    
    # Avoid leaks by closing the independent copies.
    close OLDOUT or die "Can't close OLDOUT: $!";
    close OLDERR or die "Can't close OLDERR: $!";
    unlink('empty_file');
    return 1;
}



no Moose;
1;

