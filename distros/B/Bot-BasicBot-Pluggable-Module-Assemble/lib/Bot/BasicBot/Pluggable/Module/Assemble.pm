package Bot::BasicBot::Pluggable::Module::Assemble;

use strict;
use Bot::BasicBot::Pluggable::Module;
use Regexp::Assemble;

use vars qw( @ISA $VERSION );
@ISA     = qw(Bot::BasicBot::Pluggable::Module);
$VERSION = '0.03';

sub told {
    my ( $self, $mess ) = @_;
    my $bot = $self->bot();

    # we must be directly addressed
    return
        if !( ( defined $mess->{address} && $mess->{address} eq $bot->nick() )
        || $mess->{channel} eq 'msg' );

    # ignore people we ignore
    return if $bot->ignore_nick( $mess->{who} );

    # only answer to our command (which can be our name too)
    my $src = $bot->nick() eq 'assemble' ? 'raw_body' : 'body';
    return if $mess->{$src} !~ /^\s*assemble(.)(.*)/i;

    # grab the parameter list
    my ( $delim, $args ) = ( $1, $2 );
    my @args = grep { $_ ne '' } split /\Q$delim\E+/, $args;

    # ignore short lists
    return if @args < 2;

    # compute the assembled regexp and return it
    return Regexp::Assemble->new()->add( @args )->as_string();
}

sub help {'assemble regex1 regex2 regex3'}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Assemble - IRC frontend to Regexp::Assemble

=head1 SYNOPSIS

    < you> bot: assemble ab+c ab+- a\w\d+ a\d+
    < bot> a(?:\w?\d+|b+[-c])

=head1 DESCRIPTION

This module is a frontend to the excellent C<Regexp::Assemble> module
which will let you get optimised regular expressions while chatting
over IRC.

=head1 IRC USAGE

If the regular expressions you want to assemble do not contain
whitespace, separate the regexp elements with any number of space
charaters:

    assemble Mr Mrs Ms Miss

to which the bot will reply:

    (?:M(?:(?:is)?s|rs?))

If you want to use another delimiter (presumably because you have space
characters in your regular expressions), simply attach it to the command:

    assemble!YI SYLLABLE HNI!YI SYLLABLE MGUR
    
to which the bot will reply:

    (?:YI SYLLABLE (?:MGUR|HNI))

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bot-basicbot-pluggable-module-assemble@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/>. I will be notified, and
then you'll automatically be notified of progress on your bug as I
make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2010 Philippe Bruhat (BooK), All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
