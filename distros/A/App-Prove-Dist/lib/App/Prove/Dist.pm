##
# name:      App::Prove::Dist
# abstract:  Prove that a Perl Module Dist is OK for CPAN
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.010;

use local::lib 1.008004 (); # XXX Change dep to lib::core::only
use App::Prove 3.23 ();
use App::cpanminus 1.5003 ();
use Capture::Tiny 0.11 ();
use IO::All 0.44 ();
use Module::ScanDeps 1.04 ();
use Mouse 0.97 ();
use MouseX::App::Cmd 0.08 ();
use YAML::XS 0.37 ();

#-----------------------------------------------------------------------------#
package App::Prove::Dist;
use Mouse;
extends 'MouseX::App::Cmd';
use App::Cmd::Setup -app;

our $VERSION = '0.02';

# XXX Doesn't seem to always work
use constant default_command => 'test';

#------------------------------------------------------------------------------#
# Common options
#------------------------------------------------------------------------------#
package App::Prove::Dist::common_options;
use Mouse::Role;

has perl => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    documentation => 'Version or path of perl to use',
);

#------------------------------------------------------------------------------#
package App::Prove::Dist::Command::test;
App::Prove::Dist->import( -command );
use Mouse;
extends 'App::Prove::Dist::Command';
with 'App::Prove::Dist::common_options';

use constant abstract => 'Test the Perl module dist from the current directory';
use constant usage_desc => "prove-dist test --flags='-v' --perl=<perl-version>";

has flags => (
    is => 'ro',
    isa => 'Str',
    default => sub { '' },
    documentation => "Commandline flags to be passed to 'prove'",
);

has dirty => (
    is => 'ro',
    isa => 'Bool',
    documentation => "Don't clean up after test",
);

sub execute {
    my ($self) = @_;
    $self->setup();
    for my $perl ($self->get_perl_list) {
        $self->test($perl);
    }
    $self->cleanup() unless $self->dirty;
}

#------------------------------------------------------------------------------#
package App::Prove::Dist::Command::make;
App::Prove::Dist->import( -command );
use Mouse;
extends 'App::Prove::Dist::Command';
with 'App::Prove::Dist::common_options';

use constant abstract => 'Make a custom locallib for your dist/perl';
use constant usage_desc => 'prove-dist make --perl=<perl-version>';

sub execute {
    my ($self) = @_;
    $self->setup();
    for my $perl ($self->get_perl_list) {
        $self->make($perl);
    }
    $self->cleanup();
}

#------------------------------------------------------------------------------#
package App::Prove::Dist::Command::wipe;
App::Prove::Dist->import( -command );
use Mouse;
extends 'App::Prove::Dist::Command';
with 'App::Prove::Dist::common_options';

use constant abstract => 'Remove the custom locallib for your dist/perl';
use constant usage_desc => 'prove-dist wipe --perl=<perl-version>';

sub execute {
    my ($self) = @_;
    $self->setup();
    for my $perl ($self->get_perl_list) {
        $self->wipe($perl);
    }
    $self->cleanup();
}

#------------------------------------------------------------------------------#
package App::Prove::Dist::Command::list;
App::Prove::Dist->import( -command );
use Mouse;
extends 'App::Prove::Dist::Command';

use constant abstract => 'List your declared deps';
use constant usage_desc => 'prove-dist list';

sub execute {
    my ($self) = @_;
    $self->setup();
    print YAML::XS::Dump($self->_meta->{requires});
    $self->cleanup();
}

#------------------------------------------------------------------------------#
package App::Prove::Dist::Command::scan;
App::Prove::Dist->import( -command );
use Mouse;
extends 'App::Prove::Dist::Command';

use constant abstract => 'Scan your dist for deps';
use constant usage_desc => 'prove-dist scan';

use IO::All;

sub execute {
    my ($self) = @_;
    die "Sorry. 'prove-dist scan' not yet implemented.\n";
    $self->setup();
    print YAML::XS::Dump(
        Module::ScanDeps::scan_deps(
            files => [map "$_", io('lib')->All_Files],
            recurse => 0,
        )
    );
    $self->cleanup();
}

#------------------------------------------------------------------------------#
package App::Prove::Dist::Command::perls;
App::Prove::Dist->import( -command );
use Mouse;
extends 'App::Prove::Dist::Command';

use constant abstract => 'List your available perls';
use constant usage_desc => 'prove-dist perls';

use IO::All;

sub execute {
    my ($self) = @_;
    $self->setup();
    for my $perl (sort {"$a" cmp "$b"} @{io($self->perls_root)}) {
        my $name = $perl->filename;
        my $locallib = $self->get_locallib($name);
        my $status = -e $locallib
        ? " -> $locallib"
        : '';
        $name =~ s/^perl-// or next;
        print "$name$status\n";
    }
    $self->cleanup();
}

#------------------------------------------------------------------------------#
# Command base class.
#------------------------------------------------------------------------------#
package App::Prove::Dist::Command;
use App::Cmd::Setup -command;
use Mouse;
extends 'MouseX::App::Cmd::Command';

use Cwd;
use IO::All;
use lib::core::only ();

has debug => (
    is => 'ro',
    isa => 'Bool',
    documentation => 'Print debugging info',
);

has _opts => (is => 'rw');
has _args => (is => 'rw');
has _src => (is => 'rw', default => sub {'.'});
has _meta => (is => 'rw');
has _dist_dir => (is => 'rw');
has _dist_type => (is => 'rw');

sub perlbrew_root {
    return (
        $ENV{PERLBREW_ROOT} ||
        "$ENV{HOME}/perl5/perlbrew"
    );
}

sub prove_dist_root {
    return (
        $ENV{PERL_PROVE_DIST_ROOT} ||
        (Cwd::abs_path(perlbrew_root() . "/../prove-dist"))
    );
}

sub perls_root {
    return ( perlbrew_root() . "/perls" );
}

# use XXX;

my $num = 0;
sub test {
    my ($self, $perl) = @_;
    my $dist = $self->_dist_dir;
    my $tarball = "$dist.tar.gz";
    die "'$tarball' not found" unless -e $tarball;
    my $home = Cwd::cwd();
    $self->run_cli_cmd("tar xzf $tarball")
        unless -d $dist;
    chdir $dist or die "Can't chdir to $dist";
    io('lib/lib/core/only.pm')->assert->print(io($INC{'lib/core/only.pm'})->all);

    my $flags = $self->flags;
    (my $path = $perl) =~ s!/perl$!! or die;
    local $ENV{PATH} = "$path:$ENV{PATH}";
    my $locallib = $self->get_locallib($perl);
    local $ENV{PERL5LIB} = -e $locallib
    ? "./inc:./lib:$locallib/lib/perl5"
    : './inc:./lib';
    local $ENV{PERL5OPT};
    $self->run_cli_cmd("prove $flags -Mlib::core::only t/");
    chdir $home or die "Can't chdir '$home'";
    $self->run_cli_cmd("rm -fr $dist") unless $self->dirty;
    $num++;
    print "ok $num - $dist on $perl\n";
}

sub make {
    my ($self, $perl) = @_;
    my $locallib = $self->get_locallib($perl);
    my $cpanm = `which cpanm`
        or die "Can't find cpanm";
    chomp $cpanm;
    local $ENV{PERL_CPANM_OPT};
    for my $module (sort keys %{$self->_meta->{requires}}) {
        next if $module eq 'perl';
        print "Installing $module\n";
        my $out = $self->run_cli_cmd("$perl $cpanm -l $locallib $module");
        print $out if $self->debug;
    }
}

sub wipe {
    my ($self, $perl) = @_;
    my $locallib = $self->get_locallib($perl);
    if (not -e $locallib) {
        warn "Can't wipe '$locallib'. No such directory";
        return;
    }
    $self->run_cli_cmd("rm -fr $locallib");
}

sub get_locallib {
    my ($self, $perl) = @_;
    my $perls_root = $self->perls_root;
    $perl =~ s/^$perls_root//;
    $perl =~ s/[^\w\.]+/-/g;
    $perl =~ s/-bin-perl$//;
    $perl =~ s/^-?(.*?)-?$/$1/;
    my $dist = $self->_meta->{name} or die;
    return prove_dist_root() . "/$dist/$perl";
}

sub get_perl_list {
    my ($self) = @_;
    my $perls_root = $self->perls_root;
    my $perls = $self->perl || do {
        my $perl = `which perl`;
        chomp $perl;
        [$perl];
    };
    for (my $i = 0; $i < @$perls; $i++) {
        my $perl = $perls->[$i];
        if ($perl =~ /^\d/) {
            $perl = "$perls_root/perl-$perl/bin/perl";
        }
        die "'$perl' not found" unless -e $perl;
        $perls->[$i] = $perl;
    }
    return @$perls;
}

sub setup {
    my ($self) = @_;
    my $args = $self->_args;
    if (my $count = @$args) {
        if ($count == 1) {
            $self->_src($args->[0]);
        }
        else {
            $self->usage();
            exit 1;
        }
    }
    my $src = $self->_src;
    chdir $self->_src or die "Can't chdir to $src";
    if (-e 'dist.ini') {
        die "Distzilla not yet supported";
    }
    if (not -e "Makefile.PL") {
        die "'$src' does not have a 'Makefile.PL";
    }
    $self->_dist_type('eumm');
    if (-e 'Makefile') {
        $self->run_cli_cmd("make purge");
    }
    $self->run_cli_cmd("perl Makefile.PL");
    $self->run_cli_cmd("make manifest");
    $self->run_cli_cmd("make dist");
    my ($dist) = glob("*.tar.gz");
    die "'make dist' seems to have failed"
        unless $dist;
    $self->run_cli_cmd("tar xzf $dist");
    $dist =~ s/\.tar\.gz$// or die;
    $self->_dist_dir($dist);
    $self->_meta(YAML::XS::LoadFile("$dist/META.yml"));
}

sub cleanup {
    my ($self) = @_;
    $self->run_cli_cmd("make purge");
}

sub run_cli_cmd {
    my ($self, $command) = @_;
    print "-> $command\n" if $self->debug;
    my $rc;
    my $out = Capture::Tiny::capture_merged {
        $rc = system($command);
    };
    die "FAIL '$command':\n$out\n" unless $rc == 0;
    return $out;
}

# Hack to suppress extra options I don't care about.
around usage=>sub{$a=$_[1]->{usage}{options};@$a=grep{$_->{name}ne'help'}@$a;$_[0]->($_[1])};

sub validate_args {
    my ($self, $opts, $args) = @_;
    $self->_opts($opts);
    $self->_args($args);
}

1;

=head1 SYNOPSIS

    prove-dist                      # make dist; unzip dist;
                                    # test against core-only + custom-locallib
    prove-dist test --perl=5.14.1   # use a specific perl
    prove-dist test --perl=5.10.1 --perl=5.12.0 --perl=5.14.2
    prove-dist list                 # list your defined dependencies
    prove-dist scan                 # scan for your required dependencies
    prove-dist make --perl=...      # make a custom locallib for your dist
                                      # and your perl. prove-dist will look 
                                      # for this lib when you test your dist
    prove-dist wipe --perl=...      # delete the custom locallib
    prove-dist perls                # list perls to test against

=head1 STATUS

THIS IS A ROUGH DRAFT AND PROOF OF CONCEPT RELEASE! DON'T USE IT YET!

Currently:

    * Only likes Unix
    * Only likes perlbrew
    * Many hardcoded assumptions
    * Scan not implemented
    * Not fully configurable
    * Will probably push your grandmother down the stairs

Suggestions and patches welcome!

=head1 DESCRIPTION

When releasing a Perl module distribution, it is good to test it on a clean
perl installation and on muliple versions of installed perl. Many modules have
dependency modules, so a truly clean Perl won't work. You can use locallib to
work around that. You'll need to set up a locallib for each version of perl,
for each module you release.

App::Prove::Dist does all this for you:

    cd your-dist-dir
    prove-dist perls                # Get a list of perls to use
    prove-dist make --perl=5.14.2   # Create a custom locallib for a perl
    prove-dist perls                # List now shows locallib
    prove-dist test --perl=5.14.2   # Prove against clean perl + new locallib

C<prove-dist> will use C<lib-core-only> and your custom locallib to prove your
C<t/> tests, so you can be more certain it will pass cpantesters.
