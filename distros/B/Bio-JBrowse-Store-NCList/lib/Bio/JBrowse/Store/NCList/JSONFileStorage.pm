
package Bio::JBrowse::Store::NCList::JSONFileStorage;
BEGIN {
  $Bio::JBrowse::Store::NCList::JSONFileStorage::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::JBrowse::Store::NCList::JSONFileStorage::VERSION = '0.1';
}

use strict;
use warnings;
use File::Spec ();
use File::Path ();
use JSON 2 ();
use IO::File;
use Fcntl ":flock";
use PerlIO::gzip;

use constant DEFAULT_MAX_JSON_DEPTH => 2048;


sub new {
    my ($class, $outDir, $compress, $opts) = @_;

    # create JSON object
    my $json = JSON->new->relaxed->max_depth( DEFAULT_MAX_JSON_DEPTH );
    # set opts
    if (defined($opts) and ref($opts) eq 'HASH') {
        for my $method (keys %$opts) {
            $json->$method( $opts->{$method} );
        }
    }

    my $self = {
                outDir => $outDir,
                ext => $compress ? ".jsonz" : ".json",
                compress => $compress,
                json => $json
               };
    bless $self, $class;

    File::Path::mkpath( $outDir ) unless (-d $outDir);

    return $self;
}

sub _write_htaccess {
    my ( $self ) = @_;

    if( $self->{compress} && ! $self->{htaccess_written} ) {
        my $hn = File::Spec->catfile( $self->{outDir}, '.htaccess' );
        return if -e $hn;

        open my $h, '>', $hn or die "$! writing $hn";

        my @extensions = qw( .jsonz .txtz .txt.gz );
        my $re = '('.join('|',@extensions).')$';
        $re =~ s/\./\\./g;

        print $h <<EOA;
# This Apache .htaccess file is for
# serving precompressed files (@extensions) with the proper
# Content-Encoding HTTP headers.  In order for Apache to pay attention
# to this, its AllowOverride configuration directive for this
# filesystem location must allow FileInfo overrides.
<IfModule mod_gzip.c>
    mod_gzip_item_exclude "$re"
</IfModule>
<IfModule setenvif.c>
    SetEnvIf Request_URI "$re" no-gzip dont-vary
</IfModule>
<IfModule mod_headers.c>
  <FilesMatch "$re">
    Header onsuccess set Content-Encoding gzip
  </FilesMatch>
</IfModule>
EOA
        $self->{htaccess_written} = 1;
    }
}


sub fullPath {
    my ($self, $path) = @_;
    return File::Spec->join($self->{outDir}, $path);
}


sub ext {
    return shift->{ext};
}


sub encodedSize {
    my ($self, $obj) = @_;
    return length($self->{json}->encode($obj));
}


sub put {
    my ($self, $path, $toWrite) = @_;

    $self->_write_htaccess;

    my $file = $self->fullPath($path);
    my $fh = IO::File->new( $file, O_WRONLY | O_CREAT )
      or die "couldn't open $file: $!";
    flock $fh, LOCK_EX;
    $fh->seek(0, SEEK_SET);
    $fh->truncate(0);
    if ($self->{compress}) {
        binmode($fh, ":gzip")
            or die "couldn't set binmode: $!";
    }
    $fh->print($self->{json}->encode($toWrite))
      or die "couldn't write to $file: $!";
    $fh->close()
      or die "couldn't close $file: $!";
}


sub get {
    my ($self, $path, $default) = @_;

    my $file = $self->fullPath($path);
    if (-s $file) {
        my $OLDSEP = $/;
        my $fh = IO::File->new( $file, O_RDONLY )
            or die "couldn't open $file: $!";
        binmode($fh, ":gzip") if $self->{compress};
        flock $fh, LOCK_SH;
        undef $/;
        eval {
            $default = $self->{json}->decode(<$fh>)
        }; if( $@ ) {
            die "Error parsing JSON file $file: $@\n";
        }
        $default or die "couldn't read from $file: $!";
        $fh->close()
            or die "couldn't close $file: $!";
        $/ = $OLDSEP;
    }
    return $default;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::JBrowse::Store::NCList::JSONFileStorage

=head1 SYNOPSIS

    my $storage = Bio::JBrowse::Store::NCList::JSONFileStorage->new( $outDir, $self->config->{compress} );
    $storage->put( 'relative/path/to/file.jsonz', \%data );
    my $data = $storage->get( 'relative/path/to/file.jsonz' );

    $storage->modify( 'relative/path/to/file.jsonz',
                      sub {
                         my $json_data = shift;
                         # do something with the data
                         return $json_data;
                      })

=head1 NAME

Bio::JBrowse::Store::NCList::JSONFileStorage - manage a directory structure of .json or .jsonz files

=head1 METHODS

=head2 new( $outDir, $compress, \%opts )

Constructor.  Takes the directory to work with, boolean flag of
whether to compress the results, and an optional hashref of other
options as:

  # TODO: document options hashref

=head2 fullPath( 'path/to/file.json' )

Get the full path to the given filename in the output directory.  Just
calls File::Spec->join with the C<<$outDir>> that was set at
construction.

=head2 ext

Accessor for the file extension currently in use for the files in this
storage directory.  Usually either '.json' or '.jsonz'.

=head2 encodedSize( $object )

=head2 put( $path, $data )

=head2 get( $path, $default_value )

=head1 AUTHOR

Robert Buels <rbuels@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
