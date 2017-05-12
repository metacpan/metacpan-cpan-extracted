# NAME

App::LLEvalBot - IRC bot for LLEval

# SYNOPSIS

    use App::LLEvalBot;
    my $bot = App::LLEvalBot->new(
        config => {
            host     => 'irc.example.com',
            port     => 6667,
            nickname => 'lleval_bot',
            channel  => '#test',
        },
    );
    $bot->run;

# DESCRIPTION

App::LLEvalBot is IRC bot for LLEval.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
