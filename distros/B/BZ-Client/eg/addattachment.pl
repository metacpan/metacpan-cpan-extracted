#!/usr/bin/env perl
#
use strict;
use warnings;

use Data::Printer;

use BZ::Client;
use BZ::Client::Bug;
use BZ::Client::Bug::Attachment;

my $bz = BZ::Client->new(
    'api_key' => '8k2xZlv666WTk0hCtJtuFqcRecwpo3lHG0GJefqp',
    url => 'https://landfill.bugzilla.org/bugzilla-5.0-branch/',
#'user' => 'djzort@cpan.org',
#'password' => 'cvuA6REFGLrRNU-K',
#url => 'https://landfill.bugzilla.org/bugzilla-4.4-branch/',


    logDirectory => '/tmp/bz',
);

#my $no = 5125 ; # 42508
my $no = 42508;

# my $file = '/tmp/609299a1128b20719e1ce667a0b10bd8bd11267167e1ab5fbe3af6fb74cd30f9.jpg';
my $file = '/tmp/12744439_2664974946883012_3972108356638394498_n.jpg';

eval {

my $bug = BZ::Client::Bug::Attachment->add( $bz,
{
ids => [ $no ],
file_name => $file,
summary => 'Hello',
content_type => 'image/jpeg',
} );

p $bug;

};
if ($@) {
p $@
}

#my $attachment = $bug->{bugs}->{42508}->[0];

# p $attachment;

#my $data = $attachment->data();

# p $data;
