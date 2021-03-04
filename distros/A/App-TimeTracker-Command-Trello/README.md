# NAME

App::TimeTracker::Command::Trello - App::TimeTracker Trello plugin

# VERSION

version 1.008

# DESCRIPTION

This plugin takes a lot of hassle out of working with Trello
[http://trello.com/](http://trello.com/).

Using the Trello plugin, tracker can fetch the name of a Card and use
it as the task's description; generate a nicely named `git` branch
(if you're also using the `Git` plugin); add the user as a member to
the Card; move the card to various lists; and use some hackish
extension to the Card name to store the time-worked in the Card.

# CONFIGURATION

## plugins

Add `Trello` to the list of plugins.

## trello

add a hash named `trello`, containing the following keys:

### key \[REQUIRED\]

Your Trello Developer Key. Get it from
[https://trello.com/1/appKey/generate](https://trello.com/1/appKey/generate) or via `tracker
setup_trello`.

### token \[REQUIRED\]

Your access token. Get it from
[https://trello.com/1/authorize?key=YOUR\_DEV\_KEY&name=tracker&expiration=1day&response\_type=token&scope=read,write](https://trello.com/1/authorize?key=YOUR_DEV_KEY&name=tracker&expiration=1day&response_type=token&scope=read,write).
You maybe want to set a longer expiration timeframe.

You can also get it via `tracker setup_trello`.

### board\_id \[SORT OF REQUIRED\]

The `board_id` of the board you want to use.

Not stictly necessary, as we use ids to identify cards.

If you specify the `board_id`, `tracker` will only search in this board.

You can get the `board_id` by going to "Share, print and export" in
the sidebar menu, click "Export JSON" and then find the `id` in the
toplevel hash. Or run `tracker setup_trello`.

### member\_id

Your trello `member_id`.

Needed for adding you to a Card's list of members. Currently a bit
hard to get from trello, so use `tracker setup_trello`.

### prefix

Default: `trello:`

Add this prefix to the card name when storing it as tag. Useful to
discern regular tags from card name pseudo tags.

### update\_time\_worked

If set to true, updates the time worked on this task on the Trello Card.

As Trello does not provide time-tracking (yet?), we store the
time-worked in some simple markup in the Card name:

    Callibrate FluxCompensator [w:32m]

`[w:32m]` means that you worked 32 minutes on the task.

Context: stopish commands

### listname\_as\_tag

If set to true, will fetch the name of the list the current card
belongs to and store the name as an additional tag, unless the list name matches `/^(todo|doing|done|review)$/i`

Context: startish commands

# NEW COMMANDS

## setup\_trello

    ~/perl/Your-Project$ tracker setup_trello

This will launch an interactive process that walks you throught the setup.

Depending on your config, you will be pointed to URLs to get your
`key`, `token` and `member_id`. You can also set up a `board_id`.
The data will be stored in your global / local config.

You will need a web browser to access the URLs on trello.com.

### --token\_expiry \[1hour, 1day, 30days, never\]

Token expiry time when a new token is requested from trello. Defaults
to '1day'.

'never' is the most comfortable option, but of course also the most
insecure.

Please note that you can always invalidate tokens via trello.com (go
to Settings/Applications)

# CHANGES TO OTHER COMMANDS

## start, continue

### --trello

    ~/perl/Your-Project$ tracker start --trello s1d7prUx

    ~/perl/Your-Project$ tracker start --trello https://trello.com/c/s1d7prUx/card-title

If `--trello` is set and we can find a card with this id:

- set or append the Card name in the task description ("Rev up FluxCompensator!!")
- add the Card id to the tasks tags ("trello:s1d7prUx")
- if `Git` is also used, determine a save branch name from idShort and the Card name, and change into this branch ("42\_rev\_up\_fluxcompensator")
- add member to list of members (if `member_id` is set in config)
- move to `Doing` list (if there is such a list, or another list is defined in `list_map` in config)

<C--trello> can either be the full URL of the card, or just the card
id. If you don't have access to the URL, click the 'Share and more'
link (rather hard to find in the bottom right corner of a card).

If `listname_as_tag` is set, will store the name of the card's list as a tag.

## stop

- If &lt;update\_time\_worked> is set in config, adds the time worked on this task to the Card.

### --move\_to

If --move\_to is specified and a matching list is found in `list_map` in config, move the Card to this list.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
