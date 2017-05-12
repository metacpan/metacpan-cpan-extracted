package CPAN::Mini::Inject::REST::Client::Command::dist;

use 5.010;
use strict;
use warnings;
use base 'CPAN::Mini::Inject::REST::Client::Command';


#--Command usage----------------------------------------------------------------

sub usage_desc {
    return "dist %o <distribution_name>";
}

sub abstract {
    return "Lists distribution files contained in the mirror and repository";
}

sub description {
    return "Lists distribution files contained in the mirror and repository";
}


#--Command specific options-----------------------------------------------------

sub options {
    my ($class, $app) = @_;
    
    return undef;
}


#--Validate args----------------------------------------------------------------

sub validate_args {
    my ($self, $opt, $args) = @_;
    
    $self->usage_error('Distribution name must be specified') unless @$args;
}


#--Command execute method-------------------------------------------------------

sub execute {
    my ($self, $opt, $args) = @_;

    my $dist            = shift @$args;    
    my ($code, $result) = $self->api($opt)->get("dist/$dist");
    
    given ($code) {
        when (200) {
            say "Mirror:";
            say "  $_" foreach @{$result->{mirror}};
            say "";
            say "Repository:";
            say "  $_" foreach @{$result->{repository}};
        }
        when (404) {
            die "Distribution $dist cannot be found\n"
        }
        default {
            die "Cannot retrieve distribution info - unknown error!\n";
        }
    }
}


#-------------------------------------------------------------------------------

1;