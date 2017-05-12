package CPAN::Mini::Inject::REST::Client::Command::all_dists;

use 5.010;
use strict;
use warnings;
use base 'CPAN::Mini::Inject::REST::Client::Command';


#--Command usage----------------------------------------------------------------

sub usage_desc {
    return "all_dists %o";
}

sub abstract {
    return "Lists all distributions added to the repository";
}

sub description {
    return "Lists all distributions added to the repository";
}


#--Command specific options-----------------------------------------------------

sub options {
    my ($class, $app) = @_;
    
    return undef;
}


#--Command execute method-------------------------------------------------------

sub execute {
    my ($self, $opt, $args) = @_;

    my ($code, $result) = $self->api($opt)->get("all_dists");
    
    given ($code) {
        when (200) {
            say "Distributions:";
            say "  $_" foreach @{$result->{dists}};
        }
        when (204) {
            die "No distributions have been added\n"
        }
        default {
            die "Cannot retrieve distribution info - unknown error!\n";
        }
    }
}


#-------------------------------------------------------------------------------

1;