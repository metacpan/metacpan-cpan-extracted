package CPAN::Mini::Inject::REST::Client::Command::all_files;

use 5.010;
use strict;
use warnings;
use base 'CPAN::Mini::Inject::REST::Client::Command';


#--Command usage----------------------------------------------------------------

sub usage_desc {
    return "all_files %o";
}

sub abstract {
    return "Lists all files added to the mirror";
}

sub description {
    return "Lists all files added to the mirror";
}


#--Command specific options-----------------------------------------------------

sub options {
    my ($class, $app) = @_;
    
    return undef;
}


#--Command execute method-------------------------------------------------------

sub execute {
    my ($self, $opt, $args) = @_;

    my ($code, $result) = $self->api($opt)->get("all_files");
    
    given ($code) {
        when (200) {
            say "Files:";
            say "  $_" foreach @{$result->{files}};
        }
        when (204) {
            die "No files have been added\n"
        }
        default {
            die "Cannot retrieve file info - unknown error!\n";
        }
    }
}


#-------------------------------------------------------------------------------

1;