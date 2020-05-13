package Archive::SevenZip;
use strict;
use Carp qw(croak);
use Encode qw( decode encode );
use File::Basename qw(dirname basename);
use Archive::SevenZip::Entry;
use File::Temp qw(tempfile tempdir);
use File::Copy;
use IPC::Open3 'open3';
use Path::Class;
use Exporter 'import'; # for the error codes, in Archive::Zip API compatibility

=head1 NAME

Archive::SevenZip - Read/write 7z , zip , ISO9960 and other archives

=head1 SYNOPSIS

  my $ar = Archive::SevenZip->new(
      find => 1,
      archivename => $archivename,
      verbose => $verbose,
  );

  for my $entry ( $ar->list ) {
      my $target = join "/", "$target_dir", $entry->basename;
      $ar->extractMember( $entry->fileName, $target );
  };

=head1 METHODS

=cut

our $VERSION= '0.12';

# Archive::Zip API
# Error codes
use constant AZ_OK           => 0;

use constant COMPRESSION_STORED        => 'Store';   # file is stored (no compression)
use constant COMPRESSION_DEFLATED      => 'Deflate';   # file is Deflated

our @EXPORT_OK = (qw(AZ_OK COMPRESSION_STORED COMPRESSION_DEFLATED));
our %EXPORT_TAGS = (
        ERROR_CODES => [
            qw(
              AZ_OK
              )
              #AZ_STREAM_END
              #AZ_ERROR
              #AZ_FORMAT_ERROR
              #AZ_IO_ERROR
        ],
        CONSTANTS => [
             qw(COMPRESSION_STORED COMPRESSION_DEFLATED)
        ],
);

our %sevenzip_charsetname = (
    'UTF-8' => 'UTF-8',
    'Latin-1' => 'WIN',
    'ISO-8859-1' => 'WIN',
    '' => 'DOS', # dunno what the appropriate name would be
);

our %sevenzip_stdin_support = (
    #'7z'   => 1,
    'xz'    => 1,
    'lzma'  => 1,
    'tar'   => 1,
    'gzip'  => 1,
    'bzip2' => 1,
);

if( $^O !~ /MSWin/i ) {
    # Wipe all filesystem encodings because my Debian 7z 9.20 doesn't understand them
    $sevenzip_charsetname{ $_ } = ''
        for keys %sevenzip_charsetname;
};

our %class_defaults = (
    '7zip' => '7z',
    fs_encoding => 'UTF-8',
    default_options => [ "-y", "-bd" ],
    type => 'zip',
    system_needs_quotes => scalar ($^O =~ /MSWin/i),
);

=head2 C<< Archive::SevenZip->find_7z_executable >>

    my $version = Archive::SevenZip->find_7z_executable()
        or die "No 7z found.";
    print "Found 7z version '$version'";

Finds the 7z executable in the path or in C<< $ENV{ProgramFiles} >>
or C<< $ENV{ProgramFiles(x86)} >>. This is called
when a C<< Archive::SevenZip >> instance is created with the C<find>
parameter set to 1.

If C<< $ENV{PERL_ARCHIVE_SEVENZIP_BIN} >> is set, this value will be used as
the 7z executable and the path will not be searched.

=cut

sub find_7z_executable {
    my($class) = @_;
    my $old_default = $class_defaults{ '7zip' };
    my $envsep = $^O =~ /MSWin/ ? ';' : ':';
    my $found;
    if( $ENV{PERL_ARCHIVE_SEVENZIP_BIN}) {
        $class_defaults{'7zip'} = $ENV{PERL_ARCHIVE_SEVENZIP_BIN};
        $found = $class_defaults{'7zip'};
    } else {
        my @search;
        push @search, split /$envsep/, $ENV{PATH};
        if( $^O =~ /MSWin/i ) {
            push @search, map { "$_\\7-Zip" } grep {defined} ($ENV{'ProgramFiles'}, $ENV{'ProgramFiles(x86)'});
        };
        $found = $class->version;

        while( ! defined $found and @search) {
            my $dir = shift @search;
            if ($^O eq 'MSWin32') {
                next unless -e file("$dir", "7z.exe" );
            }
            $class_defaults{'7zip'} = "" . file("$dir", "7z" );
            $found = $class->version;
        };
    };

    if( ! $found) {
        $class_defaults{ '7zip' } = $old_default;
    };
    return defined $found ? $found : ()
}

=head2 C<< Archive::SevenZip->new >>

  my $ar = Archive::SevenZip->new( $archivename );

  my $ar = Archive::SevenZip->new(
      archivename => $archivename,
      find => 1,
  );

Creates a new class instance.

C<find> - will try to find the executable using C<< ->find_7z_executable >>

=cut

sub new {
    my( $class, %options);
    if( @_ == 2 ) {
        ($class, $options{ archivename }) = @_;
    } else {
        ($class, %options) = @_;
    };

    if( $options{ find }) {
        $class->find_7z_executable();
    };

    for( keys %class_defaults ) {
        $options{ $_ } = $class_defaults{ $_ }
            unless defined $options{ $_ };
    };

    bless \%options => $class
}

sub version {
    my( $self_or_class, %options) = @_;
    for( keys %class_defaults ) {
        $options{ $_ } = $class_defaults{ $_ }
            unless defined $options{ $_ };
    };
    my $self = ref $self_or_class ? $self_or_class : $self_or_class->new( %options );

    my $cmd = $self->get_command(
        command => '',
        archivename => undef,
        options => [], # on Debian, 7z doesn't like any options...
        fs_encoding => undef, # on Debian, 7z doesn't like any options...
        default_options => [], # on Debian, 7z doesn't like any options...
    );
    my $fh = eval { $self->run($cmd, binmode => ':raw') };

    if( ! $@ ) {
        local $/ = "\n";
        my @output = <$fh>;
        if( @output >= 3) {
            # 7-Zip 19.00 (x64) : Copyright (c) 1999-2018 Igor Pavlov : 2019-02-21
            # 7-Zip [64] 16.02 : Copyright (c) 1999-2016 Igor Pavlov : 2016-05-21
            # 7-Zip [64] 9.20  Copyright (c) 1999-2010 Igor Pavlov  2010-11-18
            $output[1] =~ /^7-Zip\s+.*?\b(\d+\.\d+)\s+(?:\(x64\))?(?:\s*:\s*)?Copyright/
                or return undef;
            return $1;
        } else {
            return undef
        }
    }
}

=head2 C<< $ar->open >>

  my @entries = $ar->open;
  for my $entry (@entries) {
      print $entry->fileName, "\n";
  };

Lists the entries in the archive. A fresh archive which does not
exist on disk yet has no entries. The returned entries
are L<Archive::SevenZip::Entry> instances.

This method will one day move to the Path::Class-compatibility
API.

=cut
# Iterate over the entries in the archive
# Path::Class API
sub open {
    my( $self )= @_;
    my @contents = $self->list();
}

=head2 C<< $ar->memberNamed >>

  my $entry = $ar->memberNamed('hello_world.txt');
  print $entry->fileName, "\n";

The path separator must be a forward slash ("/")

This method will one day move to the Archive::Zip-compatibility
API.

=cut

# Archive::Zip API
sub memberNamed {
    my( $self, $name, %options )= @_;

    my( $entry ) = grep { $_->fileName eq $name } $self->members( %options );
    $entry
}

# Archive::Zip API
sub list {
    my( $self, %options )= @_;

    if( ! grep { defined $_ } $options{archivename}, $self->{archivename}) {
        # We are an archive that does not exist on disk yet
        return
    };
    my $cmd = $self->get_command( command => "l", options => ["-slt"], %options );

    my $fh = $self->run($cmd,
        encoding => $options{ fs_encoding },
        stdin_fh => $options{ fh },
     );
    my @output = <$fh>;
    my %results = (
        header => [],
        archive => [],
    );

    # Get/skip header
    while( @output and $output[0] !~ /^--\s*$/ ) {
        my $line = shift @output;
        $line =~ s!\s+$!!;
        push @{ $results{ header }}, $line;
    };

    # Get/skip archive information
    while( @output and $output[0] !~ /^----------\s*$/ ) {
        my $line = shift @output;
        $line =~ s!\s+$!!;
        push @{ $results{ archive }}, $line;
    };

    if( $output[0] =~ /^----------\s*$/ ) {
        shift @output;
    } else {
        warn "Unexpected line in 7zip output, hope that's OK: [$output[0]]";
    };

    my @members;

    # Split entries
    my %entry_info;
    while( @output ) {
        my $line = shift @output;
        if( $line =~ /^([\w ]+) =(?: (.*?)|)\s*$/ ) {
            $entry_info{ $1 } = $2;
        } elsif($line =~ /^\s*$/) {
            push @members, Archive::SevenZip::Entry->new(
                %entry_info,
                _Container => $self,
            );
            %entry_info = ();
        } else {
            croak "Unknown file entry [$line]";
        };
    };

    return @members
}
{ no warnings 'once';
*members = \&list;
}

=head2 C<< $ar->openMemberFH >>

  my $fh = $ar->openMemberFH('test.txt');
  while( <$fh> ) {
      print "test.txt: $_";
  };

Reads the uncompressed content of the member from the archive.

This method will one day move to the Archive::Zip-compatibility
API.

=cut

sub openMemberFH {
    my( $self, %options );
    if( @_ == 2 ) {
        ($self,$options{ membername })= @_;
    } else {
        ($self,%options) = @_;
    };
    defined $options{ membername } or croak "Need member name to extract";

    my $cmd = $self->get_command( command => "e", options => ["-so"], members => [$options{membername}] );
    my $fh = $self->run($cmd, encoding => $options{ encoding }, binmode => $options{ binmode });
    return $fh
}

sub content {
    my( $self, %options ) = @_;
    my $fh = $self->openMemberFH( %options );
    binmode $fh;
    local $/;
    <$fh>
}
=head2 C<< $ar->extractMember >>

  $ar->extractMember('test.txt' => 'extracted_test.txt');

Extracts the uncompressed content of the member from the archive.

This method will one day move to the Archive::Zip-compatibility
API.

=cut

# Archive::Zip API
sub extractMember {
    my( $self, $memberOrName, $extractedName, %_options ) = @_;
    $extractedName = $memberOrName
        unless defined $extractedName;

    my %options = (%$self, %_options);

    my $target_dir = dirname $extractedName;
    my $target_name = basename $extractedName;
    my $cmd = $self->get_command(
        command     => "e",
        archivename => $options{ archivename },
        members     => [ $memberOrName ],
        options     => [ "-o$target_dir" ],
    );
    my $fh = $self->run($cmd, encoding => $options{ encoding });

    while( <$fh>) {
        warn $_ if $options{ verbose };
    };
    if( basename $memberOrName ne $target_name ) {
        my $org = basename($memberOrName);
        if( $^O !~ /mswin/i) {
            $org = encode('UTF-8', $org);
        };
        rename "$target_dir/" . $org => $extractedName
            or croak "Couldn't move '$memberOrName' to '$extractedName': $!";
    };

    return AZ_OK;
};

=head2 C<< $ar->removeMember >>

  $ar->removeMember('test.txt');

Removes the member from the archive.

=cut

# strikingly similar to Archive::Zip API
sub removeMember {
    my( $self, $name, %_options ) = @_;

    my %options = (%$self, %_options);

    if( $^O =~ /MSWin/ ) {
        $name =~ s!/!\\!g;
    }

    my $cmd = $self->get_command(
        command     => "d",
        archivename => $options{ archivename },
        members     => [ $name ],
    );
    my $fh = $self->run($cmd, encoding => $options{ encoding } );
    $self->wait($fh, %options);

    return AZ_OK;
};

sub add_quotes {
    my $quote = shift;

    $quote ?
        map {
            defined $_ && /\s/ ? qq{"$_"} : $_
        } @_
    : @_
};

sub get_command {
    my( $self, %options )= @_;
    $options{ members } ||= [];
    $options{ archivename } = $self->{ archivename }
        unless defined $options{ archivename };
    if( ! exists $options{ fs_encoding }) {
        $options{ fs_encoding } = defined $self->{ fs_encoding } ? $self->{ fs_encoding } : $class_defaults{ fs_encoding };
    };
    if( ! defined $options{ default_options }) {
        $options{ default_options } = defined $self->{ default_options } ? $self->{ default_options } : $class_defaults{ default_options };
    };

    my @charset;
    if( defined $options{ fs_encoding }) {
        exists $sevenzip_charsetname{ $options{ fs_encoding }}
            or croak "Unknown filesystem encoding '$options{ fs_encoding }'";
        if( my $charset = $sevenzip_charsetname{ $options{ fs_encoding }}) {
            push @charset, "-scs" . $sevenzip_charsetname{ $options{ fs_encoding }};
        };
    };
    for(@{ $options{ members }}) {
        $_ = encode $options{ fs_encoding }, $_;
    };

    # Now quote what needs to be quoted
    for( @{ $options{ options }}, @{ $options{ members }}, $options{ archivename }, "$self->{ '7zip' }") {
    };

    my $add_quote = $self->{system_needs_quotes};
    return [grep {defined $_}
        add_quotes($add_quote, $self->{ '7zip' }),
        @{ $options{ default_options }},
        $options{ command },
        @charset,
        add_quotes($add_quote, @{ $options{ options }} ),
        "--",
        add_quotes($add_quote, $options{ archivename } ),
        add_quotes($add_quote, @{ $options{ members }} ),
    ];
}

sub run {
    my( $self, $cmd, %options )= @_;

    my $mode = '-|';
    if( defined $options{ stdin } || defined $options{ stdin_fh }) {
        $mode = '|-';
    };

    my $fh;
    warn "Opening [@$cmd]"
        if $options{ verbose };

    if( $self->{verbose} ) {
        CORE::open( $fh, $mode, @$cmd)
            or croak "Couldn't launch [$mode @$cmd]: $!/$?";
    } else {
        CORE::open( my $fh_err, '>', File::Spec->devnull )
            or warn "Couldn't redirect child STDERR";
        my $errh = fileno $fh_err;
        my $fh_in = $options{ stdin_fh };
        # We accumulate zombie PIDs here, ah well.
        $SIG{'CHLD'} = 'IGNORE';
        my $pid = open3( $fh_in, my $fh_out, '>&' . $errh, @$cmd)
            or croak "Couldn't launch [$mode @$cmd]: $!/$?";
        if( $mode eq '|-' ) {
            $fh = $fh_in;
        } else {
            $fh = $fh_out
        };
    }
    if( $options{ encoding }) {
        binmode $fh, ":encoding($options{ encoding })";
    } elsif( $options{ binmode } ) {
        binmode $fh, $options{ binmode };
    };

    if( $options{ stdin }) {
        print {$fh} $options{ stdin };
        close $fh;

    } elsif( $options{ stdin_fh } ) {
        close $fh;

    } elsif( $options{ skip }) {
        for( 1..$options{ skip }) {
            # Read that many lines
            local $/ = "\n";
            scalar <$fh>;
        };
    };

    $fh;
}

sub archive_or_temp {
    my( $self ) = @_;
    if( ! defined $self->{archivename} ) {
        $self->{is_tempfile} = 1;
        (my( $fh ),$self->{archivename}) = tempfile( SUFFIX => ".$self->{type}" );
        close $fh;
        unlink $self->{archivename};
    };
    $self->{archivename}
};

sub wait {
    my( $self, $fh, %options ) = @_;
    while( <$fh>) {
        warn $_ if ($options{ verbose } || $self->{verbose})
    };
    wait; # reap that child
}

=head2 C<< $ar->add_scalar >>

    $ar->add_scalar( "Some name.txt", "This is the content" );

Adds a scalar as an archive member.

Unfortunately, 7zip only reads archive members from STDIN
for  xz, lzma, tar, gzip and bzip2 archives.
In the other cases, the scalar will be written to a tempfile, added to the
archive and then renamed in the archive.

This requires 7zip version 9.30+

=cut

sub add_scalar {
    my( $self, $name, $scalar )= @_;

    if( $sevenzip_stdin_support{ $self->{type} } ) {
        my $cmd = $self->get_command(
            command => 'a',
            archivename => $self->archive_or_temp,
            members => ["-si$name"],
        );
        my $fh = $self->run( $cmd,
            binmode => ':raw',
            stdin   => $scalar,
            verbose => 1,
        );

    } else {

        # 7zip doesn't really support reading archive members from STDIN :-(
        my($fh, $tempname) = tempfile;
        binmode $fh, ':raw';
        print {$fh} $scalar;
        close $fh;

        # Only supports 7z archive type?!
        # 7zip will magically append .7z to the filename :-(
        my $cmd = $self->get_command(
            command => 'a',
            archivename => $self->archive_or_temp,
            members => [$tempname],
            #options =>  ],
        );
        $fh = $self->run( $cmd );
        $self->wait($fh);

        unlink $tempname
            or warn "Couldn't unlink '$tempname': $!";

        # Hopefully your version of 7zip can rename members (9.30+):
        $cmd = $self->get_command(
            command => 'rn',
            archivename => $self->archive_or_temp,
            members => [basename($tempname), $name],
            #options =>  ],
        );
        $fh = $self->run( $cmd );
        $self->wait($fh);
    };
};

=head2 C<< $ar->add_directory >>

    $ar->add_directory( "real_etc", "etc" );

Adds an empty directory

This currently ignores the directory date and time if the directory
exists

=cut

sub add_directory {
    my( $self, $localname, $target )= @_;

    $target ||= $localname;

    # Create an empty directory, add it to the archive,
    # then rename that temp name to the wanted name:
    my $tempname = tempdir;

    my $cmd = $self->get_command(
        command => 'a',
        archivename => $self->archive_or_temp,
        members => [$tempname],
        options =>  ['-r0'],
    );
    my $fh = $self->run( $cmd );
    $self->wait($fh);

    # Hopefully your version of 7zip can rename members (9.30+):
    $cmd = $self->get_command(
        command => 'rn',
        archivename => $self->archive_or_temp,
        members => [basename($tempname), $target],
    );
    $fh = $self->run( $cmd );
    $self->wait($fh);

    # Once 7zip supports reading from stdin, this will work again:
    #my $fh = $self->run( $cmd,
    #    binmode => ':raw',
    #    stdin => $scalar,
    #    verbose => 1,
    #);
};

sub add {
    my( $self, %options )= @_;

    my @items = @{ delete $options{ items } || [] };

    # Split up the list into one batch for the listfiles
    # and the list of files we need to rename

    my @filelist;
    for my $item (@items) {
        if( ! ref $item ) {
            $item = [ $item, $item ];
        };
        my( $name, $storedName ) = @$item;

        if( $name ne $storedName ) {
            # We need to pipe to 7zip from stdin (no, we don't, we can rename afterwards)
            # This still means we might overwrite an already existing file in the archive...
            # But 7-zip seems to not like duplicate filenames anyway in "@"-listfiles...
            my $cmd = $self->get_command(
                command => 'a',
                archivename => $self->archive_or_temp,
                members => [$name],
                #options =>  ],
            );
            my $fh = $self->run( $cmd );
            $self->wait($fh, %options );
            $cmd = $self->get_command(
                command => 'rn',
                archivename => $self->archive_or_temp,
                members => [$name, $storedName],
                #options =>  ],
            );
            $fh = $self->run( $cmd );
            $self->wait($fh, %options );

        } else {
            # 7zip can read the file from disk
            # Write the name to a tempfile to be read by 7zip for batching
            push @filelist, $name;
        };
    };

    if( @filelist ) {
        my( $fh, $name) = tempfile;
        binmode $fh, ':raw';
        print {$fh} join "\r\n", @filelist;
        close $fh;

        my @options;
        if( $options{ recursive }) {
            push @options, '-r';
        };

        my $cmd = $self->get_command(
            command => 'a',
            archivename => $self->archive_or_temp,
            members => ['@'.$name],
            options =>  \@options
        );
        $fh = $self->run( $cmd );
        $self->wait($fh, %options);
    };
};

=head2 C<< ->archiveZipApi >>

  my $ar = Archive::SevenZip->archiveZipApi(
      find => 1,
      archivename => $archivename,
      verbose => $verbose,
  );
  print "$_\n" for $ar->list_files;

This is an alternative constructor that gives you an API
that is somewhat compatible with the API of L<Archive::Zip>.
See also L<Archive::SevenZip::API::ArchiveZip>.

=cut

sub archiveZipApi {
    my( $class, %options ) = @_;
    require Archive::SevenZip::API::ArchiveZip;
    Archive::SevenZip::API::ArchiveZip->new( %options )
}

=head2 C<< ->archiveTarApi >>

  my $ar = Archive::SevenZip->archiveTarApi(
      find => 1,
      archivename => $archivename,
      verbose => $verbose,
  );
  print "$_\n" for $ar->list_files;

This is an alternative constructor that gives you an API
that is somewhat compatible with the API of L<Archive::Tar>.
See also L<Archive::SevenZip::API::ArchiveTar>.

=cut

sub archiveTarApi {
    my( $class, %options ) = @_;
    require Archive::SevenZip::API::ArchiveTar;
    Archive::SevenZip::API::ArchiveTar->new( %options )
}

package Path::Class::Archive::Handle;
use strict;

=head1 NAME

Path::Class::Archive - treat archives as directories

=cut

package Path::Class::Archive;

1;

__END__

=head1 CAUTION

This module tries to mimic the API of L<Archive::Zip> in some cases
and in other cases, the API of L<Path::Class>. It is also a very rough
draft that just happens to be doing what I need, mostly extracting
files.

=head1 SEE ALSO

L<File::Unpack> - also supports unpacking from 7z archives

L<Compress::unLZMA> - uncompressor for the LZMA compression method used by 7z

L<Archive::Libarchive::Any>

L<Archive::Any>

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/archive-sevenzip>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Archive-SevenZip>
or via mail to L<archive-sevenzip-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
