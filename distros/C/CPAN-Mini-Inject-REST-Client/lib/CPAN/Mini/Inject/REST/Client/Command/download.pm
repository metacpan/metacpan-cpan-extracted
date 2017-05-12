package CPAN::Mini::Inject::REST::Client::Command::download;

use 5.010;
use strict;
use warnings;
use base 'CPAN::Mini::Inject::REST::Client::Command';
use File::Basename;


#--Command usage----------------------------------------------------------------

sub usage_desc {
    return "download %o <filename>";
}

sub abstract {
    return "Downloads a file from the repository";
}

sub description {
    return "Downloads a file from the repository";
}


#--Command specific options-----------------------------------------------------

sub options {
    my ($class, $app) = @_;
    
    return (
        [ "stdout" => "Output file to STDOUT" ]
    );
}


#--Validate args----------------------------------------------------------------

sub validate_args {
    my ($self, $opt, $args) = @_;
    
    $self->usage_error('Filename must be specified') unless @$args;
}


#--Command execute method-------------------------------------------------------

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $file      = shift @$args;
    my $base_file = basename($file);
    
    my ($code, $result) = $self->api($opt)->get("repository/$base_file");
    
    given ($code) {
        when (200) {
            if ($opt->stdout) {
                print $result;
            } else {
                open my $fh, '>', $file;
                print $fh $result;
                close $fh;
            }
        }
        when (404) {
            die "File $base_file does not exist\n";
        }
        default {
            die "Could not download file - unknown error!\n";
        }
    }
}


#-------------------------------------------------------------------------------

1;