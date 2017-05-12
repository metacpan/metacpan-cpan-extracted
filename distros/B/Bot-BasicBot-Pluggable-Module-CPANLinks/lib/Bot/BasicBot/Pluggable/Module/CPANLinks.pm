# A quick Bot::BasicBot::Pluggable module to provide easy links when someone
# mentions CPAN modules
# David Precious <davidp@preshweb.co.uk>

package Bot::BasicBot::Pluggable::Module::CPANLinks;
use strict;
use base 'Bot::BasicBot::Pluggable::Module';
use Module::Load;
use URI::Title;
use 5.010;

our $VERSION = 0.02;

=head1 NAME

Bot::BasicBot::Pluggable::Module::CPANLinks - provide links to CPAN module docs

=head1 DESCRIPTION

A module for L<Bot::BasicBot::Pluggable>-powered IRC bots, to automatically
provide links to documentation when people mention certain CPAN modules or
keywords.  Can be configured to only respond to modules in certain namespaces on
a per-channel basis.

=head1 HOW IT WORKS

If someone's message looks like it contains a CPAN module name (e.g.
C<Foo::Bar>), this plugin will look for the bot setting
C<filter_$channel> where C<$channel> is the channel that the user
spoke in - so, e.g. C<filter_#dancer>.  If this setting exists, its
value should be a regular expression; if the module name matches this
expression, the plugin will look up that module, and, if it exists, provide a
link to it (unless it has done so more recently than the configurable
threshold).

Similarly, if someone says something like "the session keyword" or similar, the
plugin will check if C<keywords_$channel> exists and is set to a
package name; if it does, it will make sure that package is loaded, check if
that package C<can($keyword)>, and if so, will provide a link to the
documentation for that keyword.

So, for example, in the C<#dancer> channel, C<keywords_#dancer> would
be set to C<Dancer> - so if I say "the session keyword", the plugin will check
if C<Dancer->can('session')> to check it's a valid keyword, and if so, will
provide a link to the docs.

WARNING: this setting causes the named package to be loaded; that means that
anyone who can configure your bot from IRC can cause a package of their choosing
to be loaded into your bot.  It must be a package which is already installed on
your system, of course, but it deserves that warning.

=head1 CONFIGURATION

See L<Bot::BasicBot::Pluggable::Module::Vars> for details on how to set the
appropriate config options in your bot's store (or do it directly in the DB, if
you prefer).

The settings to set up are:

=over

=item C<filter_channelname>

Set the pattern which module names must match for a given channel.  If this
setting doesn't exist for the channel, nothing will be linked.

For example, for C<#dancer>, C<filter_#dancer> is set to C<^Dancer>.

=item C<keywords_channelname>

Set the package from which keywords are linked for a given channel.  If this
setting doesn't exist for the channel, no keywords will be linked.

If you want to use this, set this setting to the name of the package keywords
should be looked for in - for instance, for C<#dancer>, C<keywords_#dancer> is
set to C<Dancer>.  So, if I mention e.g. "see the session keyword", the bot will
check if C<Dancer->can('session')>, see that that's a valid keyword, and will
provide a link to the docs.

Be aware that using this setting means the named package will be loaded; this
means anyone who can configure your bot can cause a package of their choosing to
be loaded.  However, it's loaded by L<Module::Load> at runtime, so no importing
will be done, and it can only be a package installed on your system.  It's still
something to be aware of, though, if you think there's a possibility of code in
your C<@INC> that you wouldn't want your bot to load.

=item C<dupe_gap>

How many seconds between successive mentions of the same module name / keyword
to wait before providing a link again.  Nobody wants the bot to respond with a
link every time a given module name is mentioned.  If not set, defaults to a
sensible value.

=back

=cut

sub help {
    return <<HELPMSG;
A quick plugin for use on IRC channels to provide links to module /
keyword documentation.

See the plugin's documentation on CPAN for full details and source: 
http://p3rl.org/Bot-BasicBot-Pluggable-Module-CPANLinks
HELPMSG
}

my %link_said;
sub said {
    my ($self, $mess, $pri) = @_;
    
    return unless $pri == 2;
    my $link;
    if (my ($module) = $mess->{body} =~ /\b((?:\w+::)+\w+)\b/) {
        warn "Think I have a module mention: " . $module;
        my $key = lc $mess->{channel};
        my $filter_pattern = $self->get("filter_" . lc $mess->{channel}) 
            or return 0;
        warn "Checking if this matches pattern $filter_pattern";
        return 0 unless $module =~ /$filter_pattern/i;

        # OK, this looks like a module name which matches the pattern for this
        # channel, awesome:
        my $url = "http://p3rl.org/$module";
        my $title = URI::Title::title($url);
        if ($title) {
            $title =~ s/^$module - //;
            $title =~ s/- metacpan.+//;
            $link = "$module is at http://p3rl.org/$module ($title)";
        }
    }


    # OK, if the message contains "the ... keyword" and the channel supports
    # keywords for a given module (e.g. Dancer), see if this is a valid keyword,
    # and if so, link to the docs for it
    if (my $keywords_from 
        = $self->get('keywords_' . lc $mess->{channel}) 
        and $mess->{body} =~ m{
            (
            # match"the keyword forward", "the keyword 'forward", etc
            the \s keyword \s ['"]? (?<keyword> [a-z_-]+) ['"]?
            |
            # or "forward keyword, "'forward' keyword, "forward() keyword" etc
            \b['"]? (?<keyword> [a-z_-]+) ['"]? (?:\(\))? \s keyword
            )
        }xm
    ) {
        my $keyword = $+{keyword};
        warn "Mentioned keyword $keyword from $keywords_from, checking it";
        Module::Load::load($keywords_from);

        if ($keywords_from->can($keyword)) {
            $link = "The $keyword keyword is documented at "
                . "http://p3rl.org/$keywords_from#$keyword";
        }
    }

    # Announce the link we found, unless we already did that recently
    my $threshold_secs = $self->get('dupe_gap') || 600;
    if ($link && (time - $link_said{$link}) > $threshold_secs) {
        $link_said{$link} = time;
        return $link;
    }

    return 0; # This message didn't interest us
}


=head1 HOSTED OPTION

If you like the idea of this but don't want to go to the effort of setting it
up, I have a bot on C<irc.perl.org> already running it, which I'd be happy to
add to your channel and configure appropriately for you - just drop me a mail.


=head1 AUTHOR

David Precious (bigpresh) C<< <davidp@preshweb.co.uk> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
1;

