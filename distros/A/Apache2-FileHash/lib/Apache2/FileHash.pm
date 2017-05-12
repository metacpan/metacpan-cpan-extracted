package Apache2::FileHash;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Digest::MD5;
use Math::BigInt;
use File::Temp;
use File::Copy;
use YAML::Tiny;
use File::Basename;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw(DECLINED OK REDIRECT);

our $ConfigFile = "FileHash.yml";
our $Config;

sub hashing_function
{
    my ($r, $path) = @_;

    my $hex = &Digest::MD5::md5_hex($path);
    my $filename = "0x$hex";

    my (undef, undef, $suffix) = &File::Basename::fileparse($path, qr/\.(.*?)$/);

    $filename .= $suffix;

    return($filename);
}

sub file_exists
{
    my ($r, $headers) = @_;

    my $filename = &hashing_function($r, $headers);

    if (-e "/$$Config[0]{GLOBALS}{base_dir}/$filename") {
        return(Apache2::Const::DECLINED);
    }
    else {
        return(Apache2::Const::OK);
    }
}

sub netloc
{
    my ($r, $filename) = @_;

    my (undef, undef, $suffix) = &File::Basename::fileparse($filename, qr/\.(.*?)$/);

    my ($package) = (caller(0))[0];
    $package =~ s#^.*:##;

    my $orig_filename = $filename;
    $filename =~ s/$suffix$//;

    my $num = Math::BigInt->new($filename);
    my $num_buckets = scalar(@{ $Config->[0]{BUCKETS} });
    my $bucket_index = $num % $num_buckets;
    my $bucket = $Config->[0]{BUCKETS}[$bucket_index];

    my ($location, $name, $method, $port);

    $location = $Config->[0]{METHOD}{$package}{root_uri};
    $name = $bucket->{name};
    $method = $bucket->{method};
    $port = $bucket->{port};

    # warn("${method}://${name}:$port/$location/$orig_filename");
    return("${method}://${name}:$port/$location/$orig_filename");
}

sub getbucket
{
    my ($r, $filename) = @_;

    my (undef, undef, $suffix) = &File::Basename::fileparse($filename, qr/\.(.*?)$/);

    my $orig_filename = $filename;
    $filename =~ s/$suffix$//;

    my $num = Math::BigInt->new($filename);
    my $num_buckets = scalar(@{ $Config->[0]{BUCKETS} });
    my $bucket_index = $num % $num_buckets;
    my $bucket = $Config->[0]{BUCKETS}[$bucket_index];

    return($bucket);
}

sub inbucket
{
    my ($r, $path) = @_;

    my $uri = $r->uri();
    my $server_name = $r->get_server_name();
    my $port = $r->get_server_port();
    my $cur_netloc = "http://$server_name:$port/$uri"; # ugh.. hardcoded

    my $filename = &hashing_function($r, $path);
    # my $new_netloc = &netloc($r, $filename);

    my $bucket = &getbucket($r, $filename);

    my $location = $bucket->{location};
    my $name = $bucket->{name};
    my $method = $bucket->{method};
    $port = $bucket->{port};

    my $new_netloc = "${method}://${name}:$port/$uri";

    # warn(qq(return($cur_netloc eq $new_netloc)));
    return($cur_netloc eq $new_netloc);
}

sub save_file
{
    my ($r, $path) = @_;

    my $filename = &Apache2::FileHash::hashing_function($r, $path);
    
    my $yaml = YAML::Tiny->new;
    $yaml->[0] = { 
        path => $path,
        hashed => $filename,
    };
    $yaml->write( "/$$Config[0]{GLOBALS}{base_dir}/yaml/$filename.yml" );
    undef($yaml);

    my $tmpfh = File::Temp->new(UNLINK => 0);
    my $tmpname = $tmpfh->filename;

    my $buffer;
    my $len = 1024;
    while ($r->read($buffer, $len)) {
        last unless $len;
        print($tmpfh $buffer);
    }

    undef($tmpfh);

    &File::Copy::move($tmpname, "/$$Config[0]{GLOBALS}{base_dir}/$filename") or return(Apache2::Const::DECLINED);

    return(Apache2::Const::OK);
}

=head1 NAME

Apache2::FileHash - Methods to store and retrieve files using a hashing methodology.

=head1 SYNOPSIS

  use Apache2::FileHash;

  <VirtualHost *:80>
      <Location /storeFile>
          PerlHeaderParserHandler Apache2::FileHash::PUT
          <Limit PUT> 
              order deny,allow
              deny from all 
              allow from 192.168.5.5
          </Limit> 
      </Location>
   
      <Location /getFile>
          PerlHeaderParserHandler Apache2::FileHash::GET
      </Location>
  </VirtualHost>

  <VirtualHost *:8080>
      <Location /storeFile>
          PerlHeaderParserHandler Apache2::FileHash::PUT
          <Limit PUT> 
              order deny,allow
              deny from all 
              allow from 192.168.5.5
          </Limit> 
      </Location>

      <Location /getFile>
          PerlHeaderParserHandler Apache2::FileHash::GET
      </Location>
  </VirtualHost>

   *** startup.pl ***
    #!/opt/perl

    use strict;
    use warnings;

    use lib qw(/opt/mod_perl);
    use lib qw(/opt/mod_perl/lib);
    use lib qw(/opt/Apache2);
    use lib qw(/opt/Apache2/FileHash);

    use Apache2::FileHash;
    use Apache2::FileHash::PUT;
    use Apache2::FileHash::GET;

    use MIME::Types;

    my @array = ();
    foreach my $dir (@INC) {
        my $file = "$dir/$Apache2::FileHash::ConfigFile";
        eval {
            @array = &YAML::Tiny::LoadFile($file) or die("LoadFile($YAML::Tiny::errstr)");
        };
        unless ($@) {
            last;
        }
    }

    $Apache2::FileHash::Config = \@array;

    BEGIN { MIME::Types->new() };

    1;
    *** startup.pl ***

    *** FileHash.yml **
    ---
    GLOBALS:
      base_dir: '/tmp'
    BUCKETS:
      -
        method: http
        name: localhost
        port: 80
      -
        method: http
        name: localhost
        port: 8080
    METHOD:
      GET:
        root_uri: '/getFile'
      PUT:
        root_uri: '/storeFile'
    *** FileHash.yml ***

=head1 DESCRIPTION

This is an attempt at solving a problem with hosting millions
of static files.  It should be straight forward enough to take
a suite of n servers and store x files across them.

It is assumed that each bucket is publically accessible and that
the disks may or may not be.  It is non-trivial to add a bucket
later.

=head1 SEE ALSO

Apaceh2:::RequestRec

=head1 AUTHOR

Brian Medley, E<lt>freesoftware@bmedley.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Brian Medley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
