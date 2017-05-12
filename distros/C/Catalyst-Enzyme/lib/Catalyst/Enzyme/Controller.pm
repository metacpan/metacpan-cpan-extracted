package Catalyst::Enzyme::Controller;
use base 'Catalyst::Base';

our $VERSION = 0.10;



use strict;
use Data::Dumper;
use Carp;



=head1 NAME

Catalyst::Enzyme::Controller - Enzyme Controller Base Class with
utility methods

=head1 SYNOPSIS

See L<Catalyst::Enzyme>


=head1 PROPERTIES


=head1 METHODS


=head2 run_safe($c, $sub, $fail_action, $fail_message, @rest)

Run the $sub->(@rest) ref inside an eval cage, and return 1.

Or, if $sub dies, set stash->{message} to $fail_message,
stash->{error} to $@, log the error, shed a tear, and return 0.

=cut
sub run_safe {
    my ($self, $c, $sub, $fail_action, $fail_message, @rest) = @_;

    eval { $sub->() };
    $@ or return(1);

    my $message = $c->stash->{message} = $fail_message;
    $c->stash->{error} = $@;
    $c->log->error("$message: $@");
    $c->forward($fail_action);
    
    return(0);
}



=head2 class_to_moniker($class_name)

Return default moniker of $class_name.

Default is to take the last past of the $class_name, and split it on
lower/uppercase boundaries.

If one can't be figured out, return the $class_name.

=cut
sub class_to_moniker {
    my ($self) = shift;
    my ($class_name) = @_;

    $class_name =~ /::(\w+)$/ or return($class_name);
    my $moniker = $1;
    $moniker =~ s/([a-z])([A-Z])/$1 $2/g;
    
    return($moniker);
}





=head1 AUTHOR

Johan Lindstrom <johanl ÄT cpan.org>


=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
