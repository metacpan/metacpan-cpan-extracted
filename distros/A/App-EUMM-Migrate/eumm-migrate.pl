#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

#License: GPL (may change in the future)
#Perl tool to migrate from ExtUtils::MakeMaker to Module::Build
=pod

App::EUMM::Migrate

eumm-migrate is a tool to migrate from ExtUtils::MakeMaker to Module::Build.
It executes Makefile.PL with fake ExtUtils::MakeMaker and rewrites all parameters for
WriteMakefile into corresponding params of Module::Build->new. Calls to 'prompt' are also
intercepted and corresponding 'prompt' is written to Build.PL. All other info should be ported
manually.

Just run eumm-migrate.pl in directory with Makefile.PL. If you use Github, Internet connection
is recommended.

eumm-migrate tries to automatically detect some properties like license, minimum Perl version
required and repository used.

(c) Alexandr Ciornii
=cut

$INC{'ExtUtils/MakeMaker.pm'}=1;

package #hide from PAUSE
 ExtUtils::MakeMaker;
our $VERSION=6.56;
use Exporter;
our @ISA=qw/Exporter/;
our @EXPORT=qw/prompt WriteMakefile/;
#our @EXPORT_OK=qw/prompt WriteMakefile/;

use Data::Dumper;
use File::Slurp;
use Perl::Meta;

my @prompts;
sub prompt ($;$) {  ## no critic
    my($mess, $def) = @_;
    push @prompts,[$mess, $def];
}


#our $writefile_data;
sub WriteMakefile {
  my %params=@_;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  #print "License not specified\n" if not exists $params{LICENSE};
  if (exists $params{VERSION_FROM} and exists $params{ABSTRACT_FROM} and
   $params{VERSION_FROM} ne $params{ABSTRACT_FROM}) {
    die "VERSION_FROM can't be different from ABSTRACT_FROM in Module::Build";
  }
  if (! exists $params{PL_FILES}) {
    print "You need to add PL_FILES=> {} into Makefile.PL\n";
  }
  my %transition=qw/
NAME	module_name
VERSION_FROM	dist_version_from
PREREQ_PM	requires
INSTALLDIRS	installdirs
EXE_FILES	script_files
PL_FILES	-
LICENSE	license
BUILD_REQUIRES	build_requires
META_MERGE	meta_merge
AUTHOR	dist_author
ABSTRACT_FROM	-
ABSTRACT	dist_abstract
dist		-
/;
  my %transition2=(
   'clean'=>{
     FILES => 'add_to_cleanup',
   },
  );
  my %result;
  while (my($key,$val)=each %params) {
    next if $key eq 'MIN_PERL_VERSION';
    if (exists $transition2{$key}) {
      while (my($key1,$val1)=each %$val) {
        die "Unknown key '$key'->'$key1' in WriteMakefile call" unless exists $transition2{$key}->{$key1};
        $result{ $transition2{$key}->{$key1} }=$val1;
      }
      next;
    }
    die "Unknown key '$key' in WriteMakefile call" unless exists $transition{$key};
    next if $transition{$key} eq '-';
    if ($key eq 'INSTALLDIRS' and $val eq 'perl') {
      $val = 'core';
    }
    $result{$transition{$key}}=$val;
  }
  if (exists $params{'MIN_PERL_VERSION'}) {
    $result{requires}{perl}=$params{'MIN_PERL_VERSION'};
  }
  if (!exists $params{'META_MERGE'}{resources}{repository}) {
    my $repo = Module::Install::Repository::_find_repo(\&Module::Install::Repository::_execute);
    if ($repo and $repo=~m#://#) {
      print "Repository found: $repo\n";
      eval {
        require Github::Fork::Parent;
        $repo=Github::Fork::Parent::github_parent($repo);
  
      };
      $result{'meta_merge'}{resources}{repository}=$repo;
    }
  }
  if (exists $params{'VERSION_FROM'}) {
    my $main_file_content=eval { read_file($params{'VERSION_FROM'}) };
    if (! exists($result{requires}{perl})) {
      my $version=Perl::Meta::extract_perl_version($main_file_content);
      if ($version) {
        $result{requires}{perl}=$version;
      }
    }
    if (! exists($result{license})) {
        my $l=Perl::Meta::extract_license($main_file_content);
        if ($l) {
          $result{license}=$l;
        }
    }
  }
  if (! exists($result{requires}{perl})) {
    my $makefilepl_content=eval { read_file('Makefile.PL') };
    my $version=Perl::Meta::extract_perl_version($makefilepl_content);
    if ($version) {
      $result{requires}{perl}=$version;
    }
  }
  $result{auto_configure_requires}=0;

  open my $out,'>','Build.PL';
  my $prompts_str='';
  if (@prompts) {
    $prompts_str.="die 'please write prompt handling code';\n";
    foreach my $p (@prompts) {
      my($mess, $def) = @$p;
      $prompts_str.="Module::Build->prompt(q{$mess},q{$def});\n";
    }
    $prompts_str.="\n";
  }
  my $str;
  { local $Data::Dumper::Indent=1;local $Data::Dumper::Terse=1;
    $str=Data::Dumper->Dump([\%result], []);
    $str=~s/^\{[\x0A\x0D]+//s;
    $str=~s/\}[\x0A\x0D]+\s*$//s;
  }
  print $out <<'EOT';
use strict;
use Module::Build;
#created by eumm-migrate.pl

EOT
print $out $prompts_str;
  print $out <<'EOT';
my $build = Module::Build->new(
EOT
  print $out $str;
  print $out <<'EOT';
);

$build->create_build_script();
EOT

}

package main;
do './Makefile.PL';
die if $@;

package Module::Install::Repository;
#by Tatsuhiko Miyagawa
#See Module::Install::Repository for copyright


sub _execute {
    my ($command) = @_;
    `$command`;
}

sub _find_repo {
    my ($execute) = @_;

    if (-e ".git") {
        # TODO support remote besides 'origin'?
        if ($execute->('git remote show -n origin') =~ /URL: (.*)$/m) {
            # XXX Make it public clone URL, but this only works with github
            my $git_url = $1;
            $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
            return $git_url;
        } elsif ($execute->('git svn info') =~ /URL: (.*)$/m) {
            return $1;
        }
    } elsif (-e ".svn") {
        if (`svn info` =~ /URL: (.*)$/m) {
            return $1;
        }
    } elsif (-e "_darcs") {
        # defaultrepo is better, but that is more likely to be ssh, not http
        if (my $query_repo = `darcs query repo`) {
            if ($query_repo =~ m!Default Remote: (http://.+)!) {
                return $1;
            }
        }

        open my $handle, '<', '_darcs/prefs/repos' or return;
        while (<$handle>) {
            chomp;
            return $_ if m!^http://!;
        }
    } elsif (-e ".hg") {
        if ($execute->('hg paths') =~ /default = (.*)$/m) {
            my $mercurial_url = $1;
            $mercurial_url =~ s!^ssh://hg\@(bitbucket\.org/)!https://$1!;
            return $mercurial_url;
        }
    } elsif (-e "$ENV{HOME}/.svk") {
        # Is there an explicit way to check if it's an svk checkout?
        my $svk_info = `svk info` or return;
        SVK_INFO: {
            if ($svk_info =~ /Mirrored From: (.*), Rev\./) {
                return $1;
            }

            if ($svk_info =~ m!Merged From: (/mirror/.*), Rev\.!) {
                $svk_info = `svk info /$1` or return;
                redo SVK_INFO;
            }
        }

        return;
    }
}

1;
