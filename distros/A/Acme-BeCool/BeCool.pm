package Acme::BeCool;

=head1 NAME

Acme::BeCool -- Make your modules use the modules that get you some.

=head1 SYNOPSIS

    use Acme::BeCool; # Wakka-chikka, wakka-chikka...

    # Whatever you write here will get play.

or

    use Acme::BeCool qw(This That And The::Other); # I *define* cool.
    # really?

=cut

# This improves my Kwalitee?
q#
use strict;
use warnings;
#;

$VERSION = '0.02';

use LWP::Simple;

sub import
{
    shift;
    if (!@_) {
        my $page = get 'http://search.cpan.org/search?query=cool&mode=all';
        push @_, $1 while $page =~ m!<h2.*?<b>(.*?)</b></a></h2>!g;
    }
    @_ = grep !/\//, @_;
    my $caller = shift;
    my $cool = 0;
    for (@_) {
        eval "require $_";
        $caller->import($_) unless $@;
    }
    print STDERR "You are ", ($cool / @_), "\% cool\n";
}

1;
__END__

=head1 DESCRIPTION

This module automatically uses the top ten things returned by a CPAN
search for "cool," or uses what you tell it.  Use it to keep up with
the latest fads in Perl development, or to try to become a Perl
trend-setter yourself!  Note that it doesn't try to install anything
you don't already have, because if you're cool, you already have it.

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

Bug reports welcome, patches even more welcome.

=head1 COPYRIGHT

Copyright (C) 2009 Sean O'Rourke.  All rights reserved, some wrongs
reversed.  This module is distributed under the same terms as Perl
itself.

=head1 LICENSE

This module is distributed under the same terms as Perl itself.

=cut
