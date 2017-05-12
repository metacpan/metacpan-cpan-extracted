use strict;
use inc::Module::Install;
name            'DateLocale';
abstract        'Perl extension for use localized date';
author          'Nikolay Shulyakovskiy <shulyakovskiy at mail.ru>';
license         'mit';
perl_version    '5.008008';
no_index        directory => 'share';
repository      'https://github.com/Nikolo/perl-DateLocale';
requires        'Locale::Messages';

my $MSGFMT = 'msgfmt';
my $xgettext = 'xgettext';
my $msgmerge = 'msgmerge';
requires_external_bin( $MSGFMT );
requires_external_bin( $xgettext );
requires_external_bin( $msgmerge );

my $selected;
my $package = 'gettext_xs';
eval "use Locale::Messages";
unless( $@ ){
	$selected = Locale::Messages->select_package ($package);
};
if ($selected ne $package) {
	print "Locale::$package not available here. Please install it and try again\n";
	exit 0;
}

my $mofiles = "";
my $pofiles = [];
my $uninstall = "";
print "Portable message objects...";
my $alltarget = "update-gmo";
for (<./share/po/*.po>) {
	my ($po) = /.\/share\/po\/(.*)\.po$/;
    print " $po";
	push @$pofiles, $po;
	$uninstall .= "	\$(RM_F) \$(datadir)/locale/$po/LC_TIME/perl-DateLocale.mo\n";
    $mofiles   .= " $po.gmo";
}
print "\n";
my $loc = join("|", grep {!/^C$/} @$pofiles);
my @locales = `locale -a | egrep -i 'UTF\-?8' | egrep '^($loc)'`;
unless( @locales ){
	print "Need to install one of $loc locale";
	exit(0);
}
WriteMakefile(
	'NAME'         => 'DateLocale',
	'VERSION_FROM' => 'lib/DateLocale.pm',      # finds $VERSION
	MAN3PODS          => {
		'lib/DateLocale.pm'                => 'blib/man3/DateLocale.3',
		'lib/DateLocale/Language/ru_RU.pm' => 'blib/man3/DateLocale::Language::ru_RU.3',
	},
	PREREQ_PM         => {
		POSIX               => 0,
	},
	AUTHOR         => 'Nikolay Shulyakovskiy <shulyakovskiy@mail.ru>',
	'clean' => { FILES => $mofiles." perl-DateLocale.pot ".join(" ",map {$_.".po"}  @$pofiles)." META.yml" }
);

my $postamble = "generate.po: perl-DateLocale.pot\n";
	foreach (@$pofiles){
		$postamble .= "\t".'$(NOECHO) '.$msgmerge.' -w 83 share/po/'.$_.'.po perl-DateLocale.pot >'.$_.'.po~'.$/;
		$postamble .= "\t".'$(NOECHO) if cmp -s '.$_.'.po~ '.$_.'.po; then rm -f '.$_.'.po~ ; else mv '.$_.'.po~ '.$_.'.po; fi'.$/
	}
	$postamble .= $/.'perl-DateLocale.pot: '.$/;
	$postamble .= "\t".'$(NOECHO) '.$xgettext.' --from-code="UTF-8" `find . -type f -print | grep \'\\.pm$$\'` -o perl-DateLocale.pot'.$/;
	$postamble .= $/."generate.gmo: generate.po".$/;
	foreach (@$pofiles){
		$postamble .= "\t$MSGFMT -o $_.gmo share/po/$_.po$/";
		$postamble .= "\t".'$(NOECHO) $(MKPATH) blib/lib/DateLocale/share/locale/'.$_.'/LC_TIME'.$/;
		$postamble .= "\t".'$(NOECHO) $(CP) '.$_.'.gmo blib/lib/DateLocale/share/locale/'.$_.'/LC_TIME/perl-DateLocale.mo'.$/;
		$postamble .= "\t".'$(NOECHO) $(CHMOD) 644 blib/lib/DateLocale/share/locale/'.$_.'/LC_TIME/perl-DateLocale.mo'.$/;
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
