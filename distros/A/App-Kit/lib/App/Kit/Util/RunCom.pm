package App::Kit::Util::RunCom;

use strict;
use warnings;

package App::Kit::Obj::Ex;

use strict;
use warnings;
use Running::Commentary;

sub runcom {
    my ( $ex, @cmds ) = @_;

    run_with -critical;       # explicitly state it isn’t critical via -nocritical
    run_with -showmessage;    # be explicit
    run_with -showoutput;     # be explicit
    run_with -nocolour if !$ex->_app->detect->is_interactive || $ex->_app->detect->is_web;

    # TODO:
    # run_with -nomessage if $ex->_app->in->param('no-msg') || $ex->_app->in->param('quiet');
    # run_with -nooutput  if $ex->_app->in->param('no-out') || $ex->_app->in->param('quiet');
    # run_with -dry       if $ex->_app->in->param('dryrun');
    # ? run_with -nocolour if … ?
    # ? incorporate --verbose param ?

    for my $run (@cmds) {
        if ( ref($run) ne 'ARRAY' ) {
            print "-- $run --\n";    # TODO print $self->_app->out->head($run);
            next;
        }

        run( @{$run} );
    }
}

1;

__END__

=encoding utf-8

=head1 Do the begin-time setup and definition of ex->runcom()

The underlying module that runcom() uses, L<Running::Commentary>, must be brought and do its lexical magic and import() at compile time (i.e. can not be lazy loaded) and must be done in the right class for it to take effect where we want it.

So in order to make runcom() work how we want this module brings in L<Running::Commentary> and defines the real runcom().

That means that this module must be use()d at compile time.

Sort of a hassle (patches welcome!) I suppose but runcom() probably won't be needed in most of your code, just runcom()-type scripts really.
