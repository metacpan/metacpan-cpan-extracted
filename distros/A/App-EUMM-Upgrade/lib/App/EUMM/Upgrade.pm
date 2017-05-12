package App::EUMM::Upgrade;

use strict;
use warnings;

=head1 NAME

App::EUMM::Upgrade - Perl tool to upgrade ExtUtils::MakeMaker-based Makefile.PL

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';


=head1 SYNOPSIS

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

=head1 new EUMM features

LICENSE - shows license on search.cpan.org

META_MERGE - add something (like repository URL or bugtracker UTL) to META.yml. Repository and
bugtracker URL are used on search.cpan.org.

MIN_PERL_VERSION - minimum version of Perl required for module work. Not used currently, but will
be in the future.

CONFIGURE_REQUIRES - modules that are used in Makefile.PL and should be installed before running it.

TEST_REQUIRES - modules that are used in tests, but are not required by module
itself. Useful for ppm/OS package generaton and metadata parsing tools.

BUILD_REQUIRES - same as TEST_REQUIRES, but for building

AUTHOR - can be arrayref to allow several authors

=head1 AUTHOR

Alexandr Ciornii, C<< <alexchorny at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-eumm-upgrade at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-EUMM-Upgrade>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::EUMM::Upgrade


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-EUMM-Upgrade>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-EUMM-Upgrade>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-EUMM-Upgrade>

=item * Search CPAN

L<http://search.cpan.org/dist/App-EUMM-Upgrade/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Alexandr Ciornii.

GPL v3

=cut

use Exporter 'import';
our @EXPORT=qw/remove_conditional_code find_repo convert_url_to_public convert_url_to_web/;
sub _indent_space_number {
  my $str=shift;
  $str=~/^(\s+)/ or return 0;
  my $ind=$1; 
  $ind=~s/\t/        /gs;
  return length($ind);
}

sub _unindent_t {
#  my $replace
#  die unless
}
sub _unindent {
  my $space_string_to_set=shift;
  my $text=shift;
  #print "#'$space_string_to_set','$text'\n";
  my @lines=split /(?<=[\x0A\x0D])/s,$text;
  use List::Util qw/min/;
  my $minspace=min(map {_indent_space_number($_)} @lines);
  my $s1=_indent_space_number($space_string_to_set);
  #die "$s1 > $minspace" if $s1 > $minspace;
  return $text if $s1==$minspace;
  #if (grep { $_ !~ /^$space_string_to_set/ } @lines) {
    
  #}
  #my $space_str
  my $line;
  my $i=0;
  foreach my $l (@lines) {
    next unless $l;
    if ($i==0) {
      $l =~ s/^\s+//;
      $i++;
      next;
    }
    unless ($l=~s/^$space_string_to_set//) {
      die "Text (line '$l') does not start with removal line ($space_string_to_set)";
    }
    next unless $l;
    if ($l=~m/^(\s+)/) {
      my $space=$1;
      if (!defined $line) {
        $line=$space;
        next;
      } else {
        if ($space=~/^$line/) {
          next;
        } elsif ($line=~/^$space/) {
          $line=$space;
          if ($line eq '') {
            #warn("line set to '' on line '$l'");
          }
        } else {
          die "Cannot find common start, on line '$l'";
        }
      }
    } else {
      return $text;
    }
  }
  if (!$line and $i>1) {
    die "Cannot find common start";
  }
  $i=0;
  foreach my $l (@lines) {
    next unless $l;
    if ($i==0) {
      $l="$space_string_to_set$l";
      $i++;
      next;
    }
    unless ($l=~s/^$line//) {
      die "Text (line '$l') does not start with calculated removal line ($space_string_to_set)";
    }
    $l="$space_string_to_set$l";
  }
  return (join("",@lines)."");

  #foreach
  #$text=~s/^(\s+)(\S)/_unindent_t(qq{$1},qq{$space_string_to_set}).qq{$2}/egm;
  
  #my $style=shift;
}

sub remove_conditional_code {
  my $content=shift;
  my $space=shift;
  $content=~s/(WriteMakefile\()(?!\%)(\S)/$1\n$space$2/;

  $content=~s/
  \(\s*\$\]\s*>=\s*5\.005\s*\?\s*(?:\#\#\s*\QAdd these new keywords supported since 5.005\E\s*)?
  \s+\(\s*ABSTRACT(?:_FROM)?\s*=>\s*'([^'\n]+)',\s*(?:\#\s*\Qretrieve abstract from module\E\s*)?
  \s+AUTHOR\s*=>\s*'([^'\n]+)'
  \s*\)\s*\Q: ()\E\s*\),\s+
  /ABSTRACT_FROM => '$1',\n${space}AUTHOR => '$2',\n/sx;

  my $eumm_version_check=qr/\$ ExtUtils::MakeMaker::VERSION\s+
          (?:g[et]\s+' [\d\._]+ ' \s* | >=?\s*[\d\._]+\s+) |
          eval\s*{\s*ExtUtils::MakeMaker->VERSION\([\d\._]+\)\s*}\s*
          /xs;
  $content=~s/
          ^(\s*)\(\s* $eumm_version_check
          \?\s+\(\s* #[\n\r]
          ( [ \t]*[^()]+? ) #main text, should not contain ()
           \s*
          \)\s*\:\s*\(\)\s*\),
  /_unindent($1,$2)/msxge;

  $content=~s/
          \(\s*\$\]\s* \Q>=\E \s* 5[\d\._]+ \s* \?\s*\( \s*
          ( [^()]+? ) ,? \s*
          \)\s*\:\s*\(\)\s*\),
  /$1,/sxg;
#    ($] >= 5.005 ?
#       (AUTHOR         => 'Author <notexistingemail@hotmail.com>') : ()),
  return $content;
}

sub _do_replace {
  my $spaces=shift;
  my $i_from=shift;
  my $i_to=shift;
  my $len=length($spaces);
  my $l1=int($len/$i_from);
  if ($i_to==0) {
    return "\t"x$l1;
  } else {
    return " " x ($l1*$i_to);
  }
}

sub apply_indent {
  my $content=shift;
  my $i_from=shift || die;
  my $i_to=shift;
  $content=~s/^((?:[ ]{$i_from})+)/_do_replace($1,$i_from,$i_to)/emg;
  return $content;
}

sub add_new_fields {
  my $content = shift;
  my $new_fields = shift;
  my $text2replace = 'WriteMakefile\(';
  if ($content =~ /WriteMakefile\(\s*(\%\w+)\s*\);/) {
    my $var_params = $1;
    $text2replace = qr/$var_params\s*=\s*\(\s*$/m;
    $content =~ s/($text2replace)/$1$new_fields/ or die "Cannot find $var_params initialization in Makefile.PL";
    $content =~ s/WriteMakefile\s*\(/WriteMakefile(/s;
  } else {
    $content =~ s/WriteMakefile\s*\(/WriteMakefile($new_fields/s;
  }
  return $content;
}



#_find_repo copied from Module::Install::Repository;
#by Tatsuhiko Miyagawa
#See Module::Install::Repository for copyright

sub _execute {
    my ($command) = @_;
    local $ENV{LC_ALL} = "C";
    `$command`;
}

sub find_repo {
  return _find_repo(\&_execute);
}

sub _find_repo {
    my ($execute) = @_;

    if (-e ".git") {
        # TODO support remote besides 'origin'?
        my $git_url =  '';
        if ($execute->('git remote show -n origin') =~ /URL: (.*)$/m) {
            # XXX Make it public clone URL, but this only works with github
            $git_url = $1;
            $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
            return ('git', $git_url);
        } elsif ($execute->('git svn info') =~ /URL: (.*)$/m) {
            $git_url = $1;
        }
        return '' if $git_url =~ /\A\w+\z/;# invalid github remote might come back with just the remote name
        return ('git', $git_url);
    } elsif (-e ".svn") {
        if ($execute->('svn info') =~ /URL: (.*)$/m) {
            return ('svn', $1);
        }
    } elsif (-e "_darcs") {
        # defaultrepo is better, but that is more likely to be ssh, not http
        if (my $query_repo = `darcs query repo`) {
            if ($query_repo =~ m!Default Remote: (http://.+)!) {
                return ('darcs', $1);
            }
        }

        open my $handle, '<', '_darcs/prefs/repos' or return;
        while (<$handle>) {
            chomp;
            return ('darcs', $_) if m!^http://!;
        }
    } elsif (-e ".hg") {
        if ($execute->('hg paths') =~ /default = (.*)$/m) {
            my $mercurial_url = $1;
            $mercurial_url =~ s!^ssh://hg\@(bitbucket\.org/)!https://$1/!;
            return ('hg', $mercurial_url);
        }
    } elsif ($ENV{HOME} && -e "$ENV{HOME}/.svk") {
        # Is there an explicit way to check if it's an svk checkout?
        my $svk_info = `svk info` or return;
        SVK_INFO: {
            if ($svk_info =~ /Mirrored From: (.*), Rev\./) {
                return ('svk', $1);
            }

            if ($svk_info =~ m!Merged From: (/mirror/.*), Rev\.!) {
                $svk_info = `svk info /$1` or return;
                redo SVK_INFO;
            }
        }

        return;
    }
}

sub convert_url_to_public {
  my $url = shift;
  $url =~ s#^(?:ssh://|git://)?git\@(github\.com|bitbucket\.org)[:/]#https://$1/# and return $url;
  #ssh://git@bitbucket.org/shlomif/fc-solve.git

  $url =~ s#^(?:ssh://)hg\@(bitbucket\.org)/#https://$1/# and return $url;
  #ssh://hg@bitbucket.org/shlomif/app-notifier

  $url =~ s#^https://(\w+)\@(bitbucket\.org)/#https://$2/# and return $url;
  #ssh://hg@bitbucket.org/shlomif/app-notifier

  return $url;
}    

sub convert_url_to_web {
  my $url = shift;
  return unless $url;
  $url =~ s#^(?:https?|git)://(github\.com|bitbucket\.org)/(.*)\.git#https://$1/$2# and return $url;
  $url =~ s#^https?://(bitbucket\.org)/(.*)#https://$1/$2# and return $url;
  return;
}

1; # End of App::EUMM::Upgrade
