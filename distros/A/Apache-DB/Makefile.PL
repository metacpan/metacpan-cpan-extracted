use ExtUtils::MakeMaker;

use 5.005;
use strict;
use File::Copy 'cp';
use subs 'iedit';

my $perl5db;

for (@INC) {
    last if -e ($perl5db = "$_/perl5db.pl");
}

warn "creating Apache/perl5db.pl from $perl5db\n";

cp $perl5db => './perl5db.pl';
#poor man's patch
iedit './perl5db.pl', "s/^END /sub db_END /";
#iedit './perl5db.pl', "s/(.SIG{INT}) /#\$1 /";

WriteMakefile(
    'NAME'	=> 'Apache::DB',
    'VERSION_FROM' => 'DB.pm',
    'macro' => {
         CVSROOT => 'modperl.com:/local/cvs_repository',
    },
);

sub MY::postamble {
    return <<'EOF';

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) .
	@echo update DB.pm VERSION now

EOF
}

sub MY::post_initialize {
    my $self = shift;
    $self->{PM}{"perl5db.pl"} = '$(INST_ARCHLIB)/' . "Apache/perl5db.pl";

    '';
}

sub iedit {
    my $file = shift;
    system $^X, "-pi~", "-e", "@_", $file;
}







