package Data::RecordStore::Silo;

#
# I am a silo. I live in a directory.
# I keep my data in silo files in this directory.
# Each silo file is allowed to be only so large,
# so that is why there may be more than one of them.
#
# I may be changed by async processes, so a lot
# of my coordination and state is on the file system.
#
# You can init me by giving me a directory,
# a template and an optional size and a max size.
#   I will figure out the record size based on what you give me.
#   I will default to 2GB for a max size if no max size is given.
#   I will have limitless size if you give me 0 for a max size
#   I will save my version, the size, max size and template to the directory
#
#
# You can open me by giving a directory, then
#   push data to me and I return its id
#   get data from me after giving me its id
#   pop data from me
#   ask how many records I have
#

use strict;
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';
no strict 'refs';

use Fcntl qw( SEEK_SET );
use File::Path qw(make_path);
#use FileCache;
use IO::Handle;
use JSON;
use YAML;

use vars qw($VERSION);
$VERSION = '6.00';

$Data::RecordStore::Silo::DEFAULT_MAX_FILE_SIZE = 2_000_000_000;
$Data::RecordStore::Silo::DEFAULT_MIN_FILE_SIZE = 4_096;

use constant {
    DIRECTORY           => 0,
    VERSION             => 1,
    TEMPLATE            => 2,
    RECORD_SIZE         => 3,
    MAX_FILE_SIZE       => 4,
    RECORDS_PER_SUBSILO => 5,
    DIR_HANDLE          => 6,
};


sub open_silo {
    my( $class, $dir, $template, $size, $max_file_size ) = @_;

    if( ! $dir ) {
        die "must supply directory to open silo";
    }
    if( ! $template ) {
        die "must supply template to open silo";
    }
    my $record_size = $template =~ /\*/ ? $size : do { use bytes; length( pack( $template ) ) };
    if( $record_size < 1 ) {
        die "no record size given to open silo";
    }
    if( $size && $size != $record_size ) {
        die "Silo given size and template size do not match";
    }
    make_path( $dir, { error => \my $err } );

    if( @$err ) { die join( ", ", map { $_->{$dir} } @$err ) }

    if( $max_file_size < 1 ) {
        $max_file_size = $Data::RecordStore::Silo::DEFAULT_MAX_FILE_SIZE;
    }

    unless( -e "$dir/0" ) {
        open my $out, '>', "$dir/config.yaml";
        print $out <<"END";
VERSION: $VERSION
TEMPLATE: $template
RECORD_SIZE: $record_size
MAX_FILE_SIZE: $max_file_size
END
        close $out;
        
        # must have at least an empty silo file
        open $out, '>', "$dir/0";
        print $out '';
        close $out;
    }

    return bless [
        $dir,
        $VERSION,
        $template,
        $record_size,
        $max_file_size,
        int($max_file_size / $record_size),
        ], $class;
} #open_silo

sub reopen_silo {
    my( $cls, $dir ) = @_;
    my $cfgfile = "$dir/config.yaml";
    if( -e $cfgfile ) {
        my $cfg = YAML::LoadFile( $cfgfile );
        return $cls->open_silo( $dir, @$cfg{qw(TEMPLATE RECORD_SIZE MAX_FILE_SIZE)} );
    }
    die "could not find silo in $dir";
} #reopen_silo

sub next_id {
    my( $self ) = @_;
    my $next_id = 1 + $self->entry_count;
    $self->ensure_entry_count( $next_id );
    return $next_id;
} #next_id

sub entry_count {
    # return how many entries this silo has
    my $self = shift;
    my @files = $self->subsilos;
    my $filesize;
    for my $file (@files) {
        $filesize += -s "$self->[DIRECTORY]/$file";
    }
    return int( $filesize / $self->[RECORD_SIZE] );
} #entry_count

sub get_record {
    my( $self, $id, $template, $offset ) = @_;
    my $rec_size;

    if( $template > 0 ) {
        $rec_size = $template;
        $template = $self->[TEMPLATE];
    } elsif( $template ) {
        my $template_size = $template =~ /\*/ ? 0 : do { use bytes; length( pack( $template ) ) };
        $rec_size = $template_size;
    }
    else {
        $rec_size = $self->[RECORD_SIZE];
        $template = $self->[TEMPLATE];
    }
    if( $id > $self->entry_count || $id < 1 ) {
        die "Data::RecordStore::Silo->get_record : ($$) index $id out of bounds for silo $self->[DIRECTORY]. Silo has entry count of ".$self->entry_count;
    }
    my( $idx_in_f, $fh, $subsilo_idx ) = $self->_fh( $id );

    $offset //= 0;
    my $seek_pos = ( $self->[RECORD_SIZE] * $idx_in_f ) + $offset;

    sysseek( $fh, $seek_pos, SEEK_SET );
    my $srv = sysread $fh, (my $data), $rec_size;

    return [unpack( $template, $data )];
} #get_record

sub put_record {
    my( $self, $id, $data, $template, $offset ) = @_;

    if( $id > $self->entry_count || $id < 1 ) {
        die "Data::RecordStore::Silo->put_record : index $id out of bounds for silo $self->[DIRECTORY]. Store has entry count of ".$self->entry_count;
    }
    if( ! $template ) {
        $template = $self->[TEMPLATE];
    }

    my $rec_size = $self->[RECORD_SIZE];
    my $to_write =  pack( $template, ref $data ? @$data : ($data) );

    # allows the put_record to grow the data store by no more than one entry
    my $write_size = do { use bytes; length( $to_write ) };

    if( $write_size > $rec_size) {
        die "Data::RecordStore::Silo->put_record : record size $write_size too large. Max is $rec_size";
    }

    my( $idx_in_f, $fh, $subsilo_idx ) = $self->_fh( $id );

    $offset //= 0;
    my $seek_pos = $rec_size * $idx_in_f + $offset;
    sysseek( $fh, $seek_pos, SEEK_SET );

    syswrite( $fh, $to_write );

    return 1;
} #put_record

sub pop {
    my( $self ) = @_;
    my $entries = $self->entry_count;
    unless( $entries ) {
        return undef;
    }
    my $ret = $self->get_record( $entries );
    my( $idx_in_f, $fh, $subsilo_idx ) = $self->_fh( $entries );

    my $new_subsilo_size = (($entries-1) - ($subsilo_idx * $self->[RECORDS_PER_SUBSILO]  ))*$self->[RECORD_SIZE];

    if( $new_subsilo_size || $subsilo_idx == 0 ) {
        truncate $fh, $new_subsilo_size;
    } else {
        unlink "$self->[DIRECTORY]/$subsilo_idx";
#        FileCache::cacheout_close $fh;
    }

    return $ret;
} #pop

sub peek {
    my( $self ) = @_;
    my $entries = $self->entry_count;
    unless( $entries ) {
        return undef;
    }
    my $r = $self->get_record( $entries );
    return $r;
} #peek

sub push {
    my( $self, $data ) = @_;
    my $next_id = $self->next_id;

    $self->put_record( $next_id, $data );

    return $next_id;
} #push



sub record_size { return shift->[RECORD_SIZE] }
sub template { return shift->[TEMPLATE] }

sub max_file_size { return shift->[MAX_FILE_SIZE] }
sub records_per_subsilo { return shift->[RECORDS_PER_SUBSILO] }

sub size {
    # return how many bytes of data this silo has
    my $self = shift;
    my @files = $self->subsilos;
    my $filesize = 0;
    for my $file (@files) {
        $filesize += -s "$self->[DIRECTORY]/$file";
    }
    return $filesize;
}


sub copy_record {
    my( $self, $from_id, $to_id ) = @_;
    my $rec = $self->get_record($from_id);
    $self->put_record( $to_id, $rec );
    return $rec;
} #copy_record


#
# Destroys all the data in the silo
#
sub empty_silo {
    my $self = shift;
    my $dir = $self->[DIRECTORY];
    for my $file ($self->subsilos) {
        if( $file eq '0' ) {
            open my $fh, '+<', "$dir/0";
            truncate $fh, 0;
        } else {
            unlink "$dir/$file";
        }
    }
} #empty_silo

# destroys the silo. The silo will not be
# functional after this call.
sub unlink_silo {
    my $self = shift;
    my $dir = $self->[DIRECTORY];
    for my $file ($self->subsilos) {
        unlink "$dir/$file";
    }
    unlink "$dir/SINFO";
    @$self = ();
} #unlink_silo


#Makes sure this silo has at least as many entries
#as the count given. This creates empty records if needed
#to rearch the target record count.
sub ensure_entry_count {
    my( $self, $count ) = @_;

    my $ec = $self->entry_count;
    my $needed = $count - $ec;
    my $dir = $self->[DIRECTORY];
    my $rec_size = $self->[RECORD_SIZE];
    my $rec_per_subsilo = $self->[RECORDS_PER_SUBSILO];

    if( $needed > 0 ) {
        my( @files ) = $self->subsilos;
        my $write_file = $files[$#files];

        my $existing_file_records = int( (-s "$dir/$write_file" ) / $rec_size );
        my $records_needed_to_fill = $rec_per_subsilo - $existing_file_records;
        $records_needed_to_fill = $needed if $records_needed_to_fill > $needed;
        my $nulls;
        if( $records_needed_to_fill > 0 ) {
            # fill the last file up with \0
#            my $fh = cacheout "+<", 
            open my $fh, '+<', "$dir/$write_file" or die "$dir/$write_file : $!";
           # $fh->autoflush(1);
            $nulls = "\0" x ( $records_needed_to_fill * $rec_size );
            my $seek_pos = $rec_size * $existing_file_records;
            sysseek( $fh, $seek_pos, SEEK_SET );
            syswrite( $fh, $nulls );
            close $fh;
            undef $nulls;
            $needed -= $records_needed_to_fill;
        }
        while( $needed > $rec_per_subsilo ) {
            # still needed, so create a new file
            $write_file++;

            if( -e "$dir/$write_file" ) {
                die "Data::RecordStore::Silo->ensure_entry_count : file $dir/$write_file already exists";
            }
            open( my $fh, ">", "$dir/$write_file" );
#            $fh->autoflush(1);
            print $fh '';
            unless( $nulls ) {
                $nulls = "\0" x ( $rec_per_subsilo * $rec_size );
            }
            sysseek( $fh, 0, SEEK_SET );
            syswrite( $fh, $nulls );
            $needed -= $rec_per_subsilo;
            close $fh;
        }
        if( $needed > 0 ) {
            # still needed, so create a new file
            $write_file++;

            if( -e "$dir/$write_file" ) {
                die "Data::RecordStore::Silo->ensure_entry_count : file $dir/$write_file already exists";
            }
            open( my $fh, ">", "$dir/$write_file" );
#            $fh->autoflush(1);
            print $fh '';
            my $nulls = "\0" x ( $needed * $rec_size );
            sysseek( $fh, 0, SEEK_SET );
            syswrite( $fh, $nulls );
            close $fh;
        }
    }
    $ec = $self->entry_count;
    return;
} #ensure_entry_count

#
# Returns the list of filenames of the 'silos' of this store. They are numbers starting with 0
#
sub subsilos {
    my $self = shift;
    my $dir = $self->[DIRECTORY];
    my $dh = $self->[DIR_HANDLE];
    if( $dh ) {
        rewinddir $dh;
    } else {
        opendir( $dh, $self->[DIRECTORY] ) or die "Data::RecordStore::Silo->subsilos : can't open $dir\n";
        $self->[DIR_HANDLE] = $dh;
    }
    my( @files ) = (sort { $a <=> $b } grep { $_ eq '0' || (-s "$dir/$_") > 0 } grep { $_ > 0 || $_ eq '0' } readdir( $dh ) );
    return @files;
} #subsilos


#
# Takes an insertion id and returns
#   an insertion index for in the file
#   filehandle.
#   filepath/filename
#   which number file this is (0 is the first)
#
sub _fh {
    my( $self, $id ) = @_;

    my $dir = $self->[DIRECTORY];
    my $rec_per_subsilo = $self->[RECORDS_PER_SUBSILO];

    my $subsilo_idx = int( ($id-1) / $rec_per_subsilo );
    my $idx_in_f = ($id - ($subsilo_idx*$rec_per_subsilo)) - 1;

    open my $fh, "+<", "$dir/$subsilo_idx" or die "$dir/$subsilo_idx : $!";
    return $idx_in_f, $fh, $subsilo_idx;

} #_fh



"Silos are the great hidden constant of the industrialised world.
    - John Darnielle, Universal Harvester";

__END__

=head1 NAME

 Data::RecordStore::Silo - Indexed Fixed Record Store

=head1 SYNPOSIS

 use Data::RecordStore::Silo;

 my $silo = Data::RecordStore->open_silo( $directory, $template, $record_size, $max_file_size );

 my $id = $silo->next_id;
 $silo->put_record( $id, [ 2234234324234, 42, "THIS IS SOME TEXT" ] );

 my $record = $silo->get_record( $id );
 my( $long_val, $int_val, $text ) = @$record;

 my $count = $silo->entry_count;

 my $next_id = $silo->push( [ 999999, 12, "LIKE A STACK" ] );

 my $newcount = $silo->entry_count;
 $newcount == $count + 1;

 $record = $silo->peek;

 $newcount == $silo->entry_count;

 $record = $silo->pop;
 my $newestcount = $silo->entry_count;
 $newestcount == $newcount - 1;

 my $reopened_silo = Data::RecordStore->reopen_silo( $directory );

=head1 DESCRIPTION

=head1 METHODS

=head2 open_silo( directory, template, record_size, max_file_size )

=head2 reopen_silo( directory )

=head2 next_id

=head2 entry_count

=head2 get_record

=head2 put_record

=head2 pop

=head2 peek

=head2 push

=head2 copy_record

=head2 empty_silo

=head2 unlink_silo

=head2 record_size

=head2 template

=head2 max_file_size

=head2 records_per_subsilo

=head2 size

=head2 ensure_entry_count

=head2 subsilos

=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2012 - 2019 Eric Wolf. All rights reserved.  This program is free software; you can redistribute it and/or modify it
       under the same terms as Perl itself.

=head1 VERSION
       Version 6.00  (Oct, 2019))

=cut

