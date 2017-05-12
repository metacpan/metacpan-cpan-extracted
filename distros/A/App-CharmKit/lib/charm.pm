package charm;
$charm::VERSION = '2.07';
# ABSTRACT: Sugary Juju charm authoring goodness



use strict;
use warnings;
no bareword::filehandles;
no indirect ':fatal';

use autobox                       ();
use autobox::Core                 ();
use true                          ();
use feature                       ();
use Path::Tiny                    ();
use Test::More                    ();
use Rex                           ();
use Rex::Commands                 ();
use Rex::Commands::Box            ();
use Rex::Commands::Download       ();
use Rex::Commands::File           ();
use Rex::Commands::Fs             ();
use Rex::Commands::MD5            ();
use Rex::Commands::Network        ();
use Rex::Commands::Notify         ();
use Rex::Commands::Pkg            ();
use Rex::Commands::Rsync          ();
use Rex::Commands::Run            ();
use Rex::Commands::SCM            ();
use Rex::Commands::Service        ();
use Rex::Commands::User           ();
use Rex::Commands::Virtualization ();
use POSIX                         ();

use Import::Into;

use FindBin;
use lib "$FindBin::Bin/../lib";

sub import {
    my $target = caller;
    my $class  = shift;

    my @flags = grep /^-\w+/, @_;
    my %flags = map +($_, 1), map substr($_, 1), @flags;

    'strict'->import::into($target);
    'warnings'->import::into($target);
    'English'->import::into($target, '-no_match_vars');
    'autobox'->import::into($target);
    'autobox::Core'->import::into($target);

    warnings->unimport('once');
    warnings->unimport('experimental');
    warnings->unimport('experimental::signatures');
    warnings->unimport('reserved');

    bareword::filehandles->unimport;
    indirect->unimport(':fatal');

    feature->import(':5.20');
    feature->import('signatures');

    true->import;

    POSIX->import::into($target, qw(strftime));
    Rex->import::into($target, '-feature' => [qw(no_path_cleanup)]);
    Rex::Commands->import::into($target);
    Rex::Commands::Box->import::into($target);
    Rex::Commands::Download->import::into($target);
    Rex::Commands::File->import::into($target);
    Rex::Commands::Fs->import::into($target);
    Rex::Commands::MD5->import::into($target);
    Rex::Commands::Network->import::into($target);
    Rex::Commands::Notify->import::into($target);
    Rex::Commands::Pkg->import::into($target);
    Rex::Commands::Rsync->import::into($target);
    Rex::Commands::Run->import::into($target);
    Rex::Commands::SCM->import::into($target);
    Rex::Commands::Service->import::into($target);
    Rex::Commands::User->import::into($target);
    Rex::Commands::Virtualization->import::into($target);
    Path::Tiny->import::into($target, qw(path cwd));

    if ($flags{tester}) {
        Test::More->import::into($target);
    }

    # overrides
    require 'App/CharmKit/HookUtil.pm';
    'App::CharmKit::HookUtil'->import::into($target);
}


1;

__END__

=pod

=head1 NAME

charm - Sugary Juju charm authoring goodness

=head1 SYNOPSIS

    #!/usr/bin/env perl
    BEGIN {
        # Install charmkit
        system "curl -L http://charmkit.pl/setup.sh | sh";
    }
    
    use charm;
    
    pkg ['znc', 'znc-perl', 'znc-tcl', 'znc-python'],
        ensure => "present";
    
    my $hook_path = $ENV{JUJU_CHARM_DIR};
    
    file "/etc/systemd/system/znc.service", source => "$hook_path/templates/znc.service";
    
    my $content = template("$hook_path/templates/znc.conf", port => config 'port');
    file "/home/ubuntu/.znc/configs", ensure => "directory", owner => "ubuntu", group => "ubuntu";
    file "/home/ubuntu/.znc/configs/znc.conf",
      owner     => "ubuntu",
      group     => "ubuntu",
      content   => $content,
      on_change => sub { service znc => "restart" };

=head1 DESCRIPTION

Sugar package for making Juju charm authoring easier. We import several
underlying packages such as L<Rex>, L<Path::Tiny>, L<Smart::Comments> and
others.

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
