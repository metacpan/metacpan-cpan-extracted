package Catalyst::Controller::SimpleCAS::Store::File;

use warnings;
use Moose;

with qw(
  Catalyst::Controller::SimpleCAS::Store
);

use Data::Dumper;
use IO::File;
use Try::Tiny;
use File::Spec::Functions 'catdir', 'catfile';
use Path::Class qw( file dir );
use IO::All;
use File::Copy 'move';

has 'store_dir' => ( is => 'ro', isa => 'Str', required => 1 );

sub init_store_dir {
  my $self = shift;
  return if (-d $self->store_dir);
  mkdir $self->store_dir or die "Failed to create directory: " . $self->store_dir;
}

sub add_content {
  my $self = shift;
  my $data = shift;
  
  $self->init_store_dir;
  
  my $checksum = $self->calculate_checksum($data);
  return $checksum if ($self->content_exists($checksum));
  
  my $save_path = $self->checksum_to_path($checksum,1);
  my $fd= IO::File->new($save_path, '>:raw') or die $!;
  $fd->write($data);
  $fd->close;
  return $checksum;
}

sub add_content_file {
  my $self = shift;
  my $file = shift;
  
  $self->init_store_dir;
  
  my $checksum = $self->file_checksum($file);
  return $checksum if ($self->content_exists($checksum));
  
  my $save_path = $self->checksum_to_path($checksum,1);
  
  try {
    # This is cleaner, but will fail for various reasons like source/dest 
    # on different file systems:
    link $file, $save_path or die "Failed to create hard link: '$file' -> '$save_path'";
  }
  catch {
    move($file, $save_path)
      or die "SimpleCAS: Failed to move file '$file' -> '$save_path': $!";
  };
  
  return $checksum;
}

sub split_checksum {
  my $self = shift;
  my $checksum = shift;

  return ( substr($checksum,0,2), substr($checksum,2) );
}

sub add_content_file_mv {
  my $self = shift;
  my $file = shift;
  
  $self->init_store_dir;
  
  my $checksum = $self->file_checksum($file);
  if ($self->content_exists($checksum)) {
    unlink $file;
    return $checksum;
  }
  
  my $save_path = $self->checksum_to_path($checksum,1);
  move($file, $save_path)
    or die "SimpleCAS: Failed to move file '$file' -> '$save_path'";
  
  return $checksum;
}

sub checksum_to_path {
  my $self = shift;
  my $checksum = shift;
  my $init = shift;
  
  $self->init_store_dir;
  
  my ($d, $f) = $self->split_checksum($checksum);
  
  my $dir = catdir($self->store_dir, $d);
  if($init and not -d $dir) {
    mkdir $dir or die "Failed to create directory: " . $dir;
  }
  
  return catfile( $dir, $f );
}

sub fetch_content {
  my $self = shift;
  my $checksum = shift;
  
  my $file = $self->checksum_to_path($checksum);
  return undef unless ( -f $file);
  
  return io($file)->binary->slurp;
}

sub content_exists {
  my $self = shift;
  my $checksum = shift;
  
  return 1 if ( -f $self->checksum_to_path($checksum) );
  return 0;
}

#### --------------------- ####

no Moose;
#__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Catalyst::Controller::SimpleCAS::Store::File - Standard file-based Store for SimpleCAS

=head1 SYNOPSIS

 use Catalyst::Controller::SimpleCAS;
 ...

=head1 DESCRIPTION

This is the main "Store" object class used by L<Catalyst::Controller::SimpleCAS> for 
persisting/storing arbitrary pieces of content on disk according to their CAS (content-addressed
storage) name/address, in this case, standard 40 character SHA1 hex strings (160-bit). This is
the same thing that Git does, which was the original inspiration for the SimpleCAS module.

Currently, this is the only Store class, but others could be implemented and the system was
designed with this in mind (i.e. a DBIC-based store). Also, the implementation need not use the 
40-char sha1 addresses - any content/checksum system for IDs could be implemented.

Also note that an actual Git-based store was partially written, but never finished. See the branch
named C<partial_git_store> in the GitHub repository for more info.

This class is used internally and should not need to be called directly.

=head1 ATTRIBUTES

=head2 store_dir

Where to store the data. This is the only required option and is a pass-through from the option
of the same name in L<Catalyst::Controller::SimpleCAS>.

=head1 METHODS

=head2 add_content

=head2 add_content_base64

=head2 add_content_file

=head2 add_content_file_mv

=head2 calculate_checksum

=head2 checksum_to_path

=head2 content_exists

=head2 content_mimetype

=head2 content_size

=head2 fetch_content

=head2 fetch_content_fh

=head2 file_checksum

=head2 image_size

=head2 init_store_dir

=head2 split_checksum

=head1 SEE ALSO

=over

=item *

L<Catalyst::Controller::SimpleCAS>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut