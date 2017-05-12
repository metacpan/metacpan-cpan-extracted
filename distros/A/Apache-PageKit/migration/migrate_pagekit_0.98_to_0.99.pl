#!/usr/bin/perl

# Migratation of content from Apache::PageKit 0.98 to 0.99
# usage: ./migrate_pagekit_0.98_to_0.99.pl /path/to/pagekit/dir

use File::Find;
use File::Path;

my $root_dir = $ARGV[0];

unless($root_dir){
  print STDERR "usage: ./migrate_pagekit_0.98_to_0.99.pl /path/to/pagekit/dir\n";
  exit;
}

chomp(my $pwd = `pwd`);

my %files;

File::Find::find({wanted => sub {
		    return unless /\.tmpl$/;
		    note_template("$File::Find::dir/$_");
		  }},
#		  follow => 1},
		 "$root_dir/View"
		);

while (my ($k, $v) = each %files){
  (my $dir = $k) =~ s(/[^/]*?$)();
  File::Path::mkpath($dir);
  rename $v, $k;
}

sub note_template {
  my ($filename) = @_;

  next unless (my $to_file = $filename) =~ s!^($root_dir/View/[^/]*/)(Page/|Component/)(.*)$!$1$3!;

  if(exists $files{$to_file}){
    # conflict!
    die "Files $filename and $files{$to_file} conflict.\nPlease rename one of them and update all reference to them in your application.";
  }

  $files{$to_file} = $filename;
}
