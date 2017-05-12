package Data::TxnBuffer::Base;
use strict;
use warnings;
use Try::Tiny;

sub txn_read {
    my ($self, $code) = @_;

    my ($ret, $err);
    try {
        $code->($self);
        $ret = $self->spin;
    } catch {
        $err = $_;
        $self->reset;
    };

    if ($err) {
        # rethrow
        die $err;
    }

    $ret;
}

1;

__END__

=head1 NAME

Data::TxnBuffer::Base - base class for Data::TxnBuffer.

=head1 DESCRIPTION

See L<Data::TxnBuffer>.

=head1 method

=head2 txn_read

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

