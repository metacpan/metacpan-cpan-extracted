# App::Beeminder::Hook - Hook up Github to Beeminder

This is a dead-simple Dancer app that eats Github post-receive hook JSON and
submits it to the awesome [Beeminder](http://beeminder.com) API.

# Why the hell would I want to use this?

There is an interesting movement called the "quantified self". Basically:
measure everything! Everybody is interested in measuring different things.

I first started using Beeminder to track my
[weight](https://www.beeminder.com/dukeleto/goals/weight). If you have ever
heard of the "Hacker Diet", it basically automates all the tracking and
visualization. You just need to submit the data.

That is all fine and dandy for reporting a single number once a day. But then I wanted to keep track of how productive I was being on Github. Trying to estimate how much time I spent coding and submitting that data was a big fail. I am too lazy for that. Github post-receive URLs to the rescue!

This repo allows you to automate submitting data to Beeminder by setting
post-receive URLs. Now you can keep track of your coding productivity with
maximum laziness!

# Show me an example already!

Take a look at my ["Total Number of Github commits" Beeminder goal](https://www.beeminder.com/dukeleto/goals/github_commits).

You will notice that every time I push to Github, it submits a datapoint to Beeminder consisting of:

 * The current day
 * Number of commits
 * the organization + repo of the commits

# How Do I use this?

 * Go to [Beeminder](http://beeminder.com) and create a free account
 * Create a new goal with a type of "Do More"
 * Install App::Beeminder::Hook from Github

    git clone git://github.com/letolabs/App-Beeminder-Hook.git

 * If you don't want to use Git, you can also download a tarball from CPAN:

   wget http://www.cpan.org/authors/id/L/LE/LETO/App-Beeminder-Hook-0.001.tar.gz

 * Go into the source directory

    cd App-Beeminder-Hook

 * Change the beeminder* config values in config.yml to match your username and goal name. Set your origin to "$username_api"

 * Install dependencies with cpan or better yet, cpanm:

    cpanm Dancer YAML JSON::Any

 * Or with Dist::Zilla

    dzil listdeps | cpanm

 * Start this dancer app via

    perl bin/app.pl --port 5000

 * (Port 5000 is just an example. Run it on any port you want).
 * Add a post-receive hook to any Github repo you want to keep track of. For instance, if the hostname of your app is "foo.com", set you post receive URL to:

    http://foo.com:5000/hook

# Requirements

 * [Perl](http://perl.org) 5.10 or higher
 * [Dancer](http://perldancer.org)
 * curl

# I want this to do something else!

This is just the beginning. If you would like to track more than just your
number of commits, that is awesome! Pull requests are very welcome.

# Thanks

Thanks to Daniel Reeves and Bethany Soule for making Beeminder! It rocks.

# Author

Jonathan "Duke" Leto
