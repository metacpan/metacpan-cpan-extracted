use 5.010;      # v5.8 equired for in-memory files; v5.10 required for named backreferences and // in the commented-note() calls
use strict;
use warnings;
use Test::More tests => 5 + 5*28 + 3 + 3;

use CAD::Mesh3D qw(+STL :all);

my $lft = createVertex(0,0,0);
my $rgt = createVertex(1,0,0);
my $mid = createVertex(sqrt(3/12),sqrt(9/12),sqrt(0/12));
my $top = createVertex(sqrt(3/12),sqrt(1/12),sqrt(8/12));

# note sprintf '%s = <%.9e,%.9e,%.9e>', lft => @$lft;
# note sprintf '%s = <%.9e,%.9e,%.9e>', rgt => @$rgt;
# note sprintf '%s = <%.9e,%.9e,%.9e>', mid => @$mid;
# note sprintf '%s = <%.9e,%.9e,%.9e>', top => @$top;

my $mesh = createMesh();
my $tri = createFacet($lft, $mid, $rgt);
# note sprintf '%-8.8s = <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e>', floor => map { @$_ } @$tri;
push @$mesh, $tri;

$tri = createFacet($lft, $rgt, $top);
# note sprintf '%-8.8s = <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e>', front => map { @$_ } @$tri;
push @$mesh, $tri;

$tri = createFacet($rgt, $mid, $top);
# note sprintf '%-8.8s = <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e>', right => map { @$_ } @$tri;
push @$mesh, $tri;

$tri = createFacet($mid, $lft, $top);
# note sprintf '%-8.8s = <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e>', left  => map { @$_ } @$tri;
push @$mesh, $tri;

# note '';
# note 'MESH:';
# note sprintf '%-8.8s   <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e> <%.9e,%.9e,%.9e>', '', map { @$_ } @$_ for @$mesh;

# define the expected values for the binary tests
my $expected_ubin = qr"................................................................................................................................................................04000000........................0000000000000000000000000000003fd7b35d3f000000000000803f00000000000000000000........................0000000000000000000000000000803f00000000000000000000003f3acd933eec05513f0000........................0000803f00000000000000000000003fd7b35d3f000000000000003f3acd933eec05513f0000........................0000003fd7b35d3f000000000000000000000000000000000000003f3acd933eec05513f0000";
    # expected unpacked bin.  comments that follow help describe what's going on...
    #                 "null header....................................................................................................................................................'########n1-----'n2-----'n3-----'a1-----'a2-----'a3-----'b1-----'b2-----'b3-----'c1-----'c2-----'c3-----'sss'n1-----'n2-----'n3-----'a1-----'a2-----'a3-----'b1-----'b2-----'b3-----'c1-----'c2-----'c3-----'sss'n1-----'n2-----'n3-----'a1-----'a2-----'a3-----'b1-----'b2-----'b3-----'c1-----'c2-----'c3-----'sss'n1-----'n2-----'n3-----'a1-----'a2-----'a3-----'b1-----'b2-----'b3-----'c1-----'c2-----'c3-----'sss'"
    # if the bigendian pack fails, it will be
    #                 "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000bf8000000000000000000000000000003f0000003f5db3d7000000003f8000000000000000000000000000000000bf715bef3eaaaaab0000000000000000000000003f80000000000000000000003f0000003e93cd3a3f5105ec00003f5105ec3ef15bef3eaaaaab3f80000000000000000000003f0000003f5db3d7000000003f0000003e93cd3a3f5105ec0000bf5105ec3ef15bef3eaaaaab3f0000003f5db3d7000000000000000000000000000000003f0000003e93cd3a3f5105ec0000"
    # 2018-Sep-18: converted to regular expression, where the header and normal vectors can be anything (required, since I've lost control over those when I switched to using CAD::Format::STL)

# define the expected values for the ascii tests
my $exp_ascii_aref = do {
    # automatically generate it: need to enforce roundoff, so match will be correct
    # 2018-Sep-19: no longer need normals, since those aren't compared (cannot control whether underlying library will include normals in saves or not)
    my @v = (
        [0,0,0], [5.0e-1, 8.6602540e-1, 0], [1,0,0],
        [0,0,0], [1,0,0], [5.0000000e-001,2.8867513e-001,8.1649658e-001],
        [1.0000000e+000, 0.0000000e+000, 0.0000000e+000], [5.0000000e-001, 8.6602540e-001, 0.0000000e+000], [5.0000000e-001, 2.8867513e-001, 8.1649658e-001],
        [5.0000000e-001, 8.6602540e-001, 0.0000000e+000], [0.0000000e+000, 0.0000000e+000, 0.0000000e+000], [5.0000000e-001, 2.8867513e-001, 8.1649658e-001],
    );

    # round the array coordinates
    foreach my $i ( 0 .. $#v ) {
        foreach my $j ( 0 .. 2 ) {
            $v[$i][$j] = 0 + sprintf '%.8f', $v[$i][$j];
        }
    }

    [@v];
};

# compare the expected values for the ascii tests
sub test_ascii {
    my($ascii_string, $expect_aref, $test_name) = @_;
    $test_name = "test_ascii::${test_name}";
    note "\n", $test_name;
    $ascii_string =~ s/\h+/ /gm;  # normalize horizontal whitespace
    $ascii_string =~ s/^\s+//gm;  # trim leading whitespace on any line
    $ascii_string =~ s/\s+$//gm;  # trim trailing whitespace on any line
    #note "-----\n", $ascii_string, "\n=====\n";
    $ascii_string =~ m/^solid *(?<name>\V*?)$(?<content>.*)^endsolid *\g{name}*$/ms;
    my $name = $+{name};
    #note "\t", name => "\t", $name;
    my $content = $+{content};
    #note "\t", content => "\t", $content;
    ok $content, "${test_name}: solid/endsolid has content";
    my @facets = $content =~ m/^facet *(.*?)\R+^endfacet$/gms;
    my $n = scalar @facets;
    is $n, 4, "${test_name}: has 4 facets";
    my @vectors;
    foreach my $facet ( @facets ) {
        #note "facet {\n", $facet, "\n}\n";
        my @nv = $facet =~ m/normal (\S+) (\S+) (\S+)/gms;
        #note "normal: [@nv]";
        is scalar(@nv), 3, "${test_name}: facet normal has three coordinates";
        $facet =~ m/^outer loop$(?<content>.*)^endloop$/ms;
        $content = $+{content};
        ok $content, "${test_name}: facet has loop content";
        #note "\t", loop_content => "\t", $content;
        my @verts = $facet =~ /^vertex \S+ \S+ \S+$/gms;
        is scalar(@verts), 3, "${test_name}: facet has three vertexes";
        foreach my $vstr ( @verts ) {
            $vstr =~ m/\Avertex (?<x>\S+) (?<y>\S+) (?<z>\S+)\Z/ms;
            my $pt = [map {0 + sprintf '%.8f', $_} @+{qw/x y z/}];
            #note pt => "\t[@$pt] = $pt";
            is scalar(@$pt), 3, "${test_name}: vertex has three coordinates";
            push @vectors, $pt;
        }
    }
    is scalar(@vectors), 12, "${test_name}: found a total of 12 vertices in all the facets";
    is_deeply \@vectors, $expect_aref, "${test_name}: vertices ok" or diag explain \@vectors;

    note "\n";
}

# loop through the mainline tests using in-memory file
foreach my $asc (undef, 0, qw(false binary bin true ascii asc), 1) {
    my $memory = '';
    open my $fh, '>', \$memory or die "in-memory handle failed: $!";
    $mesh->output(STL => $fh, $asc);
    close($fh);
    my $expected;
    my $is_ascii = 0;
    while(1) {
        my $nmesh = @$mesh;
        my $count = unpack 'L<', substr($memory, 80, 4);
        $is_ascii++, last   unless $nmesh == $count;
        my $exp_size =
            + 80 # eighty header bytes
            +  4 # four bytes for the length
            + $count * (
                + 4 # normal and three point vectors
                * 3 # three values per vector
                * 4 # four bytes per value
                + 2 # the trailing short (aka 'attribute byte count')
            );
        my $got_size = length($memory);
        $is_ascii++, last   unless $exp_size == $got_size;
        last;
    }
    if($is_ascii) {       # ascii
        chomp $memory;
        test_ascii( $memory, $exp_ascii_aref, sprintf 'mesh->output(STL => fh, "%s")', defined $asc ? $asc : '<undef>' );
    } else {                # binary (unpack to a string, then compare to regex)
        $memory = unpack 'H*', $memory;
        $expected = $expected_ubin;
        like( $memory, $expected, sprintf 'mesh->output(STL => fh, "%s"): binary file matches', defined $asc ? $asc : '<undef>');
    }
    #note sprintf "MEMORY[%8.8s] = '%s'\n", defined $asc ? $asc : '<undef>', $memory;
}

# also verify STDOUT, STDERR (both redirected to in-memory) STL output, as well as filesystem STL output using temporary files
{
    my $tdir;
    for my $try ( $ENV{TEMP}, $ENV{TMP}, '/tmp', '.' ) {
        next unless defined $try;
        # diag "before: ", $try;
        $try =~ s{\\}{/}gx if index($try, '\\')>-1 ;        # without the if-index, died with modification of read-only value on /tmp or .
        # diag "after:  ", $try;
        next unless -d $try;
        next unless -w _;
        $tdir = $try;
        last;
    }
    # diag "final: '", $tdir // '<undef>', "'";
    die "could not find a writeable directory" unless defined $tdir && -d $tdir && -w $tdir;

    my $f1 = $tdir.'/filename';
    my $f2 = $tdir.'/namefile.stl';

    # redirect STDOUT & STDERR
    my($memout,$memerr);
    open my $fh_out, '>&', \*STDOUT or die "cannot dup STDOUT: $!";
    close STDOUT; open STDOUT, '>', \$memout or die "cannot open in-memory STDOUT: $!";

    open my $fh_err, '>&', \*STDERR or die "cannot dup STDERR: $!";
    close STDERR; open STDERR, '>', \$memerr or die "cannot open in-memory STDERR: $!";

    $mesh->output(STL => $_, $_ eq $f2) for 'STDOUT', 'STDERR', $f1, $f2; # use ascii for f2

    close STDERR; open STDERR, '>&', $fh_err;
    close STDOUT; open STDOUT, '>&', $fh_out;

    $memout = unpack 'H*', $memout;
    $memerr = unpack 'H*', $memerr;
    my $slurp1 = do {
        local $/ = undef;
        $f1 .= '.stl' unless $f1 =~ /\.stl$/i;
        open my $fh, '<', $f1 or die "cannot read \"$f1\": $!";
        binmode $fh;
        my $ret = unpack 'H*', <$fh>;
        close $fh;
        #note qx/ls -l $f1/;
        unlink $f1 or diag "could not unlink \"$f1\": $!";
        $ret;
    };
    my $slurp2 = do {
        local $/ = undef;
        open my $fh, '<', $f2 or die "cannot read \"$f2\": $!";
        my $ret = <$fh>;
        #note qx/ls -l $f2/;
        close $fh;
        unlink $f2 or diag "could not unlink \"$f2\": $!";
        $ret;
    };

    like( $memout, $expected_ubin,  'mesh->output(STL => STDOUT > memfile, binary): binary file matches' );
    like( $memerr, $expected_ubin,  'mesh->output(STL => STDERR > memfile, binary): binary file matches' );
    like( $slurp1, $expected_ubin,  sprintf 'mesh->output(STL => "%s", binary): binary file matches', $f1 );
    test_ascii( $slurp2, $exp_ascii_aref, sprintf 'mesh->output(STL => "%s", ascii)', $f2 );

}

###### fault handling ######
use Test::Exception;

# output(): missing fh
throws_ok { output($mesh, 'STL') } qr/output.*: requires file handle or name/, 'Error Handling: output(missing fh)';

# output(): cannot write to fh
throws_ok { output($mesh, STL => '/path/does/not/exist') } qr/output.*: cannot write to/, 'Error Handling: output(missing fh)';

# output(): non-recognized $ascii argument
throws_ok { output($mesh, STL => \*STDERR, 'bad') } qr/output.*: unknown asc\/bin switch "bad"/, 'Error Handling: output(bad ascii switch)';

done_testing();
