use strict;
use warnings;
use lib '../lib';
use AnyEvent::FTP::Client;

AnyEvent::FTP::Client->new->connect("ftp://localhost:9521/");
