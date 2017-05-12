# NAME

App::Nopaste::Service::Dancebin - nopaste service for [Dancebin](http://search.cpan.org/perldoc?Dancebin)

# VERSION

version 0.004

# SYNOPSIS

[Dancebin](https://github.com/throughnothing/Dancebin) Service for [nopaste](http://search.cpan.org/perldoc?nopaste).

To use, simple use:

    $ echo "text" | nopaste -s Dancebin

By default it pastes to [http://danceb.in/](http://danceb.in/), but you can
override this be setting the `DANCEBIN_URL` environment variable.

You can set HTTP Basic Auth credentials to use for the nopaste service
if necessary by using:

    DANCEBIN_USER=username
    DANCEBIN_PASS=password

The expiration of the post can be modified by setting the `DANCEBIN_EXP`
environment variable.  Acceptable values are things like:

    DANCEBIN_EXP=weeks:1
    DANCEBIN_EXP=years:1:months:2
    DANCEBIN_EXP=weeks:1:days:2:hours:12:minutes:10:seconds:5
    DANCEBIN_EXP=never:1  # Never Expire

# AUTHOR

William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE



William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.