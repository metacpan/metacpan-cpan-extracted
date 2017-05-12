use strict;

#use warnings FATAL => 'all';

require 5.005003;

my @clean_files = ();

my $mp_gen = satisfy_mp_generation();
warn "Goind to build against mod_perl/$mod_perl::VERSION Perl/$]\n";
test_configure($mp_gen);

# prerequisites
my %require_common = (
   "Apache::Test"       => "1.15", # config fixes
   "Time::HiRes"        => "1.19",
   "Template"           => "2.0",
);

my %require_mp1 =  (
   "GTop"               => "0.09",
   "mod_perl"           => "1.25",
   "Apache::Scoreboard" => "0.15",
);

my %require_mp2 =  (
   "GTop"               => "0.12",
   "mod_perl2"          => "2.0",
   "Apache::Scoreboard" => "2.08",
);

my %require = (%require_common, ($mp_gen == 1 ? %require_mp1 : %require_mp2));

# XXX
#prereqs();

my @scripts = qw(t/TEST);

my %common_opts = (
    NAME         => 'Apache::VMonitor',
    VERSION_FROM => 'lib/Apache/VMonitor.pm',
    PREREQ_PM    => \%require,
    clean        => {
        FILES => "@{ clean_files() }",
    }
);

if ($mp_gen == 1) {
    require ExtUtils::MakeMaker;
    ExtUtils::MakeMaker::WriteMakefile(
        %common_opts,
    );

}
else {
    require ModPerl::MM;
    ModPerl::MM::WriteMakefile(
        %common_opts,
    );
}

sub clean_files {
    return \@clean_files;
}

sub prereqs {
    for (keys %require) {
        chk_version($_ => $require{$_}) or
            warn "\n*** For Apache::VMonitor to work you require version " .
                "$require{$_}, or later, of $_.pm from CPAN\n";
    }
}

sub chk_version {
    my($pkg, $wanted) = @_;

    no strict 'refs'; 
    local $| = 1;

    print "Checking for $pkg...";

    eval { (my ($p) = $pkg . ".pm") =~ s#::#/#g; require $p;};
    print("not ok\n$@"), return if $@;

    my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
        : "not found";
    my $vnum = ${"${pkg}::VERSION"} || 0;

    print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

    $vnum >= $wanted;

}

sub test_configure {
    my $mp_gen = shift;

    if (eval { require Apache::TestMM }) {
        Apache::TestMM->import(qw(test clean));
        my @scripts = qw(t/TEST);
        # accept the configs from command line

        # check for http in common locations
        unless (grep $_ eq "httpd", @ARGV)
        {
            my @common = ('/sbin/', '/usr/sbin/', '/usr/bin/', '/bin', '/usr/local/sbin', '/usr/local/bin', '/opt/apache', '/opt/apache2' );
            foreach my $dir (@common)
            {
                if ( -e $dir . "httpd")
                {
                    push @ARGV, ( 'httpd', $dir . "httpd" );
                    last;
                }
                if ( -e $dir . "httpd2")
                {
                    push @ARGV, ( 'httpd', $dir . "httpd2" );
                    last;
                }
            }
        }

        Apache::TestMM::filter_args();

        Apache::TestMM::generate_script($_) for @scripts;

        push @clean_files, @scripts;
    } else {
        warn "***: You should install Apache::Test to do real testing\n";
        # META: soon on CPAN
        *MY::test = sub {
            return <<'EOF';
test : pure_all
	@echo \*** This test suite requires Apache::Test available from the
	@echo \*** mod_perl 2.0 sources or the httpd-test distribution.
EOF
        }
    }
}

# If a specific generation was passed as an argument,
#     if satisfied
#         return the same generation
#     else
#         die
# else @ARGV and %ENV will be checked for specific orders
#     if the specification will be found
#         if satisfied
#             return the specified generation
#         else
#             die
#     else if any mp generation is found
#              return it
#           else
#              die

sub satisfy_mp_generation {
    my $wanted = shift || wanted_mp_generation();

    unless ($wanted == 1 || $wanted == 2) {
            die "Could not find mod_perl.pm or mod_perl2.pm, please make sure you have mod_perl installed.
                 You need mod_perl for Apache 1.x and mod_perl2 for Apache 2.x";
    }

    my $selected = 0;

    if ($wanted == 1) {
        require_mod_perl();
        if ($mod_perl::VERSION >= 1.99) {
            # so we don't pick 2.0 version if 1.0 is wanted
            die "You don't seem to have mod_perl 1.0 installed";
        }
        $selected = 1;
    }
    elsif ($wanted == 2) {
        #warn "Looking for mod_perl 2.0";
        require_mod_perl();
        if ($mod_perl::VERSION < 2.0) {
            die "You don't seem to have mod_perl 2.0 installed";
        }
        $selected = 2;
    }
    else {
        require_mod_perl();
        $selected = $mod_perl::VERSION >= 1.99 ? 2 : 1;
        warn "Using $mod_perl::VERSION\n";
    }

    return $selected;
}

sub require_mod_perl {
    eval { require mod_perl };
    eval { require mod_perl2 }  if ($@);
    die "Can't find mod_perl installed\nThe error was: $@" if $@;
}

# the function looks at %ENV and Makefile.PL option to figure out
# whether a specific mod_perl generation was requested.
# It uses the following logic:
# via options:
# perl Makefile.PL MOD_PERL=2
# or via %ENV:
# env MOD_PERL=1 perl Makefile.PL
#
# return value is:
# 1 or 2 if the specification was found (mp 1 and mp 2 respectively)
# 0 otherwise
sub wanted_mp_generation {

    # check if we have a command line specification
    # flag: 0: unknown, 1: mp1, 2: mp2
    my $flag = 0;
    my @pass;
    while (@ARGV) {
        my $key = shift @ARGV;
        if ($key =~ /^MOD_PERL=(\d)$/) {
            $flag = $1;
        }
        else {
            push @pass, $key;
        }
    }
    @ARGV = @pass;

    # check %ENV
    my $env = exists $ENV{MOD_PERL} ? $ENV{MOD_PERL} : 0;

    # check for contradicting requirements
    if ($env && $flag && $flag != $env) {
        die <<EOF;
Can\'t decide which mod_perl version should be used, since you have
supplied contradicting requirements:
    enviroment variable MOD_PERL=$env
    Makefile.PL option  MOD_PERL=$flag
EOF
    }

    my $wanted = 0; 
    $wanted = 2 if $env == 2 || $flag == 2;
    $wanted = 1 if $env == 1 || $flag == 1;

    unless ($wanted) {
        # if still unknown try to require mod_perl.pm
        eval { require mod_perl };
        if ($@) {
            # if we don't have mp2, check for mp2
            eval { require mod_perl2 } if ($@);
            unless ($@) {
                $wanted = 2;
            }
        }
        else {
            $wanted = 1;
        }
    }

    return $wanted;
}


__END__
