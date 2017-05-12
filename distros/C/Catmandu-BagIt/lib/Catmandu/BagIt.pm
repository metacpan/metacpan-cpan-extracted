package Catmandu::BagIt;

use strict;
our $VERSION = '0.12';

use Catmandu::Sane;
use Catmandu;
use Moo;
use Encode;
use Digest::MD5;
use IO::File qw();
use IO::Handle qw();
use File::Copy;
use List::MoreUtils qw(first_index uniq);
use File::Path qw(remove_tree mkpath);
use File::Slurper qw(read_lines write_text);
use File::Temp qw(tempfile);
use Catmandu::BagIt::Payload;
use Catmandu::BagIt::Fetch;
use POSIX qw(strftime);
use LWP::UserAgent;
use utf8;
use namespace::clean;

use constant {
    FLAG_BAGIT        => 0x001 ,
    FLAG_BAG_INFO     => 0x002 ,
    FLAG_FETCH        => 0x004 ,
    FLAG_DATA         => 0x008 , 
    FLAG_TAG_MANIFEST => 0x016 ,
    FLAG_MANIFEST     => 0x032 ,
    FLAG_DIRTY        => 0x064 ,
};

with 'Catmandu::Logger';

has '_error' => (
    is       => 'rw',
    default  => sub { [] },
);

has 'dirty' => (
    is       => 'ro',
    writer   => '_dirty',
    default  => 0,
);

has 'path' => (
    is       => 'ro',
    writer   => '_path',
    init_arg => undef,
);

has 'version' => (
    is       => 'ro',
    writer   => '_version',
    default  => '0.97',
    init_arg => undef,
);

has 'encoding' => (
    is       => 'ro',
    writer   => '_encoding',
    default  => 'UTF-8',
    init_arg => undef,
);

has user_agent => (is => 'ro');

has '_tags' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

has '_files' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

has '_fetch' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

has '_tag_sums' => (
    is       => 'rw',
    default  => sub { {} },
    init_arg => undef,
);

has '_sums' => (
    is       => 'rw',
    default  => sub { {} },
    init_arg => undef,
);

has '_info' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

has _http_client => (
    is => 'ro', 
    lazy => 1, 
    builder => '_build_http_client', 
    init_arg => 'user_agent'
);

sub _build_http_client {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent('Catmandu-BagIt/' . $Catmandu::BagIt::VERSION);
    $ua;
}

sub BUILD {
    my $self = shift;

    $self->log->debug("initializing bag");

    $self->_update_info;
    $self->_update_tag_manifest;
    $self->_tags([qw(
            bagit.txt
            bag-info.txt
            manifest-md5.txt
            )]);


    $self->_dirty($self->dirty | FLAG_BAG_INFO | FLAG_TAG_MANIFEST | FLAG_DATA | FLAG_BAGIT);
}

sub errors {
    my ($self) = @_;
    @{$self->_error};
}

sub list_tags {
    my ($self) = @_;
    @{$self->_tags};
}

sub list_files {
    my ($self) = @_;
    @{$self->_files};
}

sub get_file {
    my ($self,$filename) = @_;
    die "usage: get_file(filename)" unless $filename;

    for ($self->list_files) {
        return $_ if $_->filename eq $filename;
    }
    return undef;
}

sub get_fetch {
    my ($self,$filename) = @_;
    die "usage: get_fetch(filename)" unless $filename;

    for ($self->list_fetch) {
        return $_ if $_->filename eq $filename;
    }
    return undef;
}

sub is_dirty {
    my ($self) = @_;
    $self->dirty != 0;
}

sub is_holey {
    my ($self) = @_;
    @{$self->_fetch} > 0;
}

sub list_fetch {
    my ($self) = @_;
    @{$self->_fetch};
}

sub list_tagsum {
    my ($self) = @_;
    keys %{$self->_tag_sums};
}

sub get_tagsum {
    my ($self,$file) = @_;

    die "usage: get_tagsum(file)" unless $file;

    $self->_tag_sums->{$file};
}

sub list_checksum {
    my ($self) = @_;
    keys %{$self->_sums};
}

sub get_checksum {
    my ($self,$file) = @_;

    die "usage: get_checksum(file)" unless $file;

    $self->_sums->{$file};
}

sub read {
    my ($class,$path) = @_;

    die "usage: read(path)" unless $path;

    my $self = $class->new;

    if (! -d $path ) {
        $self->log->error("$path doesn't exist");
        $self->_push_error("$path doesn't exist");
        return;
    }

    $self->log->info("reading: $path");

    $self->_path($path);

    my $ok = 0;

    $ok += $self->_read_version($path);
    $ok += $self->_read_info($path);
    $ok += $self->_read_tag_manifest($path);
    $ok += $self->_read_manifest($path);
    $ok += $self->_read_tags($path);
    $ok += $self->_read_files($path);
    $ok += $self->_read_fetch($path);

    $self->_dirty(0);

    $ok == 7 ? $self : undef;
}

sub write {
    my ($self,$path,%opts) = @_;

    $self->_error([]);

    die "usage: write(path[, overwrite => 1])" unless $path;

    # Check if other processes are writing or previous processes died
    if ( 
        (defined($self->path) && -f $self->path . "/.lock") || 
        -f "$path/.lock"
       ) {
        $self->log->error($self->path . "/.lock or $path/.lock exists");
        $self->_push_error($self->path . "/.lock or $path/.lock exists");
        return undef;
    }

    if (defined($self->path) && $path ne $self->path) {
        $self->log->info("copying from old path: " . $self->path);
        $self->_dirty($self->dirty | FLAG_BAGIT | FLAG_BAG_INFO | FLAG_TAG_MANIFEST | FLAG_MANIFEST | FLAG_DATA);
        
        foreach my $item ($self->list_files) {
            $item->flag($item->flag ^ FLAG_DIRTY);
        }
    }
    elsif (defined($self->path) && $path eq $self->path) {
        # we are ok the path exists and don't need to remove anything
        # updates are possible when overwrite => 1
    }
    elsif ($opts{overwrite} && -d $path) {
        $self->log->info("removing: $path");
        remove_tree($path);
    }

    if (-f "$path/bagit.txt") {
        if ($opts{overwrite}) {
            $self->log->info("overwriting: $path");
        }
        else {
            $self->log->error("$path already exists");
            $self->_push_error("$path already exists");
            return undef;
        }
    }
    else {
        $self->log->info("creating: $path");
        mkpath($path);
        $self->_dirty($self->dirty | FLAG_BAGIT);
    }

    unless ($self->touch("$path/.lock")) {
        $self->log->error("failed to create $path/.lock");
        return undef;
    }

    $self->_path($path);

    my $ok = 0;

    $ok += $self->_write_bagit($path);
    $ok += $self->_write_info($path);
    $ok += $self->_write_data($path);
    $ok += $self->_write_fetch($path);
    $ok += $self->_write_manifest($path);
    $ok += $self->_write_tag_manifest($path);

    $self->_dirty(0);

    unlink("$path/.lock");

    $ok == 6;
}

sub locked {
    my ($self,$path) = @_;
    $path //= $self->path;

    return undef unless defined($path);

    -f "$path/.lock";
}

sub touch {
    my ($self,$path) = @_;

    die "usage: touch(path)"
            unless defined($path);
    local(*F);
    open(F,">$path") || die "failed to open $path for writing: $!";
    print F "";
    close(F);

    1;
}

sub add_file {
    my ($self, $filename, $data, %opts) = @_;

    die "usage: add_file(filename, data [, overwrite => 1])" 
            unless defined($filename) && defined($data);

    $self->_error([]);

    unless ($self->_is_legal_file_name($filename)) {
        $self->log->error("illegal file name $filename");
        $self->_push_error("illegal file name $filename");
        return;
    }

    $self->log->info("adding file $filename");

    if ($opts{overwrite}) {
        $self->remove_file($filename);
    }

    if ($self->get_checksum("$filename")) {
        $self->log->error("$filename already exists in bag");
        $self->_push_error("$filename already exists in bag");
        return;
    }

    push @{ $self->_files } , Catmandu::BagIt::Payload->new(
                                    filename => $filename , 
                                    data => $data ,
                                    flag => FLAG_DIRTY ,
                                );

    my $sum = $self->_md5_sum($data);

    $self->_sums->{"$filename"} = $sum;

    # Total size changes, therefore tag manifest changes
    $self->_update_info;
    $self->_update_tag_manifest; # Try to update the manifest .. but it is dirty
                                 # Until we serialize the bag

    $self->_dirty($self->dirty | FLAG_DATA | FLAG_MANIFEST | FLAG_BAG_INFO | FLAG_TAG_MANIFEST);

    1;
}

sub remove_file {
    my ($self, $filename) = @_;

    die "usage: remove_file(filename)" unless defined($filename);

    $self->_error([]);

    unless ($self->get_checksum($filename)) {
        $self->log->error("$filename doesn't exist in bag");
        $self->_push_error("$filename doesn't exist in bag");
        return;
    }

    $self->log->info("removing file $filename");

    my $idx = first_index { $_->{filename} eq $filename } @{ $self->_files };

    unless ($idx != -1) {
        $self->_push_error("$filename doesn't exist in bag");
        return;
    }

    my @files = grep { $_->{filename} ne $filename } @{ $self->_files };

    $self->_files(\@files);

    delete $self->_sums->{$filename};

    $self->_update_info;
    $self->_update_tag_manifest;

    $self->_dirty($self->dirty | FLAG_DATA | FLAG_MANIFEST | FLAG_BAG_INFO | FLAG_TAG_MANIFEST);

    1;
}

sub add_fetch {
    my ($self, $url, $size, $filename) = @_;

    die "usage add_fetch(url,size,filename)" 
            unless defined($url) && $size =~ /^\d+$/ && defined($filename);

    die "illegal file name $filename"
            unless $self->_is_legal_file_name($filename);

    $self->log->info("adding fetch $url -> $filename");

    my (@old) = grep { $_->{filename} ne $filename} @{$self->_fetch};

    $self->_fetch(\@old);

    push @{$self->_fetch} , Catmandu::BagIt::Fetch->new(url => $url , size => $size , filename => $filename);

    $self->_update_info;
    $self->_update_tag_manifest;

    $self->_dirty($self->dirty | FLAG_FETCH | FLAG_TAG_MANIFEST);

    1;
}

sub remove_fetch {
    my ($self, $filename) = @_;

    die "usage remove_fetch(filename)" unless defined($filename);  

    $self->log->info("removing fetch for $filename");

    my (@old) = grep { $_->filename ne $filename} @{$self->_fetch};

    $self->_fetch(\@old);

    $self->_update_info;
    $self->_update_tag_manifest;

    $self->_dirty($self->dirty | FLAG_FETCH | FLAG_TAG_MANIFEST);

    1;
}

sub mirror_fetch {
    my ($self, $fetch) = @_;

    die "usage mirror_fetch(<Catmandu::BagIt::Fetch>)"
            unless defined($fetch) && ref($fetch) && ref($fetch) =~ /^Catmandu::BagIt::Fetch/;

    my ($tmp_fh, $tmp_filename) = tempfile();

    my $url       = $fetch->url;
    my $filename  = $fetch->filename;
    my $path      = $self->path;  

    $self->log->info("mirroring $url -> $tmp_filename...");

    my $response = $self->_http_client->mirror($url,$tmp_filename);

    if ($response->is_success) {
        $self->log->info("mirror is a success");
    }
    else {
        $self->log->error("mirror $url -> $tmp_filename failed : $response->status_line");
        return undef;
    }

    $self->log->info("updating file listing...");
    $self->log->debug("add new $filename");
    $self->add_file($filename, IO::File->new($tmp_filename,'r'), overwrite => 1);
}

sub add_info {
    my ($self,$name,$values) = @_;

    die "usage add_info(name,values)" 
            unless defined($name) && defined($values);  

    if ($name =~ /^(Bag-Size|Bagging-Date|Payload-Oxum)$/) {
        for my $part (@{$self->_info}) {
            if ($part->[0] eq $name) {
                $part->[1] = $values;
                return;
            }
        }
        push @{$self->_info} , [ $name , $values ];
        return;
    }

    $self->log->info("adding info $name");

    if (ref($values) eq 'ARRAY') {
        foreach my $value (@$values) {
            push @{$self->_info} , [ $name , $value ];
        }
    }
    else {
        push @{$self->_info} , [ $name , $values ];
    }

    $self->_update_tag_manifest;

    $self->_dirty($self->dirty | FLAG_BAG_INFO | FLAG_TAG_MANIFEST);

    1;
}

sub remove_info {
    my ($self,$name) = @_;

    die "usage remove_info(name)" 
            unless defined($name); 

    if ($name =~ /^(Bag-Size|Bagging-Date|Payload-Oxum)$/) {
        $self->log->error("removing info $name - is read-only");
        return undef;
    } 

    $self->log->info("removing info $name");

    my (@old) = grep { $_->[0] ne $name } @{$self->_info};

    $self->_info(\@old);
    
    $self->_update_tag_manifest;

    $self->_dirty($self->dirty | FLAG_BAG_INFO | FLAG_TAG_MANIFEST);

    1;
}

sub list_info_tags {
    my ($self) = @_;
    uniq map { $_->[0] } @{$self->_info};
}

sub get_info {
    my ($self,$field,$join) = @_;
    $join //= '; ';

    die "usage: get_info(field[,$join])" unless $field;

    my @res = map { $_->[1] } grep { $_->[0] eq $field } @{$self->_info};

    wantarray ? @res : join $join, @res;
}

sub size {
    my $self = shift;

    my $total = $self->_size;

    if ($total > 100*1000**3) {
        # 100's of GB
        sprintf "%-.3f TB" , $total/(1000**4);
    }
    elsif ($total > 100*1024**2) {
        # 100's of MB
        sprintf "%-.3f GB" , $total/(1000**3);
    }
    elsif ($total > 100*1024) {
        # 100's of KB
        sprintf "%-.3f MB" , $total/(1000**2);
    }
    else {
        sprintf "%-.3f KB" , $total/1000;
    }
}

sub payload_oxum {
    my $self = shift;

    my $size  = $self->_size;
    my $count = $self->list_files;

    my $fetches = $self->list_fetch // 0;

    $count += $fetches;

    return "$size.$count";
}

sub complete {
    my $self = shift;
    my $path = $self->path || '';

    $self->_error([]);

    $self->log->info("checking complete");

    unless ($self->version and $self->version =~ /^\d+\.\d+$/) {
        $self->log->error("Tag 'BagIt-Version' not available in bagit.txt");
        $self->_push_error("Tag 'BagIt-Version' not available in bagit.txt");
    }

    unless ($self->encoding and $self->encoding eq 'UTF-8') {
        $self->log->error("Tag 'Tag-File-Character-Encoding' not available in bagit.txt");
        $self->_push_error("Tag 'Tag-File-Character-Encoding' not available in bagit.txt");
    }

    my @missing = ();

    foreach my $file ($self->list_checksum) {
        unless (grep { (my $filename = $_->{filename} || '') =~ /^$file$/ } $self->list_files) {
            push @missing , $file;
        }
    }

    foreach my $file ($self->list_tagsum) {
        unless (grep { /^$file$/ } $self->list_tags) {
            push @missing , $file;
        }
    }

    foreach my $file (@missing) {
        unless (grep { $_->filename =~ /^$file$/ } $self->list_fetch) {
            $self->log->error("file $file doesn' exist in bag and fetch.txt");
            $self->_push_error("file $file doesn' exist in bag and fetch.txt");
        }
    }

    my $has_fetch = $self->list_fetch > 0 ? 1 : 0;

    $self->errors == 0 && @missing == 0 && $has_fetch == 0;
}

sub valid {
    my $self = shift;

    $self->log->info("checking valid");

    my $validator = sub {
        my ($file, $tag) = @_;
        my $path = $self->path;

        # To keep things very simple right now we require at least the
        # bag to be serialized somewhere before we start our validation process
        unless (defined $path && -d $path) {
            $self->log->error("sorry, only serialized (write) bags allowed when validating");
            return (1,"sorry, only serialized (write) bags allowed when validating");
        }

        my $md5 = $tag == 0 ? $self->get_checksum($file) : $self->get_tagsum($file);
        my $fh  = $tag == 0 ? new IO::File "$path/data/$file", "r" : new IO::File "$path/$file" , "r";

        unless ($fh) {
            $self->log->error("can't read $file");
            return (0,"can't read $file");
        }

        binmode($fh);

        my $md5_check = $self->_md5_sum($fh);

        undef $fh;

        unless ($md5 eq $md5_check) {
            $self->log->error("$file checksum fails $md5 <> $md5_check");
            return (0,"$file checksum fails $md5 <> $md5_check");
        }

        (1);
    };

    $self->_error([]);

    if ($self->dirty) {
        $self->log->error("bag is dirty : first serialize (write) then try again");
        $self->_push_error("bag is dirty : first serialize (write) then try again");
        return 0;
    }

    foreach my $file ($self->list_checksum) {
       my ($code,$msg) = $validator->($file,0);

       if ($code == 0) {
        $self->_push_error($msg);
       }
    }

    foreach my $file ($self->list_tagsum) {
       my ($code,$msg) = $validator->($file,1);

       if ($code == 0) {
        $self->_push_error($msg);
       }
    }

    $self->errors == 0;
}

#-----------------------------------------

sub _push_error {
    my ($self,$msg) = @_;
    my $errors = $self->_error // [];
    push @$errors , $msg;
    $self->_error($errors);
}

sub _size {
    my $self = shift;
    my $path = $self->path;

    my $total = 0;

    foreach my $item ($self->list_files) {
        my $size;
        if ($item->is_io && $item->data->can('stat')) {
            $size = [ $item->data->stat ]->[7];
        }
        else {
            $size = length($item->data);
        }
        $total += $size;
    }

    foreach my $item ($self->list_fetch) {
        my $size = $item->size;
        $total += $size;
    }

    $total;
}

sub _update_info {
    my $self = shift;

    $self->log->debug("updating the default info");

    # Add some goodies to the info file...
    $self->add_info('Bagging-Date', strftime "%Y-%m-%d", gmtime);
    $self->add_info('Bag-Size',$self->size);
    $self->add_info('Payload-Oxum',$self->payload_oxum);
}

sub _update_tag_manifest {
    my $self = shift;

    $self->log->debug("updating the tag manifest");

    {
        my $sum = $self->_md5_sum($self->_bagit_as_string);
        $self->_tag_sums->{'bagit.txt'} = $sum;
    }

    {
        my $sum = $self->_md5_sum($self->_baginfo_as_string);
        $self->_tag_sums->{'bag-info.txt'} = $sum;
    }

    {
        my $sum = $self->_md5_sum($self->_manifest_as_string);
        $self->_tag_sums->{'manifest-md5.txt'} = $sum;
    }

    if ($self->list_fetch) {
        my $sum = $self->_md5_sum($self->_fetch_as_string);
        $self->_tag_sums->{'fetch.txt'} = $sum;

        unless (grep {/fetch.txt/} $self->list_tags) {
            push @{$self->_tags} , 'fetch.txt';
        }
    }
    else {
        my (@new) = grep { $_ ne 'fetch.txt' } @{$self->_tags};
        $self->_tags(\@new);
        delete $self->_tag_sums->{'fetch.txt'};
    }
}

sub _read_fetch {
    my ($self, $path) = @_;

    $self->_fetch([]);

    return 1 unless -f "$path/fetch.txt";

    $self->log->debug("reading fetch.txt");

    foreach my $line (read_lines("$path/fetch.txt",'UTF-8')) {
        $line =~ s/\r\n$/\n/g;
        chomp($line);

        my ($url,$size,$filename) = split(/\s+/,$line,3);

        $filename =~ s/^data\///;

        push @{ $self->_fetch } , Catmandu::BagIt::Fetch->new(url => $url , size => $size , filename => $filename);
    }

    1;
}

sub _read_tag_manifest {
    my ($self, $path) = @_;

    $self->_tag_sums({});

    if (! -f "$path/tagmanifest-md5.txt") {
        return 1;
    }

    $self->log->debug("reading tagmanifest-md5.txt");

    foreach my $line (read_lines("$path/tagmanifest-md5.txt",'UTF-8')) {
       $line =~ s/\r\n$/\n/g;
        chomp($line);
        my ($sum,$file) = split(/\s+/,$line,2);
        $self->_tag_sums->{$file} = $sum;
    }

    1;
}

sub _read_manifest {
    my ($self, $path) = @_;

    $self->log->debug("reading manifest-md5.txt");

    $self->_sums({});

    if (! -f "$path/manifest-md5.txt") {
        $self->_push_error("$path/manifest-md5.txt bestaat niet");
        return 0;
    }

    foreach my $line (read_lines("$path/manifest-md5.txt",'UTF-8')) {
        $line =~ s/\r\n$/\n/g;
        chomp($line);
        my ($sum,$file) = split(/\s+/,$line,2);
        $file =~ s/^data\///;
        $self->_sums->{$file} = $sum;
    }

    1;
}

sub _read_tags {
    my ($self, $path) = @_;

    $self->log->debug("reading tag files");

    $self->_tags([]);

    local(*F);
    
    open(F,"find $path -maxdepth 1 -type f |") || die "can't find tag-files";

    while(<F>) {
        chomp($_);
        $_ =~ s/^$path.//;

        next if $_ =~ /^tagmanifest-\w+.txt$/;

        push @{ $self->_tags } , $_;
    }
    
    close(F);

    1;
}

sub _read_files {
    my ($self, $path) = @_;

    $self->log->debug("reading data files");

    $self->_files([]);

    if (! -d "$path/data" ) {
        $self->log->error("payload directory $path/data doesn't exist");
        $self->_push_error("payload directory $path/data doesn't exist");
        return 1;
    }

    local(*F);
    open(F,"find $path/data -type f |") || die "payload directory doesn't contain files";

    while(my $file = <F>) {
        chomp($file);
        my $filename = $file;
        $filename =~ s/^$path\/data\///;
        my $data = IO::File->new($file);

        push @{ $self->_files } , Catmandu::BagIt::Payload->new(filename => $filename, data => $data);
    }

    close(F);

    1;
}

sub _read_info {
    my ($self, $path) = @_;

    $self->log->debug("reading the tag info file");

    $self->_info([]);

    my $info_file = -f "$path/bag-info.txt" ? "$path/bag-info.txt" :  "$path/package-info.txt";

    if (! -f $info_file) {
        $self->log->error("$path/package-info.txt or $path/bag-info.txt doesn't exist");
        $self->_push_error("$path/package-info.txt or $path/bag-info.txt doesn't exist");
        return 0;
    }

    foreach my $line (read_lines($info_file, 'UTF-8')) {
        $line =~ s/\r\n$/\n/g;
        chomp($line);

        if ($line =~ /^\s+/) {
            $line =~ s/^\s*//;
            $self->_info->[-1]->[1] .= $line;
            next;
        }

        my ($n,$v) = split(/\s*:\s*/,$line,2);

        push @{ $self->_info } , [ $n , $v ];
    }

    1;
}

sub _read_version {
    my ($self, $path) = @_;

    $self->log->debug("reading the version file");

    if (! -f "$path/bagit.txt" ) {
        $self->log->error("$path/bagit.txt doesn't exist");
        $self->_push_error("$path/bagit.txt doesn't exist");
        return 0;
    }

    foreach my $line (read_lines("$path/bagit.txt",'UTF-8')) {
    $line =~ s/\r\n$/\n/g;
        chomp($line);
        my ($n,$v) = split(/\s*:\s*/,$line,2);

        if ($n eq 'BagIt-Version') {
            $self->_version($v);
        }
        elsif ($n eq 'Tag-File-Character-Encoding') {
            $self->_encoding($v);
        }
    }

    1;
}

sub _write_bagit {
    my ($self,$path) = @_;

    return 1 unless $self->dirty & FLAG_BAGIT;

    $self->log->info("writing the version file");

    local (*F);
    unless (open(F,">:utf8" , "$path/bagit.txt")) {
        $self->log->error("can't create $path/bagit.txt: $!");
        $self->_push_error("can't create $path/bagit.txt: $!");
        return;
    }

    printf F $self->_bagit_as_string;

    close (F);

    $self->_dirty($self->dirty ^ FLAG_BAGIT);

    1;
}

sub _bagit_as_string {
    my $self = shift;

    my $version  = $self->version;
    my $encoding = $self->encoding;

    return <<EOF;
BagIt-Version: $version
Tag-File-Character-Encoding: $encoding
EOF
}

sub _write_info {
    my ($self,$path) = @_;

    return 1 unless $self->dirty & FLAG_BAG_INFO;

    $self->log->info("writing the tag info file");

    local(*F);

    unless (open(F,">:utf8", "$path/bag-info.txt")) {
        $self->log->error("can't create $path/bag-info.txt: $!");
        $self->_push_error("can't create $path/bag-info.txt: $!");
        return;
    }

    print F $self->_baginfo_as_string;

    close(F);

    $self->_dirty($self->dirty ^ FLAG_BAG_INFO);

    1;
}

sub _baginfo_as_string {
    my $self = shift;

    my $str = '';

    foreach my $tag ($self->list_info_tags) {
        my @values = $self->get_info($tag);
        foreach my $val (@values) {
            my @msg = split //, "$tag: $val";

            my $cnt = 0;
            while (my (@chunk) = splice(@msg,0,$cnt == 0 ? 79 : 78)) {
                $str .= ($cnt == 0 ? '' : ' ') . join('',@chunk) . "\n";
                $cnt++;
            }
        }
    }

    $str;
}

sub _write_data {
    my ($self,$path) = @_;

    return 1 unless $self->dirty & FLAG_DATA;

    $self->log->info("writing the data files");

    unless (-d "$path/data") {
        unless (mkdir "$path/data") {
            $self->log->error("can't create payload directory $path/data: $!");
            $self->_push_error("can't create payload directory $path/data: $!");
            return;
        }
    }

    my @all_names_in_bag = ();

    foreach my $item ($self->list_files) {
        my $filename = 'data/' . $item->{filename};
        push @all_names_in_bag , $filename;

        next unless $item->flag & FLAG_DIRTY;

        my $dir  = $filename; $dir =~ s/\/[^\/]+$//;

        $self->log->info("serializing $filename");

        mkpath("$path/$dir") unless -d "$path/$dir";

        if ($item->is_io) {
            $item->fh->seek(0,0) if $item->data->can('seek');
            eval {
                copy($item->fh, "$path/$filename");
            };
            if ($@) {
                if ($@ =~ /are identical/) {
                    $self->log->error("attempy to copy identical files");
                }
            }
            # Close the old handle
            $item->fh->close();
            # Reopen the file at the new position
            $item->{data} = IO::File->new("$path/$filename");
            $item->flag($item->flag ^ FLAG_DIRTY);
        }
        else {
            write_text("$path/$filename", $item->data);
            $item->flag($item->flag ^ FLAG_DIRTY);
        }
    }

    # Check deleted files
    local(*F);
    
    if (open(F,"find $path/data -type f |")) {
        while(my $file = <F>) {
            chomp($file);
            
            my $filename = $file;
            $filename =~ s/^$path\///;
 
            unless (grep {$filename eq $_} @all_names_in_bag) {
                $self->log->info("deleting $path/$filename");
                unlink "$path/$filename";
            }
        }
        close(F);
    }

    $self->_dirty($self->dirty ^ FLAG_DATA);

    1;
}

sub _write_fetch {
    my ($self,$path) = @_;

    return 1 unless $self->dirty & FLAG_FETCH;

    my $fetch_str = $self->_fetch_as_string;

    unless (defined($fetch_str) && length($fetch_str)) {
        $self->log->info("removing fetch.txt");
        unlink "$path/fetch.txt" if -f "$path/fetch.txt";
        return 1;
    }

    $self->log->info("writing the fetch file");

    if ($self->_fetch == 0) {
        unlink "$path/fetch.txt" if -r "$path/fetch.txt";
        $self->_dirty($self->dirty ^ FLAG_FETCH);
        return 1;
    }

    local(*F);

    unless (open(F,">:utf8", "$path/fetch.txt")) {
        $self->log->error("can't create $path/fetch.txt: $!");
        $self->_push_error("can't create $path/fetch.txt: $!");
        return;
    }

    print F $fetch_str;

    close (F);

    $self->_dirty($self->dirty ^ FLAG_FETCH);

    1;
}

sub _fetch_as_string {
    my $self = shift;

    my $str = '';

    foreach my $f ($self->list_fetch) {
        $str .= sprintf "%s %s data/%s\n" , $f->url, $f->size, $f->filename;
    }

    $str;
}

sub _write_manifest {
    my ($self,$path) = @_;

    return 1 unless $self->dirty & FLAG_MANIFEST;

    $self->log->info("writing the manifest file");

    local (*F);

    unless (open(F,">:utf8", "$path/manifest-md5.txt")) {
        $self->log->error("can't create $path/manifest-md5.txt: $!");
        $self->_push_error("can't create $path/manifest-md5.txt: $!");
        return;
    }

    print F $self->_manifest_as_string;

    close(F);

    $self->_dirty($self->dirty ^ FLAG_MANIFEST);

    1;
}

sub _manifest_as_string {
    my $self = shift;
    my $path = $self->path;

    return undef unless defined $path;

    my $str = '';

    foreach my $file ($self->list_checksum) {
        next unless -f "$path/data/$file";
        my $md5 = $self->get_checksum($file);
        $str .= "$md5 data/$file\n";
    }

    $str;
}

sub _write_tag_manifest {
    my ($self,$path) = @_;

    return 1 unless $self->dirty & FLAG_TAG_MANIFEST;

    # The tag manifest can be dirty when writing new files
    $self->_update_tag_manifest;

    $self->log->info("writing the tag manifest file");

    local (*F);

    unless (open(F,">:utf8", "$path/tag-manifest-md5.txt")) {
        $self->log->error("can't create $path/manifest-md5.txt: $!");
        $self->_push_error("can't create $path/manifest-md5.txt: $!");
        return;
    }

    print F $self->_tag_manifest_as_string;

    close(F);

    $self->_dirty($self->dirty ^ FLAG_MANIFEST);

    1;
}

sub _tag_manifest_as_string {
    my $self = shift;

    my $str = '';

    foreach my $file ($self->list_tagsum) {
        my $md5  = $self->get_tagsum($file);
        print F "$md5 $file\n";
    }

    $str;
}

sub _md5_sum {
    my ($self, $data) = @_;

    my $ctx = Digest::MD5->new;

    if (!defined $data) {
    return $ctx->add(Encode::encode_utf8(''))->hexdigest;
    }
    elsif (! ref $data) {
        return $ctx->add(Encode::encode_utf8($data))->hexdigest;
    }
    elsif (ref $data eq 'SCALAR') {
        return $ctx->add(Encode::encode_utf8($$data))->hexdigest;
    }
    else {
        return $ctx->addfile($data)->hexdigest;
    }
}

sub _is_legal_file_name {
    my ($self, $filename) = @_;

    return 0 unless ($filename =~ /^[[:alnum:]._-]+$/);
    return 0 if ($filename =~ m{(^\.|\/\.+\/)});
    return 1;
}

sub DESTROY {
    my ($self) = @_;

    # Closing open file handles
    foreach my $item ($self->list_files) {
        if ($item->is_io && $item->fh->opened) {
            $item->fh->close;
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::BagIt - Low level Catmandu interface to the BagIt packages.

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-BagIt.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-BagIt)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-BagIt/badge.svg?branch=master&service=github)](https://coveralls.io/github/LibreCat/Catmandu-BagIt?branch=master)

=end markdown

=head1 SYNOPSIS

    use Catmandu::BagIt;

    # Assemble a new bag
    my $bagit = Catmandu::BagIt->new;

    # Read an existing
    my $bagit = Catmanu::BagIt->read($directory);

    $bag->read('t/bag');

    printf "path: %s\n", $bagit->path;
    printf "version: %s\n"  , $bagit->version;
    printf "encoding: %s\n" , $bagit->encoding;
    printf "size: %s\n", $bagit->size;
    printf "payload-oxum: %s\n", $bagit->payload_oxum;

    printf "tags:\n";
    for my $tag ($bagit->list_info_tags) {
        my @values = $bagit->get_info($tag);
        printf " $tag: %s\n" , join(", ",@values); 
    }

    printf "tag-sums:\n";
    for my $file ($bagit->list_tagsum) {
        my $sum = $bagit->get_tagsum($file);
        printf " $file: %s\n" , $sum; 
    }

    # Read the file listing as found in the manifest file
    printf "file-sums:\n";
    for my $file ($bagit->list_checksum) {
        my $sum = $bagit->get_checksum($file);
        printf " $file: %s\n" , $sum; 
    }

    # Read the real listing of files as found on the disk
    printf "files:\n";
    for my $file ($bagit->list_files) {
        my $stat = [$file->data->stat];
        printf " name: %s\n", $file->filename;
        printf " size: %s\n", $stat->[7];
        printf " last-mod: %s\n", scalar(localtime($stat->[9]));
    }

    my $file = $bagit->get_file("mydata.txt");
    my $fh   = $file->fh;

    while (<$fh>) {
       ....
    }

    print "dirty?\n" if $bagit->is_dirty;

    if ($bagit->complete) {
        print "bag is complete\n";
    }
    else {
        print "bag is not complete!\n";
    }

    if ($bagit->valid) {
        print "bag is valid\n";
    }
    else {
        print "bag is not valid!\n";
    }

    if ($bagit->is_holey) {
        print "bag is holey\n";
    }
    else {
        print "bag isn't holey\n";
    }

    if ($bagit->errors) {
        print join("\n",$bagit->errors);
    }

    # Write operations
    $bagit->add_info('My-Tag','fsdfsdfsdf');
    $bagit->add_info('My-Tag',['dfdsf','dfsfsf','dfdsf']);
    $bagit->remove_info('My-Tag');

    $bagit->add_file("test.txt","my text");
    $bagit->add_file("data.pdf", IO::File->new("/tmp/data.pdf"));
    $bagit->remove_file("test.txt");

    $bagit->add_fetch("http://www.gutenberg.org/cache/epub/1980/pg1980.txt","290000","shortstories.txt");
    $bagit->remove_fetch("shortstories.txt");

    unless ($bagit->locked) {
        $bagit->write("bags/demo04"); # fails when the bag already exists
        $bagit->write("bags/demo04", new => 1); # recreate the bag when it already existed
        $bagit->write("bags/demo04", overwrite => 1); # overwrites an exiting bag
    }

=head1 CATMANDU MODULES

=over

=item * L<Catmandu::Importer::BagIt>

=item * L<Catmandu::Exporter::BagIt>

=back

=head1 METHODS

=head2 new()

Create a new BagIt object

=head2 read($directory)

Open an exiting BagIt object

=head2 write($directory, [%options])

Write a BagIt to disk. Options: new => 1 recreate the bag when it already existed, overwrite => 1 overwrite
and existing bag (updating the changed tags/files);

=head2 locked

Check if a process has locked the BagIt. Or, a previous process didn't complete the write operations.

=head2 path()

Return the path to the BagIt.

=head2 version()

Return the version of the BagIt.

=head2 encoding()

Return the encoding of the BagIt.

=head2 size()

Return a human readble string of the expected size of the BagIt (adding the actual sizes found on disk plus 
the files that need to be fetched from the network).

=head2 payload_oxum()

Return the actual payload oxum of files found in the package.

=head2 is_dirty()

Return true when the BagIt contains changes not yet written to disk.

=head2 is_holey()

Return true when the BagIt contains a non emtpy fetch configuration.

=head2 is_error()

Return an ARRAY of errors when checking complete, valid and write. 

=head2 complete()

Return true when the BagIt is complete (all files and manifest files are consistent).

=head2 valid()

Returns true when the BagIt is complete and all checkums match the files on disk.

=head2 list_info_tags()

Return an ARRAY of tag names found in bagit-info.txt.

=head2 add_info($tag,$value)

=head2 add_info($tag,[$values])

Add an info $tag with a $value.

=head2 remove_info($tag)

Remove an info $tag.

=head2 get_info($tag, [$delim])

Return an ARRAY of values found for the $tag name. Or, in scalar context, return a string of 
all values optionally delimeted by $delim.

=head2 list_tagsum()

Return a ARRAY of all checkums of tag files.

=head2 get_tagsum($filename)

Return the checksum of the tag file $filename.

=head2 list_checksum()

Return an ARRAY of files found in the manifest file.

=head2 get_checksum($filename)

Return the checksum of the file $filname.

=head2 list_files()

Return an ARRAY of real payload files found on disk as Catmandu::BagIt::Payload.

=head2 get_file($filename)

Get a Catmandu::BagIt::Payload object for the file $filename.

=head2 add_file($filename, $string)

=head2 add_file($filename, IO::File->new(...))

Add a new file to the BagIt.

=head2 remove_file($filename)

Remove a file from the BagIt.

=head2 list_fetch()

Return an ARRAY of fetch payloads as Catmandu::BagIt::Fetch.

=head2 get_fetch($filename)

Get a Catmandu::BagIt::Fetch object for the file $filename.

=head2 add_fetch($url,$size,$filename)

Add a fetch entry to the BagIt.

=head2 remove_fetch($filename)

Remove a fetch entry from the BagIt.

=head2 mirror_fetch($fetch)

Mirror a Catmandu::BagIt::Fetch object to local disk.

=head1 SEE ALSO

L<Catmandu::Importer::BagIt> , L<Catmandu::Exporter::BagIt>

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
