#/usr/bin/env perl

use common::sense;
use warnings FATAL => q(all);
use English qw[-no_match_vars];
use File::Basename;
use File::Path qw[remove_tree];
use File::Spec::Functions;
use IO::File;
use List::Util qw[first];
use Test::More;
use Time::Piece;
use Time::Seconds;

my $basename = basename($0);
my $tmpdir = first { defined && -d $_ && -w $_ }
@ENV{qw[TMDIR TMP_DIR]},
    q(/tmp);

$tmpdir = catdir( $tmpdir, $basename );
if ( -d $tmpdir ) {
    chmod oct q(0770), $tmpdir;
    remove_tree $tmpdir or die $!;
}
mkdir $tmpdir, oct q(0770) or die $!;

my @tmpfile;
my $dt = Time::Piece->strptime( q(1970-01-01), q(%Y-%m-%d) );

my @day    = ( 0 .. 59 );
my @sep    = (qw[_ -]);
my @suffix = (qw[dat tmp txt]);
foreach my $day (@day) {
    $dt += ONE_DAY;
    my $datetime = $dt->strftime(q(%Y-%m-%d));
    foreach my $sep (@sep) {
        foreach my $suffix (@suffix) {
            my $filename = qq(test${sep}${datetime}.${suffix});
            $filename = catfile( $tmpdir, $filename );
            my $fh = IO::File->new( $filename, q(w) );
            if ( defined $fh ) {
                push @tmpfile, $filename;
                $fh->close();
            }
        }
    }
} ## end foreach my $day (@day)

if ( @tmpfile != @day * @sep * @suffix ) {
    rmdir $tmpdir;
    BAIL_OUT(q(Can't create files to test.));
}

my $class = q(App::BoolFindGrep);
use_ok($class) || say q(Bail out!);

my @test = (
    {   literal => [
            [ q(test_)  => @day * @suffix, ],    #
            [ q(.tmp)   => @day * @sep, ],       #
            [ q(-1970-) => @day * @suffix, ],    #
        ],
    },
    {   glob => [

            [ q(*) => 0 + @tmpfile, ],           #
            [ sprintf( q(test[%s]*), join q(), @sep ) => 0 + @tmpfile, ],    #
            [ q(*.tmp) => @day * @sep, ],                                   #
            [ sprintf( q(*.{%s}), join q(,), @suffix ) => 0 + @tmpfile, ],  #
            [   sprintf( q([%s]1970-??-[0-9][0-9].*), join q(), @sep ) => 0
                    + @tmpfile,
            ],
         ],
    },
    {   regexp => [
            [ q(.*)          => 0 + @tmpfile, ],                            #
            [ q(1970[\d-]+)  => 0 + @tmpfile, ],                            #
            [ q(dat|tmp|txt) => 0 + @tmpfile, ],                            #
        ],
    },
);

foreach my $test (@test) {
    my $find_type = ( keys %$test )[0];
    foreach my $expr ( @{ $test->{$find_type} } ) {
        my ( $file_expr, $sum_files ) = @$expr;
        my $obj = $class->new(
            directory => [$tmpdir],                                         #
            find_type => $find_type,                                        #
            file_expr => $file_expr,                                        #
        );
        $obj->process();
        my $found_files = 0 + @{ $obj->found_files() };
        my $test_name = qq(find_type=>'$find_type', file_expr=>'$file_expr');
        cmp_ok( $sum_files, q(==), $found_files, $test_name ) or die;
    }
} ## end foreach my $test (@test)

remove_tree $tmpdir;
done_testing();

# Local Variables:
# mode: perl
# coding: utf-8-unix
# End:
