package App::MultiModule::Tasks::DocGateway;
$App::MultiModule::Tasks::DocGateway::VERSION = '1.161330';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Postgres::Mongo;
use Storable;

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::DocGateway - Interface with a persistent document store

=cut

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
    my $state = $self->{state};
    #TODO: validate document_database, document_collection, document_method here
    $self->_find($message) if $message->{document_method} eq 'find';
    $self->_insert($message) if $message->{document_method} eq 'insert';
    $self->_remove($message) if $message->{document_method} eq 'remove';
    $self->_upsert($message) if $message->{document_method} eq 'upsert';
}

sub _upsert {
    my $self = shift;
    my $message = shift;
    #TODO: validate $message->{document_filter} here
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        my $timeout = $self->{config}->{pg_upsert_timeout} || 2;
        alarm $timeout;
        my $c = $self->_get_connection();
        my $update;
        if($message->{document_update}) {
            $update = Storable::dclone($message->{document_update});
        } else {
            $update = Storable::dclone($message);
        }
        delete $update->{document_filter};
        delete $update->{'.ipc_transit_meta'};
        $c->mongo_do(
            $message->{document_database},
            $message->{document_collection},
            'upsert',
            {   filter => $message->{document_filter}},
            update => $update,
        );
    };
    alarm 0;
    if($@) {
        $self->error("App::MultiModule::Tasks::DocGateway::_upsert failed: $@");
        return;
    }
}

sub _remove {
    my $self = shift;
    my $message = shift;
    #TODO: validate $message->{document_filter} here
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        my $timeout = $self->{config}->{pg_remove_timeout} || 2;
        alarm $timeout;
        my $c = $self->_get_connection();
        $c->mongo_do(
            $message->{document_database},
            $message->{document_collection},
            'remove',
            { filter => $message->{document_filter}});
    };
    alarm 0;
    if($@) {
        $self->error("App::MultiModule::Tasks::DocGateway::_remove failed: $@");
        return;
    }
}

sub _insert {
    my $self = shift;
    my $message = shift;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        my $timeout = $self->{config}->{pg_insert_timeout} || 2;
        alarm $timeout;
        my $c = $self->_get_connection();
        my $insert = Storable::dclone($message);
        delete $insert->{'.ipc_transit_meta'};
        $c->mongo_do(
            $message->{document_database},
            $message->{document_collection},
            'insert',
            $insert);
    };
    alarm 0;
    if($@) {
        $self->error("App::MultiModule::Tasks::DocGateway::_insert failed: $@");
        return;
    }
}

sub _find {
    my $self = shift;
    my $message = shift;
    #TODO: validate $message->{document_filter} here
    #TODO: variant that emits once per return document
    my @emits = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        my $timeout = $self->{config}->{pg_find_timeout} || 7;
        alarm $timeout;
        my $c = $self->_get_connection();
        my $documents = $c->mongo_find(
            $message->{document_database},
            $message->{document_collection},
            $message->{document_filter},
        );
        $message->{document_returns} = $documents;
        return ($message);
    };
    alarm 0;
    if($@) {
        $self->error("App::MultiModule::Tasks::DocGateway::_find failed: $@");
        return;
    }
    $self->emit($_) for @emits;
}

sub _get_connection {
    my $self = shift;
    my $handle = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        my $timeout = $self->{config}->{pg_connect_timeout} || 5;
        alarm $timeout;
        return Postgres::Mongo->new(
            userid => $self->{pg_userid},
            password => $self->{pg_password},
        );
    };
    alarm 0;
    $self->error("App::MultiModule::Tasks::DocGateway::_get_connection failed: $@") if $@;
    return $handle;
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    my $state = $self->{state};
    $self->{pg_userid} = $config->{pg_userid} || 'testuser1';
    $self->{pg_password} = $config->{pg_password} || 'testuser1';
}

=head2 is_stateful

=cut
sub is_stateful {
    return 'absolultely';
}


=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-DocGateway/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::DocGateway


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-DocGateway/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-DocGateway>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-DocGateway>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::DocGateway>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::MultiModule::Tasks::DocGateway
