use strict;
no strict qw(subs);    ## no critic
use warnings;
use 5.010_001;

use Test::Exception;
use Test::Warnings qw(warning);
use FindBin        qw($Bin);
use lib "$Bin/lib";

use Test::More;
#
# We use Test::More::UTF8 to enable UTF-8 on Test::Builder
# handles (failure_output, todo_output, and output) created
# by Test::More. Requires Test::Simple 1.302210+, and seems
# to eliminate the following error on some CPANTs builds:
#
# > Can't locate object method "e" via package "warnings"
#
use Test::More::UTF8;

BEGIN {
    use_ok( 'DBIx::Squirrel', database_entity => 'db' )
        or print "Bail out!\n";
    use_ok( 'T::Squirrel', qw(:var diagdump) )
        or print "Bail out!\n";
    use_ok(
        'DBIx::Squirrel::util',
        qw(callbacks carpf cluckf confessf has_callbacks callbacks_args),
    ) or print "Bail out!\n";
}

diag join(
    ', ',
    "Testing DBIx::Squirrel $DBIx::Squirrel::VERSION",
    "Perl $]", "$^X",
);

{
    my @tests = (
        {
            line => __LINE__, name => 'ok - cluckf (no arguments)',
            got  => sub { cluckf() },
            exp  => qr/Unhelpful warning/,
        },
        {
            line => __LINE__, name => 'ok - cluckf (empty string)',
            got  => sub { cluckf('') },
            exp  => qr/Unhelpful warning/,
        },
        {
            line => __LINE__, name => 'ok - cluckf (string)',
            got  => sub { cluckf('Foo') },
            exp  => qr/Foo/,
        },
        {
            line => __LINE__, name => 'ok - cluckf (format-string, argument)',
            got  => sub { cluckf( 'Foo (%d)', 99 ) },
            exp  => qr/Foo \(99\)/,
        },
    );

    for my $t (@tests) {
        like(
            warning { $t->{got}->() }, $t->{exp},
            sprintf( 'line %d%s', $t->{line}, $t->{name} ? " $t->{name}" : '' ),
        );
    }
}


{
    my @tests = (
        {
            line => __LINE__, name => 'ok - carpf (no arguments)',
            got  => sub { carpf() },
            exp  => qr/Unhelpful warning/,
        },
        {
            line => __LINE__, name => 'ok - carpf (empty string)',
            got  => sub { carpf('') },
            exp  => qr/Unhelpful warning/,
        },
        {
            line => __LINE__, name => 'ok - carpf (string)',
            got  => sub { carpf('Foo') },
            exp  => qr/Foo/,
        },
        {
            line => __LINE__, name => 'ok - carpf (format-string, argument)',
            got  => sub { carpf( 'Foo (%d)', 99 ) },
            exp  => qr/Foo \(99\)/,
        },
    );

    for my $t (@tests) {
        like(
            warning { $t->{got}->() }, $t->{exp},
            sprintf( 'line %d%s', $t->{line}, $t->{name} ? " $t->{name}" : '' ),
        );
    }
}


{
    my @tests = (
        {
            line => __LINE__, name => 'ok - confessf (no arguments, $@ undefined)',
            got  => sub { confessf() },
            exp  => qr/Unknown error/,
        },
        {
            line => __LINE__, name => 'ok - confessf (no arguments, $@ defined)',
            got  => sub {
                eval { die 'Oh no, the foo!' };
                confessf();
            },
            exp => qr/Oh no, the foo!/,
        },
        {
            line => __LINE__, name => 'ok - confessd (empty string, $@ undefined)',
            got  => sub { confessf('') },
            exp  => qr/Unknown error/,
        },
        {
            line => __LINE__, name => 'ok - confessf (empty string, $@ defined)',
            got  => sub {
                eval { die 'Oh no, the foo!' };
                confessf('');
            },
            exp => qr/Oh no, the foo!/,
        },
        {
            line => __LINE__, name => 'ok - confessf (string)',
            got  => sub { confessf('Foo') },
            exp  => qr/Foo/,
        },
        {
            line => __LINE__, name => 'ok - confessf (format-string, argument)',
            got  => sub { confessf( 'Foo (%d)', 99 ) },
            exp  => qr/Foo \(99\)/,
        },
        {
            line => __LINE__, name => 'ok - confessf (exception object)',
            got  => sub { confessf( bless( {}, 'AnExceptionObject' ) ) },
            exp  => qr/AnExceptionObject=/,
        },
    );

    for my $t (@tests) {
        throws_ok { $t->{got}->() } $t->{exp},
            sprintf( 'line %d%s', $t->{line}, $t->{name} ? " $t->{name}" : '' );
    }
}


{
    my $sub1 = sub { 'DUMMY 1' };
    my $sub2 = sub { 'DUMMY 2' };
    my $sub3 = sub { 'DUMMY 3' };

    my @tests = (
        {
            line => __LINE__, name => 'ok - callbacks_args (no arguments)',
            got  => [ callbacks_args() ],
            exp  => [ [] ],
        },
        {
            line => __LINE__, name => 'ok - callbacks_args (single argument)',
            got  => [ callbacks_args(1) ],
            exp  => [ [], 1 ],
        },
        {
            line => __LINE__, name => 'ok - callbacks_args (multiple arguments)',
            got  => [ callbacks_args( 1, 2 ) ],
            exp  => [ [], 1, 2 ],
        },
        {
            line => __LINE__, name => 'ok - callbacks_args (single callback)',
            got  => [ callbacks_args($sub1) ],
            exp  => [ [$sub1] ],
        },
        {
            line => __LINE__, name => 'ok - callbacks_args (multiple callbacks)',
            got  => [ callbacks_args( $sub1, $sub2 ) ],
            exp  => [ [ $sub1, $sub2 ] ],
        },
        {
            line => __LINE__,
            name => 'ok - callbacks_args (single argument, single callback)',
            got  => [ callbacks_args( 1 => $sub1 ) ],
            exp  => [ [$sub1], 1 ],
        },
        {
            line => __LINE__,
            name => 'ok - callbacks_args (multiple arguments, single callback)',
            got  => [ callbacks_args( 1, 2 => $sub1 ) ],
            exp  => [ [$sub1], 1, 2 ],
        },
        {
            line => __LINE__,
            name => 'ok - callbacks_args (multiple arguments, multiple callbacks)',
            got  => [ callbacks_args( 1, 2 => $sub1, $sub2 ) ],
            exp  => [ [ $sub1, $sub2 ], 1, 2 ],
        },
        {
            line => __LINE__,
            name =>
                'ok - callbacks_args (multiple arguments, multiple callbacks, non-callback argument)',
            got => [ callbacks_args( 1, $sub1, 3 => $sub2, $sub3 ) ],
            exp => [ [ $sub2, $sub3 ], 1, $sub1, 3 ],
        },
    );

    for my $t (@tests) {
        is_deeply $t->{got}, $t->{exp},
            sprintf( 'line %d%s', $t->{line}, $t->{name} ? " $t->{name}" : '' );
    }
}


{
    for (
        {
            loc => __LINE__,
            got => [ has_callbacks( [] ) ],
            exp => [],
        },
        {
            loc => __LINE__,
            got => [ has_callbacks( [1] ) ],
            exp => [],
        },
        {
            loc => __LINE__,
            got => [ has_callbacks( [ 1, 2, 3 ] ) ],
            exp => [],
        },
        {
            loc => __LINE__,
            got => [ has_callbacks( [ sub { }, 1, 2, 3 ] ) ],
            exp => [],
        },
        {
            loc => __LINE__,
            got => [ has_callbacks( [ sub { } ] ) ],
            exp => [ 0, 1 ],
        },
        {
            loc => __LINE__,
            got => [ has_callbacks( [ 1, 2, 3, sub { } ] ) ],
            exp => [ 3, 1 ],
        },
    ) {
        is_deeply $_->{got}, $_->{exp}, "has_callbacks, line $_->{loc}";
    }
}

done_testing();
