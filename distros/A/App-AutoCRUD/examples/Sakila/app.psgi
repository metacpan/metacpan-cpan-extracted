#!perl
use 5.010;
use strict;
use warnings;

use lib "../../lib";

use App::AutoCRUD;
use Path::Tiny;
use YAML::Any qw/LoadFile/;

# need absolute path to this dir (because we don't know from which
# current dir this psgi is run)
my $this_dir = path(__FILE__)->absolute->parent;

# load config
my $config_file = $this_dir->child("config_sakila.yaml")->canonpath;
my $config      = LoadFile $config_file;

# fix sqlite file to be an absolute path
$config->{datasources}{Sakila}{dbh}{connect}[0] 
  =~ s[dbname=(.*)]
      ["dbname=".$this_dir->child($1)->canonpath]e;

# create app
my $crud = App::AutoCRUD->new(config => $config);
my $app  = $crud->to_app;

# Allow this script to be run also directly (without 'plackup'), so that
# it can be launched from Emacs
unless (caller) {
  require Plack::Runner;
  my $runner = Plack::Runner->new;
  $runner->parse_options(@ARGV);
  return $runner->run($app);
}


return $app;



