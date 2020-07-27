package Archive::BagIt;
our $VERSION = '0.059'; # VERSION
use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
our @checksum_algos = qw(md5 sha1);
our $DEBUG=0;
use Encode qw(decode);
use File::Find;
use Data::Dumper;
#use Data::Printer;

sub new {
  my ($class,$bag_path) = @_;
  my $self = {};
  bless $self, $class;
  $bag_path=~s!/$!!;
  $self->{'bag_path'} = $bag_path || "";
  if($bag_path) {
    $self->_open();
  }
  return $self;
}

sub _open {
  my($self) = @_;

  $self->_load_manifests();
  $self->_load_tagmanifests();

  return $self;
}

sub _load_manifests {
  my ($self) = @_;

  my @manifests = $self->manifest_files();
  foreach my $manifest_file (@manifests) {
    die("Cannot open $manifest_file: $!") unless (open (my $MANIFEST,"<:encoding(utf8)", $manifest_file));
    while (my $line = <$MANIFEST>) {
        chomp($line);
        my ($digest,$file);
        ($digest, $file) = $line =~ /^([a-f0-9]+)\s+(.+)$/;
        if(!$file) {
          die ("This is not a valid manifest file");
        } else {
          print "file: $file \n" if $DEBUG;
          $self->{entries}->{$file} = $digest;
        }
    }
    close($MANIFEST);
  }

  return $self;

}

sub _load_tagmanifests {
  my ($self) = @_;

  my @tagmanifests = $self->tagmanifest_files();
  foreach my $tagmanifest_file (@tagmanifests) {
    die("Cannot open $tagmanifest_file: $!") unless (open(my $TAGMANIFEST,"<:encoding(utf8)", $tagmanifest_file));
    while (my $line = <$TAGMANIFEST>) {
      chomp($line);
      my($digest,$file) = split(/\s+/, $line, 2);
      $self->{tagentries}->{$file} = $digest;
    }
    close($TAGMANIFEST);

  }
  return $self;
}


sub make_bag {
  my ($class, $bag_dir) = @_;
  unless ( -d $bag_dir) { die ( "source bag directory doesn't exist"); }
  unless ( -d $bag_dir."/data") {
    rename ($bag_dir, $bag_dir.".tmp");
    mkdir  ($bag_dir);
    rename ($bag_dir.".tmp", $bag_dir."/data");
  }
  my $self=$class->new($bag_dir);
  $self->_write_bagit($bag_dir);
  $self->_write_baginfo($bag_dir);
  $self->_manifest_md5($bag_dir);
  $self->_tagmanifest_md5($bag_dir);
  $self->_open();
  return $self;
}

sub _write_bagit {
    my($self, $bagit) = @_;
    open(my $BAGIT, ">", $bagit."/bagit.txt") or die("Can't open $bagit/bagit.txt for writing: $!");
    print($BAGIT "BagIt-Version: 0.97\nTag-File-Character-Encoding: UTF-8");
    close($BAGIT);
    return 1;
}



sub _write_baginfo {
    use POSIX;
    my($self, $bagit, %param) = @_;
    open(my $BAGINFO, ">", $bagit."/bag-info.txt") or die("Can't open $bagit/bag-info.txt for writing: $!");
    $param{'Bagging-Date'} = POSIX::strftime("%F", gmtime(time));
    $param{'Bag-Software-Agent'} = 'Archive::BagIt <http://search.cpan.org/~rjeschmi/Archive-BagIt>';
    while(my($key, $value) = each(%param)) {
        print($BAGINFO "$key: $value\n");
    }
    close($BAGINFO);
    return 1;
}

sub _manifest_crc32 {
    require String::CRC32;
    my($self,$bagit) = @_;
    my $manifest_file = "$bagit/manifest-crc32.txt";
    my $data_dir = "$bagit/data";

    # Generate MD5 digests for all of the files under ./data
    open(my $fh, ">:encoding(utf8)",$manifest_file) or die("Cannot create manifest-crc32.txt: $!\n");
    find(
        sub {
            $_=decode('utf8', $_);
            my $file = decode('utf8', $File::Find::name);
            if (-f $_) {
                open(my $DATA, "<:encoding(utf8)", $_) or die("Cannot read $_: $!");
                my $digest = sprintf("%010d",crc32($DATA));
                close($DATA);
                my $filename = substr($file, length($bagit) + 1);
                print($fh "$digest  $filename\n");
            }
        },
        $data_dir
    );
    close($fh);
    return;
}


sub _manifest_md5 {
    use Digest::MD5;
    my($self, $bagit) = @_;
    my $manifest_file = "$bagit/manifest-md5.txt";
    my $data_dir = "$bagit/data";
    #print "creating manifest: $data_dir\n";
    # Generate MD5 digests for all of the files under ./data
    open(my $md5_fh, ">:encoding(utf8)",$manifest_file) or die("Cannot create manifest-md5.txt: $!\n");
    find(
        sub {
            my $file = decode('utf8', $File::Find::name);
            if (-f $_) {
                open(my $DATA, "<:raw", "$_") or die("Cannot read $_: $!");
                my $digest = Digest::MD5->new->addfile($DATA)->hexdigest;
                close($DATA);
                my $filename = substr($file, length($bagit) + 1);
                print($md5_fh "$digest  $filename\n");
                #print "lineout: $digest $filename\n";
            }
        },
        $data_dir
    );
    close($md5_fh);
    return;
}

sub _tagmanifest_md5 {
  my ($self, $bagit) = @_;

  use Digest::MD5;

  my $tagmanifest_file= "$bagit/tagmanifest-md5.txt";

  open (my $md5_fh, ">:encoding(utf8)", $tagmanifest_file) or die ("Cannot create tagmanifest-md5.txt: $! \n");

  find (
    sub {
      $_ = decode('utf8',$_);
      my $file = decode('utf8',$File::Find::name);
      if ($_=~m/^data$/) {
        $File::Find::prune=1;
      }
      elsif ($_=~m/^tagmanifest-.*\.txt/) {
        # Ignore, we can't take digest from ourselves
      }
      elsif ( -f $_ ) {
        open(my $DATA, "<:raw", "$_") or die("Cannot read $_: $!");
        my $digest = Digest::MD5->new->addfile($DATA)->hexdigest;
        close($DATA);
        my $filename = substr($file, length($bagit) + 1);
        print($md5_fh "$digest  $filename\n");
      }
  }, $bagit);

  close($md5_fh);
  return;
}


sub verify_bag {
    my ($self,$opts) = @_;
    #removed the ability to pass in a bag in the parameters, but might want options
    #like $return all errors rather than dying on first one
    my $bagit = $self->{'bag_path'};
    my $manifest_file = "$bagit/manifest-md5.txt";
    my $payload_dir   = "$bagit/data";
    my %manifest      = ();
    my $return_all_errors = $opts->{return_all_errors};
    my %invalids;
    my @payload       = ();

    die("$manifest_file is not a regular file") unless -f ($manifest_file);
    die("$payload_dir is not a directory") unless -d ($payload_dir);

    unless ($self->version() > .95) {
        die ("Bag Version is unsupported");
    }

    # Read the manifest file
    #print Dumper($self->{entries});
    foreach my $entry (keys(%{$self->{entries}})) {
      $manifest{$entry} = $self->{entries}->{$entry};
    }

    # Compile a list of payload files
    find(sub{ push(@payload, decode('utf8',$File::Find::name))  }, $payload_dir);

    # Evaluate each file against the manifest
    my $digestobj = Digest::MD5->new();
    foreach my $file (@payload) {
        next if (-d ($file));
        my $local_name = substr($file, length($bagit) + 1);
        my ($digest);
        #p %manifest;
        unless ($manifest{$local_name}) {
          die ("file found not in manifest: [$local_name]");
        }
        #my $start_time=time();
        open(my $fh, "<:raw", "$bagit/$local_name") or die ("Cannot open $local_name");
        $digest = $digestobj->addfile($fh)->hexdigest;
        close($fh);
        #print "$bagit/$local_name md5 in ".(time()-$start_time)."\n";
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
    if (keys(%manifest)) { die ("Missing files in bag"); }

    return 1;
}


sub get_checksum {
  my($self) =@_;
  my $bagit = $self->{'bag_path'};
  open(my $SRCFILE, "<:raw",  $bagit."/manifest-md5.txt");
  my $srchex=Digest::MD5->new->addfile($SRCFILE)->hexdigest;
  close($SRCFILE);
  return $srchex;
}


sub version {
    my($self) = @_;
    my $bagit = $self->{'bag_path'};
    my $file = join("/", $bagit, "bagit.txt");
    open(my $BAGIT, "<", $file) or die("Cannot read $file: $!");
    my $version_string = <$BAGIT>;
    my $encoding_string = <$BAGIT>;
    close($BAGIT);
    $version_string =~ /^BagIt-Version: ([0-9.]+)$/;
    return $1 || 0;
}


sub payload_files {
  my($self) = @_;
  my @payload = $self->_payload_files();
  return @payload;
}

sub _payload_files{
  my($self) = @_;

  my $payload_dir = join( "/", $self->{"bag_path"}, "data");

  my @payload=();
  File::Find::find( sub{

    push(@payload,decode('utf8',$File::Find::name));
    #print "name: ".$File::Find::name."\n";
  }, $payload_dir);

  return @payload;

}


sub non_payload_files{
  my ($self) = @_;
  my @non_payload = $self->_non_payload_files();
  return @non_payload;

}


sub _non_payload_files {
  my($self) = @_;

  my @payload = ();
  File::Find::find( sub {
    $File::Find::name = decode ('utf8', $File::Find::name);
    if(-f $File::Find::name) {
      my ($relpath) = ($File::Find::name=~m!$self->{"bag_path"}/(.*$)!);
      push(@payload, $relpath);
    }
    elsif(-d _ && $_ eq "data") {
      $File::Find::prune=1;
    }
    else {
      #directories in the root other than data?
    }
  }, $self->{"bag_path"});

  return @payload;

}



sub manifest_files {
  my($self) = @_;
  my @manifest_files;
  foreach my $algo (@checksum_algos) {
    my $manifest_file = $self->{"bag_path"}."/manifest-$algo.txt";
    if (-f $manifest_file) {
      push @manifest_files, $manifest_file;
    }
  }
  #print Dumper(@manifest_files);
  return @manifest_files;
}


sub tagmanifest_files {
  my ($self) = @_;
  my @tagmanifest_files;
  foreach my $algo (@checksum_algos) {
    my $tagmanifest_file = $self->{"bag_path"}."/tagmanifest-$algo.txt";
    if (-f $tagmanifest_file) {
      push @tagmanifest_files, $tagmanifest_file;
    }
  }
  return @tagmanifest_files;

}


1; # End of Archive::BagIt

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt

=head1 VERSION

version 0.059

=head1 SYNOPSIS

This modules will hopefully help with the basic commands needed to create
and verify a bag. My intention is not to be strict and enforce all of the
specification. The reference implementation is the java version
and I will endeavour to maintain compatibility with it.

    use Archive::BagIt;

    #read in an existing bag:
    my $bag_dir = "/path/to/bag";
    my $bag = Archive::BagIt->new($bag_dir);


    #construct bag in an existing directory
    my $bag2 = Archive::BagIt->make_bag($bag_dir);

    # Validate a BagIt archive against its manifest
    my $bag3 = Archive::BagIt->new($bag_dir);
    my $is_valid = $bag3->verify_bag();

=head1 NAME

Archive::BagIt

=head1 VERSION

version 0.059

=head1 WARNING

This is experimental software for the moment and under active development.

Under the hood, the module Archive::BagIt::Base was adapted and extended to
support BagIt 1.0 according to RFC 8493 ([https://tools.ietf.org/html/rfc8493](https://tools.ietf.org/html/rfc8493)).

Also: Check out Archive::BagIt::Fast if you are willing to add some extra dependencies to get
better speed by mmap-ing files.

=head1 NAME

Archive::BagIt - An interface to make and verify bags according to the BagIt standard

=head1 SUBROUTINES

=head2 new

An Object Oriented Interface to a bag. Opens an existing bag.

  my $bag = Archive::BagIt->new('/path/to/bag');

=head2 make_bag

A constructor that will make and return a bag from a directory

If a data directory exists, assume it is already a bag (no checking for invalid files in root)

=head2 verify_bag

An interface to verify a bag.

You might also want to check L<Archive::BagIt::Fast> to see a more direct way of
accessing files (and thus faster).

=head2 get_checksum

This is the checksum for the bag, md5 of the manifest-md5.txt

=head2 version

Returns the bagit version according to the bagit.txt file.

=head2 payload_files

Returns an array with all of the payload files (those files that are below the data directory)

=head2 non_payload_files

Returns an array with files that are in the root of the bag, non-manifest files

=head2 manifest_files

Return an array with the list of manifest files that exist in the bag

=head2 tagmanifest_files

Return an array with the list of tagmanifest files

=head1 AUTHORS

=over

=item Robert Schmidt, E<lt>rjeschmi at gmail.comE<gt>

=item William Wueppelmann, E<lt>william at c7a.caE<gt>

=item Andreas Romeyke, E<lt>pause at andreas minus romeyke.deE<gt>

=back

=head1 CONTRIBUTORS

=over

=item Serhiy Bolkun

=item Russell McOrmond

=back

=head1 SOURCE

The original development version is on github at L<http://github.com/rjeschmi/Archive-BagIt>
and may be cloned from there.

The actual development version is available at L<https://art1pirat.spdns.org/art1/Archive-BagIt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-archive-bagit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-BagIt>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::BagIt

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Archive-BagIt>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Archive-BagIt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Archive-BagIt>

=item * Search CPAN

L<http://search.cpan.org/dist/Archive-BagIt/>

=back

=head1 COPYRIGHT

Copyright (c) 2012, the above named author(s).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 SOURCE

The development version is on github at L<https://github.com/Archive-BagIt>
and may be cloned from L<git://github.com/Archive-BagIt.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
