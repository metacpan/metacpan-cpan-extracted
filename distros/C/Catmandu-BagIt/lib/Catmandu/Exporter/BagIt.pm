package Catmandu::Exporter::BagIt;

our $VERSION = '0.237';

=head1 NAME

Catmandu::Exporter::BagIt - Package that exports data as BagIts

=head1 SYNOPSIS

   use Catmandu::Exporter::BagIt;

   my $exporter = Catmandu::Exporter::BagIt->new(
                            overwrite     => 0 ,
                  );

   $exporter->add($bagit_record);

   $exporter->commit;

=head1 BagIt

The parsed BagIt record is a HASH containing the key '_id' containing the BagIt directory name
and one or more fields:

    {
          '_id' => 'bags/demo01',
          'version' => '0.97',                          # Not required, all bags will be 0.97
          'tags' => {
                      'Bagging-Date' => '2014-10-03',   # Not required, generated ...
                      'Bag-Software-Agent' => 'FooBar', # Not required, generated ...
                      'DC-Title'   => 'My downloads' ,
                      'DC-Creator' => 'Bunny, Bugs' ,
                    },
           },
           'fetch' => [
               { 'http://server/download1.pdf'  => 'data/my_download1.pdf' } ,
               { 'http://server2/download2.pdf' => 'data/my_download2.pdf' } ,
           ],
    };

All URL's in the fetch array will be mirrored and added to the bag. All payload files should
be put in the 'data' subdirectory as shown in the example above.

You can also add files from disk, using the "files" array:

    {
          '_id' => 'bags/demo01',
           'files' => [
               { '/tmp/download1.pdf'  => 'data/my_download1.pdf' } ,
               { '/tmp/download2.pdf' => 'data/my_download2.pdf' } ,
           ],
    };

=head1 METHODS

This module inherits all methods of L<Catmandu::Exporter>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Exporter> the exporter can
be configured with the following parameters:

=over

=item ignore_existing

Optional. Skip an item when the BagIt for it already exists.

=item overwrite

Optional. Throws an Catmandu::Error when the exporter tries to overwrite an existing directory.

=back

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Exporter>,
L<Archive::BagIt>

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use namespace::clean;
use Catmandu::Sane;
use Catmandu::BagIt;
use Path::Tiny;
use File::Spec;
use IO::File;
use LWP::Simple;
use Moo;

with 'Catmandu::Exporter';

has user_agent      => (is => 'ro');
has ignore_existing => (is => 'ro' , default => sub { 0 });
has overwrite       => (is => 'ro' , default => sub { 0 });

sub _mtime {
    my $file = $_[0];
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
    return $mtime;
}

sub add {
    my ($self, $data) = @_;
    my $directory = $data->{_id};
    $directory =~ s{\/$}{};

    return 1 if -d $directory && $self->ignore_existing;

    Catmandu::Error->throw("$directory exists") if -d $directory && ! $self->overwrite;

    my $bagit = defined($self->user_agent) ?
                    Catmandu::BagIt->new(user_agent => $self->user_agent) :
                    Catmandu::BagIt->new();

    if (exists $data->{tags}) {
        for my $tag (keys %{$data->{tags}}) {
            $bagit->add_info($tag,$data->{tags}->{$tag});
        }
    }

    if (exists $data->{fetch}) {
        for my $fetch (@{$data->{fetch}}) {
            my ($url) = keys %$fetch;
            my $file  = $fetch->{$url};

            my $data_dir = File::Spec->catfile($directory,'data');

            path($data_dir)->mkpath unless -d $data_dir;

            my $tmp = Path::Tiny->tempfile
                    or Catmandu::Error->throw("Could not create temp file");

            # For now using a simplistic mirror operation
            my $fname    = $tmp->stringify;
            my $response = $bagit->user_agent->mirror($url,$fname);

            unless ($response->is_success) {
                undef($tmp);
                Catmandu::Error->throw("failed to mirror $url to $fname : " . $response->status_line);
            }

            $file =~ s{^data/}{};
            $bagit->add_file($file,IO::File->new($fname));
            # close the bag to keep the number of open file handles to a minimum
            # only the files that are flagged 'dirty' will be written
            $bagit->write($directory, overwrite => 1);

            undef($tmp);
        }
    }
    if ( exists $data->{files} ) {

        for my $file ( @{ $data->{files} } ) {

            my($source)     = keys %$file;
            my $destination = $file->{$source};

            -f $source or Catmandu::Error->throw("source file $source does not exist");

            my $data_dir    = File::Spec->catfile( $directory, "data" );

            path($data_dir)->mkpath unless -d $data_dir;

            my $destination_path    = File::Spec->catfile( $directory, $destination );
            my $destination_entry   = $destination;
            $destination_entry      =~ s{^data/}{};

            #only add when destination is either older, or does not exist yet
            if (
                    (-f $destination_path && _mtime($source) > _mtime($destination_path)) ||
                    !(-f $destination_path)

            ) {

                $bagit->add_file($destination_entry, IO::File->new($source));
                $bagit->write($directory, overwrite => 1);

            }

        }

    }
    1;
}

sub commit { 1 }

1;
