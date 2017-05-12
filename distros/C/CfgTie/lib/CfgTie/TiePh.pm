#Copyright 1998-1999, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.


#Author: Randall Maas (randym@acm.org)

=head1 NAME

C<CfgTie::TiePh> -- a ph phonebook server configuration tool

=head1 SYNOPSIS

Makes it easy to manage the ph phonebook server configuration files as a hash.

   tie %myhash, 'ph'

   %myhash{who}->{Person}

=head1 DESCRIPTION

This is a file to help configure the F<ph> program.

   tie %myhash, 'ph'

   %myhash{who}->{Person}
   %myhash{who}->{Phone}

=head2 Methods

This inherits any methods from the C<CfgTie::Cfgfile> module
(L<CfgTie::Cfgfile>)

=head1 See Also

L<CfgTie::Cfgfile>,   L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>,
L<CfgTie::TieGroup>,  L<CfgTie::TieHost>,    L<CfgTie::TieMTab>,
L<CfgTie::TieNamed>,  L<CfgTie::TieNet>,     L<CfgTie::TiePh>,
L<CfgTie::TieProto>,  L<CfgTie::TieRCService>, L<CfgTie::TieRsrc>,
L<CfgTie::TieServ>,   L<CfgTie::TieShadow>, L<CfgTie::TieUser>

=head1 Author

Randall Maas (L<randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

package CfgTie::TiePh;
require CfgTie::Cfgfile;
require Tie::Hash;
@ISA=qw(CfgTie::Cfgfile);

sub scan
{
    my $self=shift;

   if (!exists $self->{Path} ||
       !defined !$self->{Path}) {$self->{Path} = 'qi.input';}

   my $F = new Secure::File '<'.$self->{Path};
   my ($who,$eml,$phn);
   while (my $J = <$F>)
    {
       foreach my $I (split("\t",$J))
        {
           $_ = $I;
           if (/([^:\n]*):([^\n]*)/)
             {
                   if ($1 == 3) {$who=$2;}
                elsif ($1==2) {$eml=$2;}
                elsif ($1==1) {$phn=$2;}
             }
        }
       $self->{Contents}->{$who}->{Person}=$eml;
       $self->{Contents}->{$who}->{Phone} =$phn;
    }
   $F->close;
}

sub makerewrites {}

sub cfg_end
{
   my $self=shift;
   my $Path='./';
   $_ = $self->{Path};
   if (/^(.*\/)[^\/]$/) {$Path = $1;}
   CfgTie::Cfgfile::system('cd '.$Path.'db;credb 10240 prod;maked prod <'.
	  $self->{Path}.
          ';makei prod;build -s prod');
}

