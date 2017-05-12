use inc::Module::Install;

assertos 'MacOSX';

name 'Cocoa-EventLoop';
all_from 'lib/Cocoa/EventLoop.pm';
readme_from 'lib/Cocoa/EventLoop.pm';

test_requires 'Test::More' => '0.88';
test_requires 'Test::TCP' => '1.11';
author_tests('xt');

auto_set_repository;

use_ppport '3.19';
cc_append_to_libs '-lobjc';

makemaker_args->{dynamic_lib} = {
    OTHERLDFLAGS => '-framework Foundation',
};

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
