# Adam/Moses Bot Framework

This framework is based on the work I've done over the last (OMG!) decade with
the Bender IRC bot on [irc.perl.org](irc://irc.perl.org).

## Synopsis

Download the [tarball][1] or clone the github repository.

 > wget --no-check-certificate https://github.com/perigrin/adam-bot-framework/tarball/master

 > git clone git://github.com/perigrin/adam-bot-framework.git
 
Then if you need to untar the file, and change into the directory.

 > tar -xvzf adam-bot-framework*.tar.gz
 > cd adam-bot-framework

Now that you're in the directory you can use `cpanminus` to install the dependencies.

 > curl -L http://cpanmin.us | perl - -L cpan/ --installdeps .

Once that is done you should be able to run one of the example scripts.

 > perl -Ilib -Icpan/lib/perl5 examples/ncbot.pl

[1]: https://github.com/perigrin/adam-bot-framework/tarball/master