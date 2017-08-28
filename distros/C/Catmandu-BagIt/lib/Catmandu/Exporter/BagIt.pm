package Catmandu::Exporter::BagIt;

=head1 NAME

Catmandu::Exporter::BagIt - Package that exports data as BagIts

=head1 SYNOPSIS

   use Catmandu::Exporter::BagIt;

   my $exporter = Catmandu::Exporter::BagIt->new(
                            overwrite     => 0 ,
                            skip_manifest => 0,
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

=item skip_manifest

Optional. Skips the re-calculation of MD5 manifest checksums in case BagIt directories get overwritten. Use this
option for instance when overwriting only the tags of a bag.

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

our $VERSION = '0.151';

with 'Catmandu::Exporter';

has user_agent      => (is => 'ro');
has ignore_existing => (is => 'ro' , default => sub { 0 });
has overwrite       => (is => 'ro' , default => sub { 0 });
has skip_manifest   => (is => 'ro' , default => sub { 0 });

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
            $bagit->write($directory, overwrite => 1);

            undef($tmp);
        }
    }

    1;
}

sub commit { 1 }

1;
