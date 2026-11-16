package Business::DPD::SK::GeoRDB;

use 5.010;
use Moo;
use namespace::autoclean;

our $VERSION = '0.01';

use Carp qw(croak);
use File::Spec;
use Config::INI::Reader;
use IO::Uncompress::Unzip qw($UnzipError);
use Business::DPD::SK::SPc;

my $ZIP_RE = qr/\AGeoRDB_(\d{6}(\d{2}))_B016\.zip\z/;

has config_file => (
    is      => 'ro',
    lazy    => 1,
    default => sub {File::Spec->catfile(Business::DPD::SK::SPc->sysconfdir, 'dpd-sk', 'geordb.ini')},
);
has data_dir => (
    is      => 'ro',
    lazy    => 1,
    default => sub {File::Spec->catdir(Business::DPD::SK::SPc->sharedstatedir, 'dpd-sk')},
);
has file => (
    is        => 'ro',
    lazy      => 1,
    builder   => 'local_file',
    clearer   => '_clear_file',
);
has download_config => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $config = Config::INI::Reader->read_file($self->config_file)->{download};
        croak 'no [download] section in ' . $self->config_file
            unless $config;
        return $config;
    },
);
has sftp => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_sftp',
);

sub _build_sftp {
    my ($self) = @_;
    require Net::SFTP::Foreign;
    my $config = $self->download_config;
    my $sftp   = Net::SFTP::Foreign->new(
        host     => $config->{hostname},
        user     => $config->{username},
        password => $config->{password},
        more     => [
            qw(
                -oPubkeyAuthentication=no
                -oPreferredAuthentications=password
                -oRequestTTY=no
                -oKbdInteractiveAuthentication=no
                -oStrictHostKeyChecking=yes
            )
        ],
        timeout => 120,
        autodie => 1,
    );
    croak 'SFTP connection to ' . $config->{hostname} . ' failed: ' . $sftp->error
        if $sftp->error;
    return $sftp;
}

sub version_of {
    my ($class, $name) = @_;
    return undef unless defined($name) && $name =~ $ZIP_RE;
    return undef if $2 eq '01';    # VV=01 is reserved for DPD test versions
    return $1;
}

sub _latest {
    my ($self, @names) = @_;
    my ($latest) = sort {$self->version_of($b) <=> $self->version_of($a)}
        grep {defined $self->version_of($_)} @names;
    return $latest;
}

sub _local_zips {
    my ($self) = @_;
    my $dir = $self->data_dir;
    opendir(my $dh, $dir) or croak "cannot read $dir: $!";
    return grep {defined $self->version_of($_)} readdir($dh);
}

sub remote_latest {
    my ($self) = @_;
    my $names = $self->sftp->ls('.', names_only => 1)
        or croak 'SFTP listing failed: ' . $self->sftp->error;
    return $self->_latest(@$names);
}

sub local_file {
    my ($self) = @_;
    my $latest = $self->_latest($self->_local_zips);
    return undef unless $latest;
    return File::Spec->catfile($self->data_dir, $latest);
}

sub local_version {
    my ($self) = @_;
    my $file = $self->local_file;
    return undef unless $file;
    return $self->version_of((File::Spec->splitpath($file))[2]);
}

sub update {
    my ($self) = @_;

    my $remote = $self->remote_latest
        // croak 'no GeoRDB file found on the SFTP server';
    my $local_version = $self->local_version;
    return undef
        if defined($local_version) && $self->version_of($remote) <= $local_version;

    my $target = File::Spec->catfile($self->data_dir, $remote);
    my $part   = $target . '.part';
    eval {$self->sftp->get($remote, $part) or die $self->sftp->error . "\n"; 1} or do {
        my $error = $@;
        unlink($part);
        croak "SFTP download of $remote failed: $error";
    };
    eval {_read_all($part); 1} or do {
        my $error = $@;
        unlink($part);
        croak "downloaded $remote is not a valid zip: $error";
    };
    rename($part, $target) or croak "cannot rename $part: $!";

    for my $old ($self->_local_zips) {
        next if $old eq $remote;
        my $path = File::Spec->catfile($self->data_dir, $old);
        unlink($path) or croak "cannot remove $path: $!";
    }
    $self->_clear_file;

    return $target;
}

# Reads the whole member so that a CRC or decompression error surfaces.
sub _read_all {
    my ($zip) = @_;
    _each_line($zip, sub { });
    return;
}

sub _each_line {
    my ($zip, $cb) = @_;
    my $z = IO::Uncompress::Unzip->new($zip, Strict => 1)
        or croak "cannot open $zip: $UnzipError";
    while (defined(my $line = $z->getline)) {
        $line =~ s/\r?\n\z//;
        $cb->($line);
    }
    croak "error reading $zip: " . ($z->error || $UnzipError)
        if $z->error;
    $z->close;
    return;
}

sub _zip_file {
    my ($self) = @_;
    my $file = $self->file;
    croak 'no GeoRDB file in ' . $self->data_dir
        unless defined $file;
    return $file;
}

sub each_row {
    my ($self, $table, $cb) = @_;
    croak 'need table and callback'
        unless $table && ref($cb) eq 'CODE';

    my $def_prefix = '#DEF:GEOROUTING:' . $table . ';';
    my $row_prefix = $table . ';';
    my ($columns, $rows, $complete) = (undef, 0, 0);

    _each_line(
        $self->_zip_file,
        sub {
            my ($line) = @_;
            if (index($line, $row_prefix) == 0) {
                croak "row for $table before its #DEF header"
                    unless $columns;
                my @values = split(/;/, substr($line, length($row_prefix)), -1);
                my %row;
                @row{@$columns} = map {$_ // ''} @values[0 .. $#$columns];
                $cb->(\%row);
                $rows++;
            }
            elsif (index($line, $def_prefix) == 0) {
                $columns = [grep {length} split(/;/, substr($line, length($def_prefix)))];
            }
            elsif ($line eq '#END') {
                $complete = 1;
            }
            return;
        }
    );

    return {rows => $rows, complete => $complete};
}

sub version {
    my ($self) = @_;
    my $version;
    $self->each_row('VERSION', sub {$version //= $_[0]});
    return $version;
}

1;

__END__

=head1 NAME

Business::DPD::SK::GeoRDB - download and read the DPD Slovakia GeoRDB

=head1 SYNOPSIS

    use Business::DPD::SK::GeoRDB;

    my $geordb = Business::DPD::SK::GeoRDB->new;

    # fetch the newest GeoRDB_<version>_B016.zip if it is newer than ours
    if (my $zip = $geordb->update) {
        say "downloaded $zip";
    }

    say $geordb->version->{VERSIONNUMBER};
    my $summary = $geordb->each_row('POSTALCODE', sub {
        my ($row) = @_;
        say join(' ', @{$row}{qw(COUNTRYCODE BEGINPOSTCODE ENDPOSTCODE)});
    });
    die 'truncated file' unless $summary->{complete};

=head1 DESCRIPTION

DPD Slovakia publishes its routing database (GeoRDB) as zip files named
C<GeoRDB_YYMMDDVV_B016.zip> on an SFTP server. Each zip contains one
semicolon-separated text file. C<#DEF:GEOROUTING:TABLE;COLUMN;...> lines
name the columns of each table; data lines start with the table name.

This module keeps the newest zip in L</data_dir> and streams rows of a
single table from it without extracting the file.

Versions whose last two digits are C<01> are DPD test versions and are
ignored.

=head1 ATTRIBUTES

=head2 config_file

INI file with a C<[download]> section holding C<hostname>, C<username> and
C<password>. Defaults to F<dpd-sk/geordb.ini> below
L<Business::DPD::SK::SPc/sysconfdir>.

=head2 data_dir

Directory where the zip is stored. Defaults to F<dpd-sk> below
L<Business::DPD::SK::SPc/sharedstatedir>.

=head2 file

The zip read by L</each_row> and L</version>. Defaults to L</local_file>.
Pass a path to read another zip.

=head2 sftp

A L<Net::SFTP::Foreign> connection built from L</config_file> on first use.
Password authentication needs L<IO::Pty>, and the server's host key must
already be in the user's F<known_hosts>.

=head1 METHODS

=head2 update

Downloads the newest production zip from the server if its version is
higher than L</local_version>. The download is written to a C<.part> file,
read completely to verify it, renamed, and older zips are deleted. Returns
the new path, or C<undef> when nothing newer exists. Dies on SFTP or zip
errors and then leaves the previous zip in place.

=head2 each_row

    my $summary = $geordb->each_row($table, sub { my ($row) = @_; ... });

Calls the callback with a hash reference per row of C<$table>, keyed by the
column names of its C<#DEF> line. Returns C<< {rows => $count, complete =>
0|1} >>; C<complete> is true when the C<#END> line was seen. Dies on
decompression or CRC errors.

=head2 version

Returns the C<VERSION> row: C<VERSIONNUMBER>, C<VALIDFROM>, C<VALIDTO> and
C<BARCODEID>.

=head2 remote_latest

Name of the newest production zip on the server.

=head2 local_file

=head2 local_version

Path and version of the newest zip in L</data_dir>, or C<undef>.

=head2 version_of

    Business::DPD::SK::GeoRDB->version_of('GeoRDB_26110211_B016.zip'); # 26110211

Version number of a zip file name, or C<undef> for other names and test
versions.

=cut
