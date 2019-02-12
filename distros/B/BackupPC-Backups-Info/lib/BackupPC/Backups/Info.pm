package BackupPC::Backups::Info;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';

=head1 NAME

BackupPC::Backups::Info - Restrieves info on BackupPC backups.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use BackupPC::Backups::Info;

    my $bpcinfo = BackupPC::Backups::Info->new();
    ...

=head1 METHODS

=head2 new

Initiates the object.

One variable is taken and that is the back to the BackupPC pool.
By default this is '/var/db/BackupPC' if not specified.

    my $bpcinfo=BackupPC::Backups::Info->new;
    if ( $bpcinfo->error ){
        warn("init failed.... the pool directy does not exist or is not accessible");
    }

=cut

sub new{
	my $dir=$_[1];

	if ( !defined( $dir ) ){
		$dir='/var/db/BackupPC';
	}

	my $self = {
        perror=>undef,
        error=>undef,
        errorString=>"",
        errorExtra=>{
			flags=>{
				1=>'badBackupPCdir',
				2=>'noPCdir',
				3=>'opendir',
				4=>'noMachineName',
				5=>'slashmachine',
				6=>'noMachine',
				7=>'open',
			}
		},
		dir=>$dir,
		pcdir=>$dir.'/pc',
		last=>{},
		parsed=>{},
		maxAge=>172800, #two days in seconds
    };
    bless $self;

	#makes sure that the directory exists.
	if ( ! -d $dir ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='"'.$dir.'" is not a directory or does not exist';
		$self->warn;
		return $self;
	}

	#makes sure that the directory exists.
	if ( ! -d $dir.'/pc' ){
		$self->{perror}=1;
		$self->{error}=2;
		$self->{errorString}='"'.$dir.'/pc" is not a directory or does not exist';
		$self->warn;
		return $self;
	}
	
	return $self;
}

=head2 get_dir

This returns the top dir for BackupPC.

There is no need for error checking as long as it did not error upon init.

    my $dir=$bpcinfo->get_dir;

=cut

sub get_dir{
	my $self=$_[0];
	
	if( ! $self->errorblank ){
        return undef;
    }

	return $self->{dir};
}

=head2 get_last

Gets the last line parsed for a for the file.

If the machine has not been parsed yet, it will be and the last
entry returned.

Two options are taken.

The first is the machine in question.

The second is perl boolean if it should reread the file even if it already has a last.

The BACKUP HASH for information on the returned hash reference.

    my $lastRef=$bpcinfo->get_last($machine)
    if ( $bpcinfo->error ){
        warn('something happened'.$self->errorstring);
    }

=cut

sub get_last{
	my $self=$_[0];
	my $machine=$_[1];
	my $force=$_[2];

	if( ! $self->errorblank ){
        return undef;
    }

	if ( !defined( $machine ) ){
		$self->{error}=4;
		$self->{errorString}='Need to specify a machine name to fetch the raw file for.';
		$self->warn;
		return undef;
	}

	if ( $machine =~ /\// ){
		$self->{error}=5;
		$self->{errorString}='The machine name may not contain a /';
		$self->warn;
		return undef;
	}
	
	if ( 
		(!defined( $self->{last}{ $machine } )) ||
		$force
		){
		$self->get_parsed( $machine );
		if ( $self->error ){
			return undef;
		}
	}

	return $self->{last}{$machine};
}

=head2 get_pc_dir

This returns the directory which will contain the directories for the hosts setup in BackupPC.

There is no need for error checking as long as it did not error upon init.

    my $dir=$bpcinfo->get_dir;
    if ( $bpcinfo->error ){
        warn('something happened'.$self->errorstring);
    }

=cut

sub get_pc_dir{
	my $self=$_[0];
	
	if( ! $self->errorblank ){
        return undef;
    }

	return $self->{pcdir};
}

=head2 get_parsed

This parses the raw backups file and then returns a array of hashes.
For a explanation of the hashes, please see BACKUP HASH.

One archment is taken and that is the machine name.

   my @parsed=$bpcinfo->get_parsed($machine);
    if ( $bpcinfo->error ){
        warn('something happened: '.$self->errorstring);
    }

=cut

sub get_parsed{
	my $self=$_[0];
	my $machine=$_[1];
	
	if( ! $self->errorblank ){
        return undef;
    }

	if ( !defined( $machine ) ){
		$self->{error}=4;
		$self->{errorString}='Need to specify a machine name to fetch the raw file for.';
		$self->warn;
		return undef;
	}

	if ( $machine =~ /\// ){
		$self->{error}=5;
		$self->{errorString}='The machine name may not contain a /';
		$self->warn;
		return undef;
	}

	#gets the raw file
	my $raw=$self->get_raw($machine);
	if ($self->error){
		return undef;
	}

	#break it at the lines
	my @lines=split(/\n/, $raw);

	#will store what we return
	my @parsed;

	my $int=0;
	while( defined( $lines[$int] ) ){
		my %backup;
		( $backup{num}, $backup{type}, $backup{startTime}, $backup{endTime},
		  $backup{nFiles}, $backup{size}, $backup{nFilesExist}, $backup{sizeExist},
		  $backup{nFilesNew}, $backup{sizeNew}, $backup{xferErrs}, $backup{xferBadFile},
		  $backup{xferBadShare}, $backup{tarErrs}, $backup{compress},
		  $backup{sizeExistComp}, $backup{sizeNewComp}, $backup{noFill},
		  $backup{fillFromNum}, $backup{mangle}, $backup{xferMethod}, $backup{level} )=split(/\t/, $lines[$int]);

		if ( $backup{compress} eq ''){
			$backup{compress}=0;
		}
		
		push( @parsed, \%backup );
		
		$int++;
	}

	#save info on the last
	my %last=%{$parsed[$#parsed]};
	$self->{last}{$machine}=\%last;

	#save the parsed
	$self->{parsed}{$machine}=\@parsed;
	
	return @parsed;
}

=head2 get_raw

This retrieves the law data from a backups file for a machine.

The section on backups file in
L<https://backuppc.github.io/backuppc/BackupPC.html#Storage-layout>
is suggested reading if you plan on actually using this.

    my $raw=$bpcinfo->get_raw('foo');
    if ($bpcinfo->error){
        warn('something errored');
    }

=cut

sub get_raw{
	my $self=$_[0];
	my $machine=$_[1];
	
	if( ! $self->errorblank ){
        return undef;
    }

	if ( !defined( $machine ) ){
		$self->{error}=4;
		$self->{errorString}='Need to specify a machine name to fetch the raw file for.';
		$self->warn;
		return undef;
	}

	if ( $machine =~ /\// ){
		$self->{error}=5;
		$self->{errorString}='The machine name may not contain a /';
		$self->warn;
		return undef;
	}

	my $pcdir=$self->get_pc_dir;
	my $machineDir=$pcdir.'/'.$machine;
	
	if (! -d $machineDir ){
		$self->{error}=6;
		$self->{eerorString}='"'.$machineDir.'" does not eixst';
		$self->warn;
		return undef;
	}

	my $backupsFile=$machineDir.'/backups';

	my $fh;
	if (! open( $fh, '<', $backupsFile ) ){
		$self->{error}=7;
		$self->{errorString}='failed to open "'.$backupsFile.'"';
		$self->warn;
	};

	my $data='';
	while ( my $line=$fh->getline ){
		$data=$data.$line;
	}
	
	return $data;
}

=head2 list_machines

This returns an array of machines backed up.

    my @machines=$bpcinfo->list_machines;
    if ( $bpcinfo->error ){
        warn('something happened: '.$self->errorstring);
    }

=cut

sub list_machines{
	my $self=$_[0];
	
	if( ! $self->errorblank ){
        return undef;
    }

	my $pcdir=$self->get_pc_dir;
	
	my $dh;
	if ( ! opendir( $dh, $pcdir ) ){
		$self->{error}=3;
		$self->{errorString}='Can not opendir "'.$pcdir.'"';
		$self->warn;
	}
	my @machines;
	while (readdir($dh) ){
		my $entry=$_;
		if ( ( -d $pcdir.'/'.$entry ) &&
			 ( $entry !~ /^\./ )
			){
			push( @machines, $entry );
		}
	}
	closedir( $dh );

	return @machines;
}

=head2 list_parsed

This returns a array the machines that have currently been parsed.

As long as no permanent errors are set, this will not error.

    my @parsed=$bpcinfo->list_parsed;

=cut

sub list_parsed{
	my $self=$_[0];
	
	if( ! $self->errorblank ){
        return undef;
    }

	return keys(%{$self->{parsed}});
}

=head2 read_in_all

This reads in the backups files for each machine.

Currently this just attempts to read in all via get_parsed
and ignores any errors, just proceeding to the next one.

As long as list_machines does not error, this will not error.

    $bpcinfo->read_in_all
    if ( $bpcinfo->error ){
        warn('something happened: '.$self->errorstring);
    }

=cut

sub read_in_all{
	my $self=$_[0];
	
	if( ! $self->errorblank ){
        return undef;
    }

	my @machines=$self->list_machines;
	if ( $self->error ){
		return undef;
	}

	my $pcdir=$self->get_pc_dir;
	
	my $int=0;
	while( defined( $machines[$int] ) ){
		if ( -f $pcdir.'/'.$machines[$int].'/backups' ){
			$self->get_parsed( $machines[$int] );
		}
				
		$int++;
	}

	return 1;
}

=head1 BACKUP HASH

Based on __TOPDIR__/pc/$host/backup from
L<https://backuppc.github.io/backuppc/BackupPC.html#Storage-layout>.

=head2 num

The backup number for the current hash.

=head2 type

Either 'incr' or 'full'.

=head2 startTime

The unix start time of the backup.

=head2 endTime

The unix end time of the backup.

=head2 nFiles

Number of files backed up.

=head2 size

Total file size backed up.

=head2 nFilesExist

Number of files already in the pool.

=head2 sizeExist

Total size of files that were already in the pool.

=head2 nFilesNew

Number of new files not already in the pool.

=head2 sizeNew

Total size of files not in the pool.

=head2 xferErrs

Number of warnings/errors from the backup method.

=head2 xferBadFile

Number of errors from the backup method in regards to bad files.

=head2 xferBadShare

Number of errors from smbclient that were bad share errors.

=head2 tarErrs

Number of errors from BackupPC_tarExtract.

=head2 compress

The compression level used on this backup. Zero means no compression.

Please note that while BackupPC may leave this field blank if none is used, this module
will check for a blank value and set it to zero.

=head2 sizeExistComp

Total compressed size of files that already existed in the pool.

=head2 sizeNewComp

Total compressed size of new files in the pool.

=head2 noFill

et if this backup has not been filled in with the most recent previous filled or full backup.
See $Conf{IncrFill} in the BackupPC docs.

=head2 fillFromNum

If filled, this is the backup it was filled from.

=head2 mangle

Set if this backup has mangled file names and attributes. Always true for backups in v1.4.0
and above. False for all backups prior to v1.4.0.

=head2 xferMethod

The value of $Conf{XferMethod} when this dump was done.

=head2 level

=head1 ERROR FLAGS

=head2 1/backBackupPCdig

/var/db/BackupPC or whatever was specified does not exist or is not a directory.

=head2 2/noPCdir

/var/db/BackupPC/pc does not exist or is not a directory.

=head2 3/opendir

Opendir failed. Most likely this script needs to be running as the same user as BackupPC.

=head2 4/noMachineName

Specify the machine name to operate on.

=head2 5/slashmachine

The machine name has a slash in it.

=head2 6/noMachine

The machine does not exist.

=head2 7/open

Open on a file failed. Please make sure the script is running as the same user as BackupPC.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-backuppc-backups-info at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BackupPC-Backups-Info>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BackupPC::Backups::Info


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BackupPC-Backups-Info>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BackupPC-Backups-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BackupPC-Backups-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/BackupPC-Backups-Info/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of BackupPC::Backups::Info
