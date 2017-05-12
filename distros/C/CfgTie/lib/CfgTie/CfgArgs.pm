#!/usr/bin/perl
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.                                                                   

package CfgTie::CfgArgs;
require Exporter;
@ISA=qw(Exporter);
use vars qw($VERSION);
$VERSION='0.41';
@EXPORT_OK=qw(Fatal Err $Prg);

=head1 NAME

C<CfgTie::CfgArgs> -- Configuration module for parsing commandline arguments

=head1 SYNOPSIS

This module is meant to help create useful configuration tools and utilities.

=head1 DESCRIPTION

A tool to allow many of your computer's subsystems to be configured.  This
module parses commandline arguments.  It is provided to help create a
standardized lexicon.

=head2 Scope controls and settings

To specify how much of your system should be affected by the change in
settings:

  --scope=session|application|user|group|system


In addition, each of the individual parts can specified (instead of their
defaults):

=over 1

=item C<--application=>I<NAME>

=item C<--application >I<NAME>

This specifies the application.

=item C<--user=>I<NAME>

=item C<--user >I<NAME>

This specifies the user name.

=item C<--group=>I<NAME>

=item C<--group >I<NAME>

This specifies the group name.

=back

=head2 Operations on variables

The specific operation to be done:

        --op=set|unset|remove|delete|exists|fetch|get|copy|rename

or:

	--copy   name1=name2 name3=name4 ...
	--exists name1 name2 name3 ...
	--test   name1=value1 name2=value2 ...
        --unset  name1 name2 ...

=over 1

=item C<--delete >I<NAME>

=item C<--delete=>I<NAME>

This will remove the entry specified by I<NAME>.  I<NAME> may be a regular
expression.

=item C<--fetch >I<NAME>

=item C<--fetch=>I<NAME>

This will retrieve the information associated with I<NAME>.  If I<NAME> is a
regular expression, information will retrieved for every entry that matches the
pattern.

=item C<--remove >I<NAME>

=item C<--remove=>I<NAME>

Like C<delete> above, this will remove the entry specified by I<NAME>.  I<NAME>
may be a regular expression.

=item C<--rename> I<NAME-NEW>=I<NAME-OLD>

This will change all of the occurrences or references that match I<NAME-OLD> to
the newer form of I<NAME-NEW>.  This may be a regular expression, similar to;

	s/NAME-OLD/NAME-NEW/

=item C<--set> I<NAME>=I<VALUE>

This will create an entry called I<NAME> with a setting of I<VALUE>.

=back


The variable names are optional, and can be explicitly specified:

        --name

Otherwise it is assumed to be the first no flag parameter.

Similarly, the value can be specified

        --value

=head2 Other flags

=over 1

=item C<--file >FILE

=item C<--file=>FILE

This specifies the configuration file to employ.  If none is specified, the
default for the particular subsystem will be used instead.  

=item C<--comment >COMMENT

=item C<--comment=>COMMENT

This provides a text comment on what changes are being made.

=back

        -n,
        --dry-run,
        --just-print
        --recon

With these flags, the utility program I<should not modify any files>.
Instead, it should merely document what changes it would make, what programs
it would run, etc.

	--copyright
        --help
	--info
	--information
	--manual
	--verbose
	--version
        --warranty

=head2 Exit value

If the operation exists the return value is zero, otherwise it is nonzero.

=head2 Return from parsing

The hash return:

   {
      SCOPE=> session,application,user,group,system
      OP  => COPY, RENAME, STORE, DELETE, FETCH, or EXISTS
      KEY =>
      VALUE=>
   }

=head1 AUTHOR

Randall Maas (L<mailto:randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

use Getopt::Long;

my @GetoptLong_Rules=(
	"scope=s","application:s","session!","user:s","group:s","op=s",

	#Options that take associative arrays
	"set:s%", "rename:s%","copy:s%",

	#Options that take lists
	"remove|delete|unset:s@","exists:s@","fetch:s@",

	#Options that take single values
	"system:s","name=s","value=s","file=s",

	#Control of wether or not it will actually do it
	"dry-run|just-print|recon!",
	"list!",
	#Miscellaneous stuff:
	"copyright!", "help|info|information|manual:s","warranty!","verbose!",
	"version!");

my $Op2Op =
  {
     set    => STORE,
     unset  => DELETE,
     remove => DELETE,
     'delete'=> DELETE,
     'exists'=> EXISTS,
     fetch  => FETCH,
     get   => GET,
     name  => KEY,
     key   => KEY,
     value => VALUE,
     group => GROUP,
     user  => USER,
     application=>APPLICATION,
  };

sub Args_parse (@)
{
   my $N ={};
   foreach my $I (@_)
    {
          if (/^\s*--scope=(session|application|user|group|system|rename|copy)\s*$/i)
            {
               if (!exists $N->{SCOPE}) {$N->{SCOPE}=lc($1);}
               else {warn "multiple attempts to set scope (to $1)!\n";}
            }
       elsif (/^\s*--(?=op=)(set|unset|remove|delete|exists|fetch|get)\s*$/i)
            {$N->{OP}=$Op2Op->{lc($1)};}
       elsif (/^\s*--(application|user|group|name|value|key)=(.+)\s*$/i)
            {
               my $k=$Op2Op->{lc($1)};
               if (!exists $N->{$k}) {$N->{$k}=lc($2);}
               else {warn "multiple attempts to set $k (to $2)!\n";}
            }
#       elsif (!exists $N->{KEY} && /^\s*xxx
#       elsif (!exists $N->{VALUE}
#       else {save this for later...}
    }
}

#while <F>
#  Args_parse(split /(?:\\)\s/);
#}


sub Help()
{
   #This returns a text string describing the flags.  It is meant to help
   #put together a command line tool help message
   my $L="\t    ";
   "Main operation mode:\n".
   "$L--op=set|unset|remove|delete|exists|fetch|get|copy|rename\n".
   "$L--copy   name1=name2 name3=name4 ...\n".
   "$L--delete name1 name2 ...\n".
   "$L--exists name1 name2 name3 ...\n".
   "$L--fetch  name1 name2 name3 ...\n".
   "$L--remove name1 name2 ...\n".
   "\nSpecifying scope of actions:\n".
   "$L--scope=session|application|user|group|system\n".
   "$L--application=\n\t\t\tThis allows you specify which application\n".
   "$L--user=\tSpecifies which user.  If option is used without a user\n".
   "\t\t\tname, it employs the effective user ID.\n".
   "$L--group=\tSpecifies which group.  If this option is used without a\n".
   "\t\t\tgroup name, the effective group ID is employed.\n".
   "\t\n".
   "\nInformative output:\n".
   "$L--copyright\tPrints this programs copyright information.\n".
   "$L--help\tPrints this help list.  Exits without doing any\n\t\t\toperation\n".
   "$L--verbose\t\n".
   "$L--version\tDisplays this programs version information.  Exits\n".
   "\t\t\twithout doing any operation.\n".
   "$L--warranty\tDisplays the programs warranty information.  Exits\n".
   "\t\t\twithout doing any operation.\n".
   "\n";
}

sub Args_exclusive
{
   my $MyArgs=shift;
   my @Rest = @_;
   my $ExitNum=0;
   foreach my $I (@_)
    {
       shift @Rest;
       if (!defined $I || !exists $MyArgs->{$I}) {next;}
       foreach my $J (@Rest)
        {
           if (!defined $J || !exists $MyArgs->{$J}) {next;}
           $ExitNum=-1;
	   if (defined $main::Prg) {print STDERR $main::Prg,": ";}
	   print STDERR	"--$I and --$J modes can not be intermixed.\n";
        }
    }
   $ExitNum;
}

sub do
{
   GetOptions(shift, @GetoptLong_Rules, @_);
}

# --- Error handling ----------------------------------------------------------
#Def of good error message
# 1. Identifies the module generating the message (manufacturer, type, etc)
# 2. Identifies the error type (a code number usually)
# 3. Identifies the subsystems or relevant locus of a problem -
# 4. Human description of the problem
# 5. What will, should, or needs to happen

my %Msgs;
my $Lang='english';
$Msgs{'english'} =
  {
     EXITING => "Exiting.",
     GROUP_MISSING  => "Group was not specified",
     USER_NONAME    => "Your user id does not have a name.",
     USER_BAD_REAL  => "Real user id is root.  This is not allowed.",
     USER_BAD_EFF   => "Effective user id is root.  This is not allowed, ".
	               "using the real user id.",
     TAINTED        => "\\1 is tainted.",
     EMAIL_BAD      => "Item to add has invalid email address: \"\\1\"",
     FILE_NEXIST    => "file \"\\1\" does not exist!",
     FILE_EXISTS    => "file \"\\1\" exists, will not overwrite.",
     FILE_CANTCREATE=> "Can not create file \"\\1\" for output.",
  };
my $ErrMsgs = $Msgs{$Lang};

sub FmtEStr
{
   my ($E,$A)=@_;
   my $Str= $ErrMsgs->{$E};
   if (!defined $Str)
     {warn "Can't look up error message for $E\n"; $Str=$E;}
   
   #Add in the users parameters
   $Str=~ s/\\1/$A/g;
   $Str;
}

$Prg='';
sub Fatal
{
   my $Str=CfgTie::CfgArgs::FmtEStr(@_);

   #Announce to the user, and die
   die "$Prg: $Str\n";
}

sub Err
{
   my $Str=CfgTie::CfgArgs::FmtEStr(@_);

   #Announce to the user
   print STDERR "$Prg: $Str\n";
}

1;
