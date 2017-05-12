package Bot::Backbone::Service::Fact::Keyword;
{
  $Bot::Backbone::Service::Fact::Keyword::VERSION = '0.142250';
}
use Bot::Backbone::Service;

# ABSTRACT: Memorize keywords and respond to them when mentioned

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
    Bot::Backbone::Service::Role::Storage
);


service_dispatcher as {
    command '!keyword' => given_parameters {
        parameter 'keyword' => ( match => qr/.+/ );
        parameter 'response' => ( match_original => qr/.+/ );
    } run_this_method 'learn_keyword';

    command '!forget_keyword' => given_parameters {
        parameter 'keyword' => ( match => qr/.+/ );
        parameter 'response' => ( match_original => qr/.+/ );
    } run_this_method 'forget_keyword';

    command '!forget_keyword' => given_parameters {
        parameter 'keyword' => ( match => qr/.+/ );
    } run_this_method 'forget_keyword';

    also not_command spoken respond_by_method 'recall_keyword_sometimes';
};


has frequency => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
    default     => 0.1,
);


sub load_schema {
    my ($self, $db_conn) = @_;

    $db_conn->run(fixup => sub {
        $_->do(q[
            CREATE TABLE IF NOT EXISTS fact_keywords(
                keyword TEXT,
                response TEXT,
                PRIMARY KEY (keyword, response)
            )
        ]);
    });
}


sub learn_keyword {
    my ($self, $message) = @_;

    my $keyword = $message->parameters->{keyword};
    my $response = $message->parameters->{response};

    $self->db_conn->run(fixup => sub {
        $_->do(q[
            INSERT OR IGNORE INTO fact_keywords(keyword, response)
            VALUES (?, ?)
        ], undef, $keyword, $response);
    });

    return 1;
}


sub forget_keyword {
    my ($self, $message) = @_;

    my $keyword = $message->parameters->{keyword};
    my $response = $message->parameters->{response};

    if ($response and $response =~ /\S/) {
        $self->db_conn->run(fixup => sub {
            $_->do(q[
                DELETE FROM fact_keywords
                WHERE keyword = ? AND response = ?
            ], undef, $keyword, $response);
        });
    }
    else {
        $self->db_conn->run(fixup => sub {
            $_->do(q[
                DELETE FROM fact_keywords
                WHERE keyword = ?
            ], undef, $keyword);
        });
    }

    return 1;
}


sub recall_keyword_sometimes {
    my ($self, $message) = @_;

    return unless rand() < $self->frequency;

    my @words = map { $_->text } $message->all_args;
    my $qlist = join ', ', ('?') x scalar @words;
    my ($response) = $self->db_conn->run(fixup => sub {
        $_->selectrow_array(qq[
            SELECT response
              FROM fact_keywords
             WHERE keyword IN ($qlist)
          ORDER BY RANDOM()
             LIMIT 1
        ], undef, @words);
    });

    return unless $response;
    return $response;
}


sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Bot::Backbone::Service::Fact::Keyword - Memorize keywords and respond to them when mentioned

=head1 VERSION

version 0.142250

=head1 SYNOPSIS

    # in the bot config
    service keyword => (
        service   => 'Fact::Keyword',
        frequency => 0.25,
    );

    # in the chat
    alice> !keyword bot That's my name, don't wear it out.
    alice> hello bot
    alice> i said bot, hello
    alice> you dumb bot
    bot> That's my name, don't wear it out.
    alice> !forget_keyword bot

=head1 DESCRIPTION

Allows members of the chat to establish a set of keywords that the bot can
respond to a configurable percentage of the time. Each keyword can have more
than one response associated with it, in which case, a response is chosen at random.

=head1 DISPATCHER

=head2 !keyword

  !keyword name text of the response

This is used to tell the bot to memorize a keyword. The first word given ot the command is the keyword to trigger on. The remainder is the response to the bot should give when it encounters the keyword.

=head2 !forget_keyword

  !forget_keyword name
  !forget_keyword name text of the response

This command allows the chat user to tell the bot to forget the a keyword or particular response. In the first form, all responses to the keyword that have been memorized will be deleted. In the second form, only the response given for that keyword will be forgotten.

=head1 ATTRIBUTES

=head2 frequency

This is a value between 0 and 1 that determines how often the bot will search chat texts for keywords. The reason for this is twofold:

=over

=item 1.

If the bot always responded to every keyword, it's likely the bot would become annoying in most cases.

=item 2.

There's a small performance penalty with the way this works. The bot has to use every word in the text to search for a keyword. Chances are this is not a big problem, but it exists.

=back

=head1 METHODS

=head2 load_schema

This is used by the L<Bot::Backbone::Service::Role::Storage> role to setup the
C<fact_keywords> table used to store keywords for use with this service.

=head2 learn_keyword

This implements the C<!keyword> command to memorize keywords.

=head2 forget_keyword

This implements teh C<!forget_keyword> command to forget keywords.

=head2 recall_keyword_sometimes

This searches texts in the chat according to the L</frequency> setting for
keywords. If a keyword is found on one of those searches, the response
will be sent back to the chat.

=head2 initialize

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
