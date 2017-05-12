#!perl -T

use strict;
use warnings;

use Test::More tests => 1 + 6 + 10;

use CPANPLUS::Dist::Gentoo::Maps;

*nc2g = \&CPANPLUS::Dist::Gentoo::Maps::name_c2g;

is nc2g('CPANPLUS-Dist-Gentoo'), 'CPANPLUS-Dist-Gentoo', 'name_c2g returns non gentooisms correctly';

my %core_gentooisms = (
 'Digest'          => 'digest-base',
 'I18N-LangTags'   => 'i18n-langtags',
 'Locale-Maketext' => 'locale-maketext',
 'Net-Ping'        => 'net-ping',
 'Pod-Parser'      => 'PodParser',
 'PathTools'       => 'File-Spec',
);

for my $dist (sort keys %core_gentooisms) {
 is nc2g($dist), $core_gentooisms{$dist}, "name_c2g('$dist')";
}

my %cpan_gentooisms = (
 'CGI-Simple'    => 'Cgi-Simple',
 'Date-Manip'    => 'DateManip',
 'Gtk2'          => 'gtk2-perl',
 'Log-Dispatch'  => 'log-dispatch',
 'Math-Pari'     => 'math-pari',
 'Regexp-Common' => 'regexp-common',
 'Time-Period'   => 'Period',
 'Tk'            => 'perl-tk',
 'Wx'            => 'wxperl',
 'YAML'          => 'yaml',
);

for my $dist (sort keys %cpan_gentooisms) {
 is nc2g($dist), $cpan_gentooisms{$dist}, "name_c2g('$dist')";
}
