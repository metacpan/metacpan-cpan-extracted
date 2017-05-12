
=head1 NAME

CGI::Application::Plugin::AB - A/B Testing for CGI::Application-based applications.

=head1 SYNOPSIS

  use CGI::Application::Plugin::AB;


  # Your application
  sub run_mode {
    my ($self) = ( @_);

    my $version = $self->a_or_b();
  }

=cut


=head1 DESCRIPTION

This module divides all visitors into an "A" group, or a "B" group,
and allows you to determine which set they are a member of.

=cut

=head1 MOTIVATION

To test the effectiveness of marketing text, or similar, it is sometimes
useful to display two different versions of a web-page to visitors:

=over 8

=item *
One version will show features and a price of $5.00

=item *
One version will show features and a price of $10.00

=back

To do this you must pick 50% of your visitors at random and show half
one template, and the other half the other.

Once the user signs up you can record which version of the page was displayed,
allowing you to incrementally improve your signup-rate.

This module helps you achieve this goal by automatically assigning all
visitors membership of the A-group, or the B-group.

You're expected to handle the logic of showing different templates and
recording the version the user viewed.

=cut

use strict;
use warnings;

package CGI::Application::Plugin::AB;


our $VERSION = '0.4';


=head1 METHODS


=head2 import

Force the C<a_or_b> method into the caller's namespace.
=cut

sub import
{
    my $pkg     = shift;
    my $callpkg = caller;

    {
        ## no critic
        no strict qw(refs);
        ## use critic
        *{ $callpkg . '::a_or_b' } = \&a_or_b;
    }
}


=head2 a_or_b

Return whether the visitor to this site is in the A-group, or the B-group.

No significance is paid to which group the visitors are member of in this
module, it is expected you'll handle the logic yourself:

=over 8

=item *
Show a different template to members of the different sets.

=item *
Record the set membership when a user signs up, etc.

=back

=cut

sub a_or_b
{
    my $cgi_app = shift;

    #
    #  Get the IP and strip non-digits.
    #
    my $addr = $ENV{ 'REMOTE_ADDR' };
    $addr =~ s/\D//g;

    #
    #  Sum the digits
    #
    my $sum = 0;
    for my $c (split //, $addr)
    {
        $sum += $c;
    }

    #
    #  Odd == a.
    #  Even == b.
    return( "A" ) if ( $sum % 2 == 0 );
    return( "B" ) if ( $sum % 2 == 1 );

}




=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut



1;
