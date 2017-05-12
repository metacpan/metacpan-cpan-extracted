#!/usr/bin/perl

# Migratation of content from Apache::PageKit 0.99 to 1.00
# usage: ./migrate_pagekit_0.99_to_1.00.pl /path/to/pagekit/dir

use File::Find;
use File::Path;

my $root_dir = $ARGV[0];

unless($root_dir){
  print STDERR "usage: ./migrate_pagekit_0.99_to_1.00.pl /path/to/pagekit/dir\n";
  exit;
}

chomp(my $pwd = `pwd`);

my %files;

File::Find::find({wanted => sub {
		    return unless /\.tmpl$/;
		    migrate_pkit_tags("$File::Find::dir/$_");
		  }},
#		  follow => 1},
		 "$root_dir/View"
		);

sub migrate_pkit_tags {
  my ($filename) = @_;
  local($/) = undef;
  open TEMPLATE, $filename;
  my $template = <TEMPLATE>;
  close TEMPLATE;

  # change flag, records whether change has been made
  my $cf = 0;

  # PKIT_COMPONENTS
  # make current components absolute
  $cf += ($template =~ s!<PKIT_COMPONENT +(NAME *=)? *"?([^/].*?)"?>!<PKIT_COMPONENT NAME="/$2">!sig);

  # PKIT_IF NAME="VIEW:view"
  $cf += ($template =~ s!<PKIT_IF +NAME *= *("|')?VIEW:(.*?)("|') *>(.*?)</PKIT_IF>!<PKIT_VIEW NAME="$2">$4</PKIT_VIEW>!sig);

  # <PKIT_LOOP NAME="MESSAGE">
  $cf += ($template =~ s!<PKIT_LOOP +NAME *= *("|')?MESSAGE("|')? *>(.*?)</PKIT_LOOP>!<PKIT_MESSAGES>$3</PKIT_MESSAGES>!sig);
  $cf += ($template =~ s!<PKIT_IF +NAME *= *("|')?IS_ERROR("|')? *>(.*?)</PKIT_IF>!<PKIT_IS_ERROR>$3</PKIT_IS_ERROR>!sig);
  $cf += ($template =~ s!<PKIT_VAR +NAME *= *("|')?MESSAGE("|')? *>!<PKIT_MESSAGE>!sig);

  # <PKIT_VAR NAME="HOSTNAME">
  $cf += ($template =~ s!<PKIT_VAR +NAME *= *("|')?HOSTNAME("|')? *>!<PKIT_HOSTNAME>!sig);

  if($cf){
    print "updated $filename, made $cf substitution(s)\n";
#    rename "$filename", "$filename.bak";
    open TEMPLATE, ">$filename";
    print TEMPLATE $template;
    close TEMPLATE;
  }
}
