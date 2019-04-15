use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);
use Path::Tiny qw(path);
use CPAN::Index::API::File::ModList;

# defaults
my $with_modules = <<'EndOfModules';
File:        03modlist.data.gz
Description: Package names found in directory $CPAN/authors/id/
Modcount:    3
Written-By:  CPAN::Index::API::File::ModList 0.008
Date:        Fri Mar 23 18:23:15 2012 GMT

package CPAN::Modulelist;
# Usage: print Data::Dumper->new([CPAN::Modulelist->data])->Dump or similar
# cannot 'use strict', because we normally run under Safe
# use strict;
sub data {
my $result = {};
my $primary = "modid";
for (@$CPAN::Modulelist::data){
my %hash;
@hash{@$CPAN::Modulelist::cols} = @$_;
$result->{$hash{$primary}} = \%hash;
}
$result;
}
$CPAN::Modulelist::cols = [
'modid',
'statd',
'stats',
'statl',
'stati',
'statp',
'description',
'userid',
'chapterid'
];

$CPAN::Modulelist::data = [
[
'Foo',
'S',
'd',
'c',
'f',
'?',
'Foo for you',
'FOOBAR',
'4'
],
[
'Baz',
'c',
'd',
'p',
'f',
'?',
'Some baz',
'LOCAL',
'4'
],
[
'Acme::Qux',
'R',
'd',
'p',
'O',
'?',
'Qux your code',
'PSHANGOV',
'23'
],
];
EndOfModules

my $without_modules = <<'EndOfModules';
File:        03modlist.data.gz
Description: Package names found in directory $CPAN/authors/id/
Modcount:    0
Written-By:  CPAN::Index::API::File::ModList 0.008
Date:        Fri Mar 23 18:23:15 2012 GMT

package CPAN::Modulelist;
# Usage: print Data::Dumper->new([CPAN::Modulelist->data])->Dump or similar
# cannot 'use strict', because we normally run under Safe
# use strict;
sub data {
my $result = {};
my $primary = "modid";
for (@$CPAN::Modulelist::data){
my %hash;
@hash{@$CPAN::Modulelist::cols} = @$_;
$result->{$hash{$primary}} = \%hash;
}
$result;
}
$CPAN::Modulelist::cols = [
'modid',
'statd',
'stats',
'statl',
'stati',
'statp',
'description',
'userid',
'chapterid'
];

$CPAN::Modulelist::data = [];
EndOfModules

my @modules = (
    {
        name              => 'Foo',
        authorid          => 'FOOBAR',
        description       => 'Foo for you',
        chapterid         => '4',
        development_stage => 'S',
        support_level     => 'd',
        language_used     => 'c',
        interface_style   => 'f',
        public_license    => '?',
    },
    {
        name              => 'Baz',
        authorid          => 'LOCAL',
        description       => 'Some baz',
        chapterid         => '4',
        development_stage => 'c',
        support_level     => 'd',
        language_used     => 'p',
        interface_style   => 'f',
        public_license    => '?',
    },
    {
        name              => 'Acme::Qux',
        authorid          => 'PSHANGOV',
        description       => 'Qux your code',
        chapterid         => '23',
        development_stage => 'R',
        support_level     => 'd',
        language_used     => 'p',
        interface_style   => 'O',
        public_license    => '?',
    },
);

my $version = $CPAN::Index::API::File::ModList::VERSION;

my $writer_with_modules = CPAN::Index::API::File::ModList->new(
    last_generated => 'Fri Mar 23 18:23:15 2012 GMT',
    generated_by   => "CPAN::Index::API::File::ModList $version",
    modules        => \@modules,
);

my $writer_without_modules = CPAN::Index::API::File::ModList->new(
    last_generated => 'Fri Mar 23 18:23:15 2012 GMT',
    generated_by   => "CPAN::Index::API::File::ModList $version",
);

eq_or_diff( $writer_with_modules->content, $with_modules, 'with modules' );
eq_or_diff( $writer_without_modules->content, $without_modules, 'without modules' );

my ($fh_with_modules, $filename_with_modules) = tempfile;
$writer_with_modules->write_to_file($filename_with_modules);
my $content_with_modules = path($filename_with_modules)->slurp_utf8;
eq_or_diff( $content_with_modules, $with_modules, 'write to file with modules' );

my ($fh_without_modules, $filename_without_modules) = tempfile;
$writer_without_modules->write_to_file($filename_without_modules);
my $content_without_modules = path($filename_without_modules)->slurp_utf8;
eq_or_diff( $content_without_modules, $without_modules, 'write to file without modules' );


my $reader_with_modules = CPAN::Index::API::File::ModList->read_from_string($with_modules);
my $reader_without_modules = CPAN::Index::API::File::ModList->read_from_string($without_modules);

my %expected = (
    filename     => '03modlist.data.gz',
    generated_by => "CPAN::Index::API::File::ModList $version",
    description  => 'Package names found in directory $CPAN/authors/id/',
);

foreach my $attribute ( keys %expected ) {
    is ( $reader_without_modules->$attribute, $expected{$attribute}, "read $attribute (without modules)" );
}

my @no_modules = $reader_without_modules->modules;

ok ( !@no_modules, "reader without modules has no modules" );

foreach my $attribute ( keys %expected ) {
    is ( $reader_with_modules->$attribute, $expected{$attribute}, "read $attribute (with modules)" );
}

my @three_modules = $reader_with_modules->modules;

is ( scalar @three_modules, 3, "reader with modules has 3 modules" );

(my $foo) = grep { $_->{name} eq 'Foo' } @three_modules;

my %expected_attributes = (
    name              => 'Foo',
    chapterid         => 4,
    authorid          => 'FOOBAR',
    description       => 'Foo for you',
    public_license    => undef,
    development_stage => 'S',
    language_used     => 'c',
    support_level     => 'd',
    interface_style   => 'f'
);

foreach my $attribute ( keys %expected_attributes ) {
    is ( $foo->{$attribute}, $expected_attributes{$attribute}, "read module $attribute" );
}

done_testing;
