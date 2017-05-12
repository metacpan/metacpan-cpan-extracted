package CPAN::Mini::Inject::REST::Client::Command::add;

use 5.010;
use strict;
use warnings;
use base 'CPAN::Mini::Inject::REST::Client::Command';
use File::Basename;


#--Command usage----------------------------------------------------------------

sub usage_desc {
    return "add %o <filename>";
}

sub abstract {
    return "Adds a new file to the repository";
}

sub description {
    return "Adds a new file to the repository";
}


#--Command specific options-----------------------------------------------------

sub options {
    my ($class, $app) = @_;
    
    return undef;
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
    
    my ($code, $result) = $self->api($opt)->post(
        "repository/$base_file", {
            file => [$file],
        }
    );
    
    given ($code) {
        when (201) {
            say "$base_file has been added to the repository\n";
            say "Indexed modules:";
            say '  ' . $_->{module} . '  (' . $_->{version} . ')' foreach (@{$result->{provides}});
        }
        when (400) {
            die $result->{error}, "\n";
        }
        default {
            die "Could not add file - unknown error!\n";
        }
    }
}


#-------------------------------------------------------------------------------

1;