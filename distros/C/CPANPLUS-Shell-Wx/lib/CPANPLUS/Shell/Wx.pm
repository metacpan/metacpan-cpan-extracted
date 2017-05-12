package CPANPLUS::Shell::Wx;

# Module name:         CPANPLUS::Shell::Wx
# Author:             Skaman Sam Tyler
# Date:             May 9th, 2008
# Description:         This is a perl Module which is a frontend to CPANPLUS.
#
# NOTES:
#    NOTE I have used the methods contained in CPANPLUS::Shell::Tk to create
#        my skeleton code for this module.


# Preloaded methods go here.

=head1 NAME

CPANPLUS::Shell::Wx - A CPANPLUS GUI Shell written in wxWidgets

=head1 AUTHOR

Skaman Sam Tyler <skamansam@gmail.com>

=head1 SYNOPSIS

  perl -MCPANPLUS -eshell(Wx);


=head1 DESCRIPTION

This is a GUI shell for CPANPLUS.

=head2 FURTHER HELP

There is full online documentation, accessible via the help menu.

=head1 SEE ALSO

CPAN, CPANPLUS, CPANPLUS::Shell::Tk

website: http://wxcpan.googlecode.com
mailing-list: wxcpan@googlegroups.com
mailing-list website: http://groups.google.com/group/wxcpan

=head1 AUTHOR

Skaman Sam Tyler, E<lt>skamansam@gmail.comE<gt>
website: http://rbe.homeip.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Skaman Sam Tyler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use 5.005;
use strict;

use CPANPLUS::Error;
use CPANPLUS::Backend;
use CPANPLUS::Configure::Setup;
use CPANPLUS::Internals::Constants;
use CPANPLUS::Internals::Constants::Report qw[GRADE_FAIL];

use Cwd;
use IPC::Cmd;
use Data::Dumper;
use Wx;

use Module::Load                qw[load];
use Params::Check               qw[check];
use Module::Load::Conditional   qw[can_load check_install];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

use CPANPLUS::Shell::Wx::App;

local $Params::Check::VERBOSE   = 1;
local $Data::Dumper::Indent     = 1; # for dumpering from !

#---- where we begin!
BEGIN {
  use vars        qw( @ISA $VERSION );
  @ISA        =   qw( CPANPLUS::Shell::_Base CPANPLUS::Backend);
  $VERSION    =   '0.04';
}

#initialize the class
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self ={};
  bless $self,$class;
  return $self;
}

#create the shell and start the app
sub shell{
    my $self=shift;
    my $app=CPANPLUS::Shell::Wx::App->new();
    $app->MainLoop;
}

1;