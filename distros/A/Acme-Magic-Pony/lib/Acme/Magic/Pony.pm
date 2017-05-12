package Acme::Magic::Pony;

use warnings;
use strict;
use CPAN;

sub _magic_pony {
    my $file = $_[0];
    eval { CORE::require( $file ) };
    if( $@ ){ # oops, they don't have it!
        ( my $module = $file ) =~ s/\//::/g;
        $module =~ s/\.pm$//g;
        warn "You appear to be missing $module, but don't worry, a Magic Pony is here to help!\n";
        *CORE::GLOBAL::require = *CORE::require; # disable magic pony while we go for a ride...
        CPAN::Shell->install($module); 
        CORE::require $file;
        *CORE::GLOBAL::require = sub { _magic_pony(@_) };
    }
}

BEGIN {
   *CORE::GLOBAL::require = sub { _magic_pony(@_) };
}

=head1 NAME

Acme::Magic::Pony - Schwern asked for a Magic Pony!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS


    use Acme::Magic::Pony;

That's it.  Every time you use any module, Acme::Magic::Pony will look to see if 
you have it.  If you do, it does nothing, but if you're missing it, it will 
attempt to use CPAN::Shell to install it.


=head1 EXPORT

Nothing.

=head1 FUNCTIONS

None.

=head1 METHODS

None.

=head1 AUTHOR

Jeff Lavallee, C<< <jeff at zeroclue.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-magic-pony at rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Magic-Pony>.  
I will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Magic::Pony


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Magic-Pony>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Magic-Pony>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Magic-Pony>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Magic-Pony>

=back


=head1 INSPIRATION

Michael G Schwern said:

    As long as we're talking platitudes, why don't we just say you never have to
    upgrade!  In fact, you never even have to install the software, magic ponies
    inside your computer will just know when you need it and go get it for you. [1]

    Also everyone gets a million dollars and a pet dragon.


    [1]  I anticipate the Acme::Magic::Pony auto-installer on CPAN by Monday.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Jeff Lavallee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 TODO

Acme::Magic::Pony doesn't offer to upgrade modules that aren't at the most recent 
version.  Maybe it's not so magic after all!

=head1 NOTE

This might be vaguely useful when writing new code on a system that doesn't have 
modules you're used to using.  It'll fire up CPAN for you and install things as 
you go.  But heaven forbid you leave "use Acme::Magic::Pony" around in your code, 
it will be more or less guaranteed to cause anyone who runs across your code no 
end of headaches.

I'm sure this module could be vastly improved.  Please file bugs and/or send me 
email directly.  In particular, I'm not sure what a good testing strategy is - 
I suppose I could attempt to identify some module that the user doesn't have, 
and see that Acme::Magic::Pony installs it and that it can then be used, but 
that seems rather intrusive and risky.  Ideas?


=cut

1; # End of Acme::Magic::Pony
