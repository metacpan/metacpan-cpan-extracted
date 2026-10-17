package Claude::Agent::Permission::Result::Deny;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Permission::Result;

BEGIN {
    Object::Proto::define('Claude::Agent::Permission::Result::Deny',
        extends => 'Claude::Agent::Permission::Result',
        'message:Str:predicate',
        'interrupt:predicate',
    );
}

sub BUILD {
    my ($self) = @_;
    $self->behavior('deny');
    return;
}

sub to_hash {
    my ($self) = @_;
    my $hash = {
        behavior  => 'deny',
        interrupt => $self->interrupt ? \1 : \0,
    };
    $hash->{message} = $self->message if $self->has_message;
    return $hash;
}

1;

__END__

=head1 NAME

Claude::Agent::Permission::Result::Deny - Permission result that denies a tool

=head1 DESCRIPTION

Permission result that stops the tool from running.

=head1 ATTRIBUTES

=head2 behavior

Always C<deny>.

=head2 message

The reason, shown to the model.

=head2 interrupt

True to end the whole turn rather than let the model carry on.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 to_hash

    my $hash = $result->to_hash;

C<{ behavior =E<gt> 'deny', interrupt =E<gt> \1 or \0, message =E<gt> ... }>.
C<interrupt> is always present as a JSON boolean.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
