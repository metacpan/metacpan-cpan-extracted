# Copyright 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package Regexp::Common::Perl;
use strict;
use warnings;
use Carp;
use Regexp::Common ('no_defaults', # no $RE import
                    'pattern',     # pattern func
                   );

# uncomment this to run the ### lines
#use Smart::Comments;

pattern (name   => ['Perl','version'],
         create => 'v?[0-9][0-9.]*');

pattern (name   => ['Perl','identifier'],
         create => '[[:alpha:]_][[:alnum:]_]*');

pattern (name   => ['Perl','qualified'],
         create => sub {"$RE{Perl}{identifier}(?:::$RE{Perl}{identifier})*"});

pattern (name   => ['Perl','lws'],
         create => sub { "(?:\\s+($RE{comment}{Perl}\\s*)*"
                           . "|$RE{comment}{Perl}(\\s*$RE{comment}{Perl})*)" });
pattern (name   => ['Perl','pod'],
         create => "(?:^|\n)(?:^|\n)(=[[:alpha:]][^\n]*\n.*?\n)?=cut(\n|\$)(\n|\$)");

# ENHANCE-ME: also q{} etc strings
pattern (name   => ['Perl','string'],
         create => sub { $RE{delimited}{-delim=>'"\''}{-esc=>'\\\\'} });


package MyExtractUse;
use strict;
use warnings;
use Perl6::Slurp;
use Pod::Strip;
use Regexp::Common;

use constant DEBUG => 0;

print "RE lws $RE{Perl}{lws}\n";
my $lws = qr/$RE{Perl}{lws}/o;
my $use_re
  = qr{\b(?<type>use|require|no)
       $lws
       (?<package>$RE{Perl}{qualified})
       ($lws(?<version>$RE{Perl}{version}))?
    }ox;
my $use_code_re
  = qr{(?<eval>eval${lws}?\{)?
       ${lws}?
       $use_re}ox;
my $use_eval_string_re
  = qr{(?<eval>eval${lws}?['"]
       ${lws}?
       $use_re)}ox;
my $use_base_re
  = qr{\b(?<type>use)${lws}base
       $lws
       (\($lws)?['"](?<package>$RE{Perl}{qualified})
    }ox;
my $use_perl_re
  = qr{\b(?<type>use|no|require)
       ${lws}
       (?<version>$RE{Perl}{version})
      }ox;
my $VERSION_check_re
  = qr{\b(?<package>$RE{Perl}{qualified})
      $lws
      ->
      $lws
      VERSION
      $lws
      \(
      $lws
      ['"]?(?<version>$RE{Perl}{version})
      }ox;

# my $re = $use_eval_string_re;
# print "re: $re\n";
# my $str = "eval 'use Foo::Bar 3; 1' ";
# print "str: $str\n";
# if ($str =~ $use_eval_string_re) {
#   print "match\n";
#   require Data::Dumper;
#   print Data::Dumper::Dumper(\%+);
# } else {
#   print "no match\n";
# }
# exit 0;


sub from_file {
  my ($class, $filename) = @_;
  ### from_file(): $filename
  return if ($filename =~ m{selfloader-fork\.pl$});
  return $class->from_string (scalar Perl6::Slurp::slurp($filename));
}
sub from_string {
  my ($class, $str) = @_;

  my @ret;
  my $one = sub {
    my ($re) = @_;
    if (DEBUG >= 2) { print $str; }

    while ($str =~ /$re/g) {
      my %ret = %+;
      $ret{'pos'} = pos($str);
      $ret{'version'} = version->new($ret{'version'} || 0);
      push @ret, \%ret;

      if (DEBUG) {
        require Data::Dumper;
        print Data::Dumper::Dumper(\%ret);
      }
    }
  };

  #  $str = _pod_to_comments ($str);
  $str = _pod_to_whitespace ($str);
  $str = _comments_to_whitespace ($str);
  $str = _heredoc_to_whitespace ($str);

  $one->($use_base_re);
  $one->($use_eval_string_re);
  $one->($VERSION_check_re);
  $str = _strings_to_whitespace ($str);
  $one->($use_code_re);

  return @ret;
}

my $heredoc_re = qr/<<(?<open>['"]|)(?<word>$RE{Perl}{identifier})\k<open>(.*\n)+?\k<word>/;
  #$str =~ s/($heredoc_re)/_to_whitespace($1)/ego;

sub _heredoc_to_whitespace {
  my ($str) = @_;
  ### _heredoc_to_whitespace()
  while ($str =~ /<<['"]?($RE{Perl}{identifier})/) {
    my $pos = $-[0];
    my $word = $1;
    my $end = index ($str, "\n$word", $pos);
    if ($end < 0) { $end = length($str); }
    substr ($str, $pos, $end-$pos, '');
  }
  ### return: length($str)
  return $str;
}
# print _heredoc_to_whitespace('
#   show <<"HERE";
# foo ""
# HERE
# bar
#   xxx <<EOF;
# EOF
# ');
# exit 0;

sub _comments_to_whitespace {
  my ($str) = @_;
  $str =~ s/($RE{comment}{Perl})/_to_whitespace($1)/ego;
  return $str;
}

sub _pod_to_comments {
  my ($str) = @_;
  ### _pod_to_comments()
  my $stripper = Pod::Strip->new;
  $stripper->replace_with_comments (1);
  my $out;
  $stripper->output_string (\$out);
  $stripper->parse_string_document ($str);
  return $out;
}

sub _pod_to_whitespace {
  my ($str) = @_;
  ### _pod_to_whitespace()
  $str =~ s/($RE{Perl}{pod})/_to_whitespace($1)/ego;
  return $str;
}
# print  _pod_to_whitespace(<<HERE);
# 
# =foo
# 
# =cut
# 
# HERE
# exit 0;

# my $string_single_re = qr/'([^\\']|\\.)*?'/s;
# my $string_double_re = qr/"([^\\"]|\\.)*?"/s;
# #my $string_re = qr/$string_single_re|$string_double_re/o;
#   #$str =~ s/($string_re)/_string_empty($1)/ego;
# my $string_re = qr/(?<open>['"])(?<content>([^\\]|\\.)*?)(?<close>\k<open>)/s;
#   $str =~ s/($string_re)/$+{open}._to_whitespace($+{content}).$+{close}/ego;

sub _strings_to_whitespace {
  my ($str) = @_;
  $str =~ s{($RE{Perl}{string})}
           {_delimited_to_whitespace($1)}ego;
  return $str;
}
#  print qr//,"\n";
#  print _strings_to_whitespace(" 'f\\'oo' 'bar' ");


sub _delimited_to_whitespace {
  my ($str) = @_;
  return substr($str,0,1)
    . _to_whitespace(substr($str,1,-1))
      . substr($str,-1);
};
sub _to_whitespace {
  my ($str) = @_;
  $str =~ s/([^[:space:]]+)/' ' x length($1)/ge;
  return $str;
}

1;
__END__
