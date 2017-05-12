package TheBug;

sub new     { bless { message => $_[1] }, $_[0] }
sub result  { $_[0] }

package RPC::ExtDirect::Test::PollProvider;

use strict;
use warnings;
no  warnings 'uninitialized';

use Carp;

use RPC::ExtDirect;
use RPC::ExtDirect::Event;

# This is to control what gets returned
our $WHAT_YOURE_HAVING = 'Usual, please';

sub foo : ExtDirect( pollHandler ) {
    my ($class) = @_;

    my $password_file = '/tmp/apache-extdirect-password';

    if ( -r $password_file ) {
        open my $fh, '<', $password_file;
        $WHAT_YOURE_HAVING = <$fh>;
    };

    # There ought to be something more substantive, but...
    if ( $WHAT_YOURE_HAVING eq 'Usual, please' ) {
        return (
                RPC::ExtDirect::Event->new('foo_event', [ 'foo' ]),
                RPC::ExtDirect::Event->new('bar_event', { foo => 'bar' }),
               );
    }

    elsif ( $WHAT_YOURE_HAVING eq 'Ein kaffe bitte' ) {
        return (
                RPC::ExtDirect::Event->new('coffee',
                                           'Uno cappuccino, presto!'),
               );
    }

    elsif ( $WHAT_YOURE_HAVING eq 'Whiskey, straight away!' ) {
        croak "Burp!";
    }

    elsif ( $WHAT_YOURE_HAVING eq "Hey man! There's a roach in my soup!" ) {
        my $bug = new TheBug 'TIGER ROACH!! WHOA!';
        return $bug;
    }

    else {
        # Nothing special to report in our Special News Report!
        return ();
    };
}

1;
