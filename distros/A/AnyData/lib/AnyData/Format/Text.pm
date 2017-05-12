#########################################################
package AnyData::Format::Text;
#########################################################
# AnyData driver for plain text files
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
#########################################################
use strict;
use warnings;
use AnyData::Format::Base;
use AnyData::Storage::FileSys;
use vars qw( @ISA $DEBUG );
@AnyData::Format::Text::ISA = qw( AnyData::Format::Base );
$DEBUG = 0;

sub new {
    my $class = shift;
    my $self = shift || {};
    #use Data::Dumper; die Dumper $self;
    $self->{rec_sep}   ||= "\n";
    if ($self->{dirs}) {
        $self->{storage} = 'FileSys';
        $self->{col_names} = 'fullpath,path,name,ext,size,content';
        $self->{records}   = get_data( {},$self->{dirs} );
    }
    else {
        $self->{col_names} = 'text';
        $self->{key}       = 'text';
    }
    $self->{keep_first_line} = 1;
    return bless $self, $class;
}
sub write_fields {
    my $self   = shift;
    return $self->{dirs}
        ? pop @_
        : join '', @_;
}
sub read_fields {
    my $self = shift;
    my $str = shift || return undef;
    if (!$self->{dirs}) {
        my @row = ($str);
        return @row
    }
}
sub get_data {
    my $self = shift;
    my $dirs = shift;
#    my @col_names = @{ $self->{col_names} };
    my $table = [];
    my @files = AnyData::Storage::FileSys::get_filename_parts(
        dirs => $dirs
    );
    for my $file_info(@files) {
        my $file = $file_info->[0];
        # my $cols = get_mp3_tag($file) || next;
        #my $filesize = -s $file;
        #my @row  = (@$file_info,$filesize);
        my @row = ( $file_info->[0],
                    $file_info->[2],
                    $file_info->[1],
                    $file_info->[3],
                  );
        push @$table, \@row;
        # 'fullpath,path,name,ext,size,content';
        # 'fullpath,file_name,path,ext,size,'
        # 'name,artist,album,year,comment,genre';
    }
    return $table;
}

1;

