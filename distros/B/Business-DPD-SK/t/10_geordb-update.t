use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use IO::Compress::Zip qw(zip $ZipError);

use Business::DPD::SK::GeoRDB;

# Minimal stand-in for the Net::SFTP::Foreign calls used by update().
{
    package FakeSFTP;
    sub new { my ($class, %files) = @_; return bless {files => {%files}, error => ''}, $class }
    sub ls {
        my ($self, $dir, %opt) = @_;
        return [sort keys %{$self->{files}}];
    }
    sub get {
        my ($self, $remote, $local) = @_;
        my $content = $self->{files}{$remote};
        unless (defined $content) {$self->{error} = 'no such file'; return}
        open(my $fh, '>:raw', $local) or die $!;
        print {$fh} $content;
        close($fh);
        return 1;
    }
    sub error { $_[0]{error} }
}

sub zip_bytes {
    my ($member, $content) = @_;
    my $out;
    zip(\$content => \$out, Name => $member) or die $ZipError;
    return $out;
}

sub geordb_zip {
    my ($version) = @_;
    my $name = 'GeoRDB_' . $version . '_B016';
    return zip_bytes($name, join("\r\n", "#FILE;$name;", "#VERSION;$version;", '#END', ''));
}

sub zips_in {
    my ($dir) = @_;
    opendir(my $dh, $dir) or die $!;
    return [sort grep {/\.zip\z/} readdir($dh)];
}

subtest 'version_of parses file names' => sub {
    is(Business::DPD::SK::GeoRDB->version_of('GeoRDB_26110211_B016.zip'), '26110211', 'production version');
    is(Business::DPD::SK::GeoRDB->version_of('GeoRDB_26110201_B016.zip'), undef, 'VV=01 is a test version');
    is(Business::DPD::SK::GeoRDB->version_of('GeoRDB_26110211_B015.zip'), undef, 'other business unit');
    is(Business::DPD::SK::GeoRDB->version_of('notes.txt'), undef, 'unrelated file');
};

subtest 'remote_latest picks the highest production version' => sub {
    my $geordb = Business::DPD::SK::GeoRDB->new(
        data_dir => tempdir(CLEANUP => 1),
        sftp     => FakeSFTP->new(
            'GeoRDB_26100512_B016.zip' => 'x',
            'GeoRDB_26110211_B016.zip' => 'x',
            'GeoRDB_26120101_B016.zip' => 'x',    # test version, ignored
            'readme.txt'               => 'x',
        ),
    );
    is($geordb->remote_latest, 'GeoRDB_26110211_B016.zip', 'newest production zip');
};

subtest 'update downloads a newer zip and removes the old one' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $old = File::Spec->catfile($dir, 'GeoRDB_26100512_B016.zip');
    open(my $fh, '>:raw', $old) or die $!;
    print {$fh} geordb_zip('26100512');
    close($fh);

    my $geordb = Business::DPD::SK::GeoRDB->new(
        data_dir => $dir,
        sftp     => FakeSFTP->new('GeoRDB_26110211_B016.zip' => geordb_zip('26110211')),
    );
    my $new = $geordb->update;
    is($new, File::Spec->catfile($dir, 'GeoRDB_26110211_B016.zip'), 'returns the stored path');
    is_deeply(zips_in($dir), ['GeoRDB_26110211_B016.zip'], 'only the new zip remains');
    is($geordb->local_version, '26110211', 'local version follows the download');
    is($geordb->update, undef, 'second update finds nothing newer');
};

subtest 'update keeps a local zip that is newer or equal' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $local = File::Spec->catfile($dir, 'GeoRDB_26110211_B016.zip');
    open(my $fh, '>:raw', $local) or die $!;
    print {$fh} geordb_zip('26110211');
    close($fh);

    my $geordb = Business::DPD::SK::GeoRDB->new(
        data_dir => $dir,
        sftp     => FakeSFTP->new('GeoRDB_26100512_B016.zip' => geordb_zip('26100512')),
    );
    is($geordb->update, undef, 'older remote is not downloaded');
    is_deeply(zips_in($dir), ['GeoRDB_26110211_B016.zip'], 'local zip untouched');
};

subtest 'a corrupt download keeps the previous zip' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $old = File::Spec->catfile($dir, 'GeoRDB_26100512_B016.zip');
    open(my $fh, '>:raw', $old) or die $!;
    print {$fh} geordb_zip('26100512');
    close($fh);

    my $zip    = geordb_zip('26110211');
    my $broken = substr($zip, 0, int(length($zip) / 2));    # interrupted transfer

    my $geordb = Business::DPD::SK::GeoRDB->new(
        data_dir => $dir,
        sftp     => FakeSFTP->new('GeoRDB_26110211_B016.zip' => $broken),
    );
    dies_ok {$geordb->update} 'corrupt zip dies';
    is_deeply(zips_in($dir), ['GeoRDB_26100512_B016.zip'], 'previous zip kept, no partial file left');
};

subtest 'local_file picks the highest version when two zips exist' => sub {
    my $dir = tempdir(CLEANUP => 1);
    for my $v (qw(26100512 26110211)) {
        open(my $fh, '>:raw', File::Spec->catfile($dir, "GeoRDB_${v}_B016.zip")) or die $!;
        print {$fh} geordb_zip($v);
        close($fh);
    }
    my $geordb = Business::DPD::SK::GeoRDB->new(data_dir => $dir);
    is($geordb->local_file, File::Spec->catfile($dir, 'GeoRDB_26110211_B016.zip'), 'highest local zip');
};

subtest 'configuration is read from the ini file' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $ini = File::Spec->catfile($dir, 'geordb.ini');
    open(my $fh, '>', $ini) or die $!;
    print {$fh} "[download]\nhostname=sftp.example.test\nusername=u\npassword=p\n";
    close($fh);
    my $geordb = Business::DPD::SK::GeoRDB->new(config_file => $ini, data_dir => $dir);
    is($geordb->download_config->{hostname}, 'sftp.example.test', 'hostname from ini');
};

done_testing();
