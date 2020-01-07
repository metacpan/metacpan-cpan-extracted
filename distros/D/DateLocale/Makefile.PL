use strict;
use lib ".";
use inc::Module::Install;

name            'DateLocale';
abstract        'Perl extension for use localized date';
author          'Nikolay Shulyakovskiy <shulyakovskiy at mail.ru>';
license         'mit';
perl_version    '5.008008';
all_from        'lib/DateLocale.pm';
no_index        directory => 'share';
repository      'https://github.com/Nikolo/perl-DateLocale';
requires        'Locale::Messages';
requires        'POSIX';

my $MSGFMT = 'msgfmt';
my $xgettext = 'xgettext';
my $msgmerge = 'msgmerge';
requires_external_bin( $MSGFMT );
requires_external_bin( $xgettext );
requires_external_bin( $msgmerge );

my $mofiles = "";
my $pofiles = [];
my $uninstall = "";
print "Portable message objects...";
my $alltarget = "update-gmo";
for (<./share/po/*.po>) {
    my ($po) = /.\/share\/po\/(.*)\.po$/;
    print " $po";
    push @$pofiles, $po;
    $uninstall .= "\t\$(RM_F) \$(datadir)/locale/$po/LC_TIME/perl-DateLocale.mo\n";
    $mofiles   .= " $po.gmo";
}
print "\n";
my $loc = join("|", grep {!/^C$/} @$pofiles);
my @locales = `locale -a | egrep -i 'UTF\-?8' | egrep '^($loc)'`;
unless( @locales ){
    print "Need to install one of $loc locale";
    exit(0);
}

my $postamble = "generate.po: perl-DateLocale.pot\n";
    foreach (@$pofiles){
        $postamble .= "\t" . '$(NOECHO) ' . $msgmerge . ' -w 83 share/po/' . $_ . '.po perl-DateLocale.pot >' . $_ . '.po~' . $/;
        $postamble .= "\t" . '$(NOECHO) if cmp -s ' . $_ . '.po~ ' . $_ . '.po; then rm -f ' . $_ . '.po~ ; else mv ' . $_ . '.po~ ' . $_ . '.po; fi' . $/;
        clean_files $_ . '.po';
    }
    $postamble .= $/.'perl-DateLocale.pot: '.$/;
    $postamble .= "\t".'$(NOECHO) ' . $xgettext . ' --from-code="UTF-8" `find . -type f -print | grep \'\\.pm$$\'` -o perl-DateLocale.pot' . $/;
    clean_files 'perl-DateLocale.pot';
    $postamble .= $/."generate.gmo: generate.po".$/;
    foreach (@$pofiles){
        $postamble .= "\t" . '$(NOECHO) ' . "$MSGFMT -o $_.gmo share/po/$_.po$/";
        $postamble .= "\t" . '$(NOECHO) $(MKPATH) blib/lib/DateLocale/share/locale/' . $_ . '/LC_TIME' . $/;
        $postamble .= "\t" . '$(NOECHO) $(MV) ' . $_ . '.gmo blib/lib/DateLocale/share/locale/' . $_ . '/LC_TIME/perl-DateLocale.mo' . $/;
        $postamble .= "\t" . '$(NOECHO) $(CHMOD) 644 blib/lib/DateLocale/share/locale/' . $_ . '/LC_TIME/perl-DateLocale.mo' . $/;
    }
$postamble .= <<XXX
all :: generate.gmo 

uninstall :: uninstall-po

uninstall-po ::
$uninstall

clean ::
	test -f Makefile || mv -f Makefile.old Makefile
XXX
;
postamble( $postamble );
WriteAll();
