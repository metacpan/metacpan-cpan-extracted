#!/usr/bin/env perl
use Modern::Perl '2012';
use FindBin qw($Bin);
use lib "$Bin/../lib";
use <% dist_module %>;
use <% dist_module %>::Schema;
use Getopt::Long;
GetOptions(
    'user|u=s' => \(my $user_name = 'admin'),
    'password|p=s' => \my $password
);
die "need --password\n" unless defined $password;
my $connect_info = <% dist_module %>->config->{'Model::DB'}{connect_info};
my $schema = <% dist_module %>::Schema->connect($connect_info) or die "Unable to connect\n";
my $user = $schema->resultset('User')->find({ name => $user_name });
die "cannot find user '$user'\n" unless defined $user;
$user->password($password);
$user->update;
