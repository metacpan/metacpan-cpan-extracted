# $Id: MortalForward.pm 1111 2006-02-22 00:39:49Z ykerherve $
package Catalyst::Plugin::MortalForward;
use warnings;
use strict;

our $VERSION = '0.01';

use NEXT;
    
sub execute {
    my $c = shift;
    my ($class, $action) = @_;
    local $NEXT::NEXT{ $c, 'execute' };
    my $error_count = scalar @{$c->error};
    $c->NEXT::execute(@_);
    # Don't die for internal actions
    return $c->state if $c->depth < 3 || $action->name =~ m/^_/; 

    my @errors = @{ $c->error };
    if ($error_count < scalar @errors) {
        my $error = pop @errors;
        $c->error(0);
        $c->error(@errors);
        die $error;
    }
    return $c->state;
}

"Il ne doit en rester qu'un";

=pod

=head1 NAME 

Catalyst::Plugin::MortalForward - Make forward() to throw exception

=head1 SYNOPSIS

    use Catalyst qw( MortalForward );

    sub someaction : Local {
        ...
        $c->forward('check_input'); # may die

        # never executed if forward dies
        do_something_important(); # assume that the input has been checked
    }

=head1 DESCRIPTION

I<Catalyst::Plugin::MortalForward> is a small plugin that changes the behaviour
of C<< $c->forward >> which usually never dies (because the forwarded code
is internally wrapped into an eval block.

This plugin changes this behaviour B<globally>. The forward method will throw
exceptions (that you should be carefull to handle at somepoint or the default
Catalyst error page will be displayed)

=head1 SEE ALSO

Discussion on the Catalyst mailing list: 
L<http://lists.rawmode.org/pipermail/catalyst/2006-January/004874.html>
(followed-up in February)

=head1 BUGS & TODOS

Please report any problem.
If you let the exception reach Catalyst internal, then the error (which is logged
might be a bit messy) because it holds the information of all successive layers
that the exception went thru. For instance : 

Caught exception in TestApp->class_fwd "Caught exception in TestApp::C::Elsewhere->test "I die too, sorry at /Users/yann/Catalyst/Catalyst-Plugin-MortalForward/t/lib/TestApp/C/Elsewhere.pm line 8." at lib/Catalyst/Plugin/MortalForward.pm line 24."


=head1 AUTHOR

Six Apart, cpan@sixapart.com

=head1 LICENSE

I<Catalyst::Plugin::MortalForward> is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<Catalyst::Plugin::MortalForward> is
Copyright 2006 Six Apart, cpan@sixapart.com. All rights reserved.

=cut
