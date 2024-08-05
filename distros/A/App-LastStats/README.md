laststats
=========

I've been scrobbling my music for a very long time. I really like being able
to look back and see my tastes change as I listen to different artists over
time.

One of the nice tools built on top of scrobbling was
[Tweekly.fm](https://tweekly.fm/) which posted a brief list of my most
listened to artists to Twitter every weekend. Sadly, when Elon Musk took
over Twitter, he made it prohibitively expensive for services like that
to continue so the owner of the service, very sensibly, closed the service
down.

This is a very quick program that starts to replicate the logic behind
Tweekly.fm. It lists your ten most listened-to artists over the last
seven days.

Currently, it just prints that list to the terminal. I'll probably work
out a way to display the output publicly at some point.

## Command line options

* `--user` : Last.fm username (defaults to "davorg")
* `--count` : The number of artists to display (defaults to 10)
* `--format` : The format to display results in. Can be "text", "html" or "json" (defaults to "text")
* `--period` : The time period for the stats. Can be "overall", "7day", "1month", "3month", "6month", "12month" (defaults to "7day")
* `--api-key` : Last.fm API key
* `--api-secret` : Last.fm API secret

The values for `--api-key` and `--api-secret` can alternatively be read from
environment variables called `LASTFM_API_KEY` and `LASTFM_API_SECRET`.

## API KEY

As shown above, you will need an API key and secret. You can get these from:

* https://www.last.fm/api/account/create

