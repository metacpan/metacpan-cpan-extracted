# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 7 };
use Data::Fallback;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use strict;
use Data::Fallback;
use Carp qw(confess);

# I use dumper just to show some complex structures
use Data::Dumper;

# here I write out a couple files which I later clean up
# the idea is that the over file, overrides the default file

my $over_file    = "/tmp/data_fallback_over";
my $default_file = "/tmp/data_fallback_default";

open (FILE, ">$over_file") || confess "couldn't open $over_file: $!";
print FILE "key2 over2";
close(FILE);

open (FILE, ">$default_file") || confess "couldn't open $default_file: $!";
print FILE "key1 default1\nkey2 default2";
close(FILE);

my $self = Data::Fallback->new({

# list is an array ref of hash refs to fall through looking for data

list => [
{
# accept_update says to update the conf
  accept_update => 'group',

# this means to cache everything
cache_level => 'all',

# where to get the content
content => $over_file,
},
{
  cache_level => 'all',
  content     => $default_file,
},
],

# need to name list
list_name => 'test',

# object global for package
package => 'ConfFile',

zeroth_hash => {
  ttl => '5 seconds',
},
});
my $back1 = $self->get('key2');
print "\$back1 = '$back1'\n";
print Dumper $self->{history};
ok($back1 eq 'over2');

my $back2 = $self->get('key2');
print "\$back2 = '$back2'\n";
print Dumper $self->{history};
ok($back2 eq 'over2');

my $back3 = $self->get('key1');
print "\$back3 = '$back3'\n";
print Dumper $self->{history};
ok($back3 eq 'default1');

my $back4 = $self->get('key1');
print "\$back4 = '$back4'\n";
print Dumper $self->{history};
ok($back4 eq 'default1');

my $back5 = $self->get('key2');
print "\$back5 = '$back1'\n";
print Dumper $self->{history};
ok($back5 eq 'over2');

ok(unlink $over_file, $default_file);
