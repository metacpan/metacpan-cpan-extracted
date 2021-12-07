package Archive::BagIt;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Encode qw( decode );
use File::Spec ();
use Class::Load qw( load_class );
use Carp qw( carp croak confess);
use POSIX qw( strftime );
use Moo;
with "Archive::BagIt::Role::Portability";

our $VERSION = '0.086'; # VERSION

# ABSTRACT: The main module to handle bags.



around 'BUILDARGS' , sub {
    my $orig = shift;
    my $class = shift;
    if (@_ == 1 && !ref $_[0]) {
        return $class->$orig(bag_path=>$_[0]);
    } else {
        return $class->$orig(@_);
    }
};


sub BUILD {
    my ($self, $args) = @_;
    return $self->load_plugins(("Archive::BagIt::Plugin::Manifest::MD5", "Archive::BagIt::Plugin::Manifest::SHA512"));
}

###############################################


has 'use_parallel' => (
    is => 'rw',
    lazy => 1,
    default => 0,
);

###############################################


has 'use_async' => (
    is => 'rw',
    lazy => 1,
    default => 0,
);

###############################################


has 'force_utf8' => (
    is        => 'rw',
    lazy      => 1,
    predicate => 1,
);

###############################################


has 'bag_path' => (
    is => 'rw',
);

###############################################

has 'bag_path_arr' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_bag_path_arr',
);

###############################################


has 'metadata_path' => (
    is=> 'ro',
    lazy => 1,
    builder => '_build_metadata_path',
);

sub _build_metadata_path {
    my ($self) = @_;
    return $self->bag_path;
}

###############################################

has 'metadata_path_arr' => (
    is =>'ro',
    lazy => 1,
    builder => '_build_metadata_path_arr',
);


###############################################

has 'rel_metadata_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_rel_metadata_path',
);

###############################################


has 'payload_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_path',
);

sub _build_payload_path {
    my ($self) = @_;
    return File::Spec->catdir($self->bag_path, "data");
}

###############################################

has 'payload_path_arr' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_path_arr',
);

###############################################

has 'rel_payload_path' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_rel_payload_path',
);

###############################################


has 'checksum_algos' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_checksum_algos',
);

###############################################


has 'bag_version' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_bag_version',
);

###############################################


has 'bag_encoding' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_bag_encoding',
);

###############################################


has 'bag_info' => (
    is        => 'rw',
    lazy      => 1,
    builder   => '_build_bag_info',
    predicate => 1
);

###############################################


has 'errors' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { my $self = shift; return [];},
);

###############################################



has 'warnings' => (
    is   => 'ro',
    lazy => 1,
    builder => sub { my $self = shift; return [];},
);

###############################################


has 'digest_callback' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my $sub = sub {
            my ($digestobj, $filename) = @_;
            if (-f $filename) {
                open(my $fh, '<:raw', $filename) or confess("Cannot open '$filename', $!");
                binmode($fh);
                my $digest = $digestobj->get_hash_string($fh);
                close $fh or confess("could not close file '$filename', $!");
                return $digest;
            } else {
                croak "file $filename is not a real file!";
            }
        };
        return $sub;
    }
);

###############################################


sub get_baginfo_values_by_key {
    my ($self, $searchkey) = @_;
    my $info = $self->bag_info();
    my @values;
    if (defined $searchkey) {
        my $lc_flag = $self->is_baginfo_key_reserved( $searchkey );
        foreach my $entry (@{ $info }) {
            return unless defined $entry;
            my ($key, $value) = %{ $entry };
            if ( __case_aware_compare_for_baginfo( $key, $searchkey, $lc_flag) ) {
                push @values, $value;
            }
        }
    }
    return @values if (scalar(@values) > 0);
    return;
}

###############################################


sub is_baginfo_key_reserved_as_uniq {
    my ($self, $searchkey) = @_;
    return $searchkey =~ m/^(Bagging-Date)|(Bag-Size)|(Payload-Oxum)|(Bag-Group-Identifier)|(Bag-Count)$/i;
}

###############################################


sub is_baginfo_key_reserved {
    my ($self, $searchkey) = @_;
    return $searchkey =~ m/^
        (Source-Organization)|
        (Organisation-Adress)|
        (Contact-Name)|
        (Contact-Phone)|
        (Contact-Email)|
        (External-Description)|
        (Bagging-Date)|
        (External-Identifier)|
        (Bag-Size)|
        (Payload-Oxum)|
        (Bag-Group-Identifier)|
        (Bag-Count)|
        (Internal-Sender-Identifier)|
        (Internal-Sender-Description)$/ix

}

###############################################

sub __case_aware_compare_for_baginfo {
    my ($internal_key, $search_key, $lc_flag) = @_;
    return (defined $internal_key) && (
        ( $lc_flag && ((lc $internal_key) eq (lc $search_key)) ) # for reserved keys use caseinsensitive search
            ||
            ( (!$lc_flag) && ($internal_key eq $search_key) ) # for other keys sensitive search
    )
}

###############################################

sub _find_baginfo_idx {
    my ($self, $searchkey) = @_;
    if (defined $searchkey) {
        if ($searchkey =~ m/:/) {croak "key should not contain a colon! (searchkey='$searchkey')";}
        my $info = $self->bag_info();
        my $size = scalar(@{$info});
        my $lc_flag = $self->is_baginfo_key_reserved($searchkey);
        foreach my $idx (reverse 0.. $size-1) { # for multiple entries return the latest addition
            my %entry = %{$info->[$idx]};
            my ($key, $value) = %entry;
            if (__case_aware_compare_for_baginfo($key, $searchkey, $lc_flag)) {
                return $idx;
            }
        }
    }
    return;
}
###############################################


sub verify_baginfo {
    my ($self) = @_;
    my %keys;
    my $info = $self->bag_info();
    my $ret = 1;
    if (defined $info) {
        foreach my $entry (@{$self->bag_info()}) {
            my ($key, $value) = %{$entry};
            if ($self->is_baginfo_key_reserved($key)) {
                $keys{ lc $key }++;
            }
            else {
                $keys{ $key }++
            }
        }
        foreach my $key (keys %keys) {
            if ($self->is_baginfo_key_reserved_as_uniq($key)) {
                if ($keys{$key} > 1) {
                    push @{$self->{errors}}, "Baginfo key '$key' exists $keys{$key}, but should be uniq!";
                    $ret = undef;
                }
            }
        }
    }
    # check for payload oxum
    my ($loaded_payloadoxum) = $self->get_baginfo_values_by_key('Payload-Oxum');
    if (defined $loaded_payloadoxum) {
        my ($octets, $streamcount) = $self->calc_payload_oxum();
        if ("$octets.$streamcount" ne $loaded_payloadoxum) {
            push @{$self->{errors}}, "Payload-Oxum differs, calculated $octets.$streamcount but $loaded_payloadoxum was expected by bag-info.txt";
            $ret = undef;
        }
    } else {
        push @{$self->{warnings}}, "Payload-Oxum was expected in bag-info.txt, but not found!"; # payload-oxum is recommended, but optional
    }
    return $ret;
}

###############################################


sub delete_baginfo_by_key {
    my ($self, $searchkey) = @_;
    my $idx = $self->_find_baginfo_idx($searchkey);
    if (defined $idx) {
        splice @{$self->{bag_info}}, $idx, 1; # delete nth indexed entry
    }
    return 1;
}

###############################################


sub exists_baginfo_key {
    my ($self, $searchkey) =@_;
    return (defined  $self->_find_baginfo_idx($searchkey));
}

###############################################

sub _replace_baginfo_by_first_match {
    my ($self, $searchkey, $newvalue) = @_;
    my $idx = $self->_find_baginfo_idx( $searchkey);
    if (defined $idx) {
        $self->{bag_info}[$idx] = {$searchkey => $newvalue};
        return $idx;
    }
    return;
}

###############################################


sub append_baginfo_by_key {
    my ($self, $searchkey, $newvalue) = @_;
    if (defined $searchkey) {
        if ($searchkey =~ m/:/) { croak "key should not contain a colon! (searchkey='$searchkey')"; }
        if ($self->is_baginfo_key_reserved_as_uniq($searchkey)) {
            if (defined $self->get_baginfo_values_by_key($searchkey)) {
                # hmm, search key is marked as uniq and still exists
                return;
            }
        }
        push @{$self->{bag_info}}, {$searchkey => $newvalue};
    }
    return 1;
}

###############################################


sub add_or_replace_baginfo_by_key {
    my ($self, $searchkey, $newvalue) = @_;
    if (defined $searchkey) {
        if ($searchkey =~ m/:/) { croak "key should not contain a colon! (searchkey='$searchkey')"; }
        if (defined $self->{bag_info}) {
            my $idx = $self->_replace_baginfo_by_first_match( $searchkey, $newvalue);
            if (defined $idx) { return $idx;}
        }
        $self->append_baginfo_by_key( $searchkey, $newvalue );
        return -1;
    }
}

###############################################


has 'forced_fixity_algorithm' => (
    is   => 'ro',
    lazy => 1,
    builder  => '_build_forced_fixity_algorithm',
);

###############################################


has 'manifest_files' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_manifest_files',
);

###############################################


has 'tagmanifest_files' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_tagmanifest_files',
);

###############################################


has 'payload_files' => ( # relatively to bagit base
    is => 'ro',
    lazy => 1,
    builder => '_build_payload_files',
);

###############################################


has 'non_payload_files' => (
    is=>'ro',
    lazy => 1,
    builder => '_build_non_payload_files',
);

###############################################


has 'plugins' => (
    is=>'rw',
    #isa=>'HashRef',
);

###############################################



has 'manifests' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_manifests'
    #isa=>'HashRef',
);

###############################################



has 'algos' => (
    is=>'rw',
    #isa=>'HashRef',
);

###############################################

sub _build_bag_path_arr {
    my ($self) = @_;
    my @split_path = File::Spec->splitdir($self->bag_path);
    return @split_path;
}

sub _build_payload_path_arr {
    my ($self) = @_;
    my @split_path = File::Spec->splitdir($self->payload_path);
    return @split_path;
}

sub _build_rel_payload_path {
    my ($self) = @_;
    my $rel_path = File::Spec->abs2rel( $self->payload_path, $self->bag_path ) ;
    return $rel_path;
}

sub _build_metadata_path_arr {
    my ($self) = @_;
    my @split_path = File::Spec->splitdir($self->metadata_path);
    return @split_path;
}

sub _build_rel_metadata_path {
    my ($self) = @_;
    my $rel_path = File::Spec->abs2rel( $self->metadata_path, $self->bag_path ) ;
    return $rel_path;
}

sub _build_checksum_algos {
    my($self) = @_;
    my $checksums = [ 'md5', 'sha1', 'sha256', 'sha512' ];
    return $checksums;
}

sub _build_manifest_files {
    my($self) = @_;
    my @manifest_files;
    foreach my $algo (@{$self->checksum_algos}) {
        my $manifest_file = File::Spec->catfile($self->metadata_path, "manifest-$algo.txt");
        if (-f $manifest_file) {
            push @manifest_files, $manifest_file;
        }
    }
    return \@manifest_files;
}

sub _build_tagmanifest_files {
    my ($self) = @_;
    my @tagmanifest_files;
    foreach my $algo (@{$self->checksum_algos}) {
        my $tagmanifest_file = File::Spec->catfile($self->metadata_path,"tagmanifest-$algo.txt");
        if (-f $tagmanifest_file) {
            push @tagmanifest_files, $tagmanifest_file;
        }
    }
    return \@tagmanifest_files;
}

sub __handle_nonportable_local_entry {
    my $self = shift;
    my $local_entry = shift;
    my $dir = shift;
    my $rx_portable = qr/^[a-zA-Z0-9._-]+$/;
    my $is_portable = $local_entry =~ m/$rx_portable/;
    if (! $is_portable) {
        my $local_entry_utf8 = decode("UTF-8", $local_entry);
        if ((!$self->has_force_utf8)) {
            my $hexdump = "0x" . unpack('H*', $local_entry);
            $local_entry =~m/[^a-zA-Z0-9._-]/; # to find PREMATCH, needed nextline
            my $prematch_position = $`;
            carp "possible non portable pathname detected in $dir,\n",
                "got path (hexdump)='$hexdump'(hex),\n",
                "decoded path='$local_entry_utf8'\n",
                "              "." "x length($prematch_position)."^"."------- first non portable char\n";
        }
        $local_entry = $local_entry_utf8;
    }
    return $local_entry;
}



sub __file_find { # own implementation, because File::Find has problems with UTF8 encoded Paths under MSWin32
    # finds recursively all files in given directory.
    # if $excludedir is defined, the content will be excluded
    my ($self,$dir, $excludedir) = @_;
    if (defined $excludedir) {
        $excludedir = File::Spec->rel2abs( $excludedir);
    }
    my @file_paths;

    my $finder;
    $finder = sub {
        my ($current_dir) = @_; #absolute path
        my @todo;
        my @tmp_file_paths;
        opendir( my $dh, $current_dir);
        my @paths = File::Spec->no_upwards ( readdir $dh );
        closedir $dh;
        foreach my $local_entry (@paths) {
            my $path_entry = File::Spec->catdir($current_dir, $self->__handle_nonportable_local_entry($local_entry, $dir));
            if (-f $path_entry) {
                push @tmp_file_paths, $path_entry;
            } elsif (-d $path_entry) {
                next if ((defined $excludedir) && ($path_entry eq $excludedir));
                push @todo, $path_entry;
            } else {
                croak "not a file nor a dir found '$path_entry'";
            }
        }
        push @file_paths, sort @tmp_file_paths;
        foreach my $subdir (sort @todo) {
            &$finder($subdir);
        }
    };
    my $absolute = File::Spec->rel2abs( $dir );
    &$finder($absolute);
    @file_paths = map { File::Spec->abs2rel( $_, $dir)} @file_paths;
    return @file_paths;
}

sub _build_payload_files{
    my ($self) = @_;
    my $payload_dir = $self->payload_path;
    my $reldir = File::Spec->abs2rel($payload_dir, $self->bag_path());
    $reldir =~ s/^\.$//;
    my @payload = map {
        $reldir eq "" ? $_ : File::Spec->catfile($reldir, $_)
    } $self->__file_find($payload_dir, File::Spec->rel2abs($self->metadata_path));
    return wantarray ? @payload : \@payload;
}


sub __build_read_bagit_txt {
    my($self) = @_;
    my $bagit = $self->metadata_path;
    my $file = File::Spec->catfile($bagit, "bagit.txt");
    open(my $BAGIT, "<:encoding(UTF-8)", $file) or croak("Cannot read '$file': $!");
    my $version_string = <$BAGIT>;
    my $encoding_string = <$BAGIT>;
    close($BAGIT);
    if (defined $version_string) {
        $version_string =~ s/[\r\n]//;
    }
    if (defined $encoding_string) {
        $encoding_string =~s/[\r\n]//;
    }
    return ($version_string, $encoding_string, $file);
}

sub _build_bag_version {
    my($self) = @_;
    my ($version_string, $encoding_string, $file) = $self->__build_read_bagit_txt();
    croak "Version line missed in '$file" unless defined $version_string;
    if ($version_string =~ /^BagIt-Version: ([01]\.[0-9]+)$/) {
        return $1;
    } else {
        $version_string =~ s/\r/<CR>/;
        $version_string =~ s/^\N{U+FEFF}/<BOM>/;
        croak "Version string '$version_string' of '$file' is incorrect";
    };
}

sub _build_bag_encoding {
    my($self) = @_;
    my ($version_string, $encoding_string, $file) = $self->__build_read_bagit_txt();
    croak "Encoding line missed in '$file" unless defined $encoding_string;
    croak "Encoding '$encoding_string' of '$file' not supported by current Archive::BagIt module!" unless ($encoding_string !~ m/^UTF-8$/);
    return $encoding_string;
}

sub __sort_bag_info {
    my @sorted = sort {
        my %tmpa = %{$a};
        my %tmpb = %{$b};
        my ($ka, $va) = each %tmpa;
        my ($kb, $vb) = each %tmpb;
        my $kres = $ka cmp $kb;
        if ($kres != 0) {
            return $kres;
        } else {
            return $va cmp $vb;
        }
    } @_;
    return @sorted;
}

sub _parse_bag_info { # parses a bag-info textblob
    my ($self, $textblob) = @_;
    #    metadata elements are OPTIONAL and MAY be repeated.  Because "bag-
    #    info.txt" is intended for human reading and editing, ordering MAY be
    #    significant and the ordering of metadata elements MUST be preserved.
    #
    #    A metadata element MUST consist of a label, a colon ":", a single
    #    linear whitespace character (space or tab), and a value that is
    #    terminated with an LF, a CR, or a CRLF.
    #
    #    The label MUST NOT contain a colon (:), LF, or CR.  The label MAY
    #    contain linear whitespace characters but MUST NOT start or end with
    #    whitespace.
    #
    #    It is RECOMMENDED that lines not exceed 79 characters in length.
    #    Long values MAY be continued onto the next line by inserting a LF,
    #    CR, or CRLF, and then indenting the next line with one or more linear
    #    white space characters (spaces or tabs).  Except for linebreaks, such
    #    padding does not form part of the value.
    #
    #    Implementations wishing to support previous BagIt versions MUST
    #    accept multiple linear whitespace characters before and after the
    #    colon when the bag version is earlier than 1.0; such whitespace does
    #    not form part of the label or value.
    # find all labels
    my @labels;
    while ($textblob =~ s/^([^:\s]+)\s*:\s*//m) { # label if starts with chars not colon or whitespace followed by zero or more spaces, a colon, zero or more spaces
        # label found
        my $label = $1; my $value="";

        if ($textblob =~ s/(.+?)(?=^\S)//ms) {
            # value if rest string starts with chars not \r and/or \n until a non-whitespace after \r\n
            $value = chomp_portable($1);
        } elsif ($textblob =~ s/(.*)//s) {
            $value = chomp_portable($1);
        }
        if (defined $label) {
            push @labels, { "$label" => "$value" };
        }
    }
    # The RFC does not allow reordering:
    #my @sorted = __sort_bag_info(@labels);
    #return \@sorted;
    return \@labels;
}

sub _build_bag_info {
    my ($self) = @_;
    my $bagit = $self->metadata_path;
    my $file = File::Spec->catfile($bagit, "bag-info.txt");
    if (-e $file) {
        open(my $BAGINFO, "<:encoding(UTF-8)", $file) or croak("Cannot read $file: $!");
        my @lines;
        while ( my $line = <$BAGINFO>) {
            push @lines, $line;
        }
        close($BAGINFO);
        my $lines = join("", @lines);
        return $self->_parse_bag_info($lines);
    }
    # bag-info.txt is optional
    return;
}

sub _build_non_payload_files {
    my ($self) = @_;
    my $non_payload_dir = $self->metadata_path();
    my $reldir = File::Spec->abs2rel($non_payload_dir, $self->bag_path());
    $reldir =~ s/^\.$//;
    my @non_payload = map {
        $reldir eq "" ? $_ : File::Spec->catfile($reldir, $_)
    } $self->__file_find($non_payload_dir, File::Spec->rel2abs($self->payload_path));
    return wantarray ? @non_payload : \@non_payload;
}

sub _build_forced_fixity_algorithm {
    my ($self) = @_;
    if ($self->bag_version() >= 1.0) {
        return Archive::BagIt::Plugin::Algorithm::SHA512->new(bagit => $self);
    }
    else {
        return Archive::BagIt::Plugin::Algorithm::MD5->new(bagit => $self);
    }
}

###############################################


sub load_plugins {
    my ($self, @plugins) = @_;

    #p(@plugins);
    my $loaded_plugins = $self->plugins;
    @plugins = grep { not exists $loaded_plugins->{$_} } @plugins;

    return if @plugins == 0;
    foreach my $plugin (@plugins) {
        load_class ($plugin) or croak ("Can't load $plugin");
        $plugin->new({bagit => $self});
    }

    return 1;
}

###############################################


sub load {
    my ($self) = @_;
    # call trigger
    $self->bag_path;
    $self->bag_version;
    $self->bag_encoding;
    $self->bag_info;
    $self->payload_path;
    $self->manifest_files;
    $self->checksum_algos;
    $self->tagmanifest_files;
    return 1;
}

###############################################


sub verify_bag {
    my ($self,$opts) = @_;
    #removed the ability to pass in a bag in the parameters, but might want options
    #like $return all errors rather than dying on first one
    my $bagit = $self->bag_path;
    my $version = $self->bag_version(); # to call trigger
    my $encoding = $self->bag_encoding(); # to call trigger
    my $baginfo = $self->verify_baginfo(); #to call trigger
    my $forced_fixity_alg = $self->forced_fixity_algorithm()->name();
    my $fetch_file = File::Spec->catfile($self->metadata_path, "fetch.txt");
    my $manifest_file = File::Spec->catfile($self->metadata_path, "manifest-$forced_fixity_alg.txt");
    my $payload_dir   = $self->payload_path;
    my $return_all_errors = $opts->{return_all_errors};

    if (-f $fetch_file) {
        croak("Fetching via file '$fetch_file' is not supported by current Archive::BagIt implementation")
    }
    croak("Manifest '$manifest_file' is not a regular file or does not exist for given bagit version '$version'") unless -f ($manifest_file);
    croak("Payload-directory '$payload_dir' is not a directory or does not exist") unless -d ($payload_dir);

    unless ($version > .95) {
        croak ("Bag Version $version is unsupported");
    }

    # check forced fixity

    my @errors;


    # check for manifests
    foreach my $algorithm ( keys %{ $self->manifests }) {
        my $res = $self->manifests->{$algorithm}->verify_manifest($self->payload_files, $return_all_errors);
        if ((defined $res) && ($res ne "1")) { push @errors, $res; }
    }
    #check for tagmanifests
    foreach my $algorithm ( keys %{ $self->manifests }) {
        my $res = $self->manifests->{$algorithm}->verify_tagmanifest($self->non_payload_files, $return_all_errors);
        if ((defined $res) && ($res ne "1")) { push @errors, $res; }
    }
    push @{$self->{errors}}, @errors;
    my $err = $self->errors();
    my @err =  @{ $err };
    if (scalar( @err ) > 0) {
        croak join("\n","bag verify for bagit version '$version' failed with invalid files.", @err);
    }
    return 1;
}


sub calc_payload_oxum {
    my($self) = @_;
    my @payload = @{$self->payload_files};
    my $octets=0;
    my $streamcount = scalar @payload;
    foreach my $local_name (@payload) {# local_name is relative to bagit base
        my $file = File::Spec->catfile($self->bag_path(), $local_name);
        if (-e $file) {
            my $filesize = 0;
            $filesize = -s $file or carp "empty file $file detected";
            $octets += $filesize;
        } else { croak "file $file does not exist, $!"; }
    }
    return ($octets, $streamcount);
}


sub calc_bagsize {
    my($self) = @_;
    my ($octets,$streamcount) = $self->calc_payload_oxum();
    if ($octets < 1024) { return "$octets B"; }
    elsif ($octets < 1024*1024) {return sprintf("%0.1f kB", $octets/1024); }
    elsif ($octets < 1024*1024*1024) {return sprintf "%0.1f MB", $octets/(1024*1024); }
    elsif ($octets < 1024*1024*1024*1024) {return sprintf "%0.1f GB", $octets/(1024*1024*1024); }
    else { return sprintf "%0.2f TB", $octets/(1024*1024*1024*1024); }
}


sub create_bagit {
    my($self) = @_;
    my $metadata_path = $self->metadata_path();
    my $bagit_path = File::Spec->catfile( $metadata_path, "bagit.txt");
    open(my $BAGIT, ">:encoding(UTF-8)", $bagit_path) or croak("Can't open $bagit_path for writing: $!");
    print($BAGIT "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8");
    close($BAGIT);
    return 1;
}


sub create_baginfo {
    my($self) = @_; # because bag-info.txt allows multiple key-value-entries, hash is replaced
    $self->add_or_replace_baginfo_by_key('Bagging-Date', POSIX::strftime("%Y-%m-%d", gmtime(time)));
    $self->add_or_replace_baginfo_by_key('Bag-Software-Agent', 'Archive::BagIt <https://metacpan.org/pod/Archive::BagIt>');
    my ($octets, $streams) = $self->calc_payload_oxum();
    $self->add_or_replace_baginfo_by_key('Payload-Oxum', "$octets.$streams");
    $self->add_or_replace_baginfo_by_key('Bag-Size', $self->calc_bagsize());
    # The RFC does not allow reordering:
    my $metadata_path = $self->metadata_path();
    my $bag_info_path = File::Spec->catfile( $metadata_path, "bag-info.txt");
    open(my $BAGINFO, ">:encoding(UTF-8)", $bag_info_path) or croak("Can't open $bag_info_path for writing: $!");
    foreach my $entry (@{ $self->bag_info() }) {
        my %tmp = %{ $entry };
        my ($key, $value) = %tmp;
        if ($key =~ m/:/) { carp "key should not contain a colon! (searchkey='$key')"; }
        print($BAGINFO "$key: $value\n");
    }
    close($BAGINFO);
    return 1;
}


sub store {
    my($self) = @_;
    $self->create_bagit();
    $self->create_baginfo();
    # it is important to create all manifest files first, because tagmanifest should include all manifest-xxx.txt
    foreach my $algorithm ( keys %{ $self->manifests }) {
        $self->manifests->{$algorithm}->create_manifest();
    }
    foreach my $algorithm ( keys %{ $self->manifests }) {
        $self->manifests->{$algorithm}->create_tagmanifest();
    }
    # retrigger builds
    $self->{checksum_algos} = $self->_build_checksum_algos();
    $self->{tagmanifest_files} = $self->_build_tagmanifest_files();
    $self->{manifest_files} = $self->_build_manifest_files();
    return 1;
}


sub init_metadata {
    my ($class, $bag_path, $options) = @_;
    $bag_path =~ s#/$##; # replace trailing slash
    unless ( -d $bag_path) { croak ( "source bag directory '$bag_path' doesn't exist"); }
    my $self = $class->new(bag_path=>$bag_path, %$options);
    carp "no payload path" if ! -d $self->payload_path;
    unless ( -d $self->payload_path) {
        rename ($bag_path, $bag_path.".tmp");
        mkdir  ($bag_path);
        rename ($bag_path.".tmp", $self->payload_path);
    }
    unless ( -d $self->metadata_path) {
        #metadata path is not the root path for some reason
        mkdir ($self->metadata_path);
    }
    $self->store();
    return $self;
}


sub make_bag {
    my ($class, $bag_path, $options) = @_;
    my $isa = ref $class;
    if ($isa eq "Archive::BagIt") { # not a class, but an object!
        croak "make_bag() only a class subroutine, not useable with objects. Try store() instead!\n";
    }
    my $self = $class->init_metadata($bag_path, $options);
    return $self;
}





__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt - The main module to handle bags.

=head1 VERSION

version 0.086

=head1 NAME

Achive::BagIt - The main module to handle Bags

=head1 SOURCE

The original development version was on github at L<http://github.com/rjeschmi/Archive-BagIt>
and may be cloned from there.

The actual development version is available at L<https://git.fsfe.org/art1pirat/Archive-BagIt>

=head1 Conformance to RFC8493

The module should fulfill the RFC requirements, with following limitations:

=over

=item only encoding UTF-8 is supported

=item version 0.97 or 1.0 allowed

=item version 0.97 requires tag-/manifest-files with md5-fixity

=item version 1.0 requires tag-/manifest-files with sha512-fixity

=item BOM is not supported

=item Carriage Return in bagit-files are not allowed

=item fetch.txt is unsupported

=back

At the moment only filepaths in linux-style are supported.

To get an more detailled overview, see the testsuite under F<t/verify_bag.t> and corresponding test bags from the BagIt conformance testsuite of Library of Congress under F<bagit_conformance_suite/>.

See L<https://datatracker.ietf.org/doc/rfc8493/?include_text=1> for details.

=head1 TODO

=over

=item enhanced testsuite

=item reduce complexity

=item use modern perl code

=item add flag to enable very strict verify

=back

=head1 FAQ

=head2 How to access the manifest-entries directly?

Try this:

   foreach my $algorithm ( keys %{ $self->manifests }) {
       my $entries_ref = $self->manifests->{$algorithm}->manifest_entries();
       # $entries_ref returns a hashref like:
       # {
       #     data/hello.txt   "e7c22b994c59d9cf2b48e549b1e24666636045930d3da7c1acb299d1c3b7f931f94aae41edda2c2b207a36e10f8bcb8d45223e54878f5b316e7ce3b6bc019629"
       # }
   }

Similar for tagmanifests

=head2 How fast is L<Archive::BagIt>?

I have made great efforts to optimize Archive::BagIt for high throughput. There are two limiting factors:

=over

=item calculation of checksums, by switching from the module "Digest" to OpenSSL by using L<Net::SSLeay> a significant
   speed increase could be achieved.

=item loading the files referenced in the manifest files was previously done serially and using synchronous I/O. By
   using the L<IO::Async> module, the files are loaded asynchronously and the checksums are calculated in parallel.
   If the underlying file system supports parallel accesses, the performance gain is huge.

=back

On my system with 8cores, SSD and a large 9GB bag with 568 payload files the results for C<verify_bag()> are:

                    processing time          run time             throughput
   Version       user time    system time    total time    total    MB/s
    v0.71        38.31s        1.60s         39.938s       100%     230
    v0.81        25.48s        1.68s         27.1s          67%     340
    v0.82        48.85s        3.89s          6.84s         17%    1346

=head2 How fast is L<Archive::BagIt::Fast>?

It depends. On my system with 8cores, SSD and a 38MB bag with 48 payload files the results for C<verify_bag()> are:

                  Rate         Base         Fast
   Base         3.01/s           --         -21%
   Fast         3.80/s          26%           --

On my system with 8cores, SSD and a large 9GB bag with 568 payload files the results for C<verify_bag()> are:

                s/iter         Base         Fast
   Base           74.6           --          -9%
   Fast           68.3           9%           --

But you should measure which variant is best for you. In general the default L<Archive::BagIt> is fast enough.

=head2 How to update an old bag of version v0.97 to v1.0?

You could try this:

   use Archive::BagIt;
   my $bag=Archive::BagIt->new( $my_old_bag_filepath );
   $bag->load();
   $bag->store();

=head2 How to create UTF-8 based paths under MS Windows?

For versions < Windows10: I have no idea and suggestions for a portable solution are very welcome!
For Windows 10: Thanks to L<https://superuser.com/questions/1033088/is-it-possible-to-set-locale-of-a-windows-application-to-utf-8/1451686#1451686>
you have to enable UTF-8 support via 'System Administration' -> 'Region' -> 'Administrative'
-> 'Region Settings' -> Flag 'Use Unicode UTF-8 for worldwide language support'

Hint: The better way is to use only portable filenames. See L<perlport> for details.

=head1 BUGS

There are problems related to Parallel::parallel_map and IO::AIO under MS Windows. The tests are skipped there. Use the
 parallel feature or the L<Archive::BagIt::Fast> at your own risks on a MS Window System.
 If you are a MS Windows developer, feel free to send me patches or hints to fix the issues.

=head1 THANKS

Thanks to Rob Schmidt <rjeschmi@gmail.com> for the trustful handover of the project and thanks for your initial work!
I would also like to thank Patrick Hochstenbach and Rusell McOrmond for their valuable and especially detailed advice!
And without the helpful, sometimes rude help of the IRC channel #perl I would have been stuck in a lot of problems.
Without the support of my colleagues at SLUB Dresden, the project would never have made it this far.

=head1 SYNOPSIS

This modules will hopefully help with the basic commands needed to create
and verify a bag. This part supports BagIt 1.0 according to RFC 8493 ([https://tools.ietf.org/html/rfc8493](https://tools.ietf.org/html/rfc8493)).

You only need to know the following methods first:

=head2 read a BagIt

    use Archive::BagIt;

    #read in an existing bag:
    my $bag_dir = "/path/to/bag";
    my $bag = Archive::BagIt->new($bag_dir);

=head2 construct a BagIt around a payload

    use Archive::BagIt;
    my $bag2 = Archive::BagIt->make_bag($bag_dir);

=head2 verify a BagIt-dir

    use Archive::BagIt;

    # Validate a BagIt archive against its manifest
    my $bag3 = Archive::BagIt->new($bag_dir);
    my $is_valid1 = $bag3->verify_bag();

    # Validate a BagIt archive against its manifest, report all errors
    my $bag4 = Archive::BagIt->new($bag_dir);
    my $is_valid2 = $bag4->verify_bag( {report_all_errors => 1} );

=head2 read a BagIt-dir, change something, store

Because all methods operate lazy, you should ensure to parse parts of the bag *BEFORE* you modify it.
Otherwise it will be overwritten!

    use Archive::BagIt;
    my $bag5 = Archive::BagIt->new($bag_dir); # lazy, nothing happened
    $bag5->load(); # this updates the object representation by parsing the given $bag_dir
    $bag5->store(); # this writes the bag new

=head1 METHODS

=head2 Constructor

The constructor sub, will create a bag with a single argument,

    use Archive::BagIt;

    #read in an existing bag:
    my $bag_dir = "/path/to/bag";
    my $bag = Archive::BagIt->new($bag_dir);

or use hashreferences

    use Archive::BagIt;

    #read in an existing bag:
    my $bag_dir = "/path/to/bag";
    my $bag = Archive::BagIt->new(
        bag_path => $bag_dir,
    );

The arguments are:

=over 1

=item C<bag_path> - path to bag-directory

=item C<force_utf8> - if set the warnings about non portable filenames are disabled (default: enabled)

=item C<use_async> - if set it uses IO::Async to read payload files asynchronly, only useful under Linux.

=item C<use_parallel> - if set it uses Parallel::parallel_map to calculate digests of payload files in parallel,
      only useful if underlying filesystem supports parallel read and if multiple CPU cores available.

=back

The bag object will use $bag_dir, BUT an existing $bag_dir is not read. If you use C<store()> an existing bag will be overwritten!

See C<load()> if you want to parse/modify an existing bag.

=head2 use_parallel()

if set it uses parallel digest processing, default: false

=head2 use_async()

if set it uses async IO, default: false

=head2 has_force_utf8()

to check if force_utf8() was set.

If set it ignores warnings about potential filepath problems.

=head2 bag_path([$new_value])

Getter/setter for bag path

=head2 metadata_path()

Getter for metadata path

=head2 payload_path()

Getter for payload path

=head2 checksum_algos()

Getter for registered Checksums

=head2 bag_version()

Getter for bag version

=head2 bag_encoding()

Getter for bag encoding.

HINT: the current version of Archive::BagIt only supports UTF-8, but the method could return other values depending on given Bags.

=head2 bag_info([$new_value])

Getter/Setter for bag info. Expects/returns an array of HashRefs implementing simple key-value pairs.

HINT: RFC8493 does not allow *reordering* of entries!

=head2 has_bag_info()

returns true if bag info exists.

=head2 errors()

Getter to return collected errors after a C<verify_bag()> call with Option C<report_all_errors>

=head2 warnings()

Getter to return collected warnings after a C<verify_bag()> call

=head2 digest_callback()

This method could be reimplemented by derived classes to handle fixity checks in own way. The
getter returns an anonymous function with following interface:

   my $digest = $self->digest_callback;
   &$digest( $digestobject, $filename);

This anonymous function MUST use the C<get_hash_string()> function of the L<Archive::BagIt::Role::Algorithm> role,
which is implemented by each L<Archive::BagIt::Plugin::Algorithm::XXXX> module.

See L<Archive::BagIt::Fast> for details.

=head2 get_baginfo_values_by_key($searchkey)

Returns all values which match $searchkey, undef otherwise

=head2 is_baginfo_key_reserved_as_uniq($searchkey)

returns true if key is reserved and should be uniq

=head2 is_baginfo_key_reserved( $searchkey )

returns true if key is reserved

=head2 verify_baginfo()

checks baginfo-keys, returns true if all fine, otherwise returns undef and the message is pushed to C<errors()>.
Warnings pushed to C< warnings() >

=head2 delete_baginfo_by_key( $searchkey )

deletes an entry of given $searchkey if exists.
If multiple entries with $searchkey exists, only the last one is deleted.

=head2 exists_baginfo_key( $searchkey )

returns true if a given $searchkey exists

=head2 append_baginfo_by_key($searchkey, $newvalue)

Appends a key value pair to bag_info.

HINT: check return code if append was successful, because some keys needs to be uniq.

=head2 add_or_replace_baginfo_by_key($searchkey, $newvalue)

It replaces the first entry with $newvalue if $searchkey exists, otherwise it appends.

=head2 forced_fixity_algorithm()

Getter to return the forced fixity algorithm depending on BagIt version

=head2 manifest_files()

Getter to find all manifest-files

=head2 tagmanifest_files()

Getter to find all tagmanifest-files

=head2 payload_files()

Getter to find all payload-files

=head2 non_payload_files()

Getter to find all non payload-files

=head2 plugins()

Getter/setter to algorithm plugins

=head2 manifests()

Getter/Setter to all manifests (objects)

=head2 algos()

Getter/Setter to all registered Algorithms

=head2 load_plugins

As default SHA512 and MD5 will be loaded and therefore used. If you want to create a bag only with one or a specific
checksum-algorithm, you could use this method to (re-)register it. It expects list of strings with namespace of type:
Archive::BagIt::Plugin::Algorithm::XXX where XXX is your chosen fixity algorithm.

=head2 load()

Triggers loading of an existing bag

=head2 verify_bag($opts)

A method to verify a bag deeply. If C<$opts> is set with C<{return_all_errors}> all fixity errors are reported.
The default ist to croak with error message if any error is detected.

HINT: You might also want to check Archive::BagIt::Fast to see a more direct way of accessing files (and thus faster).

=head2 calc_payload_oxum()

returns an array with octets and streamcount of payload-dir

=head2 calc_bagsize()

returns a string with human readable size of paylod

=head2 create_bagit()

creates a bagit.txt file

=head2 create_baginfo()

creates a bag-info.txt file

Hint: the entries 'Bagging-Date', 'Bag-Software-Agent', 'Payload-Oxum' and 'Bag-Size' will be automagically set,
existing values in internal bag-info representation will be overwritten!

=head2 store()

store a bagit-obj if bagit directory-structure was already constructed.

=head2 init_metadata()

A constructor that will just create the metadata directory

This won't make a bag, but it will create the conditions to do that eventually

=head2 make_bag( $bag_path )

A constructor that will make and return a bag from a directory,

It expects a preliminary bagit-dir exists.
If there a data directory exists, assume it is already a bag (no checking for invalid files in root)

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Andreas Romeyke <cpan@andreas.romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Rob Schmidt <rjeschmi@gmail.com>, William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
