package CPANPLUS::Shell::Default::Plugins::Prereqs;

use strict;
use warnings;
use File::Basename qw[basename];
use CPANPLUS::Internals::Constants;

use Carp;
use Data::Dumper;

our $VERSION = '0.10';

sub plugins {
    return ( prereqs => 'install_prereqs', );
}

sub install_prereqs {
    my $class = shift;          # CPANPLUS::Shell::Default::Plugins::Prereqs
    my $shell = shift;          # CPANPLUS::Shell::Default object
    my $cb    = shift;          # CPANPLUS::Backend object
    my $cmd   = shift;          # 'prereqs'
    my $input = shift;          # show|list|install [dirname]
    my $opts  = shift || {};    # { foo => 0, bar => 2 }

    # get the operation and possble target dir.
    my ( $op, $dir ) = split /\s+/, $input, 2;    ## no critic

    # default to the current dir
    $dir ||= '.';

    # you want us to install, or just list?
    my $install = {
        list    => 0,
        show    => 0,
        install => 1,
    }->{ lc $op };

    # you passed an unknown operation
    unless ( defined $install ) {
        print __PACKAGE__->install_prereqs_help;
        return;
    }

    my $mod;

    # was a directory specified
    if ( -d $dir ) {

        # get the absolute path to the directory
        $dir = File::Spec->rel2abs($dir);

        $mod = CPANPLUS::Module::Fake->new(
            module  => basename($dir),
            path    => $dir,
            author  => CPANPLUS::Module::Author::Fake->new,
            package => basename($dir),
        );

        # set the fetch & extract targets, so we know where to look
        $mod->status->fetch($dir);
        $mod->status->extract($dir);

        # figure out whether this module uses EU::MM or Module::Build
        # do this manually, as we're setting the extract location
        # ourselves.
        $mod->get_installer_type or return;

    } else {

        # get the module per normal
        $mod = $cb->parse_module( module => $dir )
          or return;

    }

    # run 'perl Makefile.PL' or 'M::B->new_from_context' to find the
    # prereqs.
    $mod->prepare(%$opts) or return;

    # get the list of prereqs
    my $href = $mod->status->prereqs or return;

    # print repreq header
    printf "\n  %-30s %10s %10s %10s %10s\n",
      'Module', 'Req Ver', 'Installed', 'CPAN', 'Satisfied'
      if keys %$href;

    # list and/or install the prereqs
    while ( my ( $name, $version ) = each %$href ) {

        # find the module or display msg no such module
        my $obj = $cb->module_tree($name)
          or print "Prerequisite '$name' was not found on CPAN\n" and next;

        # display some info
        printf "  %-30s %10s %10s %10s %10s\n",
          $name, $version, $obj->installed_version, $obj->version,
          ( $obj->is_uptodate( version => $version ) ? 'Yes' : 'No' );

        # that is it, unless we need to install
        next unless $install;

        # we already have this version or better installed
        next if $obj->is_uptodate( version => $version );

        # install it
        $obj->install(%$opts);
    }

    return;
}

sub install_prereqs_help {
    return
        "    /prereqs <cmd> [mod]  # Install missing prereqs for given module\n"
      . "        <cmd>  =>  show|list|install\n"
      . "        [mod]      directory, module name or URL (defaults to .)\n";

}

1;

__END__

=head1 NAME

CPANPLUS::Shell::Default::Plugin::Prereqs - Plugin for CPANPLUS to automate the installation of prerequisites without installing the module

=head1 SYNOPSIS

  use CPANPLUS::Shell::Default::Plugin::Prereqs;

  $ cpanp /prereqs <show|list|install> [Module|URL|dir]

=head1 DESCRIPTION

A plugin for CPANPLUS's default shell which will display and/or install any
missing prerequisites for a module. The module can be specified by name, as a
URL or path to the directory of an unpacked module. The plugin assumes the
current directory if no module is specified.

=head1 EXAMPLE COMMAND LINES

The following would list any reprequsites found in the Build.PL or Makefile.PL
for the C<MyModule> module:

  $ cd MyModule
  $ cpanp /prereqs show .

Or you could just have given the module name, and C<cpanp> will find the the
module on CPAN:

  $ cpanp /prereqs show YAML

And of course you can install the prereqs:

  $ cd MyModule
  $ cpanp /prereqs install .

=head1 SUBROUTINES

The module subroutines are primarily expected to be utilized by the
C<CPANPLUS> plugin infrasctructure.

=head2 plugins

Reports the plugin routines provided by this module.

=head2 install_prereqs

Performs the reqrequsite listing or installation. Conforms to the
C<CPANPLUS::Shell::Default::Plugins::HOWTO> API.

=head2 install_prereqs_help

Returns the short version documentation for the plugin.

=head1 SEE ALSO

C<CPANPLUS>, C<CPANPLUS::Shell::Default::Plugins::HOWTO>

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 THANKS

Thanks to Jos Boumans for his excellent suggestions to improve both the plugin
functionality and the quality of the code.

=head1 TODO

Add test for MakeMaker and Module::Install based modules. Add test for
/prereq install. Split C<install_prereqs> into multiple subroutines.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-12 by mgrimes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
