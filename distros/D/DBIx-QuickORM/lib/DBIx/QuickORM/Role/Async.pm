package DBIx::QuickORM::Role::Async;
use strict;
use warnings;

our $VERSION = '0.000022';

use Time::HiRes qw/sleep/;
use Role::Tiny;

with 'DBIx::QuickORM::Role::STH';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Async - Role for asynchronous statement handles.

=head1 DESCRIPTION

Extends L<DBIx::QuickORM::Role::STH> for statement handles whose results
arrive asynchronously (driver-level async or a forked child). Provides
C<wait> (poll C<ready> until the result is available) and a C<DESTROY> that
cancels or drains an unfinished handle so it never leaks an in-flight query.

=cut

sub wait { sleep 0.1 until $_[0]->ready }

sub DESTROY {
    my $self = shift;

    return if $self->done;

    unless ($self->got_result) {
        if ($self->cancel_supported) {
            $self->cancel;
        }
        else {
            $self->wait;
        }
    }

    $self->set_done;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
