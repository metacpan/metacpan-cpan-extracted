package App::MultiModule::Tasks::SmartMerge;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Message::SmartMerge;
use IPC::Transit;
use Storable;

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::SmartMerge - The great new App::MultiModule::Tasks::SmartMerge!

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use App::MultiModule::Tasks::SmartMerge;

    my $foo = App::MultiModule::Tasks::SmartMerge->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 message

=cut
sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
    if($message->{add_merge}) {
        eval {
            $self->_add_merge($message->{add_merge});
        };
        if($@) {
            $self->error("App::MultiModule::Tasks::SmartMerge::message: call to _add_merge() failed: $@", message => $message);
        }
        return;
    }
    if($message->{remove_merge}) {
        eval {
            $self->_remove_merge($message->{remove_merge});
        };
        if($@) {
            $self->error("App::MultiModule::Tasks::SmartMerge::message: call to _remove_merge() failed: $@", message => $message);
        }
        return;
    }
    eval {
        $self->{smartmerge}->message($message);
    };
    if($@) {
        $self->error("App::MultiModule::Tasks::SmartMerge::message: call to message() failed: $@", message => $message);
    }
}

sub _add_merge {
    my $self = shift;
    my $merge = shift;
    my %args = @_;
    $self->{smartmerge}->add_merge($merge);
}

sub _remove_merge {
    my $self = shift;
    my $merge_id = shift;
    my %args = @_;
    $self->{smartmerge}->remove_merge($merge_id);
}

sub _my_emit {
    my $self = shift;
    my $message = shift;
    $self->emit($message);
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    if(not $self->{smartmerge}) {
        $self->{smartmerge} = mine->new(state => $self->{state});
        $self->{smartmerge}->config($config);
        $App::MultiModule::Tasks::SmartMerge::global_object = $self;
    }
    $self->named_recur(
        recur_name => 'SmartMerge_state_sync',
        repeat_interval => 1,
        work => sub {
#            $self->{state} = Storable::dclone($self->{smartmerge}->get_state);
            $self->{state} = $self->{smartmerge}->get_state;
        },
    );
}

=head2 is_stateful

=cut
sub is_stateful {
    return 'yes';
}
=head1 AUTHOR

Dana M. Diederich, C<< <diederich at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-multimodule-tasks-buckets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-MultiModule-Tasks-SmartMerge>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::SmartMerge


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-MultiModule-Tasks-SmartMerge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-SmartMerge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-SmartMerge>

=item * Search CPAN

L<http://search.cpan.org/dist/App-MultiModule-Tasks-SmartMerge/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dana M. Diederich.

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

package mine;
$mine::VERSION = '1.142121';
use base 'Message::SmartMerge';
sub emit {
    my $self = shift;
    my %args = @_;
    #oh dear god...
    $App::MultiModule::Tasks::SmartMerge::global_object->_my_emit($args{message});
}
1; # End of App::MultiModule::Tasks::SmartMerge
