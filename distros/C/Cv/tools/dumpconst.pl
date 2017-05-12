#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;

# dumpconst - convert opencv header files to Perl constants
# 
# dumpconst.pl [-verbose] [-unlink] dirs
# 
# dumpconst.pl は、opencv の定数を Perl モジュールに変換する。はじめに、
# 指定されたディレクトリ下の opencv のヘッダファイルを find コマンド検索
# し、h2ph で変換する。

our @incdir = ();
our $verbose = 0;
our $unlink = 0;
our $output = 0;
our $tmpdir;
use lib $tmpdir = "./tmp";

use Getopt::Long;
GetOptions (
	"unlink" => \$unlink,
	"output=s" => \$output,
	"verbose+" => \$verbose,
	)
	or die "usage: $0 [-verbose] [-unlink]\n";

if ($output) {
	open STDOUT, ">$output"
		or die "$0: can't open $output\n";
}

print STDERR "include: ", join(', ', @ARGV), "\n" if $verbose > 1;

use File::Basename;
for my $dir (@ARGV) {
	open FIND, "(cd $dir && find opencv* -name '*.h' -o -name '*.hpp')|"
		or die "$0: can't find";
	while (<FIND>) {  chop; h2ph($dir, $_); }
}

# 変換された .ph のうち、opencv/ の下の cv.h highgui.h cvaux.h と
# opencv2/ の下の opencv.hpp を require で動的に取り込む。そのとき、
# opencv.hpp は OpenCV-1* にはないので、 eval { } でエラーを無視した。


require "opencv/cv.ph";
require "opencv/highgui.ph";
require "opencv/cvaux.ph";
eval { require "opencv2/opencv.hpp" };

# そして、変換結果を B::Deparse し、定数らしく見えるものを出力することに
# した。手作業で変換したものや定数でないものものもあるので、無視して欲し
# いものは %ignore に置いた。

use B::Deparse;

our %ignore;
$ignore{$_} = 1 for qw(

CV2IPL_DEPTH CVAPI CV_16SC CV_16UC CV_32FC CV_32SC CV_64FC CV_8SC
CV_8UC CV_CARRAY CV_CDECL CV_CUSTOM_CARRAY CV_EXPORTS
CV_EXPORTS_AS CV_EXPORTS_W CV_EXPORTS_W_MAP CV_EXPORTS_W_SIMPLE
CV_EXTERN_C CV_FOURCC_DEFAULT CV_IMPL CV_INLINE CV_IN_OUT CV_MAKETYPE
CV_MAKE_TYPE CV_MAT_CN CV_MAT_DEPTH CV_MAT_TYPE CV_OUT CV_PROP
CV_PROP_RW CV_STDCALL CV_VERSION CV_WRAP CV_WRAP_AS CV_WRAP_DEFAULT
IPL2CV_DEPTH IPL_ALIGN_16BYTES IPL_ALIGN_32BYTES IPL_ALIGN_4BYTES
IPL_ALIGN_8BYTES IPL_ALIGN_DWORD IPL_ALIGN_QWORD

CV_IS_CONT_MAT CV_IS_SET_ELEM_EXISTS
CV_STEREO_GC_OCCLUDED

	);

# 定数として出力するものは、名前が /^(CV|IPL)_/ に一致し、B::Deparse して
# eval が含まれていないものを選ぶことにした。変換結果には、C言語では定数
# になる sizeof() もあった。しかし、Cv の定数として扱いを決められなかった
# ので、不都合が生じるまで出力しないことにした。この他 h2ph が 3.14f のよ
# うな浮動小数点の定数を 3.14 & 'f' という形で出力するところも補正した。

our @subs;
sub dumpsub {
	my $name = shift;
	my $class = eval "\\%$name";
	for (keys %$class) {
		&dumpsub($name . $_) if /^\w+::$/;
		next if $ignore{$_};
		next unless /^(CV|IPL)_/;
		next unless my $p = $class->{$_};
		next unless my $code = eval "${p}{CODE}";
		my $body = B::Deparse->new(qw(-sC))->coderef2text($code);
		next if $body =~ /\b(eval|sizeof)\b/;
		$body =~ s/(\d+(\.\d+)?)\s+\&\s*'f'/$1/g;
		$body =~ s/\s*\bno warnings;\s+/ /;
		$body =~ s/;\s*}/ }/g;
		push(@subs, "sub $_ $body");
		$ignore{$_} = 1;
	}
}

&dumpsub(qw(main::));
print &preamble;
print "\n# Following constants were made from OpenCV Version: ",
	join('.', &CV_MAJOR_VERSION, &CV_MINOR_VERSION,  &CV_SUBMINOR_VERSION),
	".\n\n";
print &macros;
print map { "$_\n" } sort @subs;
print &postamble;
&cleanup;
exit 0;


# h2ph() は h2ph を呼び、opencv のヘッダファイルを .ph に変換する。ここで
# は単に定数を取り出せれば十分なので、変換された .ph 中の include に相当
# する require を eval { } で括り、エラーの発生を無視することにした。
# これは、opencv のヘッダファイル以外のヘッダファイルが .ph に変換されて
# いないときに発生するエラーを抑止する。


sub h2ph {
	my $dir = shift;
	local $_ = shift;
    print STDERR "h2ph -d $tmpdir $_\n" if $verbose;
	my $h = "$dir/$_";
    (my $ph = "$tmpdir/$_") =~ s/\.h$/\.ph/;
	mkdirhier(dirname($ph));
    # system("h2ph <$h >$ph");
	open PH, ">$ph" or die "$0: can't open $ph";
	open H2PH, "h2ph <$h |" or die "$0: can't h2ph $h";
	while (<H2PH>) {
		my $ec = s/\brequire\s+\'([^\']+)\'/eval { $& } || eval { require \'opencv\/$1\' }/;
		print PH;
		if ($verbose > 1) {
			print PH "warn \"can't $&\" if \$@;\n" if $ec;
		}
	}
	close H2PH;
	close PH;
}

sub mkdirhier {
    my $dir;
    for (split('/', $_[0])) {
		$dir .= $_;
		unless (-d $dir) {
			print STDERR "mkdir $dir\n" if $verbose;
			mkdir $dir;
		}
		$dir .= "/";
    }
	$dir;
}


sub cleanup {
	unless ($unlink) {
		if ($tmpdir && $tmpdir ne "." && $tmpdir ne "/") {
			my $cmd = "rm -rf $tmpdir";
			print STDERR $cmd, "\n" if $verbose;
			system($cmd);
		}
	}
}


sub preamble {
	<<'----';
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::Constant;

use 5.008008;
use strict;
use warnings;
# use Carp;

our $VERSION = '0.19';
----
	;
}


sub macros {
	<<'----';
*cvSlice = \&Cv::cvSlice;

sub CV_MAKETYPE {
	my ($depth, $cn) = @_;
	Carp::croak "CV_MAKETYPE: ?cn" unless $cn >= 1 && $cn <= &CV_CN_MAX;
	(&CV_MAT_DEPTH($depth) + ((($cn)-1) <<  &CV_CN_SHIFT));
}

sub CV_MAKE_TYPE { goto &CV_MAKETYPE }

sub CV_8UC  { unshift(@_, &CV_8U); goto &CV_MAKETYPE }
sub CV_8SC  { unshift(@_, &CV_8S); goto &CV_MAKETYPE }
sub CV_16UC { unshift(@_, &CV_16U); goto &CV_MAKETYPE }
sub CV_16SC { unshift(@_, &CV_16S); goto &CV_MAKETYPE }
sub CV_32SC { unshift(@_, &CV_32S); goto &CV_MAKETYPE }
sub CV_32FC { unshift(@_, &CV_32F); goto &CV_MAKETYPE }
sub CV_64FC { unshift(@_, &CV_64F); goto &CV_MAKETYPE }

sub CV_MAT_CN {
	my ($flags) = @_;
	(((($flags) &  &CV_MAT_CN_MASK) >>  &CV_CN_SHIFT) + 1);
}

sub CV_MAT_DEPTH {
	my ($flags) = @_;
	(($flags) &  &CV_MAT_DEPTH_MASK);
}

sub CV_MAT_TYPE {
	my ($flags) = @_;
	(($flags) &  &CV_MAT_TYPE_MASK);
}

sub CV_FOURCC {
	my ($c1, $c2, $c3, $c4) = map { split(//, $_) } @_;
	ord($c1) + (ord($c2) << 8) + (ord($c3) << 16) + (ord($c4) << 24);
}

sub CV_FOURCC_DEFAULT { CV_FOURCC('IYUV') }

our @CV2IPL_DEPTH = (
	&IPL_DEPTH_8U,
	&IPL_DEPTH_8S,
	&IPL_DEPTH_16U,
	&IPL_DEPTH_16S,
	&IPL_DEPTH_32S,
	&IPL_DEPTH_32F,
	&IPL_DEPTH_64F,
	0,
	);

sub CV2IPL_DEPTH {
	my ($type) = @_;
	$CV2IPL_DEPTH[&CV_MAT_DEPTH($type)];
}

sub IPL2CV_DEPTH {
    my ($depth) = @_;
    ( ( (&CV_8U) + (&CV_16U << 4) + (&CV_32F << 8) + (&CV_64F << 16) +
		(&CV_8S  << 20) + (&CV_16S << 24) + (&CV_32S << 28) )
	  >> ((($depth & 0xF0) >> 2) + (($depth & &IPL_DEPTH_SIGN)? 20 : 0)
	  )
	) & 15;
}

----
	;
}


sub postamble {
	<<'----';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	'all' => [ grep { /^(IPL|CV)/ && !/VERSION/ } keys %Cv::Constant:: ],
	);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ( );

1;
----
	;
}

