use 5.004;

# Win32->UNIX CRLF converter for MakeMaker
# then usual 'make dist' will convert all ascii files to UNIX format
# (I suppose only .dll files might be binary here)
$PREOP =<<'EOP';
$(FULLPERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
  -e "$$dir = $$ARGV[0];use File::Find;" \
  -e "find(\&process, $$dir); sub process { return if -d || /\.dll$$/i;" \
  -e "open(I,$$_) || die \"to_unix: can't read file `$$_'\n\";" \
  -e "@file = <I>; close I;chmod 0666, $$_;" \
  -e "open(O,\">$$_\") || die \"to_unix: can't write file `$$_'\n\";" \
  -e "binmode O;print O map { s/\r\n/\n/;$$_ } @file; close O; }" $*
EOP

use ExtUtils::MakeMaker;
WriteMakefile(
    "NAME"		=> "Crypt::CBCeasy",
    "DISTNAME"		=> "Crypt-CBCeasy",
    "VERSION_FROM"	=> "CBCeasy.pm",
    "PREREQ_PM"		=> { "Crypt::CBC" => "1.20", "MD5" => 0 },
    ($] < 5.005 ? () :
      (
	"ABSTRACT"	=> "Easy things make really easy with Crypt::CBC",
	"AUTHOR"	=> "Mike Blazer <blazer\@mail.nevalink.ru>",
    )),
    "dist"		=> { COMPRESS => 'gzip -9frN', SUFFIX => 'gz',
	($^O eq "MSWin32" ? (PREOP => $PREOP) : ())},
    "clean"		=> { FILES => "./tests pod2* *.html" },
);

sub MY::postamble {
    my $postamble =<<'END';

html: CBCeasy.pm
	pod2html --netscape --noindex CBCeasy.pm > CBCeasy.pm.html
END

    $postamble;
}

