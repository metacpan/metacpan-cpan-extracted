use strict;
use warnings;
package Bot::Backbone::Service::OFun;
$Bot::Backbone::Service::OFun::VERSION = '0.142230';
# ABSTRACT: A set of Bot::Backbone services optimized for fun


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::OFun - A set of Bot::Backbone services optimized for fun

=head1 VERSION

version 0.142230

=head1 SYNOPSIS

    service code_name => (
        service         => 'OFun::CodeName',
        adjectives_file => 'adjectives.txt',
        nouns_file      => 'nouns.txt',
        db_dsn          => "dbi:SQLite:codename.db",
    );
    
    service dice => (
        service => 'OFun::Dice',
    );
    
    service insult => (
        service  => 'OFun::Insult',
    );

    service "karma" => (
        service     => 'OFun::Karma',
        db_dsn      => "dbi:SQLite:karma.db",
    );

    service "hailo" => (
        service    => 'OFun::Hailo',
        brain_file => "hailo.db",
    );

    dispatcher "chatroom" => as {
        redispatch_to 'code_name';
        redispatch_to 'dice';
        redispatch_to 'insult';
        redispatch_to 'karma';
        redispatch_to 'hailo';
    };

=head1 DESCRIPTION

This is a collection of modules designed for use with L<Bot::Backbone> to help
make it easy to create bot with various fun features. Many of these services
require additional input files or configuration and may also require
a database for persistent storage of information. As much as possible, I've
tried to implement these in a standardish way. 

In the case of persistent storage, I had to choose something, so I chose
L<DBI>, which is made avaialble through the
L<Bot::Backbone::Service::Role::Storage>.

Here's a list of the included services and what they each do:

=over

=item *

L<Bot::Backbone::Service::OFun::CodeName>. This is a service that gives you a
C<!codename> command that will generate a code name for a word or phrase, which
can be a fun way of assigning secret names to your project. It requires storage
to save the code names as they are assigned and a couple of word lists.

=item *

L<Bot::Backbone::Service::OFun::Dice>. This is a very simple service that
provides a few commands related to picking numbers at random. The <!roll>
command will roll a set of dice according to standard dice notation. The
C<!flip> command will flip a coin. The C<!choose> command can choose items
from a list. The C<!shuffle> command takes a list and shuffles it to display
again.

=item *

L<Bot::Backbone::Service::OFun::Hailo>. This is a conversation generator. If
someone addresses the bot directly, the bot will respond using L<Hailo>. This
will save the markov chains learned and used to generate the conversation in a
SQLite database.

=item *

L<Bot::Backbone::Service::OFun::Insult>. This provides a C<!insult> command
based upon the L<Acme::Whoresone::Scurvy::Bilgerat> insult generator.

=item *

L<Bot::Backbone::Service::OFun::Karma>. This provides a karma/score tracker.
Any time someone uses a ++ or -- notation on a word or phrase, that word or
phrase will have a score recorded. You can then see the list of highest and
lowest scores or score for a specific item with the C<!score> command. This
requires some storage to track the scores.

=back

=head1 CAVEATS

This release also include L<Bot::Backbone::Service::Role::Storage>, which does
not belong here. It will likely be moved into a seperate distribution in the
future.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
