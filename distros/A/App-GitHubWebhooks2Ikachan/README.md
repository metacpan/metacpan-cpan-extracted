[![Build Status](https://travis-ci.org/moznion/App-GitHubWebhooks2Ikachan.png?branch=master)](https://travis-ci.org/moznion/App-GitHubWebhooks2Ikachan)
# NAME

App::GitHubWebhooks2Ikachan - Web server to notify GitHub Webhooks to [App::Ikachan](https://metacpan.org/pod/App::Ikachan)

# SYNOPSIS

    $ githubwebhooks2ikachan --ikachan_url=http://your-ikachan-server.com/notice --port=12345

# DESCRIPTION

App::GitHubWebhooks2Ikachan is the server to notify GitHub Webhooks to [App::Ikachan](https://metacpan.org/pod/App::Ikachan).

Now, this application supports `issues`, `pull_request`, `issue_comment`, `commit_comment`, `pull_request_review_comment` and `push` webhooks of GitHub.

# PARAMETERS

Please refer to the [githubwebhooks2ikachan](https://metacpan.org/pod/githubwebhooks2ikachan).

# USAGE

Please set up webhooks at GitHub (if you want to know details, please refer [http://developer.github.com/v3/activity/events/types/](http://developer.github.com/v3/activity/events/types/)).

Payload URL will be like so;

    http://your-githubwebhooks2ikachan-server.com/${path}?subscribe=issues,pull_request&issues=opened,closed&pull_request=opened

This section describes the details.

- PATH INFO
    - ${path}

        Destination of IRC channel or user to send message. This is essential.
        If you want to send `#foobar` channel, please fill here `%23foobar`.
- QUERY PARAMETERS
    - subscribe

        Event names to subscribe. Specify by comma separated value.
        Now, this application supports `issues`, `pull_request`, `issue_comment`, and `push`.

        If you omit this parameter, it will subscribe the all of supported events.

    - issues

        Action names to subscribe for `issues` event. Specify by comma separated value.
        Now this application supports `opened`, `closed`, and `reopend`.

        If you omit this parameter, it will subscribe the all of supported actions of `issues`.

    - pull\_request

        Action names to subscribe for `pull_request` event. Specify by comma separated value.
        Now this application supports `opened`, `closed`, `reopend`, and `synchronize`.

        If you omit this parameter, it will subscribe the all of supported actions of `pull_request`.

# SEE ALSO

[githubwebhooks2ikachan](https://metacpan.org/pod/githubwebhooks2ikachan)

[http://developer.github.com/v3/activity/events/types/](http://developer.github.com/v3/activity/events/types/).

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
