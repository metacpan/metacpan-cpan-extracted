package CPAN::Mini::Inject::REST::Client::Command::file;

use 5.010;
use strict;
use warnings;
use base 'CPAN::Mini::Inject::REST::Client::Command';


#--Command usage----------------------------------------------------------------

sub usage_desc {
    return "file %o <filename>";
}

sub abstract {
    return "Provides file details as indexed by the mirror";
}

sub description {
    return "Provides file details as indexed by the mirror";
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

    my $file            = shift @$args;    
    my ($code, $result) = $self->api($opt)->get("mirror/$file");
    
    given ($code) {
        when (200) {
            say "Path:";
            say "  " . $result->{path};
            say "";
            say "Modules:";
            foreach my $module (sort keys %{$result->{provides}}) {
                my $version = $result->{provides}->{$module}->{version};
                say "  $module ($version)";
            }
        }
        when (404) {
            die "File $file cannot be found\n"
        }
        default {
            die "Cannot retrieve file info - unknown error!\n";
        }
    }
}


#-------------------------------------------------------------------------------

1;