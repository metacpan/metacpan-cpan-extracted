package App::PAIA::Command::config;
use strict;
use v5.10;
use parent 'App::PAIA::Command';

our $VERSION = '0.30';

use App::PAIA::JSON;

sub usage_desc {
    "%c config %o [ key [value] ]"
}

sub opt_spec {
    ['ini|i' => 'list configuration in sorted ini-style'],
    ['delete|d=s' => 'remove a key from the configuration file'];
}

sub _execute {
    my ($self, $opt, $args) = @_;

    if (defined $opt->delete) {
        $self->config->load;
        $self->config->delete($opt->delete);
        $self->config->store;
        return;
    }

    if (@$args) {
        my ($key, $value) = @$args;

        if (defined $value) {
            if (defined $self->config->file and -e $self->config->file) {
                $self->config->load;
            }
            $self->config->set( $key => $value );
            $self->config->store;
            return;
        } elsif( defined ($value = $self->config->get($key)) ) {
            say $value;
            return;
        } else {
            exit 1;
        }
    }
        
    $self->config->load;

    if ($opt->ini) {
        foreach ( sort keys %{$self->config->{data}} ) {
            say "$_=".$self->config->get($_); 
        }
    } else {
        return $self->config->{data};
    }
     
    return;
}

1;
__END__

=head1 NAME

App::PAIA::Command::config - show or modify configuration

=head1 DESCRIPTION

This command shows or modifies the current configuration. Configuration
is printed as JSON object or in INI-sytle as sorted key-value-pairs.

=cut
