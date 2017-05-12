#!/usr/bin/perl
# 
# This example show you that ->param() called with a list name 
# gives you the reference to the actual structure of the object. 
# Therefore, modifying the values (or even the references) means 
# modifying the object. 
# 
use strict;
use Config::Natural;

my $config = new Config::Natural \*DATA;

my $users = $config->param('user');

# Now we walk along the tree of data in order to
# modify the email address of each user
my @n = qw(rei ichi ni san);
for my $user (@$users) {
    $user->{'mail'} =~ s/^user(\d+)/$n[$1]/;
}

# For debugging, we change the SMTP relay server
# and the 'debug' parameter
$config->param({ debug => 1,  relay => 'localhost' });

print $config->dump_param;


__END__

debug = 0
relay = smtp.domain.net

user {
    name = First User
    mail = user1@domain.net
}

user {
    name = Second User
    mail = user2@domain.net
}

user {
    name = Third User
    mail = user3@domain.net
}

