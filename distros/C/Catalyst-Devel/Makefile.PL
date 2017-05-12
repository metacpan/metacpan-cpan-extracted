use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

name     'Catalyst-Devel';
all_from 'lib/Catalyst/Devel.pm';
authority 'cpan:MSTROUT';

requires 'Moose';
requires 'MooseX::Emulate::Class::Accessor::Fast';
requires 'File::ShareDir';
requires 'namespace::clean';
requires 'namespace::autoclean';
requires 'Catalyst'    => '5.90001';
requires 'Catalyst::Action::RenderView' => '0.10';
requires 'Catalyst::Plugin::Static::Simple' => '0.28';
requires 'Catalyst::Plugin::ConfigLoader' => '0.30';
requires 'Config::General' => '2.42'; # as of 1.07, we use .conf and not .yaml
requires 'File::ChangeNotify' => '0.07';
requires 'File::Copy::Recursive';
requires 'Path::Class' => '0.09';
requires 'Template'    => '2.14';

if (!$Module::Install::AUTHOR && $^O ne 'MSWin32') {
    requires 'MooseX::Daemonize'; # Optional in scripts
    requires 'Starman'; # Optional in scripts
}

# The Catalyst applications this module distribution have a Makefile.PL using
# Module::Install as well as the Module::Install::Catalyst extension included in
# this distribution. Therefore we really *depend* on Module::Install to be
# installed, even though we also use it to build this distribution and include
# it in its inc/ directory for releases.
requires 'Module::Install' => '1.02';

author_requires 'IPC::Run3';
author_requires 'Module::Info';
author_requires 'File::Find::Rule';
author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';

test_requires 'Test::More' => '0.94';
test_requires 'Test::Fatal' => '0.003';

install_share 'share';

author_tests 't/author';

if (!$ENV{CATALYST_DEVEL_NO_510_CHECK}) {
    use Symbol 'gensym';
    use IPC::Open3;
    use File::Spec;
    open NULL, '>', File::Spec->devnull;
    my $err = gensym;
    my $pid = open3(gensym, '&>NULL', $err, "$^X -It/lib -MUnknownError -e 1");

    my $unknown_error = 0;

    while (<$err>) {
        $unknown_error = 1 if /^Unknown error/;
    }

    waitpid $pid, 0;

    if ($unknown_error) {
        warn <<EOE;
############################### WARNING #################################
#                                                                       #
# You are using perl 5.10.0 with the "Unknown error" bug. This can make #
# developing Catalyst applications much more painful, as it will come   #
# up with no details every time you have a syntax error in a Controller.#
#                                                                       #
# For more information see:                                             #
#                                                                       #
#  * http://rt.perl.org/rt3/Public/Bug/Display.html?id=49472            #
#                                                                       #
# It is highly recommended that you use a different version of perl or  #
# compile a patched version for Catalyst development.                   #
#                                                                       #
# To skip this check, set the CATALYST_DEVEL_NO_510_CHECK environment   #
# variable.                                                             #
#                                                                       #
#########################################################################

EOE
        my $ans = prompt('Do you want to continue?', 'no');
        exit 0 unless $ans =~ /^y(es)?\z/i;
    }
}

# kill warning from older versions of Class::C3
if ($] >= 5.009_005 && can_use('Class::C3') && !can_use('Class::C3', 0.20)) {
    requires 'Class::C3' => '0.20';
}

auto_install;

WriteAll;

if ($Module::Install::AUTHOR) {
    Meta->{values}{resources} = [
        [ 'MailingList' => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst' ],
        [ 'IRC'         => 'irc://irc.perl.org/#catalyst' ],
        [ 'license',    => 'http://dev.perl.org/licenses/' ],
        [ 'homepage',   => 'http://dev.catalyst.perl.org/'],
        [ 'repository', => 'git://git.shadowcat.co.uk/catagits/Catalyst-Devel.git' ],
    ];

    Meta->{values}{requires} = [ grep {
        $_->[0] ne 'Class::C3'
    } @{ Meta->{values}{requires} } ];

    Meta->write;
}
