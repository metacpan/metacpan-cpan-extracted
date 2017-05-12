package App::PAIA::Command::renew;
use strict;
use v5.10;
use parent 'App::PAIA::Command';

our $VERSION = '0.30';

sub usage_desc {
    "%c renew %o URI [item=URI] [edition=URI] ..."
}

sub _execute {
    my ($self, $opt, $args) = @_;

    my @docs = $self->uri_list(@$args);
    
    $self->usage_error("Missing document URIs to cancel")
        unless @docs;

    $self->core_request( 'POST', 'renew', { doc => \@docs } );
}

1;
__END__

=head1 NAME

App::PAIA::Command::renew - renew one or more documents held by a patron

=head1 DESCRIPTION

Renews documents given by their item's (default) or edition's URI.

=cut
