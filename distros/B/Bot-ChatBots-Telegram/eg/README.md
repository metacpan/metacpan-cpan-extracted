# Examples

This directory contains examples of using `Bot::ChatBots::Telegram`:

- `longpoll`: based on a "long polling", i.e. constantly asking the
  server for new messages in polling mode. The "business logic" does
  little more than echo what is received.

- `webhook`: same business logic as `longpoll` above, just a different
  way of getting messages, i.e. being notified about them.

To use both, you need to generate a token for your bot through the
special Telegram bot `BotFather`. The token can be used directly on
the command line with the first program:

    $ ./longpoll $TOKEN

The second program needs a place to be installed and run, as well as
exposing an HTTPS type of endpoint, so you need to do an extra mile
to see it at work.
