package Apache::DnsZone::Language;

# $Id: Language.pm,v 1.7 2001/06/03 11:10:24 thomas Exp $

use strict;
use vars qw($VERSION);
use Apache::DnsZone;
use MLDBM qw(GDBM_File Data::Dumper);
use Fcntl;

($VERSION) = qq$Revision: 1.7 $ =~ /([\d\.]+)/;

sub fetch {
    my $class = shift;
    my $cfg = shift;
    my $lang = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::Language::fetch($lang) called});
    my $lang_dir = $cfg->{'cfg'}->{DnsZoneLangDir};
    $lang_dir .= '/DnsZoneLang';
    my $dbm;
    my %dbm;
    $dbm = tie %dbm, 'MLDBM', $lang_dir, O_RDONLY, 0640 or die "$! : $lang_dir";
    my %lang = %{$dbm{$lang}};
    undef $dbm;
    untie %dbm;
    return %lang;
}

1;
