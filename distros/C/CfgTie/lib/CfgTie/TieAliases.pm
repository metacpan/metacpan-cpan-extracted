#!/usr/bin/perl -w
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.


package CfgTie::TieAliases;
use CfgTie::Cfgfile;
require Tie::Hash;
use Secure::File;
use vars qw($VERSION @ISA);
$VERSION='0.41';
use AutoLoader 'AUTOLOAD';
use Carp;
@ISA=qw(AutoLoader CfgTie::Cfgfile);
#use strict;
1;

__END__

=head1 NAME

CfgTie::TieAliases -- an associative array of mail aliases to targets

=head1 SYNOPSIS

Makes it easy to manage the mail aliases (F</etc/aliases>) table as a hash.

   tie %mtie,'CfgTie::TieAliases'

   #Redirect mail for foo-man to root
   $mtie{'foo-man'}=['root'];

=head1 DESCRIPTION

This Perl module ties to the F</etc/aliases> file so that things can be
updated on the fly.  When you tie the hash, you are allowed an optional
parameter to specify what file to tie it to.

   tie %mtie,'CfgTie::TieAliases'

or

   tie %mtie,'CfgTie::TieAliases',I<aliases-like-file>

or

   tie %mtie,'CfgTie::TieAliases',I<revision-control-object>

=head2 Methods

C<ImpGroups> will import the various groups from F</etc/group> using
C<CfgTie::TieGroup>.  It allows an optional code reference to select which
groups get imported.  This code is passed a reference to each group and needs
to return nonzero if it is to be imported, or zero if it not to be imported.
For example:

   (tied  %mtie)->ImpGroups
	{
	   my $T=shift;
	   if ($T->{'id} < 100) {return 0;}
	   return 1;
	}

=head2 Format of the F</etc/aliases> file

The format of the F</etc/aliases> file is poorly documented.  The format that
C<CfgTie::TieAliases> understands is documented as follows:

=over 1

=item C<#>I<comments>

Anything after a hash mark (C<#>) to the end of the line is treated as a
comment, and ignored.

=item I<text>C<:>

The letters, digits, dashes, and underscores before a colon are treated as
the name of an alias.  The alias will be expanded to whatever is on the
line after the colon.  (Each of those is in turn expanded).

=item C<:include:>I<file>

Any element of the alias list that includes C<:include:> indicates that the
specified file should be read from.  The file may only specify user names or
email addresses.  Several include directives may used in the aliase.  It is not
clear which of these files is the preferred file to modify.

=item Continuation lines

Any line that starts with a space is a continuation of the previous line.

=back

=head1 Caveats

Not all changes to are immediately reflected to the specified file.  See the
L<CfgTie::Cfgfile> module for more information

=head1 FILES

F</etc/aliases>

=head1 See Also

L<CfgTie::Cfgfile>,    L<CfgTie::TieRCService>,
L<CfgTie::TieGeneric>, L<CfgTie::TieGroup>, L<CfgTie::TieHost>,
L<CfgTie::TieNamed>,   L<CfgTie::TieNet>, L<CfgTie::TiePh>,
L<CfgTie::TieProto>,   L<CfgTie::TieServ>,  L<CfgTie::TieShadow>,
L<CfgTie::TieUser>

L<aliases(5)>
L<newaliases(1)>

=head1 Author

Randall Maas (L<randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

sub files
{
   if (exists $_[0]->{'Files'})
   {
       return ($_[0]->{'Path'},@{$_[0]->{'Files'}});
   }
   $_[0]->{'Path'};
}

sub scan
{
   # Read the aliases file
   my $self= shift;

   #A structure to help keep track of the files we employ
   my %files;
   if (!exists $self->{'Path'})
     {
        #Path has not been defined... define it to the default.
        $self->{'Path'} = '/etc/aliases';
     }

   my $F=new Secure::File '<'.$self->{'Path'};
   if (!defined $F)
     {
	carp "CfgTie::TieAliases: Unable to open aliases file:". $self->{'Path'};
	return;
     }

   $files{$self->{'Path'}}++;

   while (my $L=<$F>)
    {
       chomp $L;
       $L=~ s/\s*#.*$//;  #Remove the comments

       my $currpos=$F->tell;

       #Handle continuation lines
     LINE:
       while (<$F>)
       {
          if (!/^\s/)
            {
               #Done with the continuation lines... clean up and parse it.
               $F->seek($currpos, 0);
               last LINE;
            }

          #Only keep the stuff before the comment
          chomp;
          s/\s*#.*$//;

          #Glue this line onto the big *whole* line
          $L .= $_;

          #Save our place so we can get back to it later
          $currpos = $F->tell;
       }

       if ($L =~ /([^:]+):\s*([^\n]*)/i)
         {
           #Right here is where it gets special
           #Would need to carefully handle includes...
           foreach my $I (split(/[,\s]+/, $2))
            {
               if ($I =~ /:include:([^\s]*)/)
                 {
                    #Read in an include file
                    push @{$self->{Files}}, $1;
                    my $G = new Secure::File "<$1";
                    if (defined $G)
                      {
                         while(<$G>)
                          {
                             chomp;
                             s/\s*#.*$//;
                             push @{$self->{Contents}->{$1}}, split /[,\s]+/;
                          }
                         $G->close;
                      }
                 }
                else
                 {
                    push @{$self->{Contents}->{$1}},$I;
                 }
            }
         }
     }
   $F->close;
}

sub cfg_end
{
   my $self = shift;
   if (exists $self->{Path} && $self->{Path} eq '/etc/aliases')
     {CfgTie::filever::system("/usr/bin/newaliases");}
#    else {print "Not a path for newaliases\n";}
}

sub format($$)
{
   my ($self,$key,$value)=@_;
   "$key: ".join(',',@{$value})."\n";
}

#sub is_tainted {not eval {join('',@_),kill 0; 1;};}

sub makerewrites
{
   my ($self) = @_;
   my $Sub;
   my $Rules = "\$Sub = sub {\n   \$_=shift;\n";
   foreach my $I (keys %{$self->{Queue}})
    {
       if (!defined $self->{Queue}->{$I} || !length $self->{Queue}->{$I})
         #Build a deletion rule
         {$Rules.="   if(/^\\s*$I\\s*:/i){return;}";}
        else
         {
            #Build a change value rule
            $Rules.="   if(/^\\s*$I\\s*:[^#\\n]*(#[^\\n]*)?/i)\n   ".
                    "{my \$Ret ='$I:". join(',',@{$self->{Queue}{$I}}).
                    "';\n    ".
                    "if (defined \$1) {\$Ret .=\$1;}\n   return \$Ret.\"\\n\";}\n";
         }
    }
   $Rules .="\n   \$_;\n};\n";
   $@='';
#   if (&is_tainted($Rules))
#       {die "Rules for updating aliases file are tainted\n";}
#    else
     {eval $Rules;}
   if (defined $@ && length $@) {die "rewrite rules compilation failed: $@";}
   return $Sub;
}

sub ImpGroups(&$)
{
   my ($CodeRef,$Ref)=@_;
   #Create a list of group names that pass the selection criteria
   #The code ref is passed a reference to the group information
   my %groups;
   use CfgTie::TieGroup;
   tie %groups, 'CfgTie::TieGroup';

   if (!defined $CodeRef)
     {
        foreach my $I (keys %groups)
	 {$Ref->{$I}= $groups{$I}->{'members'};}
     }
    else
     {
        foreach my $I (keys %groups)
          {
	      if (!&$CodeRef($groups{$I})) {next;}
	      $Ref->{$I}=$groups{$I}->{'members'};
	  }
     }
}

sub HTML
{
   my $self = shift;
   my $Ret = "<table border=0>";
   foreach my $I (sort keys %{$self->{Contents}})
    {
       $Ret .= "<tr><th align=right><a name=$I>$I</a></th><td>";
       foreach my $J (@{$self->{Contents}->{$I}})
        {
           if (exists $self->{Contents}->{$J})
             {$Ret .= "<a href=\"#$J\">$J</a> ";}
            else
             {$Ret .= $I.' ';}
        }
       $Ret .= "</td></tr>\n";
    }
   $Ret."</table>\n";
}

1;
