use warnings;
use strict;

=head1 NAME

CommitBit::Action::Logout

=cut

package CommitBit::Action::Logout;
use base qw/Jifty::Action/;

=head2 arguments

Return the email and password form fields

=cut

sub arguments {
    return ( {} );
}

=head2 take_action

Nuke the current user object

=cut

sub take_action {
    my $self = shift;
    Jifty->web->current_user(undef);
    return 1;
}

1;
