package Bot::BasicBot::Pluggable::Module::VieDeMerde;

use warnings;
use strict;

use HTML::Entities;
use WWW::VieDeMerde;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.2';

sub render_item {
    my $msg = shift;
    my $response = decode_entities($msg->text);
    $response .= ' #' . $msg->id;
    $response .= ' (+' . $msg->agree . ',-' . $msg->deserved . ')';

    return $response;
}

sub render_comment {
    my $msg = shift;
    my $response = decode_entities($msg->text);
    $response .= ' (' . $msg->author . ')';

    return $response;
}

sub said {
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body};
    my $who  = $mess->{who};

    return unless $body =~ /^\@?(vdm|fml)(?:\s+(.*))?$/;
    my $site = $1;
    my $cmd = $2 // 'random';

    my $lang;
    $lang = 'fr' if $site eq 'vdm';
    $lang = 'en' if $site eq 'fml';
    my $vdm = WWW::VieDeMerde->new(lang => $lang);

    my $msg;
    if ($cmd) {
        if ($cmd eq 'random') {
            return render_item($vdm->random());
        }
        if ($cmd =~ /comments\s+#?(\d+)(?:\s+(?:(?:#?(\d+))|(--all)))?/) {
            my @comments = $vdm->comments($1);
            if (@comments) {
                if (defined($3)) {
                    return join("\n", map { render_comment($_) } @comments[0,15]);
                }
                else {
                    if (defined($2)) {
                        return 'Error comments begin at #1' if $2 == 0;
                        return "Warning, your request can be accurate due to deleted comments\n". render_comment($comments[$2 - 1]);
                    }
                    else {
                        return render_comment($comments[int(rand(@comments))]);
                    }
                }
            }
            else {
                return "No comments found for id $1 in viedemerde.fr" if $lang eq 'fr';
                return "No comments found for id $1 in fmylife.com" if $lang eq 'en';
                return "No comments found for id $1 and language $lang";
            }
        }
        if ($cmd =~ /#?(\d+)/) {
            my $item = $vdm->get($1);
            if (defined $item) {
                return render_item($item);
            }
            else {
                return "No item found for id $1 in viedemerde.fr" if $lang eq 'fr';
                return "No item found for id $1 in fmylife.com" if $lang eq 'en';
                return "No item found for id $1 and language $lang";
            }
        }
        if ($cmd =~ /top\s*(day|week|month|all)(\s+--all)?/) {
            my @items;
            @items = $vdm->top_day()   if $1 eq 'day';
            @items = $vdm->top_week()  if $1 eq 'week';
            @items = $vdm->top_month() if $1 eq 'month';
            @items = $vdm->top()       if $1 eq 'all';
            if (@items) {
                if (defined($2)) {
                    return join("\n", map { render_item($_) } @items);
                }
                else {
                    return render_item($items[int(rand(@items))]);
                }
            }
            else {
                return "Error, no top for this $1." unless @items;
            }
        }
        if ($cmd =~ /flop\s*(day|week|month|all)(\s+--all)?/) {
            my @items;
            @items = $vdm->flop_day()   if $1 eq 'day';
            @items = $vdm->flop_week()  if $1 eq 'week';
            @items = $vdm->flop_month() if $1 eq 'month';
            @items = $vdm->flop()       if $1 eq 'all';
            if (@items) {
                if (defined($2)) {
                    return join("\n", map { render_item($_) } @items);
                }
                else {
                    return render_item($items[int(rand(@items))]);
                }
            }
            else {
                return "Error, no flop for this $1." unless @items;
            }
        }
        if ($cmd =~ /lasts(\s+--all)?/) {
            my @items = $vdm->last();
            if (@items) {
                if (defined($1)) {
                    return join("\n", map { render_item($_) } @items);
                }
                else {
                    return render_item($items[int(rand(@items))]);
                }
            }
            else {
                return "No items, this shouldn't happen." unless @items;
            }
        }
        if ($cmd =~ /last/) {
            my @items = $vdm->last();
            return render_item($items[0]);
        }
        return "Unknown command '$site $cmd' in Bot::BasicBot::Pluggable::Module::VieDeMerde";
    }
}

sub help {
    "Display a quote from viedemerde.fr or fmylife.com.\n"
        . "Usage vdm, vdm #id, vdm comments #id, vdm last, vdm lasts [--all], vdm top day|week|month|global [--all], vdm flop day|week|month|global [--all], vdm comments #id [#id_comment|--all].\n
"
. "You can replace vdm by fml.\nYou can prefix every command with a @ for drop-in compatibilty with the geekquotes module for supybot."
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::VieDeMerde - VieDeMerde plugin for BasicBot::Pluggable

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

On a channel with the bot, type @vdm to get a random VDM.

=head1 DESCRIPTION

IRC frontend for the WWW::VieDeMerde module.

=head1 IRC USAGE

@vdm or @vdm cmd

Currently there are no commands implemented.

=head1 METHODS (it's not interesting)

=head2 said

Read the commands and return the answers.

=head2 help

Display the help

=head2 render_item

Format an item for displaying

=head2 render_comment

Format an comment for displaying

=head1 AUTHOR

Olivier Schwander, C<< <iderrick at cpan.org> >>

=head1 BUGS

The comment returned by 'comment #id' may not be the same as the comment
id on the website since deleted comments keeps an id on the website but
are not returned by the API. It may be possible to avoid this by doing a
linear search for a given id in the returned list, but it may be very
slow on IRC.

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-watchlinks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-VieDeMerde>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::VieDeMerde


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-VieDeMerde>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-VieDeMerde>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-VieDeMerde>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-VieDeMerde>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Olivier Schwander, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

