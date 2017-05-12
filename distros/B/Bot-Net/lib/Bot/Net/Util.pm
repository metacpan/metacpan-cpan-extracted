use strict;
use warnings;

package Bot::Net::Util;

use Bot::Net;
use Carp;
use Regexp::Common qw/ delimited /;

=head1 NAME

Bot::Net::Util - miscellaneous utility functions

=head1 SYNOPSIS

  my @args = Bot::Net::Util->parse_bot_command($message);

=head1 DESCRIPTION

Provides utility functions for use elsewhere.

=head1 METHODS

=head2 parse_bot_command MESSAGE

Returns an array of words found in the given message. This tries to sensibly break up a command. The string will be split on whitespace or grouped by quotes.

Quoted strings may contain quotes by containing a double-quote to escape it. For example,

  tell 'bob''s friend' """Hello World"""

would become:

  ('tell', "bob's friend", '"Hello World"')

=cut

sub parse_bot_command {
    my $class = shift;
    local $_  = shift;

    unless (defined $_) {
        carp "No string given to parse. Returning an empty list.";
        return;
    }

    my @args = m/
        ( $RE{delimited}{-delim=>'"'}{-esc=>'"'} 
        | $RE{delimited}{-delim=>"'"}{-esc=>"'"}
        | \S+
        )
    /gx;

    # Strip the quotes and unescape the "" and '' escapes
    map {
        /^"/ && /"$/ && s/^"// && s/"$// && s/""/"/g;
        /^'/ && /'$/ && s/^'// && s/'$// && s/''/'/g;
    } @args;

    return @args;
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
