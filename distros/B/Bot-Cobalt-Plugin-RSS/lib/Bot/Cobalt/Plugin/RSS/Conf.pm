package Bot::Cobalt::Plugin::RSS::Conf;

sub conf { local $/; my $cf = <DATA>; return $cf }

1

__DATA__
---
## Bot::Cobalt::Plugin::RSS plugin configuration

Feeds:

## These are your configured feeds and where they should go.
## Format:
##
##  $NAME:
##    URL: <url>
##    Delay: <seconds>  # defaults to 120
##    Spaced: <seconds> # defaults to 5
##    AnnounceTo:
##      $CONTEXT_NAME:
##        - '#channelA'
##        - '#channelB'
##
## If a feed is fairly active, you may want to crank Delay down 
## and Spaced up; Spaced determines the interval between message 
## dispatches to IRC, which is useful for feeds that tend to publish 
## a lot of headlines in one go.
##
## Example of a configured Feed:

#  CPANTest:
#    URL: 'http://www.cpantesters.org/author/A/AVENJ.rss'
#    Delay: 300
#    Spaced: 60
#    AnnounceTo:
#      Main:
#        - '#eris'
#        - '#unix'
