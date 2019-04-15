use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);
use Path::Tiny qw(path);
use Compress::Zlib qw(gzopen);
use CPAN::Index::API::File::PackagesDetails;

# defaults
my $with_packages = <<'EndOfPackages';
File:         02packages.details.txt.gz
URL:          http://www.example.com/modules/02packages.details.txt.gz
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   CPAN::Index::API::File::PackagesDetails 0.001
Line-Count:   4
Last-Updated: Fri Mar 23 18:23:15 2012 GMT

Acme::Qux                           9.99  P/PS/PSHANGOV/Acme-Qux-9.99.tar.gz
Baz                                1.234  L/LO/LOCAL/Baz-1.234.tar.gz
Foo                                 0.01  F/FO/FOOBAR/Foo-0.01.tar.gz
Foo::Bar                           undef  F/FO/FOOBAR/Foo-0.01.tar.gz
EndOfPackages

my $without_packages = <<'EndOfPackages';
File:         02packages.details.txt.gz
URL:          http://www.example.com/modules/02packages.details.txt.gz
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   CPAN::Index::API::File::PackagesDetails 0.001
Line-Count:   0
Last-Updated: Fri Mar 23 18:23:15 2012 GMT
EndOfPackages

my @packages = (
    { name => 'Foo',       version => '0.01',  distribution => 'F/FO/FOOBAR/Foo-0.01.tar.gz' },
    { name => 'Foo::Bar',  version =>  undef,  distribution => 'F/FO/FOOBAR/Foo-0.01.tar.gz' },
    { name => 'Baz',       version => '1.234', distribution => 'L/LO/LOCAL/Baz-1.234.tar.gz' },
    { name => 'Acme::Qux', version => '9.99',  distribution => 'P/PS/PSHANGOV/Acme-Qux-9.99.tar.gz' },
);

my $writer_with_packages = CPAN::Index::API::File::PackagesDetails->new(
    repo_uri       => 'http://www.example.com',
    last_generated => 'Fri Mar 23 18:23:15 2012 GMT',
    generated_by   => 'CPAN::Index::API::File::PackagesDetails 0.001',
    packages       => \@packages,
);

my $writer_without_packages = CPAN::Index::API::File::PackagesDetails->new(
    repo_uri       => 'http://www.example.com',
    last_generated => 'Fri Mar 23 18:23:15 2012 GMT',
    generated_by   => 'CPAN::Index::API::File::PackagesDetails 0.001',
);

eq_or_diff( $writer_with_packages->content, $with_packages, 'with packages' );
eq_or_diff( $writer_without_packages->content, $without_packages, 'without packages' );

my ($fh_with_packages, $filename_with_packages) = tempfile;
$writer_with_packages->write_to_file($filename_with_packages);
my $content_with_packages = path($filename_with_packages)->slurp_utf8;
eq_or_diff( $content_with_packages, $with_packages, 'write to file with packages' );

my ($fh_without_packages, $filename_without_packages) = tempfile;
$writer_without_packages->write_to_file($filename_without_packages);
my $content_without_packages = path($filename_without_packages)->slurp_utf8;
eq_or_diff( $content_without_packages, $without_packages, 'write to file without packages' );

my $reader_with_packages = CPAN::Index::API::File::PackagesDetails->read_from_string($with_packages);
my $reader_without_packages = CPAN::Index::API::File::PackagesDetails->read_from_string($without_packages);

my %expected = (
    last_generated => 'Fri Mar 23 18:23:15 2012 GMT',
    intended_for   => 'Automated fetch routines, namespace documentation.',
    description    => 'Package names found in directory $CPAN/authors/id/',
    uri            => 'http://www.example.com/modules/02packages.details.txt.gz',
    filename       => '02packages.details.txt.gz',
    generated_by   => 'CPAN::Index::API::File::PackagesDetails 0.001',
    columns        => 'package name, version, path',
);

foreach my $attribute ( keys %expected ) {
    is ( $reader_without_packages->$attribute, $expected{$attribute}, "read $attribute (without packages)" );
}

my @no_packages = $reader_without_packages->packages;

ok ( !@no_packages, "reader without packages has no packages" );

foreach my $attribute ( keys %expected ) {
    is ( $reader_with_packages->$attribute, $expected{$attribute}, "read $attribute (with packages)" );
}

my @four_packages = $reader_with_packages->packages;

is ( scalar @four_packages, 4, "reader with packages has 4 packages" );

(my $foo) = grep { $_->{name} eq 'Foo' } @four_packages;

is ( $foo->{name},         'Foo',                         'read package name'         );
is ( $foo->{version},      '0.01',                        'read package version'      );
is ( $foo->{distribution}, 'F/FO/FOOBAR/Foo-0.01.tar.gz', 'read package distribution' );

(my $undef_version) = grep { ! defined $_->{version} } @four_packages;

is ( $undef_version->{version}, undef, 'read missing version' );

my ($tarball_fh_with_packages, $tarball_name_with_packages) = tempfile;
$writer_with_packages->write_to_tarball($tarball_name_with_packages);

my ($buffer, $content_from_tarball);
my $gz = gzopen($tarball_name_with_packages, 'rb');
$content_from_tarball .= $buffer while $gz->gzread($buffer) > 0 ;
$gz->gzclose;

is ( $content_from_tarball, $with_packages, 'read_from_tarball');

my $mutable_writer = CPAN::Index::API::File::PackagesDetails->new(
    repo_uri       => 'http://www.example.com',
    last_generated => 'Fri Mar 23 18:23:15 2012 GMT',
    generated_by   => 'CPAN::Index::API::File::PackagesDetails 0.001',
    packages       => [@packages[0..2]],
);

unlike $mutable_writer->content, qr/PSHANGOV/, 'content before addition';

$mutable_writer->add_package($packages[3]);
$mutable_writer->rebuild_content;

like $mutable_writer->content, qr/PSHANGOV/, 'content after addition';

done_testing;
