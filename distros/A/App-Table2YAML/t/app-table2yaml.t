#/usr/bin/env perl

use common::sense;
use warnings FATAL => q(all);
use Test::More;
use File::Find;
use File::Spec::Functions qw[catdir splitdir];
use File::Basename;
use File::ShareDir::ProjectDistDir;

my $class = q(App::Table2YAML);
use_ok($class) || say q(Bail out!);

my $test_dir = catdir( dist_dir($class), q(test) );

my %test_file;
find( sub { $test_file{$File::Find::name}++ if -e -f }, $test_dir, );

my %offset = (
    ascii7 => [ 4, 4, 4,  25, ],
    simple => [ 4, 7, 16, 20, 14, 18, 12, 14, 7, ],
);
my ( %yml, @test );
foreach my $file ( keys %test_file ) {
    my ( $name, $dir, $suffix ) = fileparse( $file, qr{\.[^.]*$} );

    if ( $suffix eq q(.yml) ) {
        my $yml = do { local ( @ARGV, $/ ) = $file; <> };
        $yml{$name} = [ split m{\n}msx, $yml ];
        next;
    }

    my $type = basename($dir);
    my %opt  = (
        $name => {
            input      => $file,
            input_type => $type,
            testname   => catdir( $type, basename($file) ),
        }
    );

    if ( $type eq q(dsv) ) {
        $opt{$name}{record_separator} = qq(\n);
        if ( $suffix eq q(.csv) ) {
            $opt{$name}{field_separator} = q(,);
        }
        elsif ( $suffix eq q(.tsv) ) {
            $opt{$name}{field_separator} = qq(\t);
        }
    }
    elsif ( $type eq q(fixedwidth) ) {
        $opt{$name}{record_separator} = qq(\n);
        $opt{$name}{field_offset}     = $offset{$name};
    }

    push @test, {%opt};
} ## end foreach my $file ( keys %test_file)

{
    my $obj;
    ok( $class->new(), sprintf( q(%s->new()), $class ) );
    can_ok( $class, qw[loader serializer convert] );
}

foreach my $test (@test) {
    my $name     = ( keys %{$test} )[0];
    my $testname = delete $test->{$name}{testname};

    my $opts = $test->{$name};

    my ( $obj, $output );
    my $testname_new = sprintf( q(%s->new() => %s), $class, $testname );
    ok( $obj = App::Table2YAML->new($opts), $testname_new ) || die;

SKIP: {
        eval { $output = [ $obj->convert() ] };
        my $why = sprintf q(%s loader unimplemented), $opts->{input_type};
        skip $why, 1 if index( $@, q(Unimplemented) ) + 1;

        my $testname_deep = join( q( == ), $testname, $name . q(.yml) );
        unless ( is_deeply( $output, $yml{$name}, $testname_deep ) ) {
            die;
        }
    }
} ## end foreach my $test (@test)

done_testing();

# Local Variables:
# mode: perl
# coding: utf-8-unix
# End:
