package Antispam::httpBL;
BEGIN {
  $Antispam::httpBL::VERSION = '0.02';
}

use strict;
use warnings;
use namespace::autoclean;

use Antispam::Toolkit 0.06;
use Antispam::Toolkit::Result;
use MooseX::Types::Moose qw( Str );
use WWW::Honeypot::httpBL;

use Moose;
use MooseX::StrictConstructor;

with 'Antispam::Toolkit::Role::IPChecker';

has access_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub check_ip {
    my $self = shift;
    my %p    = @_;

    my $hp
        = WWW::Honeypot::httpBL->new( { access_key => $self->access_key() } );

    $hp->fetch( $p{ip} );

    my @details;

    push @details, 'IP address is a comment spammer'
        if $hp->is_comment_spammer();
    push @details, 'IP address is an email harvester'
        if $hp->is_harvester();
    push @details, 'IP address is suspicious'
        if $hp->is_suspicious();
    push @details, 'IP address threat score is ' . $hp->threat_score();
    push @details, 'Days since last activity for this IP: '
        . $hp->days_since_last_activity();

    # See http://www.projecthoneypot.org/threat_info.php - a score that's much
    # above 75 is ridiculously unlikely, so we'll just treat >= 75 as a 10.
    my $score = $hp->threat_score() > 75 ? 10 : $hp->threat_score() / 7.5;

    return Antispam::Toolkit::Result->new(
        score   => $score,
        details => \@details,
    );
}

{
    unless ( WWW::Honeypot::httpBL->can('days_since_last_activity') ) {
        *WWW::Honeypot::httpBL::days_since_last_activity
            = \&WWW::Honeypot::httpBL::days_since_last_actvity;
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Antispam checks using Project Honeypot's http blacklist



=pod

=head1 NAME

Antispam::httpBL - Antispam checks using Project Honeypot's http blacklist

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  my $bl = Antispam::httpBL->new( access_key => 'abc123' );

  my $result = $bl->check_ip( ip => '1.2.3.4' );

  if ( $result->score() ) { ... }

=head1 DESCRIPTION

This module implements the L<Antispam::Toolkit::Role::IPChecker> role using
Project Honeypot's Http:BL API to check whether a given IP address is
associated with spamming or email harvesting.

=head1 METHODS

This class provides the following methods:

=head2 Antispam::httpBL->new( access_key => ... )

This method constructs a new object. It requires an access key. You can get an
access key from the Project Honeypot website at
L<http://www.projecthoneypot.org/>.

=head2 $bl->check_ip( ip => ... )

This method checks whether an ip address is associated with some sort of
spam-related behavior.

It returns an L<Antispam::Toolkit::Result> object.

While the Http:BL API allows for threat scores from 0-255, the result will
contain a score from 0-10. This score is the Http:NL threat score divided by
7.5, and capped at 10.

The details in the result object will break down all the results returned by
the Http:BL API.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-antispam-httpbl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

