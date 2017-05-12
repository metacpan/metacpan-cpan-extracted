use inc::Module::Install;
use File::Spec;

{
    # check OS and version
    die 'OS unsupported' unless ($^O eq 'darwin');

    my @ver = map { chomp; $_ } split /\./, `sw_vers -productVersion`;
    my $ver = sprintf '%d.%03d%03d', @ver;

    die 'OS unsupported' unless $ver ge '10.005';
}

name 'Cocoa-Growl';
all_from 'lib/Cocoa/Growl.pm';
readme_from 'lib/Cocoa/Growl.pm';

requires 'parent';
requires 'URI';
requires 'File::ShareDir';

test_requires 'Test::More' => '0.88';
author_tests('xt');

auto_set_repository;

use_ppport '3.19';
cc_append_to_libs '-lobjc';

my $use_local_framework;
if ($use_local_framework = (grep(/USE_LOCAL_GROWL_FRAMEWORK=.*/, @ARGV))[0] ) {
    $use_local_framework =~ s/.*?=//;
}
@ARGV = grep !/USE_LOCAL_GROWL_FRAMEWORK/, @ARGV;

if ($use_local_framework) {
    cc_append_to_ccflags '-DUSE_LOCAL_GROWL';

    makemaker_args->{dynamic_lib} = {
        OTHERLDFLAGS => '-framework Foundation -framework Growl',
    };
}
else {
    cc_append_to_ccflags sprintf '-I%s',
        File::Spec->rel2abs(File::Spec->catfile('share', 'Growl.framework', 'Versions', 'A', 'Headers'));

    makemaker_args->{dynamic_lib} = {
        OTHERLDFLAGS => '-framework Foundation',
    };

    install_share;
}

{
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
