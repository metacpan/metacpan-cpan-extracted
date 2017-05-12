$|++;
use strict;
use Test::More;

plan skip_all => "upgrade_db.pl doesn't actually do anything correct.";

# Add skips here
BEGIN {
    plan skip_all => "Skipping the upgrade_db.pl tests on Win32/cygwin for now."
        if ( $^O eq 'MSWin32' || $^O eq 'cygwin' );

    plan skip_all => "Skipping the upgrade_db.pl tests on *bsd for now."
        if ( $^O =~ /bsd/i );

    my @failures;
    eval "use Pod::Usage 1.3;"; push @failures, 'Pod::Usage' if $@;
    eval "use FileHandle::Fmode;"; push @failures, 'FileHandle::Fmode' if $@;
    if ( @failures ) {
        my $missing = join ',', @failures;
        plan skip_all => "'$missing' must be installed to run these tests";
    }
}

plan tests => 351;

use t::common qw( new_fh );
use File::Spec;
use Test::Deep;

my $PROG = File::Spec->catfile( qw( utils upgrade_db.pl ) );

my $short = get_pod( $PROG, 0 );
my $long = get_pod( $PROG, 1 );

is( run_prog( $PROG ), "Missing required parameters.\n$long", "Failed no params" );
is( run_prog( $PROG, '-input foo' ), "Missing required parameters.\n$long", "Failed only -input" );
is( run_prog( $PROG, '-output foo' ), "Missing required parameters.\n$long", "Failed only -output" );
is(
    run_prog( $PROG, '-input foo', '-output foo' ),
    "Cannot use the same filename for both input and output.\n$short",
    "Failed same name",
);

is(
    run_prog( $PROG, '-input foo', '-output bar' ),
    "'foo' is not a file.\n$short",
    "Failed input does not exist",
);

my (undef, $input_filename) = new_fh();
my (undef, $output_filename) = new_fh();

is(
    run_prog( $PROG, "-input $input_filename", "-output $output_filename" ),
    "'$input_filename' is not a DBM::Deep file.\n$short",
    "Input is not a DBM::Deep file",
);

unlink $input_filename;unlink $output_filename;

# All files are of the form:
#   $db->{foo} = [ 1 .. 3 ];

my @input_files = (
    '0-983',
    '0-99_04',
    '1-0000',
    '1-0003',
);

my @output_versions = (
    '0.91', '0.92', '0.93', '0.94', '0.95', '0.96', '0.97', '0.98',
    '0.981', '0.982', '0.983',
    '0.99_01', '0.99_02', '0.99_03', '0.99_04',
    '1.00', '1.000', '1.0000', '1.0001', '1.0002',
    '1.0003', '1.0004', '1.0005', '1.0006', '1.0007', '1.0008', '1.0009', '1.0010',
    '1.0011', '1.0012', '1.0013', '1.0014', '2.0000'
);

foreach my $input_filename (
    map { 
        File::Spec->catfile( qw( t etc ), "db-$_" )
    } @input_files
) {
    # chmod it writable because old DBM::Deep versions don't handle readonly
    # files correctly. This is fixed in DBM::Deep 1.0000
    chmod 0600, $input_filename;

    foreach my $v ( @output_versions ) {
        my (undef, $output_filename) = new_fh();

        my $output = run_prog(
            $PROG,
            "-input $input_filename",
            "-output $output_filename",
            "-version $v",
        );

        #warn "Testing $input_filename against $v\n";

        # Clone was removed as a requirement in 1.0006
        if ( $output =~ /Can\'t locate Clone\.pm in \@INC/ ) {
            ok( 1 );
            unless ( $input_filename =~ /_/ || $v =~ /_/ ) {
                ok( 1 ); ok( 1 );
            }
            next;
        }

        if ( $input_filename =~ /_/ ) {
            is(
                $output, "'$input_filename' is a dev release and not supported.\n$short",
                "Input file is a dev release - not supported",
            );

            next;
        }

        if ( $v =~ /_/ ) {
            is(
                $output, "-version '$v' is a dev release and not supported.\n$short",
                "Output version is a dev release - not supported",
            );

            next;
        }

        # Now, read the output file with the right version.
        ok( !$output, "A successful run produces no output" );
        die "'$input_filename' -> '$v' : $output\n" if $output;

        my $db;
        my $db_version;
        if ( $v =~ /^2(?:\.|\z)/ ) {
            push @INC, 'lib';
            eval "use DBM::Deep 1.9999"; die $@ if $@;
            $db = DBM::Deep->new( $output_filename );
            $db_version = 2;
        }
        elsif( $v =~ /^1\.001[0-4]/ || $v =~ /^1\.000[3-9]/ ) {
            push @INC, 'lib';
            eval "use DBM::Deep $v"; die $@ if $@;
            $db = DBM::Deep->new( $output_filename );
            $db_version = '1.0003';
        }
        elsif ( $v =~ /^1\.000?[0-2]?/ ) {
            push @INC, File::Spec->catdir( 'utils', 'lib' );
            eval "use DBM::Deep::10002";
            $db = DBM::Deep::10002->new( $output_filename );
        }
        elsif ( $v =~ /^0/ ) {
            push @INC, File::Spec->catdir( 'utils', 'lib' );
            eval "use DBM::Deep::09830";
            $db = DBM::Deep::09830->new( $output_filename );
        }
        else {
            die "How did we get here?!\n";
        }

        ok( $db, "Writing to version $v made a file" );

        cmp_deeply(
            $db->export,
            { foo => [ 1 .. 3 ] },
            "We can read the output file",
        );

        if($db_version) {
            is $db->db_version, $db_version, "db_version is $db_version";
        }
    }
}

################################################################################

#XXX This needs to be made OS-portable
sub run_prog {
    open( my $fh, '-|', "$^X @_ 2>&1" )
      or die "Cannot launch '@_' as a piped filehandle: $!\n";
    return join '', <$fh>;
}

# In 5.8, we could use in-memory filehandles and have done:
#     open( my $fh, '>', \my $pod ) or die "Cannot open in-memory filehandle: $!\n";
#     ...
#     return $pod;
# However, DBM::Deep requires 5.6, so this set of contortions will have to do.
sub get_pod {
    my ($p,$v) = @_;

    my ($fh, $fn) = new_fh();
    close $fh;

    open $fh, '>', $fn;
    pod2usage({
        -input   => $p,
        -output  => $fh,
        -verbose => $v,
        -exitval => 'NOEXIT',
    });
    close $fh;

    open $fh, '<', $fn;
    return join '', <$fh>;
}
