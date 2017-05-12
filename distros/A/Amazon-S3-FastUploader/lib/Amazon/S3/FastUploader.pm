package Amazon::S3::FastUploader;
use strict;
use warnings;
use File::Find;
use Amazon::S3;
use Amazon::S3::FastUploader::File;
use Parallel::ForkManager;
use base qw( Class::Accessor );
__PACKAGE__->mk_accessors( qw(config) );

our $VERSION = '0.08';

sub new {
    my $class = shift;
    my $config = shift;
    bless { config => $config }, $class;
}


sub upload {

    my $self = shift;
    my $local_dir = shift;
    my $bucket_name = shift;
    my $target_dir = shift;

    my $config = $self->config;

    my $process = $config->{process};
    my $s3 = Amazon::S3->new($config);

    my $bucket = $s3->bucket($bucket_name) or die 'cannot get bucket';

    $self->_print("local  dir : " . $local_dir . "\n");
    $self->_print("remote dir : " . $target_dir . "\n");
    $self->_print("max process: " . $process . "\n");
    $self->_print("use SSL: " . $config->{secure}. "\n");
    $self->_print("use encryption: " . $config->{encrypt}. "\n");

    my @local_files;

    my $callback = sub {
        return unless -f ;
        my $file = Amazon::S3::FastUploader::File->new({
            s3         => $s3,
            local_path => $File::Find::name,
            target_dir => $target_dir,
            bucket     => $bucket,
            config     => $config,
        });
        push @local_files , $file;
    };

    chdir $local_dir;
    find($callback, '.');

    if ($process > 1) {
        $self->_upload_parallel(\@local_files, $process);
    } else {
        $self->_upload_single(\@local_files);
    }
}

sub _upload_single {
    my $self = shift;
    my @files = @{ shift; };

    $self->_print("uploading by a single process\n");

    my $i = 0;
    my $total_num = @files;

    for my $file (@files) {
        $i++;

        $file->upload();
        $self->_print("ok    $i / $total_num " .  $file->from_to . "\n");

    }

    $self->_print(sprintf("%d files uploaded\n" , $i));
}

sub _upload_parallel {
    my $self = shift;
    my @files = @{ shift; };
    my $max = shift;

    $self->_print("uploading by multi processes\n");

    my $pm = new Parallel::ForkManager($max);
    $pm->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident) = @_;
            if ($exit_code != 0) {
                # on Windows 7, I saw sometimes error like below:
                #URI/_query.pm did not return a true value at C:/Perl/lib/URI/_generic.pm line 3.
                #
                #Compilation failed in require at C:/Perl/lib/URI/_server.pm line 2.
                #Compilation failed in require at C:/Perl/lib/URI/http.pm line 3.
                #Compilation failed in require at (eval 25) line 2.

                die("error (exit_code = $exit_code )");
            }
        });

    my $i = 0;
    my $total_num = @files;

    for my $file (@files) {
        $i++;

        $pm->start and next;
        $file->upload();
        $self->_print("ok    $i / $total_num " .  $file->from_to . "\n");

        $pm->finish;
        $i++;
    }

    $pm->wait_all_children;
    my $count = @files;
    $self->_print(sprintf("%d files uploaded\n" , $count));
}

sub _print {
    my $self = shift;
    return unless $self->config->{verbose};
    print @_;
}


=head1 NAME

Amazon::S3::FastUploader -  fast uploader to Amazon S3


=head1 SYNOPSIS

By this module, you can upload many files to Amazon S3 at the same time
 (in another word, in parallel) .
The module uses Parallel::ForkManager internally.


    use Amazon::S3::FastUploader;

    my $local_dir = '/path/to/dir/';
    my $bucket_name = 'myubcket';
    my $remote_dir '/path/to/dir/';
    my $uploader = Amazon::S3::FastUploader->new({
        aws_access_key_id => 'your_key_id',
        aws_secret_access_key => 'your_secre_key',
        process => 10, # num of proccesses in parallel
        secure  => 1,  # use SSL
        encrypt => 1,  # use ServerSide Encryption
        retry   => 5,
        verbose => 1,  # print log to stdout
        acl_short => 'public-read',  # private if ommited
    });

    $uploader->upload($local_dir, $bucket_name, $remote_dir);

=head1 METHODS

=head2 new

Instaniates a new object. 

Requires a hashref


=head2 upload $local_dir  $bucket_name  $remote_dir

upload recursively $local_dir to $remote_dir


=head1 AUTHOR

DQNEO, C<< <dqneoo at gmail.com> >>

=head1 Github Repository

https://github.com/DQNEO/Amazon-S3-FastUploader

Forks & Pull Requests are wellcome!

=head1 BUGS

Please report any bugs or feature requests to C<bug-amazon-s3-fastuploader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amazon-S3-FastUploader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Amazon::S3::FastUploader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Amazon-S3-FastUploader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Amazon-S3-FastUploader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Amazon-S3-FastUploader>

=item * Search CPAN

L<http://search.cpan.org/dist/Amazon-S3-FastUploader/>

=back

=head1 SEE ALSO

L<Amazon::S3>
L<Parallel::ForkManager>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 DQNEO.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Amazon::S3::FastUploader
