#!/usr/bin/perl -w
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

package CfgTie::TieGeneric;
use Secure::File;
use vars qw($VERSION @ISA);
use AutoLoader 'AUTOLOAD';
$VERSION='0.41';

=head1 NAME

CfgTie::TieGeneric -- A generic hash that automatically binds others

=head1 SYNOPSIS

This is an associative array that automatially ties other configuration hashes

=head1 DESCRIPTION

This is a tie to bring other ties together automatically so you, the busy
programmer and/or system administrator, don't have to.  The related Perl
module is not loaded unless it is needed at runtime.

        my %gen;
        tie %gen, 'CfgTie::TieGeneric';

=head2 Primary, or well-known, keys

=over 1

=item C<env>

This refers directly to the C<ENV> hash.

=item C<group>

=item C<mail>

This is a special key.  It forms a hash, with subkeys.  See below for more
information

=item C<net>

This is a special key.  It forms a hash with additional subkeys. See
below for more details.

=item C<user>

This is a link to the C<TieUser> module (L<CfgTie::TieUser>).

=item I<Composite>

Composite primary keys are just like absolute file paths.  For example, if
you wanted to do something like this:

        my %lusers = $gen{'user'};
        my $Favorite_User = $lusers{'mygirl'};

You could just do:

        my $Favorite_User = $gen{'/users/mygirl'};

=item others...

These are the things automatically included in.  This will be described below.

=back

=head2 Subkeys for C<mail>

=over 1

=item C<aliases>

L<CfgTie::TieAliases> 

=back

=head2 Subkeys for C<net>

=over 1

=item C<host>

L<CfgTie::TieHost>

=item C<service>

L<CfgTie::TieServ>

=item C<protocol>

L<CfgTie::TieProto>

=item C<addr>

L<CfgTie::TieNet>

=back

=head2 How other ties are automatically bound

Other keys are automatically (if it all possible) brought in using the
following procedure:

=over 1

=item 1. If it is something already linked to it, that thingy is automatically
returned (of course).

=item 2. If the key is simple, like F<AABot>, we will try to C<use AABot;>
If that works we will tie it and return the results.

=item 3. If the key is more complex, like F</OS3/Config>, we will try to see
if C<OS3> is already tied (and try to tie it, like above, if not).  If that
works, we will just look up C<Config> in that hash.  If it does not work, we
will try to C<use> and C<tie> C<OS3::Config>, C<OS3::TieConfig>, and
C<OS3::ConfigTie>.  If any of those work, we return the results.

=item 4. Otherwise, C<undef> will be returned.

=back


=head1 See Also

L<CfgTie::TieAliases>, L<CfgTie::TieGroup>, L<CfgTie::TieHost>,
L<CfgTie::TieMTab>,    L<CfgTie::TieNamed>, L<CfgTie::TieNet>,
L<CfgTie::TiePh>,      L<CfgTie::TieProto>, L<CfgTie::TieRCService>,
L<CfgTie::TieRsrc>,    L<CfgTie::TieServ>,  L<CfgTie::TieShadow>,
L<CfgTie::TieUser>

=head1 Author

Randall Maas (L<mailto:randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

# These are the builtins that we always add to the global arena...

# This forms the abstract tie for the net sub-hash
my $net_builtins ={host=>['CfgTie::TieHost'],
      service=>['CfgTie::TieServ'],
      protocol=>['CfgTie::TieProto'],
      addr    =>['CfgTie::TieNet']
    };

# This forms the abstract tie for the mail sub-hash
my $mail_builtins={aliases=>['CfgTie::TieAliases']};

my $builtins =
     {
        user => ['CfgTie::TieUser'],
        group =>['CfgTie::TieGroup'],
#        env =>  \%main'ENV,
        mail => ['CfgTie::TieGeneric', $mail_builtins],
        net =>  ['CfgTie::TieGeneric', $net_builtins], 
        runlevel=>['CfgTie::TieRCService'],
     };

use CfgTie::TieGroup;
use CfgTie::TieServ;
use CfgTie::TieProto;
use CfgTie::TieNet;
use CfgTie::TieHost;
@ISA=qw(CfgTie::TieGroup CfgTie::TieServ  CfgTie::TieProto
	CfgTie::TieNet  CfgTie::TieHost AutoLoader);
1;
__END__


sub TIEHASH
{
   my ($self,$BuildIns) =@_;
   if (!defined $BuildIns) {$BuildIns = $builtins;}
   my $node = {builtins => $BuildIns};
   return bless $node, $self;
}
sub new {TIEHASH(@_);}

my $Node_Separator = '/';

sub EXISTS
{
   my ($self,$key)=@_;

   if (!defined $key) {return 0;}

   #if the $key has a separator in it, check the cache.
   if (exists $self->{Cache}->{$key})   {return 1;}

   # Check to see if it is already mapped in, and overrides ours
   if (exists $self->{Contents}->{$key}) {return 1;}

   #At this point, it is not mapped in.
   #Try to automagically add it in..
   #First try to use a builtin if possible
   if (exists $self->{builtins}->{$key}) {return 1;}

   #recursively try to find it...
   my ($LeftKey, $RightKey);
   if ($key =~ /^(.*)\/([^\/]+)$/)
     {$LeftKey=$1; $RightKey=$2;}
    else
     {
        #Finally try to mount the thingy
        eval "use $key";
        tie %{$self->{Contents}->{$key}}, $key;
	return exists $self->{Contents}->{$key};
     }
   if (!EXISTS($self, $LeftKey)) {return 0;}

   # stick it in the quick look up cache
   my $X = FETCH($self, $LeftKey);
   $self->{Cache}->{$key} = $X->{$RightKey};
   return 1;
}

sub FETCH
{
   my ($self,$key)=@_;
   if (!EXISTS($self,$key)) {return;}
   #If we fully cached the long key, get already
   if (!exists $self->{Contents}->{$key})
     {
        my ($A,$B) = @{$self->{builtins}->{$key}};

        #load the perl module
        eval "use $A";

        #Tie in the key
        tie %{$self->{Contents}->{$key}}, $A,$B;
     }
   if (exists $self->{Cache}->{$key}) {return $self->{Cache}->{$key};}
   #Try to get the local thing first
   if (exists $self->{Contents}->{$key}) {return $self->{Contents}->{$key};}
   return undef;
}

sub HTML($)
{
   my $self=shift;
   my $A='';
   for (my $I=FIRSTKEY($self); $I; $I=NEXTKEY($self,$I))
    {
       $A.="<tr>".CfgTie::Cfgfile::td("<a href=\"$I\">$I</a>")."</tr>";
    }
   CfgTie::Cfgfile::table('Directory',$A,1);
}

sub FIRSTKEY
{
   my $self = shift;
   my $a = keys %{$self->{Contents}};

   my $b = scalar each %{$self->{Contents}};
   if ($b) {return $b;}

   #Scan thru the builtins
   my $c = keys %{$self->{builtins}};
   return scalar each %{$self->{builtins}};
}

sub NEXTKEY
{
   my $self = shift;
   my $lastkey=shift;
   my $a = scalar each %{$self->{Contents}};
   if ($a) {return $a;}

   if (exists $self->{Contents}->{$lastkey})
     {
        #Prime it with a psuedo FIRSTKEY
        my $b = keys %{$self->{builtins}};
     }

   while (($a) = each %{$self->{builtins}})
    {
       if (!exists $self->{Contents}->{$a})
         {return $a;}
    }
   return $a;
}
