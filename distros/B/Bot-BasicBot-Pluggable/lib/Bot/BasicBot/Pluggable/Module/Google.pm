package Bot::BasicBot::Pluggable::Module::Google;
$Bot::BasicBot::Pluggable::Module::Google::VERSION = '1.20';
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

use Net::Google;

sub init {
    my $self = shift;
    $self->config(
        {
            user_google_key         => "** SET ME FOR GOOGLE LOOKUPS **",
            user_languages          => "en",
            user_num_results        => 3,
            user_require_addressing => 1,
        }
    );
}

sub help {
    return
"Searches Google for terms and spellings. Usage: google <terms>, spell <words>.";
}

sub told {
    my ( $self, $mess ) = @_;
    my $body = $mess->{body};

    return
      if ( $self->get("user_require_addressing") and not $mess->{address} );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "google" ) {
        return
"No Google key has been set! Set it with '!set Google google_key <key>'."
          unless $self->get("user_google_key");
        return
"Your configuration has exceeded the maximum number of allowed Google results (10)."
          if $self->get("user_num_results") > 10;

        my $google = Net::Google->new( key => $self->get("user_google_key") );
        my $search = $google->search(
            lr          => qw($self->get("user_languages")),
            max_results => $self->get("user_num_results")
        );
        $search->query( split( /\s+/, $param ) );

        my $res;    # magical concatenation of all results.
        $res .= $_->title . ": " . $_->URL . "\n" for @{ $search->results() };
        $res =~ s/<[^>]+>//g;    # remove the bolded search terms.

        return $res ? $res : "No results for \'$param\'.";

    }
    elsif ( $command eq "spell" ) {
        return
"No Google key has been set! Set it with '!set Google google_key <key>'."
          unless $self->get("user_google_key");
        my $google = Net::Google->new( key => $self->get("user_google_key") );
        my $res = $google->spelling( phrase => $param )->suggest();
        return $res ? $res : "No results for \'$param\'.";
    }
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Google - searches Google for terms and spellings

=head1 VERSION

version 1.20

=head1 IRC USAGE

=over 4

=item google <terms>

Returns Google hits for the terms given.

=item spell <term>

Returns a Google spelling suggestion for the term given.

=back

=head1 VARS

To set module variables, use L<Bot::BasicBot::Pluggable::Module::Vars>.

=over 4

=item google_key

A valid Google API key is required for lookups.

=item languages

Defaults to 'en'; a space-separated list of language restrictions.

=item num_results

Defaults to 3; the number of Google search results to return (maximum 10).

=item require_addressing

Defaults to 1; whether you need to address the bot for Google searches.

=back

=head1 REQUIREMENTS

L<Net::Google>

L<http://www.google.com/apis/>

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
