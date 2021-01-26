use warnings;
use strict;

package Acme::PM::Barcelona::Meeting;
# ABSTRACT: When is the next meeting?
$Acme::PM::Barcelona::Meeting::VERSION = '0.06';
use base 'DateTime::Set';
use DateTime;
use DateTime::Event::ICal;


sub new {
    my $class = shift;

    # every last Thu of the month at 20:00
    my $self = DateTime::Event::ICal->recur(
        dtstart  => DateTime->now,
        freq     => 'monthly',
        byday    => [ "-1th" ],
        byhour   => [ 20 ],
        byminute => [ 0 ],
        bysecond => [ 0 ],
    );

    bless $self, $class;
}


1; # End of Acme::PM::Barcelona::Meeting

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PM::Barcelona::Meeting - When is the next meeting?

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Acme::PM::Barcelona::Meeting;

  my $barcelona_pm = Acme::PM::Barcelona::Meeting->new();
  print $barcelona_pm->next->datetime(), "\n";

=head1 DESCRIPTION

This module helps finding when the next Barcelona Perl Mongers meeting
will take place.

=head1 USAGE

=over 4

=item new

Creates a parent DateTime::Set object. All other methods are inherited.

=back

=head1 ACKNOWLEDGEMENTS

Barcelona Perl Mongers

=head1 AUTHOR

Alex Muntada <alexm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009-2021 by Alex Muntada.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
