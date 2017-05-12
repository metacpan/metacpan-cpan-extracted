#!/usr/bin/perl -Tw
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

package CfgTie::TieRsrc;

=head1 NAME

CfgTie::TieRsrc -- an associative array of resources and their usage limits

=head1 SYNOPSIS

This module makes the resource limits available as a regular hash

        tie %Resources,'CfgTie::TieRsrc'

=head1 DESCRIPTION

This is a straightforward hash tie that allows us to access the user database
sanely.

The resource limits for the system.
Note: this requires that C<BSD::Resource> be installed.

It is a hash reference.  The keys may be any of C<cpu>, C<data>, C<stack>,
C<core>, C<rss>, C<memlock>, C<nproc>, C<nofile>, C<open_max>, C<as>, C<vmem>,
C<nlimits>, C<infinity>.  The values are always list references of the form:

		[$soft, $hard]

=head1 See Also

L<CfgTie::Cfgfile>, L<CfgTie::TieAliases>,  L<CfgTie::TieGeneric>,
L<CfgTie::TieGroup>,L<CfgTie::TieHost>,     L<CfgTie::TieMTab>,
L<CfgTie::TieNamed>,L<CfgTie::TieNet>,      L<CfgTie::TiePh>,
L<CfgTie::TieProto>,L<CfgTie::TieRCService>,L<CfgTie::TieServ>,
L<CfgTie::TieShadow>

=head1 Author

Randall Maas (L<mailto:randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

my $Ok=0;
if (eval("use BSD::Resource;")) {$Ok=1;}

my $K=
{
   cpu  =>RLIMIT_CPU,
   fsize=>RLIMIT_FSIZE,
   data =>RLIMIT_DATA,
   stack=>RLIMIT_STACK,
   core =>RLIMIT_CORE,
   rss  =>RLIMIT_RSS,
   memlock=>RLIMIT_MEMLOCK,
   nproc  =>RLIMIT_NPROC,
   nofile =>RLIMIT_NOFILE,
   open_max=>RLIMIT_OPEN_MAX,
   as      =>RLIMIT_AS,
   vmem    =>RLIMIT_VMEM,
   nlimits =>RLIMIT_NLIMITS,
   infinity=>RLIMIT_INFINITY,
};
1;

sub TIEHASH
{
   if (!$Ok) {return undef;}
   return bless {}, $_[0];
}

sub FETCH
{
   #Get the limits setting from the system
   getrlimits($_[0]->{id},$->{$_[1]});
}

sub STORE
{
   #Pass the rlimits setting onto the system
   setrlimits($K->{$_[1]}, $_[2]->[0],$_[2]->[1]);
}
