#!/usr/bin/env perl
use strict;
use Test::More;
use Test::Exception;

use Text::CaffeinatedMarkup::HTMLFormatter;

my $data = "Yup, we're here! Caffeinated Panda Creations has launched the first phase of our new website.\n\nRight now as you can see the blog is up and running and we'll be using it to keep you up to date with projects, events we're involved with, and new features coming to the site. Of course we'll still be streaming updates and content on [[http://facebook.com/caffeinatedpandacreations|facebook]] and [[http://twitter.com/cafpanda|twitter]] as well so come and join us there too!\n\nAs time goes on we'll be adding new sections to the website so stay tuned for updates. Upcoming soon will be more details on our creations and services, so here's some things to whet your appetite!@@||##2|Custom Cyberfalls##{{cyberfalls.jpg|<<,H100,W130}}Cyberfalls for all your cybergoth and dance needs, at Caffeinated Panda Creations we specialise in custom designs and sets with [[https://www.google.co.uk/search?q=el+wire&safe=off&tbm=isch|EL-wire]] installations.\n\nWhether you're looking for a themed set for a special occassion or straight forward cyber-chic, get in touch and we'll be happy to work with you!||##2|xD Printing##{{makerbot.jpg|<<,H100,W130}}We here at Caffeinated Panda Creations are the proud owners of a [[http://store.makerbot.com/replicator2.html|Makerbot Replicator 2]] 3D printer.\n\nAs well as using it for our creations we can also offer a bespoke printing service. Design your own objects or let us work with you to create and realise your vision in high quality PLA plastic.@@ @@||##2|Emporia##{{etsy.jpg|<<,H100,W130}}Over the next few months we'll be opening our online stores where we'll be selling some of our premade and customisable pieces along with t-shirts and other apparel.||##2|Costuming##{{mask.jpg|<<,H100,W130}}The panda team are keen costumers and going forward will be working on several exciting cosplaying projects for ourselves and others.\n\nWe'll also be keeping you up to date on where we'll be appearing and giving details on how we can work with you on your own costuming projects.@@";

my $formatter = Text::CaffeinatedMarkup::HTMLFormatter->new;
lives_ok{$formatter->format($data)} "Document #1 parse ok";

done_testing();
