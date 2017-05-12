
###################################################################################
#
#   DBIx::Recordset - Copyright (c) 1997-2000 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS IS BETA SOFTWARE!
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: FileSeq.pm,v 1.4 2000/06/26 05:16:18 richter Exp $
#
###################################################################################


package DBIx::Recordset::FileSeq ;

use strict 'vars' ;

use Cwd ;


## ----------------------------------------------------------------------------
##
## new
##
## creates a new DBIx::Recordset::FileSeq object. 
##
## $dir          = Directory which holds the sequences
##

sub new

    {
    my ($class, $dummy, $dir, $min, $max) = @_ ;
    

    mkdir $dir, 0755 or die "Cannot create $dir ($!)" if (!-e $dir) ; 
    
    die "$dir is not a directory" if (!-d $dir) ;

    

    my $self = {
                '*Debug'      => $DBIx::Recordset::Debug,
                '*Dir'        => Cwd::abs_path ($dir),
                '*DefaultMin' => $min || 1,
                '*DefaultMax' => $max || '',
               } ;

    bless ($self, $class) ;

    $self -> ReadCounter ;

    return $self ;
    }


## ----------------------------------------------------------------------------
##
## ReadCounter
##
## read current counters form filesystem
##
##


sub ReadCounter

    {
    my $self = shift ;

    my %counter ;
    my %max ;

    opendir DH, $self -> {'*Dir'} or die "Cannot open directory $self->{'*Dir'} ($!)" ;
    
    while ($_ = readdir DH)
        {
        if (/seq\.(.*?)\.(\d*?)\.(\d+)$/) 
            {
            $counter{$1}=$3 ;
            $max{$1}=$2 ;
            }
        }
    
    $self -> {'*Counter'} = \%counter ;
    $self -> {'*Max'} = \%max ;
    }


## ----------------------------------------------------------------------------
##
## NextVal
##
## get next value from counter
##
## in   $name = counter name
##


sub NextVal 

    {
    my ($self, $name) = @_ ;

    my $dir = $self -> {'*Dir'} ;
    my $lastcnt ;

    local $^W = 0 ;
 
    while (1)
        {
        my $cnt = $self -> {'*Counter'}{$name} ;
        my $max = $self -> {'*Max'}{$name} ;

        if (!defined ($cnt))
            {
            $cnt = $self->{'*DefaultMin'} ;
            $max = $self->{'*DefaultMax'} ;
            open FH, ">$dir/seq.$name.$max.$cnt" or die "Cannot create seq.$name..1 ($!)" ;
            close FH ;
            }

        my $cnt1 = $cnt + 1 ;

        die "Max count reached for Sequence $name" if ($max ne '' && $cnt1 > $max) ;

        if (rename ("$dir/seq.$name.$max.$cnt", "$dir/seq.$name.$max.$cnt1"))
            {
            $self -> {'*Counter'}{$name} = $cnt1 ;
            return $cnt ;
            }

	my $lastcnt = $cnt ;
        $self -> ReadCounter ;
	die "Problems updating Sequence $name (File $dir/seq.$name.$max.$cnt)" if ($lastcnt == $self -> {'*Counter'}{$name} ) ;
        }
    }

1;

__END__


=pod

=head1 NAME

DBIx::Recordset::FileSeq - Sequence generator in Filesystem

=head1 SYNOPSIS

 use DBIx::Recordset::FileSeq ;

 $self = DBIx::Recordset::FileSeq (undef, '/tmp/seq', $min, $max) ;
 
 $val1 = $self -> NextVal ('foo') ;
 $val2 = $self -> NextVal ('foo') ;
 $val3 = $self -> NextVal ('bar') ;
 

=head1 DESCRIPTION


DBIx::Recordset::FileSeq generates unique numbers. State is kept in the
filesystem. With the new constructor you sepcify the directory
where the state is kept. (First parameter is a dummy values, that will
receive the database handle from DBIx::Recordset, but you don't need it
when you use it without DBIx::Recordset). Optionaly you can give a min and
a max values, which will be used for new sequences.

With B<NextVal> you can get the next value
for the sequence of the given name.

The state if kept by haveing a file with the name

seq.<seqencename>.<max>.<count>

Each time the sequnce value increments the file is renamed. If the <max>
if a numeric value the new value is checked against <max> and NextVal
dies if the sequnce value increment above max.

=head1 AUTHOR

G.Richter (richter@dev.ecos.de)

=head1 SEE ALSO

=item DBIx::Recordset


=cut
    


