use strict;
use warnings;

{
    # check OS and version
    die 'OS unsupported' unless ($^O eq 'darwin');

    my @ver = map { chomp; $_ } split /\./, `sw_vers -productVersion`;
    my $ver = sprintf '%d.%03d%03d', @ver;

    die 'Mac OS X 10.7 or later is required' unless $ver ge '10.007';
}

BEGIN {
    my @devmods = qw(
        Module::Install::AuthorTests
        Module::Install::ReadmeFromPod
        Module::Install::Repository
        Module::Install::XSUtil
        Module::Install::AssertOS
    );
    my @not_available;

    {
        local *STDOUT;
        eval qq{use inc::Module::Install; 1;} or push @not_available, 'inc::Module::Install';
    }

    for my $mod (@devmods) {
        eval qq{require $mod} or push @not_available, $mod;
    }
    if (@not_available) {
        print qq{# The following modules are not available.\n};
        print qq{# `$^X $0 | cpanm` will install them:\n};
        print $_, "\n" for @not_available;
        print "\n";
        exit -1;
    }
}

use inc::Module::Install;
$Module::Install::AUTHOR = 0 if $ENV{TRAVIS};

name 'Cocoa-BatteryInfo';
all_from 'lib/Cocoa/BatteryInfo.pm';
readme_from 'lib/Cocoa/BatteryInfo.pm';

test_requires 'Test::More' => '0.86';

requires 'perl' => '5.008001';

author_tests 'xt';
auto_set_repository;

use_ppport '3.20';

makemaker_args->{dynamic_lib} = {
    OTHERLDFLAGS => '-framework Foundation -framework IOKit',
};

{
    no warnings 'redefine';

    # http://www.mail-archive.com/makemaker@perl.org/msg02823.html
    # Add some required machinery to support .m files
    package MY;
    sub c_o {
        my $inherited = shift->SUPER::c_o(@_);
        $inherited .= <<'EOMESS';
.m$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.m

EOMESS
        $inherited;
    }

    sub xs_c {
        my $inherited = shift->SUPER::xs_c(@_);
        $inherited .= <<'EOMESS';
.xs.m:
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $(XSUBPP_EXTRA_ARGS) $*.xs > $*.xsm && $(MV) $*.xsm $*.m

EOMESS
        $inherited;
    }

    sub init_dirscan {
        my $self = shift;
        $self->SUPER::init_dirscan;
    
        foreach my $name ($self->lsdir($self->curdir)) {
            next unless $name =~ /\.m$/;
            push @{$self->{'C'}}, $name;
            $name =~ s/\.m$/$self->{'OBJ_EXT'}/;
            push @{$self->{'O_FILES'}}, $name;
        }
    }
}

WriteAll;
