package App::Multigit::Future;

use strict;
use warnings;

use base qw( IO::Async::Future );

our $VERSION = '0.18';

=head1 NAME

App::Multigit::Future - Futures for App::Multigit

=head1 DESCRIPTION

Extensio of IO::Async::Future with a few extra methods.

=head1 METHODS

=head2 finally

Like C<followed_by>, but unpacks the Future and calls C<done> on the result.

As documented in L<run|App::Multigit::Repo/"run($command, [%data])">, all
operations complete with the same data structure. This is also true when a
command fails to run.

This is therefore a convenience method that runs the subref with the C<%data>
structure, irrespective of whether the preceding steps caused a failure or not.

    my $final_f = mg_each(sub {
        my $repo = shift;
        $repo->run([qw/ git command that might fail /])
            ->finally($repo->curry::report);
    });

=cut

sub finally {
    my ($self, $code) = @_;

    $self->followed_by( sub {
        my $f = shift;
        my @result;


        if (@result = $f->failure) {
            @result = @result[2 .. $#result];
        }
        else {
            @result = $f->get;
        }

        (ref $f)->done(@result);
    })
    ->then($code);
}

1;
