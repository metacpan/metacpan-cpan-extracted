package Catmandu::BagIt;

use strict;
our $VERSION = '0.15';

use Catmandu::Sane;
use Catmandu;
use Moo;
use Encode;
use Digest::MD5;
use IO::File qw();
use IO::Handle qw();
use File::Copy;
use List::MoreUtils qw(first_index uniq);
use Path::Tiny;
use Path::Iterator::Rule;
use Catmandu::BagIt::Payload;
use Catmandu::BagIt::Fetch;
use POSIX qw(strftime);
use LWP::UserAgent;
use utf8;
use namespace::clean;

# Flags indicating which operations are needed to create a valid bag
use constant {
    FLAG_BAGIT        => 0x001 , # Flag indicates updating the bagit.txt file required
    FLAG_BAG_INFO     => 0x002 , # Flag indicates updating the bag-info.txt file required
    FLAG_FETCH        => 0x004 , # Flag indicates updating the fetch.txt file required
    FLAG_DATA         => 0x008 , # Flag indicating new payload data available
    FLAG_TAG_MANIFEST => 0x016 , # Flag indicates updateing tag-manifest-manifest.txt required
    FLAG_MANIFEST     => 0x032 , # Flag indicates updating manifest-md5.txt required
    FLAG_DIRTY        => 0x064 , # Flag indicates payload file that hasn't been serialized
};

with 'Catmandu::Logger';

# Array containing all errors when reading/writing bags
has '_error' => (
    is       => 'rw',
    default  => sub { [] },
);

# Integer containing a combinatation of FLAG_* set for this bag
has 'dirty' => (
    is       => 'ro',
    writer   => '_dirty',
    default  => 0,
);

# Path to a directory containing a bag
has 'path' => (
    is       => 'ro',
    writer   => '_path',
    init_arg => undef,
);

# Version number of the bag specification
has 'version' => (
    is       => 'ro',
    writer   => '_version',
    default  => '0.97',
    init_arg => undef,
);

# Encoding of all tag manifests
has 'encoding' => (
    is       => 'ro',
    writer   => '_encoding',
    default  => 'UTF-8',
    init_arg => undef,
);

# User agent used to fetch payloads from the Internet
has user_agent => (is => 'lazy');

# An array of a tag file names
has '_tags' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

# An array of Catmandu::BagIt::Payloads
has '_files' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

# An array of Catmandu::BagIt::Fetch
has '_fetch' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

# A lookup hash of md5 checksums for the tag files
has '_tag_sums' => (
    is       => 'rw',
    default  => sub { {} },
    init_arg => undef,
);

# A lookup hahs of md5 checksums for the payload files
has '_sums' => (
    is       => 'rw',
    default  => sub { {} },
    init_arg => undef,
);

# An array of hashes of all name/value pairs in the bag-info.txt file
has '_info' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef,
);

sub _build_user_agent {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent('Catmandu-BagIt/' . $Catmandu::BagIt::VERSION);
    $ua;
}

# Settings requires when creating a new bag from scratch
sub BUILD {
    my $self = shift;

    $self->log->debug("initializing bag");

    # Intialize the in memory settings of the bag-info
    $self->_update_info;

    # Initialize the in memory settings of the tag-manifests
    $self->_update_tag_manifest;

    # Intialize the names of the basic tag files
    $self->_tags([qw(
            bagit.txt
            bag-info.txt
            manifest-md5.txt
            )]);

    # Set this bag as dirty requiring an update of all the files
    $self->_dirty($self->dirty | FLAG_BAG_INFO | FLAG_TAG_MANIFEST | FLAG_DATA | FLAG_BAGIT);
}

# Return all the arrors as an array
sub errors {
    my ($self) = @_;
    @{$self->_error};
}

# Return an array of tag file names
sub list_tags {
    my ($self) = @_;
    @{$self->_tags};
}

# Return an array of all Catmandu::BagIt::Payload-s
sub list_files {
    my ($self) = @_;
    @{$self->_files};
}

# Return a Catmandu::BagIt::Payload given a file name
sub get_file {
    my ($self,$filename) = @_;
    die "usage: get_file(filename)" unless $filename;

    for ($self->list_files) {
        return $_ if $_->filename eq $filename;
    }
    return undef;
}

# Return a Catmandu::BagIt::Fetch given a file name
sub get_fetch {
    my ($self,$filename) = @_;
    die "usage: get_fetch(filename)" unless $filename;

    for ($self->list_fetch) {
        return $_ if $_->filename eq $filename;
    }
    return undef;
}

# Return true when this bag is dirty
sub is_dirty {
    my ($self) = @_;
    $self->dirty != 0;
}

# Return true when this bag is holey (and requires fetching data from the Internet
# to be made complete)
sub is_holey {
    my ($self) = @_;
    @{$self->_fetch} > 0;
}

# Return an array of Catmandu::BagIt::Fetch
sub list_fetch {
    my ($self) = @_;
    @{$self->_fetch};
}

# Return an array of tag file
sub list_tagsum {
    my ($self) = @_;
    keys %{$self->_tag_sums};
}

# Return the md5 checksum of a file
sub get_tagsum {
    my ($self,$file) = @_;

    die "usage: get_tagsum(file)" unless $file;

    $self->_tag_sums->{$file};
}

# Return an array of payload files
sub list_checksum {
    my ($self) = @_;
    keys %{$self->_sums};
}

# Return the md5 checksum of of a file name
sub get_checksum {
    my ($self,$file) = @_;

    die "usage: get_checksum(file)" unless $file;

    $self->_sums->{$file};
}

# Read the content of a bag
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

    if ( wantarray ) {
        return $ok == 7 ? ($self) : (undef, $self->errors);
    }
    else {
        return $ok == 7 ? $self : undef;
    }
}

# Write the content of a bag back to disk
sub write {
    my ($self,$path,%opts) = @_;

    $self->_error([]);

    die "usage: write(path[, overwrite => 1])" unless $path;

    # Check if other processes are writing or previous processes died
    if ($self->locked($path)) {
        $self->log->error("$path is locked");
        $self->_push_error("$path is locked");
        return undef;
    }

    if (defined($self->path) && $path ne $self->path) {
        # If the bag is copied from to a new location than all the tag files and
        # files should be flagged as dirty and need to be overwritten
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
        # Remove existing bags
        $self->log->info("removing: $path");
        path($path)->remove_tree;
    }

    if (-f $self->_bagit_file($path)) {
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
        path($path)->mkpath;
        $self->_dirty($self->dirty | FLAG_BAGIT);
    }

    unless ($self->touch($self->_lock_file($path))) {
        $self->log->error("failed to lock in $path");
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

    return undef unless $ok == 6;

    $self->_dirty(0);

    unlink($self->_lock_file($path));

    $ok = 0;

    # Reread the contents of the bag
    $ok += $self->_read_version($path);
    $ok += $self->_read_info($path);
    $ok += $self->_read_tag_manifest($path);
    $ok += $self->_read_manifest($path);
    $ok += $self->_read_tags($path);
    $ok += $self->_read_files($path);
    $ok += $self->_read_fetch($path);

    $ok == 7;
}

sub _bagit_file {
    my ($self,$path) = @_;

    File::Spec->catfile($path,'bagit.txt');
}

sub _bag_info_file {
    my ($self,$path) = @_;

    File::Spec->catfile($path,'bag-info.txt');
}

sub _package_info_file {
    my ($self,$path) = @_;

    File::Spec->catfile($path,'package-info.txt');
}

sub _manifest_md5_file {
    my ($self,$path) = @_;

    File::Spec->catfile($path,'manifest-md5.txt');
}

sub _tagmanifest_md5_file {
    my ($self,$path) = @_;

    File::Spec->catfile($path,'tagmanifest-md5.txt');
}

sub _fetch_file {
    my ($self,$path) = @_;

    File::Spec->catfile($path,'fetch.txt');
}

sub _tag_file {
    my ($self,$path,$file) = @_;

    File::Spec->catfile($path,$file);
}

sub _payload_file {
    my ($self,$path,$file) = @_;

    File::Spec->catfile($path,'data',$file);
}

sub _lock_file {
    my ($self,$path) = @_;

    File::Spec->catfile($path,'.lock');
}

sub locked {
    my ($self,$path) = @_;
    $path //= $self->path;

    return undef unless defined($path);

    -f $self->_lock_file($path);
}

sub touch {
    my ($self,$path) = @_;

    die "usage: touch(path)"
            unless defined($path);

    path("$path")->spew("");

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

    my $payload = Catmandu::BagIt::Payload->from_any($filename,$data);
    $payload->flag(FLAG_DIRTY);

    push @{ $self->_files }, $payload;

    my $fh = $payload->open;

    binmode($fh,":raw");

    my $sum = $self->_md5_sum($fh);

    close($fh);

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
            unless defined($url) && $size =~ /^[0-9]+$/ && defined($filename);

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

    my $tmp_filename = Path::Tiny->tempfile;

    my $url       = $fetch->url;
    my $filename  = $fetch->filename;
    my $path      = $self->path;

    $self->log->info("mirroring $url -> $tmp_filename...");

    my $response = $self->user_agent->mirror($url,$tmp_filename);

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

    unless ($self->version and $self->version =~ /^[0-9]+\.[0-9]+$/) {
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
            $self->log->error("file $file doesn't exist in bag and fetch.txt");
            $self->_push_error("file $file doesn't exist in bag and fetch.txt");
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
        my $fh  = $tag == 0 ?
                    new IO::File $self->_payload_file($path,$file), "r" :
                    new IO::File $self->_tag_file($path,$file) , "r";

        unless ($fh) {
            $self->log->error("can't read $file");
            return (0,"can't read $file");
        }

        binmode($fh,':raw');

        my $md5_check = $self->_md5_sum($fh);

        close($fh);

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

    foreach my $file ($self->list_files) {
        my $fh   = $file->open;
        my $size = [ $fh->stat ]->[7];
        $fh->close;
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

    return 1 unless -f $self->_fetch_file($path);

    $self->log->debug("reading fetch.txt");

    foreach my $line (path($self->_fetch_file($path))->lines_utf8) {
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

    if (! -f $self->_tagmanifest_md5_file($path)) {
        return 1;
    }

    $self->log->debug("reading tagmanifest-md5.txt");

    foreach my $line (path($self->_tagmanifest_md5_file($path))->lines_utf8) {
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

    if (! -f $self->_manifest_md5_file($path)) {
        $self->_push_error("no manifest-md5.txt in $path");
        return 0;
    }

    foreach my $line (path($self->_manifest_md5_file($path))->lines_utf8) {
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

    my $rule = Path::Iterator::Rule->new;
    $rule->max_depth(1);
    $rule->file;
    my $iter = $rule->iter($path);

    while(my $file = $iter->()) {
        $file =~ s/^$path.//;

        next if $file =~ /^tagmanifest-\w+.txt$/;

        push @{ $self->_tags } , $file;
    }

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

    my $rule = Path::Iterator::Rule->new;
    $rule->file;
    my $iter = $rule->iter("$path/data");

    while(my $file = $iter->()) {
        my $filename = $file;
        $filename =~ s/^$path\/data\///;
        my $payload = Catmandu::BagIt::Payload->new(filename => $filename, path => $file);
        push @{ $self->_files } , $payload;
    }

    1;
}

sub _read_info {
    my ($self, $path) = @_;

    $self->log->debug("reading the tag info file");

    $self->_info([]);

    my $info_file = -f $self->_bag_info_file($path) ?
                        $self->_bag_info_file($path) :
                        $self->_package_info_file($path);

    if (! -f $info_file) {
        $self->log->error("no package-info.txt or bag-info.txt in $path");
        $self->_push_error("no package-info.txt or bag-info.txt in $path");
        return 0;
    }

    foreach my $line (path($info_file)->lines_utf8) {
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

    if (! -f $self->_bagit_file($path) ) {
        $self->log->error("no bagit.txt in $path");
        $self->_push_error("no bagit.txt in $path");
        return 0;
    }

    foreach my $line (path($self->_bagit_file($path))->lines_utf8) {
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

    path($self->_bagit_file($path))->spew_utf8($self->_bagit_as_string);

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

    path($self->_bag_info_file($path))->spew_utf8($self->_baginfo_as_string);

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

# Write BagIt data payloads to disk
sub _write_data {
    my ($self,$path) = @_;

    # Return immediately when no files need to be written
    return 1 unless $self->dirty & FLAG_DATA;

    $self->log->info("writing the data files");

    # Create a data/ directory for payloads
    unless (-d "$path/data") {
        unless (mkdir "$path/data") {
            $self->log->error("can't create payload directory $path/data: $!");
            $self->_push_error("can't create payload directory $path/data: $!");
            return;
        }
    }

    # Create a list of all files written to the payload directory
    # Compare this list later with files found in the payload directory
    # This difference are the files that can be deleted
    my @all_names_in_bag = ();

    foreach my $item ($self->list_files) {
        my $filename = 'data/' . $item->{filename};
        push @all_names_in_bag , $filename;

        # Only process files that are dirty
        next unless $item->flag & FLAG_DIRTY;

        # Check for deep directories that need to be stored
        my $dir  = $filename; $dir =~ s/\/[^\/]+$//;

        $self->log->info("serializing $filename");

        path("$path/$dir")->mkpath unless -d "$path/$dir";

        my $old_path = $item->path;
        my $new_path = "$path/$filename";

        if ($item->is_new) {
            File::Copy::move($old_path,$new_path);
        }
        else {
            File::Copy::copy($old_path,$new_path);
        }

        $item->flag($item->flag ^ FLAG_DIRTY);
    }

    # Check deleted files. Delete all files not in the @all_names_in_bag list
    my $rule = Path::Iterator::Rule->new;
    $rule->file;
    my $iter = $rule->iter("$path/data");

    while(my $file = $iter->()) {
        my $filename = $file;
        $filename =~ s/^$path\///;

        unless (grep {$filename eq $_} @all_names_in_bag) {
            $self->log->info("deleting $path/$filename");
            unlink "$path/$filename";
        }
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
        unlink $self->_fetch_file($path) if -f $self->_fetch_file($path);
        return 1;
    }

    $self->log->info("writing the fetch file");

    if ($self->_fetch == 0) {
        unlink $self->_fetch_file($path) if -r $self->_fetch_file($path);
        $self->_dirty($self->dirty ^ FLAG_FETCH);
        return 1;
    }

    path($self->_fetch_file($path))->spew_utf8($fetch_str);

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

    path($self->_manifest_md5_file($path))->spew_utf8($self->_manifest_as_string);

    $self->_dirty($self->dirty ^ FLAG_MANIFEST);

    1;
}

sub _manifest_as_string {
    my $self = shift;
    my $path = $self->path;

    return undef unless defined $path;

    my $str = '';

    foreach my $file ($self->list_checksum) {
        next unless -f $self->_payload_file($path,$file);
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

    $self->log->info("writing the tagmanifest file");

    path($self->_tagmanifest_md5_file($path))->spew_utf8($self->_tag_manifest_as_string);

    $self->_dirty($self->dirty ^ FLAG_MANIFEST);

    1;
}

sub _tag_manifest_as_string {
    my $self = shift;

    my $str = '';

    foreach my $file ($self->list_tagsum) {
        my $md5  = $self->get_tagsum($file);
        $str .= "$md5 $file\n";
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
    elsif (ref($data) eq 'SCALAR') {
        return $ctx->add(Encode::encode_utf8($$data))->hexdigest;
    }
    elsif (ref($data) =~ /^IO/) {
        return $ctx->addfile($data)->hexdigest;
    }
    else {
        die "unknown data type: `" . ref($data) . "`";
    }
}

sub _is_legal_file_name {
    my ($self, $filename) = @_;

    return 0 unless ($filename =~ /^[[:alnum:]._-]+$/);
    return 0 if ($filename =~ m{(^\.|\/\.+\/)});
    return 1;
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
        my $stat = [$file->path];
        printf " name: %s\n", $file->filename;
        printf " size: %s\n", $stat->[7];
        printf " last-mod: %s\n", scalar(localtime($stat->[9]));
    }

    my $file = $bagit->get_file("mydata.txt");
    my $fh   = $file->open;

    while (<$fh>) {
       ....
    }

    close($fh);

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

=item * L<Catmandu::Store::File::BagIt>

=back

=head1 METHODS

=head2 new()

Create a new BagIt object

=head2 read($directory)

Open an exiting BagIt object and return an instance of BagIt or undef on failure.
In array context the read method also returns all errors as an array:

  my $bagit = Catmandu::BagIt->read("/data/my-bag");

  my ($bagit,@errors) = Catmandu::BagIt->read("/data/my-bag");

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

=head2 add_file($filaname, sub { my $io = shift; .... })

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

L<Catmandu::Importer::BagIt> , L<Catmandu::Exporter::BagIt> , L<Catmandu::Store::File::BagIt>

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
