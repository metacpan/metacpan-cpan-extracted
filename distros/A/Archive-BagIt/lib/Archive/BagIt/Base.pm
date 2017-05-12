use strict;
use warnings;

package Archive::BagIt::Base;

use File::Find;
use File::Spec;
use Digest::MD5;

use Data::Printer;

our $VERSION = '0.052'; # VERSION

use Sub::Quote;
use Moo;

my $DEBUG=0;


has 'bag_path' => (
    is => 'rw',
);

has 'bag_path_arr' => (
    is => 'lazy',
);

has 'metadata_path' => (
    is=> 'rw',
    default => sub { my ($self) = @_; return $self->bag_path; },
);

has 'metadata_path_arr' => (
    is =>'lazy',
);

has 'rel_metadata_path' => (
    is => 'lazy',
);

has 'payload_path' => (
    is => 'rw',
    default => sub { my ($self) = @_; return $self->bag_path."/data"; },
);

has 'payload_path_arr' => (
    is => 'lazy',
);

has 'rel_payload_path' => (
    is => 'lazy',
);

has 'checksum_algos' => (
    is => 'lazy',
);

has 'bag_version' => (
    is => 'lazy',
);

has 'bag_checksum' => (
    is => 'lazy',
);

has 'manifest_files' => (
    is => 'lazy',
);

has 'tagmanifest_files' => (
    is => 'lazy',
);

has 'manifest_entries' => (
    is => 'lazy',
);

has 'tagmanifest_entries' => (
    is => 'lazy',
);

has 'payload_files' => (
    is => 'lazy',
);

has 'non_payload_files' => (
    is=>'lazy',
);


around 'BUILDARGS' , sub {
    my $orig = shift;
    my $class = shift;
    if (@_ == 1 && !ref $_[0]) {
        return $class->$orig(bag_path=>$_[0]);
    }
    else {
        return $class->$orig(@_);
    }
};

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
    my $checksums = [ 'md5', 'sha1' ];
    return $checksums;
}

sub _build_bag_checksum {
  my($self) =@_;
  my $bagit = $self->{'bag_path'};
  open(my $SRCFILE, "<",  $bagit."/manifest-md5.txt");
  binmode($SRCFILE);
  my $srchex=Digest::MD5->new->addfile($SRCFILE)->hexdigest;
  close($SRCFILE);
  return $srchex;
}

sub _build_manifest_files {
  my($self) = @_;
  my @manifest_files;
  #p $self->checksum_algos;
  foreach my $algo (@{$self->checksum_algos}) {
    my $manifest_file = $self->metadata_path."/manifest-$algo.txt";
    if (-f $manifest_file) {
      push @manifest_files, $manifest_file;
    }
  }
  #print Dumper(@manifest_files);
  return \@manifest_files;
}

sub _build_tagmanifest_files {
  my ($self) = @_;
  my @tagmanifest_files;
  foreach my $algo (@{$self->checksum_algos}) {
    my $tagmanifest_file = $self->metadata_path."/tagmanifest-$algo.txt";
    if (-f $tagmanifest_file) {
      push @tagmanifest_files, $tagmanifest_file;
    }
  }
  return \@tagmanifest_files;

}

sub _build_tagmanifest_entries {
  my ($self) = @_;

  my @tagmanifests = @{$self->tagmanifest_files};
  my $tagmanifest_entries = {};
  foreach my $tagmanifest_file (@tagmanifests) {
    die("Cannot open $tagmanifest_file: $!") unless (open(my $TAGMANIFEST,"<", $tagmanifest_file));
    while (my $line = <$TAGMANIFEST>) {
      chomp($line);
      my($digest,$file) = split(/\s+/, $line, 2);
      $tagmanifest_entries->{$file} = $digest;
    }
    close($TAGMANIFEST);

  }
  return $tagmanifest_entries;
}

sub _build_manifest_entries {
  my ($self) = @_;

  my @manifests = @{$self->manifest_files};
  my $manifest_entries = {};
  foreach my $manifest_file (@manifests) {
    die("Cannot open $manifest_file: $!") unless (open (my $MANIFEST, "<", $manifest_file));
    while (my $line = <$MANIFEST>) {
        chomp($line);
        my ($digest,$file);
        ($digest, $file) = $line =~ /^([a-f0-9]+)\s+([a-zA-Z0-9_\.\/\-]+)/;
        if(!$file) {
          die ("This is not a valid manifest file");
        } else {
          print "file: $file \n" if $DEBUG;
          $manifest_entries->{$file} = $digest;
        }
    }
    close($MANIFEST);
  }

  return $manifest_entries;

}

sub _build_payload_files{
  my($self) = @_;

  my $payload_dir = $self->payload_path;

  my @payload=();
  File::Find::find( sub{
    if (-f $_) {
        my $rel_path=File::Spec->catdir($self->rel_payload_path,File::Spec->abs2rel($File::Find::name, $payload_dir));
        #print "pushing ".$rel_path." payload_dir: $payload_dir \n";
        push(@payload,$rel_path);
    }
    elsif($self->metadata_path_arr > $self->payload_path_arr && -d _ && $_ eq $self->rel_metadata_path) {
        #print "pruning ".$File::Find::name."\n";
        $File::Find::prune=1;
    }
    else {
        #payload directories
    }
    #print "name: ".$File::Find::name."\n";
  }, $payload_dir);

  #print p(@payload);

  return wantarray ? @payload : \@payload;

}

sub _build_bag_version {
    my($self) = @_;
    my $bagit = $self->metadata_path;
    my $file = join("/", $bagit, "bagit.txt");
    open(my $BAGIT, "<", $file) or die("Cannot read $file: $!");
    my $version_string = <$BAGIT>;
    my $encoding_string = <$BAGIT>;
    close($BAGIT);
    $version_string =~ /^BagIt-Version: ([0-9.]+)$/;
    return $1 || 0;
}

sub _build_non_payload_files {
  my($self) = @_;

  my @non_payload = ();

  File::Find::find( sub{
    if (-f $_) {
        my $rel_path=File::Spec->catdir($self->rel_metadata_path,File::Spec->abs2rel($File::Find::name, $self->metadata_path));
        #print "pushing ".$rel_path." payload_dir: $payload_dir \n";
        push(@non_payload,$rel_path);
    }
    elsif($self->metadata_path_arr < $self->payload_path_arr && -d _ && $_ eq $self->rel_payload_path) {
        #print "pruning ".$File::Find::name."\n";
        $File::Find::prune=1;
    }
    else {
        #payload directories
    }
    #print "name: ".$File::Find::name."\n";
  }, $self->metadata_path);

  return wantarray ? @non_payload : \@non_payload;

}


sub verify_bag {
    my ($self,$opts) = @_;
    #removed the ability to pass in a bag in the parameters, but might want options
    #like $return all errors rather than dying on first one
    my $bagit = $self->bag_path;
    my $manifest_file = $self->metadata_path."/manifest-md5.txt";
    my $payload_dir   = $self->payload_path;
    my $return_all_errors = $opts->{return_all_errors};
    my %invalids;
    my @payload       = @{$self->payload_files};

    die("$manifest_file is not a regular file") unless -f ($manifest_file);
    die("$payload_dir is not a directory") unless -d ($payload_dir);

    unless ($self->bag_version > .95) {
        die ("Bag Version is unsupported");
    }

    # Read the manifest file
    #print Dumper($self->{entries});
    my %manifest = %{$self->manifest_entries};

    # Evaluate each file against the manifest
    my $digestobj = new Digest::MD5;
    foreach my $local_name (@payload) {
        my ($digest);
        unless ($manifest{$local_name}) {
          die ("file found not in manifest: [$local_name]");
        }
        open(my $fh, "<", "$bagit/$local_name") or die ("Cannot open $local_name");
        $digest = $digestobj->addfile($fh)->hexdigest;
        #print $digest."\n";
        close($fh);
        unless ($digest eq $manifest{$local_name}) {
          if($return_all_errors) {
            $invalids{$local_name} = $digest;
          }
          else {
            die ("file: $local_name invalid");
          }
        }
        delete($manifest{$local_name});
    }
    if($return_all_errors && keys(%invalids) ) {
      foreach my $invalid (keys(%invalids)) {
        print "invalid: $invalid hash: ".$invalids{$invalid}."\n";
      }
      die ("bag verify failed with invalid files");
    }
    # Make sure there are no missing files
    if (keys(%manifest)) { die ("Missing files in bag".p(%manifest)); }

    return 1;
}


sub make_bag {
  my ($class, $bag_path) = @_;
  unless ( -d $bag_path) { die ( "source bag directory doesn't exist"); }
  my $self = $class->new(bag_path=>$bag_path);
  unless ( -d $self->payload_path) {
    rename ($bag_path, $bag_path.".tmp");
    mkdir  ($bag_path);
    rename ($bag_path.".tmp", $self->payload_path);
  }
  unless ( -d $self->metadata_path) {
    #metadata path is not the root path for some reason
    mkdir ($self->metadata_path);
  }
  $self->_write_bagit();
  $self->_write_baginfo();
  $self->_write_manifest_md5();
  $self->_write_tagmanifest_md5();
  return $self;
}

sub _write_bagit {
    my($self) = @_;
    open(my $BAGIT, ">", $self->metadata_path."/bagit.txt") or die("Can't open $self->metadata_path/bagit.txt for writing: $!");
    print($BAGIT "BagIt-Version: 0.97\nTag-File-Character-Encoding: UTF-8");
    close($BAGIT);
    return 1;
}

sub _write_baginfo {
    use POSIX;
    my($self, %param) = @_;
    open(my $BAGINFO, ">", $self->metadata_path."/bag-info.txt") or die("Can't open $self->metadata_path/bag-info.txt for writing: $!");
    $param{'Bagging-Date'} = POSIX::strftime("%F", gmtime(time));
    $param{'Bag-Software-Agent'} = 'Archive::BagIt <http://search.cpan.org/~rjeschmi/Archive-BagIt>';
    while(my($key, $value) = each(%param)) {
        print($BAGINFO "$key: $value\n");
    }
    close($BAGINFO);
    return 1;
}

sub _write_manifest_md5 {
    use Digest::MD5;
    my($self) = @_;
    my $manifest_file = $self->metadata_path."/manifest-md5.txt";
    # Generate MD5 digests for all of the files under ./data
    open(my $md5_fh, ">",$manifest_file) or die("Cannot create manifest-md5.txt: $!\n");
    foreach my $rel_payload_file (@{$self->payload_files}) {
        #print "rel_payload_file: ".$rel_payload_file;
        my $payload_file = File::Spec->catdir($self->bag_path, $rel_payload_file);
        open(my $DATA, "<", "$payload_file") or die("Cannot read $payload_file: $!");
        my $digest = Digest::MD5->new->addfile($DATA)->hexdigest;
        close($DATA);
        print($md5_fh "$digest  $rel_payload_file\n");
        #print "lineout: $digest $filename\n";
    }
    close($md5_fh);
}

sub _write_tagmanifest_md5 {
  my ($self) = @_;

  use Digest::MD5;

  my $tagmanifest_file= $self->metadata_path."/tagmanifest-md5.txt";

  open (my $md5_fh, ">", $tagmanifest_file) or die ("Cannot create tagmanifest-md5.txt: $! \n");

  foreach my $rel_nonpayload_file (@{$self->non_payload_files}) {
      my $nonpayload_file = File::Spec->catdir($self->bag_path, $rel_nonpayload_file);
      if ($rel_nonpayload_file=~m/tagmanifest-.*\.txt$/) {
        # Ignore, we can't take digest from ourselves
      }
      elsif ( -f $nonpayload_file && $nonpayload_file=~m/.*\.txt$/) {
        open(my $DATA, "<", "$nonpayload_file") or die("Cannot read $_: $!");
        my $digest = Digest::MD5->new->addfile($DATA)->hexdigest;
        close($DATA);
        print($md5_fh "$digest  $rel_nonpayload_file\n");
      }
      else {
        die("A file or directory that doesn't match: $rel_nonpayload_file");
      }
  }

  close($md5_fh);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Base

=head1 VERSION

version 0.052

=head1 NAME

Achive::BagIt::Base - The common base for both Bagit and dotBagIt

=head2 BUILDARGS

The constructor sub, will create a bag with a single argument

=head2 verify_bag

An interface to verify a bag.

You might also want to check Archive::BagIt::Fast to see a more direct way of accessing files (and thus faster).

=head2 make_bag
  A constructor that will make and return a bag from a direcory

  If a data directory exists, assume it is already a bag (no checking for invalid files in root)

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 SOURCE

The development version is on github at L<http://github.com/rjeschmi/Archive-BagIt>
and may be cloned from L<git://github.com/rjeschmi/Archive-BagIt.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/rjeschmi/Archive-BagIt/issues>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
