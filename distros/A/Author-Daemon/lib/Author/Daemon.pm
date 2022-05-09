package Author::Daemon;

use v5.28;
use strict;
use warnings;
use experimental 'signatures';

use Data::Dumper;

# Load all our submodules
use Author::Daemon::Enviroment::Absorb;
use Author::Daemon::Log::Basic;
use Author::Daemon::Snippet::Time;

our $VERSION = '0.001';

sub new ( $class ) {
    my $self = {};
    bless $self, $class;
    return $self;
}

1;

=head1 NAME

Author::Daemon - daemon's helpful creations 

=head1 SYNOPSIS

    use Author::Daemon;

    my $util = Author::Daemon->new();

    $util->read_the_docs();

=for comment Brief examples of using the module.

=head1 DESCRIPTION

A place to store my things!

Over the years I realized I was in the habbit of rewriting a lot of common
functionalities that on there own did not warrent a fully fledged module,
simply due to them requiring expansion of functionality, more git repositories,
more tests ... more work than just re-writing the snippets when they was
required. 

However, when I worked out just how much time I had likely wasted re-writing
loose odds and ends, I decided something must be done, but what?

Well after some thought I decided that I would slowly add all my little tidbits
into one singular module nicely packed in git with dzil with some form of
generic interface so it was easy to add other bits of code here and there with
no more cost than what it would cost me to once again re-write those snippets.

I could not see or find an actual reference to how a pause/perl user should
really go about such a thing while still keeping the ease of a published
module, there seems to be no particular Author who has ever done what I am
attempting (could be wrong though!); so after even more thought. I come to the
conclusion the ideal solution would be A namespace providing the previously
stated single interface that could not collide with fully fledged modules,
almost a 'users unreleased'. 

I found that Author::__PAUSEID__ seemed to hit the nail on the head, at the
time of writing is not reserved in anyway infact I could not see any modules
using the prefix at all. Though I am hoping one or two module authors like the
idea to hopefully push the idea forwards.

From what I can see, it is a benefit to everyone - the authors have a nice
public place to fetch their favorite play things and possible others will find
the odd 'never made a module but still a cool function' enough to develop them
further into actual modules.

Let me know how you feel if you do stumble over this module (either message me
on irc libera.org or perl.org nickname 'daemon' or drop me an issue against the
repository for this module on github)

=for comment The module's description.

=head1 INDEX

Below is all functionality offered via the suite of modules under the namespace though some may require other modules to be availible (this will be noted).

* Nothing yet working on it!

=head2 

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
