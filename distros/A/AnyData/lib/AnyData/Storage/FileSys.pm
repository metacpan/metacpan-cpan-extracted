package AnyData::Storage::FileSys;

use strict;
use warnings;
use File::Find;
use File::Basename;
use vars qw( @ISA @files $wanted_part $wanted_re );
use AnyData::Storage::File;
@ISA = qw( AnyData::Storage::File );
use Data::Dumper;

sub open_table {}

sub new {
    my $class = shift;
    my $self  = shift || {};
    $self->{col_names} = ['fullpath','path','name','ext','size','content' ];
    bless $self, $class;
    my $exts = $self->{exts};
    if ($exts) {
        $self->{wanted_part} = 'ext';
        $self->{wanted_re}   = qr/\.$exts$/;
    }
    $self->{records}   = $self->get_data;
    $self->{index} = 0;
    return $self;
}
sub is_deleted {}

sub get_data {
    my $self = shift;
    my $dirs = shift || $self->{dirs};
    my @col_names = @{ $self->{col_names} };
    my $table = [];
    my @files = $self->get_filename_parts;
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
    #use Data::Dumper; print "!",Dumper $table; exit;
    return $table;
}

sub seek_first_record {
    my $self = shift;
    $self->{index} = 0;
}
sub file2str {
    my $self = shift;
    my $curindex = $self->{index};
    return undef if $curindex >= scalar @{$self->{records}};
    $self->{index}++;
    my $rec = $self->{records}->[$curindex];
    my $file = $rec->[0];
    push @$rec, -s $file;
    local $/;
    undef $/;
    my $fh = $self->open_local_file( $file, $self->{open_mode});
    my $str = <$fh>;
    undef $fh;
    push @$rec, $str;
    return $rec;
}
sub col_names { shift->{col_names} }
sub get_filename_parts {
    my $self = shift;
    my %flags;
    %flags = @_ if scalar @_;
    #use Data::Dumper; print "!",Dumper \%flags; exit;
    $wanted_part = $flags{part} || $self->{wanted_part} || '';
    $wanted_re   = $flags{re}   || $self->{wanted_re} || '';
    my $dirs     = $flags{dirs} || $self->{dirs} || [];
    my $wanted_sub  = $flags{sub} || \&wanted;
    @files       = ();
    find { no_chdir => 1,
           wanted   => $wanted_sub,
         },
         @$dirs;
    ;
    my @results = @files;
    @files      = ();
    return @results;
}

sub wanted {
    my @info = fileparse($_,'\.[^\.]*$');
    my($name,$path,$ext) = map{$_ || ''} @info;
    if (!$name && $ext) { $name = $ext; $ext  = ''; }
    unshift @info,$File::Find::name;
    my $cols;
    @{$cols}{('fullpath','filename','path','ext')} = @info;
    if ($wanted_part && $wanted_re) {
        return unless $cols->{$wanted_part} =~ $wanted_re;
    }
    push @files, \@info;
}
1;
