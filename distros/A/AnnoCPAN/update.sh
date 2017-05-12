#!/bin/bash

#cd ~/annocpan
date=`date +%Y-%m-%d`
rsync -av --delete rsync.nic.funet.fi::CPAN ~/CPAN >rsync.log.$date 2>rsync.err.$date
~/bin/perl -Mblib bin/annocpan_load -v ~/CPAN 2>err.$date >log.$date
~/bin/perl -Mblib bin/ac_recent_dists_rss > html/recent_dists.rss
