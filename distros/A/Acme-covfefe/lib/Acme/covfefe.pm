package Acme::covfefe;

use 5.026002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(covfefe);

our $VERSION = '42';

sub covfefe {
    my @tweetreasons = (
        'negative press',
        'aliens',
        'immigrants',
        'the border wall',
        'politics',
        'the space force',
        'Hillary',
        'the flying spagetti monster',
        'Twitter',
        'climate change',
        'global warming',
    );

    my $reasonid = int rand @tweetreasons;
    my $tweet = 'Despite ' . $tweetreasons[$reasonid] . ' covfefe';

    return $tweet;
}


1;
__END__

=head1 NAME

Acme::covfefe - Simulate POTUS tweets

=head1 SYNOPSIS

  use Acme::covfefe;
  print covfefe(), "\n";

=head1 DESCRIPTION

Perlmonks asked for the meaning of "covfefe" in a poll. A possible
answer was 'An "Acme" module'. After this upload shows up on CPAN,
this will be one of the correct answers.

As a side effect, it can generate confusing tweets, simulating the U.S. president.

=head2 EXPORT

Exports covfefe() which returns a confusing POTUS tweet.

=head1 SEE ALSO

This is the place where any helpful documentation and other useful resources
should be mentioned. Well, there aren't any. That would make too much sense.

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.2 or,
at your option, any later version of Perl 5 you may have available.

You may even send a copy to POTUS if you so desire.


=cut
