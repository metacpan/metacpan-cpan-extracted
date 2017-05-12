package Bot::BasicBot::Pluggable::Module::MetaSyntactic;
{
  $Bot::BasicBot::Pluggable::Module::MetaSyntactic::VERSION = '1.004';
}

use strict;
use warnings;
use Carp;
use Bot::BasicBot::Pluggable::Module;
use Acme::MetaSyntactic ();
use Text::Wrap;

our @ISA     = qw(Bot::BasicBot::Pluggable::Module);

my $META = Acme::MetaSyntactic->new()
    or carp "fatal: Can't create new Acme::MetaSyntactic object";

sub init {
    my $self = shift;

    $self->{meta} = {
        limit => 100,
        wrap  => 256,
    };

    $Text::Wrap::columns = $self->{meta}{wrap};
}

sub told {
    my ( $self, $mess ) = @_;
    my $bot = $self->bot();

    # we must be directly addressed
    return
        if !(   (   defined $mess->{address}
                    && $mess->{address} eq $bot->nick()
                )
                || $mess->{channel} eq 'msg'
        );

    # ignore people we ignore
    return if $bot->ignore_nick( $mess->{who} );

    # only answer to our command (which can be our name too)
    my $src = $bot->nick() eq 'meta' ? 'raw_body' : 'body';
    return if $mess->{$src} !~ /^\s*meta(.*)/i;

    # ignore the noise
    ( my $command = "$1" ) =~ s/^\W*//;

    # pick up the commands
    ( $command, my @args ) = split /\s+/, $command;
    return if !$command || !length $command;

    # it's a theme
    if ( $command =~ /^[-\w\/]+$/ ) {
        my ( $theme, $category ) = split m'/', $command, 2;
        $self->{meta}{theme}{$command} //= _load_theme($theme, $category);
        return "No such theme: $theme"
            if !$META->has_theme($theme);
        if ( $category && $self->{meta}{theme}{$command}
            ->isa('Acme::MetaSyntactic::MultiList')
            && !grep { $_ eq $category }
            $self->{meta}{theme}{$command}->categories )
        {
            delete $self->{meta}{theme}{$command};
            return "No such theme/category: $theme/$category";
        }

        # compute the list of items
        my ( $num, $re );
        for my $arg (@args) {
            if ( $arg =~ /^[0-9]+$/ ) { $num //= $arg; }
            elsif ( $arg =~ m{^/([^\/]*)/$} ) {
                $re = eval {qr/$1/}
                    or do { ( my $err = $@ ) =~ s/ at .*//s; return $err; }
            }
            else {return}    # can't parse this argument
        }

        # enforce the limit if explicitely asked for more
        $num //= 1;
        $num = $self->{meta}{limit} if $num > $self->{meta}{limit};

        my $meta  = $self->{meta}{theme}{$command};
        my @items = $meta->name( $re ? 0 : $num );
        if ($re) {    # NOTE: the extra loop is never run if $num == 0
            @items = grep /$re/, @items;
            splice @items, $num if $num && @items > $num;
            push @items, grep /$re/, $meta->name(0)
                while @items && @items < $num;
        }
        splice @items, $self->{meta}{limit}    # enforce the limit
            if @items > $self->{meta}{limit};
        return join ' ', @items;
    }

    # it's a command
    elsif ( $command eq 'themes?' ) {
        my @themes = $META->themes();
        return join ' ', scalar @themes, 'themes available:', @themes;
    }
    elsif ( $command eq 'categories?' ) {
        return if !@args;
        my $theme = shift @args;
        $self->{meta}{theme}{$theme} //= _load_theme($theme);
        return "No such theme: $theme"
            if !$META->has_theme($theme);
        return "Theme $theme does not have any categories"
            if !$self->{meta}{theme}{$theme}
                ->isa('Acme::MetaSyntactic::MultiList');
        return join ' ', "Categories for $theme:",
            sort $self->{meta}{theme}{$theme}->categories;
    }
}

sub _load_theme {
    my ($theme, $category) = @_;
    my $module = "Acme::MetaSyntactic::$theme";
    return eval "require $module" || $META->has_theme($theme)
        ? $module->new( ( category => $category ) x !!$category )
        : '';
}

sub help {'meta theme [count]'}

1;

# ABSTRACT: IRC frontend to Acme::MetaSyntactic


__END__
=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::MetaSyntactic - IRC frontend to Acme::MetaSyntactic

=head1 VERSION

version 1.004

=head1 SYNOPSIS

    < you> bot: meta batman
    < bot> kapow

=head1 DESCRIPTION

This module is a frontend to the L<Acme::MetaSyntactic> module which
will let you pick metasyntactical variables names while chatting over IRC.

This module takes inspiration from the first IRC metasyntactic bot:
L<Bot::MetaSyntactic> in some of its behaviour and messages.

=head1 IRC USAGE

The bot will accept a number of commands:

=head2 Theme commands

These commands return items from L<Acme::MetaSyntactic> themes.

=over 4

=item C<< meta <theme> [ <count> ] [ /regexp/ ] >>

return one or more items from the theme.

Items are picked at random from the list, and not repeated until the list
is exhausted.

This will pick the default category if the theme has multiple categories.

=item C<< meta <theme>/<category> [ <count> ] [ /regexp/ ] >>

return one or more items from the theme sub-categories.

The bot maintains state for each theme/category, so items can be picked
from sub-categories of the same theme independently.

=back

If I<count> is C<0>, then the whole list if returned (which does not
disturb the partially consumed list from the non-zero use case).
Note that there is a limit to the number of items returned, so that the
bot does not accidentaly spam a channel.

If a I</regexp/> is given, only items that match the regular expression
will be shown. With a I<count> of C<0>, I<all> matching items are
returned.  The filtering is done on the whole list, so it has no influence
on the state of non-filtered request (with regard to repetition).

=head2 Meta (sic) commands

These commands allow to query the L<Acme::MetaSyntactic> themes:

=over 4

=item C<meta themes?>

return the list of available themes.

=item C<meta categories? I<theme>>

return the list of categories for the given theme.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>,
L<Bundle::MetaSyntactic>,
L<Bot::MetaSyntactic>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Philippe Bruhat (BooK).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

