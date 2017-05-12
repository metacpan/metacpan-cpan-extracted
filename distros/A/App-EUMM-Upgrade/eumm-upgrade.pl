#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

#License: GPL (may change in the future)

#use Perl6::Say;
use File::Slurp;
#require Module::Install::Repository;
#require Module::Install::Metadata;
use Text::FindIndent 0.08;
use Perl::Meta;
use App::EUMM::Upgrade;
use Getopt::Long;

my $noparent = 0;
GetOptions("noparent" => \$noparent) or die("Error in command line arguments\n");
print "will not search for github parent repository\n" if $noparent;

my $content=read_file('Makefile.PL') or die "Cannot find 'Makefile.PL'";
if ($content =~ /use inc::Module::Install/) {
  die "Module::Install is used, no need to upgrade";
}
if ($content =~ /WriteMakefile1\s*\(/) {
  print "Upgrade is already applied\n";
  exit;
}
if ($content !~ /\b(?:use|require) ExtUtils::MakeMaker/ or $content !~ /WriteMakefile\s*\(/) {
  die "ExtUtils::MakeMaker is not used";
}

sub process_file {
  my $content=shift;
  my $indentation_type = Text::FindIndent->parse($content,first_level_indent_only=>1);
  my $space_to_use;
  my $indent_str;
  if ($indentation_type =~ /^[sm](\d+)/) {
    print "Indentation with $1 spaces\n";
    $space_to_use=$1;
    $indent_str=' 'x$space_to_use;
  } elsif ($indentation_type =~ /^t(\d+)/) {
    print "Indentation with tabs, a tab should indent by $1 characters\n";
    $space_to_use=0;
    $indent_str="\t";
  } else {
    print "Indentation unknown, will use 4 spaces\n";
    $space_to_use=4;
    $indent_str=' 'x4;
  }

  my $DZ_compatibility_code = 0;
  if ($content =~ /\QWriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;\E/) {
    print "Dist::Zilla compatibility code detected, skipping own code\n";
    $DZ_compatibility_code++;
  }

  my $compat_layer=<<'EOT';
sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}
EOT
  my $space=' 'x4;
  unless ($DZ_compatibility_code) {
    $content=~s/(WriteMakefile\()(?!\%)(\S)/$1\n$indent_str$2/;
    $content=remove_conditional_code($content,$indent_str) ;
  }
  my @param;

  my $meta_modify_persent = 0;
  my $meta_modify_ver = 0;
  if ($content =~ m#META_MERGE['" ]\s*=>#) {
    $meta_modify_persent = 1;
    if ($content =~ m#['"]meta-spec['"]\s*=>\s*{\s*version\s*=>\s*2\s*}#s) {
      $meta_modify_ver = 2;
    }
  }

  my @resourses;
  my ($type, $repo) = find_repo();
  my $repo_string;
  if ($repo and $repo=~m#://#) {
    $repo = convert_url_to_public($repo);
    print "Repository found: $repo. Check that this is public URL.\n";
    unless ($noparent) {
      eval {
        require Github::Fork::Parent;
        $repo=Github::Fork::Parent::github_parent($repo);
      };
    }
    $repo_string = "repository => '$repo',";
  } else {
    $repo_string = "#repository => 'URL to repository here',";
  }
  my $web_url = convert_url_to_web($repo);
  if ($meta_modify_ver == 2 || (!$meta_modify_persent && $web_url))  {
    $meta_modify_ver = 2;
    push @resourses, "${space}${space}${space}repository => {";
    if ($repo) {
      push @resourses, "${space}${space}${space}${space}type => '$type',";
      push @resourses, "${space}${space}${space}${space}url => '$repo',";
      push @resourses, "${space}${space}${space}${space}web => '$web_url',";
    } else {
      push @resourses, "${space}${space}${space}${space}#see CPAN::Meta::Spec";
    }
    push @resourses, "${space}${space}${space}},";
  } else {
    push @resourses, "${space}${space}${space}$repo_string";
  }

  if ($content=~/\bVERSION_FROM['"]?\s*=>\s*['"]([^'"\n]+)['"]/ || $content=~/\bVERSION_FROM\s*=>\s*q\[?([^\]\n]+)\]/) {
    my $main_file=$1;
    my $main_file_pod = $1;
    my $main_file_content = eval { read_file($main_file) };
    if (!$main_file_content) {
      print "Cannot open $main_file\n";
    } else {
      if ($main_file_pod =~ s/\.pm$/\.pod/ && -e $main_file_pod) {
        $main_file_content .= "\n\n".eval { read_file($main_file_pod) };
      } else {
        $main_file_pod = '';
      }
      my @links=Perl::Meta::extract_bugtracker($main_file_content);
      if (@links==2) {
        my $remove;
        my $dist;
        foreach my $i (0.. $#links) {
          my $dist1;
          if ($links[$i] =~ m#^\Qhttp://rt.cpan.org/NoAuth/ReportBug.html?Queue=\E(\w+)#) {
            $remove = $i;
            $dist1 = $1;
          } elsif ($links[$i] =~ m#^\Qhttp://rt.cpan.org/NoAuth/Bugs.html?Dist=\E(\w+)#) {
            $dist1 = $1;
          } else {
            die "unknown bugtraker type $links[$i]";
          }
          if ($dist and $dist1 ne $dist) {
            die;
          }
        }
        splice(@links,$remove,1) if defined $remove;
      }
      if (@links==1) {
        my $bt=$links[0];
        print "Bugtracker found: $bt\n";
        if ($meta_modify_ver == 2)  {
          push @resourses, "${space}${space}${space}bugtracker => { 'web' => '$bt' },";
        } else {
          push @resourses, "${space}${space}${space}bugtracker => '$bt',";
        }
      } elsif (@links>1) {
        print "Too many links to bugtrackers found in $main_file\n";
      }
      if ($content !~ /\bLICENSE\s*=>\s*['"]/ and $content !~ /['"]LICENSE['"]\s*=>\s*['"]/) {
        my $l=Perl::Meta::extract_license($main_file_content);
        if ($l) {
          push @param,"    LICENSE => '$l',\n";
        } else {
          print "license not found\n";
        }
      }
      if ($content !~ /\bMIN_PERL_VERSION['"]?\s*=>\s*['"]?\d/) {
        my $version=Perl::Meta::extract_perl_version($main_file_content) ||
          Perl::Meta::extract_perl_version($content);
        if ($version) {
          push @param,"    MIN_PERL_VERSION => '$version',\n";
        }
      }
    }
  } else {
    print "VERSION_FROM not found\n";
    if ($content !~ /\bMIN_PERL_VERSION\s*=>\s*['"\d]/) {
      my $version=Perl::Meta::extract_perl_version($content);
      if ($version) {
        push @param,"    MIN_PERL_VERSION => '$version',\n";
      }
    }
  }

  if (@resourses) { # and $content !~ /\bMETA_MERGE\s*=>\s*\{/
    my $res=join("\n",@resourses);
    my $metaspec = '';
    #'meta-spec' => { version => 2 },
    
    if ($meta_modify_ver == 2 && !$meta_modify_persent)  {
      $metaspec="\n        'meta-spec' => { version => 2 },";
    }
    push @param,<<EOT;
    META_MERGE => {$metaspec
        resources => {
$res
        },
    },
EOT
  }

  if ($content !~ /\bTEST_REQUIRES['"]?\s*=>\s*\{/) {
    push @param,"    #TEST_REQUIRES => {\n"."    #},\n";
  }
  
  my $param='';
  if (@param) {
    $param="\n".join('',@param);
    $param = App::EUMM::Upgrade::apply_indent($param,4,$space_to_use);
    $param=~s/\s+$/\n/s;
  }
  $content = App::EUMM::Upgrade::add_new_fields($content, $param);

  unless ($DZ_compatibility_code) {
    $content =~ s/WriteMakefile\s*\(/WriteMakefile1(/s;
    $compat_layer="\n\n".App::EUMM::Upgrade::apply_indent($compat_layer,4,$space_to_use);
    $content=~s/(package\s+MY; | __DATA__ | $ )/$compat_layer$1/sx;
  }
  return $content;
}

rename('Makefile.PL','Makefile.PL.bak');
write_file('Makefile.PL',process_file($content));

=pod

eumm-upgrade is a tool to allow using new features of ExtUtils::MakeMaker without losing
compatibility with older versions. It adds compatibility code to Makefile.PL and
tries to automatically detect some properties like license, minimum Perl version required and
repository used.

Just run eumm-upgrade.pl in directory with Makefile.PL. Old file will be copied to Makefile.PL.bak.
If you use Github, Internet connection is required.

You need to check resulting Makefile.PL manually as transformation is done
with regular expressions.

If you need to declare number of spaces in indent in Makefile.PL, use following string at start of
it (set 'c-basic-offset' to your value):

# -*- mode: perl; c-basic-offset: 4; indent-tabs-mode: nil; -*-

(c) Alexandr Ciornii
=cut

1;
