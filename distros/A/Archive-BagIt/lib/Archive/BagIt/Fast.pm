package Archive::BagIt::Fast;

use strict;
use warnings;
use parent "Archive::BagIt";

our $VERSION = '0.058'; # VERSION

use IO::AIO;
use Time::HiRes qw(time);



sub verify_bag {
    my ($self,$opts) = @_;
    use IO::AIO;
    #removed the ability to pass in a bag in the parameters, but might want options
    #like $return all errors rather than dying on first one
    my $bagit = $self->{'bag_path'};
    my $manifest_file = "$bagit/manifest-md5.txt";
    my $payload_dir   = "$bagit/data";
    my %manifest      = ();
    my $return_all_errors = $opts->{return_all_errors};
    my $MMAP_MIN = $opts->{mmap_min} || 8000000;
    my %invalids;
    my @payload       = ();
    die("$manifest_file is not a regular file") unless -f ($manifest_file);
    die("$payload_dir is not a directory") unless -d ($payload_dir);
    # Read the manifest file
    #print Dumper($self->{entries});
    foreach my $entry (keys %{$self->{entries}}) {
      $manifest{$entry} = $self->{entries}->{$entry};
    }
    # Compile a list of payload files
    File::Find::find(sub{ push(@payload, $File::Find::name)  }, $payload_dir);
    # Evaluate each file against the manifest
    my $digestobj = new Digest::MD5; # FIXME: use plugins instead
    foreach my $file (@payload) {
        next if (-d ($file));
        my $local_name = substr($file, length($bagit) + 1);
        my ($digest);
        unless ($manifest{$local_name}) {
          die ("file found not in manifest: [$local_name]");
        }

        open(my $fh, "<:raw", "$bagit/$local_name") or die ("Cannot open $local_name");
        stat $fh;
        $self->{stats}->{files}->{"$bagit/$local_name"}->{size}= -s _;
        $self->{stats}->{size} += -s _;
        my $start_time = time();
        if (-s _ < $MMAP_MIN ) {
          sysread $fh, my $data, -s _;
          $digest = $digestobj->add($data)->hexdigest;
        }
        elsif ( -s _ < 1500000000) {
          IO::AIO::mmap my $data, -s _, IO::AIO::PROT_READ, IO::AIO::MAP_SHARED, $fh or die "mmap: $!";
          $digest = $digestobj->add($data)->hexdigest;
        }
        else {
          $digest = $digestobj->addfile($fh)->hexdigest; # FIXME: use plugins instead
        }
        my $finish_time = time();
        $self->{stats}->{files}->{"$bagit/$local_name"}->{verify_time}= ($finish_time - $start_time);
        $self->{stats}->{verify_time} += ($finish_time-$start_time);
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
    if (keys(%manifest)) { die ("Missing files in bag"); }

    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Fast

=head1 VERSION

version 0.058

=head1 NAME

Archive::BagIt::Fast

=head1 VERSION

version 0.058

=head1 NAME

Archive::BagIt::Fast - For people who are willing to rely on some other modules in order to get better performance

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
