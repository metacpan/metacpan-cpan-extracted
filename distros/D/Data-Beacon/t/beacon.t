#!perl -Tw

use strict;
use warnings;

use Test::More;

use_ok('Data::Beacon');

done_testing;
__END__
my $r;
my $b = new Data::Beacon();
isa_ok($b,'Data::Beacon');

$b = beacon();
isa_ok($b,'Data::Beacon');
is( $b->errors, 0 );

# meta fields
my %m = $b->meta();
is_deeply( \%m, { 'FORMAT' => 'BEACON' }, 'meta()' );

is_deeply( $b->meta('fOrMaT'), 'BEACON' );
is_deeply( $b->meta('foo'), undef );
is_deeply( $b->meta( {} ), undef );

# not allowed or bad arguments
my @badmeta = (
 [ 'a','b','c' ],
 [ 'format' => '' ],
 [ ' ' => 'x' ],
 [ '~' => 'x' ],
 [ 'prefix' => 'htt' ],    # invalid PREFIX
 [ 'Feed' => 'http://#' ], # invalid FEED
);
foreach my $bad (@badmeta) {
    eval { $b->meta( @$bad ); }; ok( $@ );
    if (@$bad == 2 && $bad->[0] ne ' ') {
        my $line = '#' . join(': ',@$bad) . "\n";
        my $c = beacon( \$line );
        is( $c->errors, 1, 'bad meta field' );
    }
}
is( $b->errors, 0, 'croaking errors are not counted' );

$b->meta( 'prefix' => 'http://foo.org/' );
is_deeply( { $b->meta() }, { 'FORMAT' => 'BEACON', 'PREFIX' => 'http://foo.org/' } );
$b->meta( 'prefix' => 'u:' ); # URI prefix
$b->meta( 'prefix' => '' );

# expandsource
$b = beacon({PREFIX => 'http://foo.org/'});
is( $b->expandsource( 0 ), 'http://foo.org/0', 'expandsource' );
is( $b->expandsource( '' ), '', 'expandsource' );
is( $b->expandsource( undef ), '', 'expandsource' );
is( beacon()->expandsource( 'x' ), '', 'expandsource' );
is( beacon()->expandsource( 'id:0' ), 'id:0', 'expandsource' );
is( beacon()->expandsource( undef ), '', 'expandsource' );
$b->meta('prefix' => undef);

eval { $b->meta( 'revisit' => 'Sun 3rd Nov, 1943' ); }; 
ok( $@ , 'detect invalid REVISIT');
$b->meta( 'REvisit' => '2010-02-31T12:00:01' );
is_deeply( { $b->meta() }, 
  { 'FORMAT' => 'BEACON', 
    'REVISIT' => '2010-03-03T12:00:01' } );
$b->meta( 'REVISIT' => '' );

is( $b->meta( 'EXAMPLES' ), undef );
$b->meta( 'EXAMPLES', 'foo | bar||doz ' );
is( $b->meta('EXAMPLES'), 'foo|bar|doz', 'EXAMPLES' );
$b->meta( 'EXAMPLES', '|' );
is( $b->meta('EXAMPLES'), undef );
$b->meta( 'EXAMPLES', '' );

my $expected = { 'FORMAT' => 'BEACON', 'FOO' => 'bar', 'X' => 'YZ' };
$b->meta('foo' => 'bar ', ' X ' => " Y\nZ");
is_deeply( { $b->meta() }, $expected );
$b->meta('foo',''); # unset
is_deeply( { $b->meta() }, { 'FORMAT' => 'BEACON', 'X' => 'YZ' } );

eval { $b->meta( 'format' => 'foo' ); }; ok( $@, 'detect invalid FORMAT' );
$b->meta( 'format' => 'FOO-BEACON' );
is( $b->meta('format'), 'FOO-BEACON' );

is( $b->meta('COUNT'), undef, 'meta("COUNT")' );
is( $b->count, 0, 'count()' );
$b->meta('count' => 7);
is( $b->count, 7, 'count()' );
is( $b->line, 0, 'line()' );

# {ID} or {LABEL} in #TARGET optional
$b->meta( 'target' => 'u:ri:' );
is ( $b->meta('target'), 'u:ri:{ID}' );

$b = beacon( $expected );
is_deeply( { $b->meta() }, $expected );
is( $b->errors, 0 );

my ($haserror, @l);

$b = beacon( errors => sub { $haserror = 1; } ); 
$b->meta('PREFIX','x:');
#ok( $b->appendlink('0','','','0'), 'zero is valid source' );
#ok( !$b->errors && !$haserror, 'error handler not called' );

$b = beacon( $expected, errors => sub { $haserror = 1; } ); 
ok( !$b->errors && !$haserror, 'error handler' );

$b->appendlink('0');
ok( $b->errors && $haserror, 'error handler' );

$b = beacon();
$b->meta( 'feed' => 'http://example.com', 'target' => 'http://example.com/{ID}' );

$b = beacon();
ok (! $b->appendline( undef ), 'undef line');

my %t;

=head1
# split BEACON format link without validating or expanding

# line parsing (invalid URI not checked)
%t = (
  "qid" => ["qid","","",""],
  "qid|\t" => ["qid","","",""],
  "qid|" => ["qid","","",""],
  "qid|lab" => ["qid","lab","",""],
  "qid|  lab |dsc" => ["qid","lab","dsc",""],
  "qid| | dsc" => ["qid","","dsc",""],
  " qid||dsc" => ["qid","","dsc",""],
  "qid |u:ri" => ["qid","","","u:ri"],
  "qid |lab  |dsc|u:ri" => ["qid","lab","dsc","u:ri"],
  "qid|lab|u:ri" => ["qid","lab","","u:ri"],
  " \t" => [],
  "" => [],
  "qid|lab|dsc|u:ri|foo" => ["qid","lab","dsc","u:ri"]
  "|qid|u:ri" => [],
  "qid|lab|dsc|abc" => "URI part has not valid URI form: abc",
);
while (my ($line, $link) = each(%t)) {
    # my @l = $b->appendline( $line );
use Data::Dumper;
print "L:$line\n";
print Dumper(\@l)."\n";
    #$r = parsebeaconlink( $line ); # without prefix or target
    #is_deeply( \@l, $link );
}
=cut

# with prefix and target
$b = beacon({PREFIX=>'x:',TARGET=>'y:'});
ok( $b->appendline( "0|z" ), 'appendline, scalar' );

%t = ("qid |u:ri" => ['qid','u:ri','','']);
while (my ($line, $link) = each(%t)) {
    ok( $b->appendline( $line ), 'appendline, scalar' );

    my @l = $b->appendline( $line );
    @l = @l[0..3];
    is_deeply( \@l, $link, 'appendline, list' );
    # TODO: test fullid and fulluri

    ok( $b->appendlink( @l ), 'appendlink, scalar' );

    my @l2 = $b->appendlink( @l );
    @l2 = @l2[0..3];
    is_deeply( \@l2, $link, 'appendlink, list' );
}

# with prefix only
$b = beacon({PREFIX=>'x:'});
%t = ( 
  'a|b|http://example.com/bar' => ['x:a','b','','http://example.com/bar'],
  "a|b|http://example.com/bar\n" => ['x:a','b','','http://example.com/bar']  
);
while (my ($line, $link) = each(%t)) {
    ok( $b->appendline($line) );
    $b->expanded; # multiple calls should not alter the link
    $line =~ s/\n//;
    is_deeply( [ $b->expanded ], $link, "expanded with PREFIX: $line" );
}

# file parsing
$b = beacon("~");
is( $b->errors, 1, 'failed to open file' );

$b = beacon( undef );
is( $b->errors, 0, 'no file specified' );

$b = beacon( "t/beacon1.txt" );
is_deeply( { $b->meta() }, {
  'FORMAT' => 'BEACON',
  'TARGET' => 'http://example.com/{ID}',
  'FOO' => 'bar doz',
  'PREFIX' => 'x:'
}, "parsing meta fields" );

is( $b->line, 6, 'line()' );
$b->parse();
is( $b->errors, 0 );
is( $b->count, 7 );

$b->parse("~");
is( $b->errors, 1 );

my $e = $b->lasterror;
is( $e, 'Failed to open ~', 'lasterror, scalar context' );

my @es = $b->lasterror;
is_deeply( \@es, [ 'Failed to open ~', 0, '' ], 'lasterror, list context' );

$b->parse( { } );
is( $b->errors, 1, 'cannot parse a hashref' );

# string parsing
$b->parse( \"x:from|x:to\n\n|comment" );
is( $b->count, 1, 'parse from string' );

is( $b->line, 3, '' );
is_deeply( [$b->link], ['x:from','','','x:to'] );
is_deeply( [$b->expanded], ['x:from','','','x:to'] );

$b->parse( \"\xEF\xBB\xBFx:from|x:to", links => sub { @l = @_; } );
is( $b->line, 1 );
is( $b->errors, 0 );
is_deeply( \@l, [ 'x:from', '', '', 'x:to' ], 'BOM' );


my @tmplines = ( '#FOO: bar', '#DOZ', '#BAZ: doz' );
$b->parse( from => sub { return shift @tmplines; } );
is( $b->line, 3, 'parse from code ref' );
is( $b->count, 0, '' );
is( $b->metafields, "#FORMAT: BEACON\n#BAZ: doz\n#FOO: bar\n#COUNT: 0\n" );
is( $b->link, undef, 'no links' );

$b->parse( from => sub { die 'hard'; } );
is( $b->errors, 1 );
ok( $b->lasterror =~ /^hard/, 'dead input will not kill us' );

# expected examples
$b = beacon( \"#EXAMPLES: a:b|c:d\na:b|to:1\nc:d|to:2" );
ok( $b->parse() );

$b = beacon( \"#EXAMPLES: a:b|c\na:b|to:1" );
$b->parse();
is_deeply( [ $b->lasterror ], [ 'examples not found: c',2,''], 'examples' );

$b = beacon( \"#EXAMPLES: a\n#PREFIX x:\na|to:1" );
ok( $b->parse() );

$b = beacon( \"#EXAMPLES: x:a\n#PREFIX x:\na|to:1" );
ok( $b->parse() );

# ensure that IDs are URIs
$b = beacon( \"xxx |foo" );
$b->parse();
is_deeply( [ $b->lasterror ], [ 'source is no URI: xxx',1,'xxx |foo' ], 
            'skipped non-URI id' );

# pull parsing
$b = beacon( \"\nid:1|t:1\n|comment\n" );
is_deeply( [$b->nextlink], ["id:1","","","t:1"] );
is_deeply( [$b->expanded], ["id:1","","","t:1"] );
is_deeply( [$b->nextlink], [] );
is_deeply( [$b->link], ["id:1","","","t:1"], 'last link' );

$b = beacon( \"id:1|t:1\na b|\nid:2|t:2" );
is_deeply( [$b->nextlink], ["id:1","","","t:1"] );
# a b| is ignored
is_deeply( [$b->nextlink], ["id:2","","","t:2"] );
is_deeply( [$b->link], ["id:2","","","t:2"] );
ok( !$b->nextlink );
is( $b->errors, 1 );
is_deeply( [ $b->lasterror ], [ 'source is no URI: a b',2,'a b|' ] );

# check method 'plainbeaconlink'
my @p = ( 
    ["",""],
    ["","","","http://example.com"]
);
while (@p) {
    my $in = shift @p;
    is( plainbeaconlink( @{$in} ), '', 'plainbeaconlink = ""');
}

@p = (
    ["a","b","c ",""], "a|b|c",
    ["a"," b","",""], "a|b",
    ["a","","",""], "a",
    ["a"," b ","c"," z"] => 'a|b|c|z',
    ["a","","","z"] => 'a|||z',
    ["a"," "," b "] => 'a||b',
);
while (@p) {
    my $in = shift @p;
    my $out = shift @p;
    my $line = plainbeaconlink( @{$in} );
    is( $line, $out, 'plainbeaconlink');

    $line = "#PREFIX: http://example.org/\n$line";
    $b = beacon( \$line );
    ok( !$b->parse ); # TARGET is not an URI

    $line = "#TARGET: foo:{ID}\n$line";
    $b = beacon( \$line );
    my $l = [$b->nextlink];
    @$in = map { s/^\s+|\s+$//g; $_; } @$in;
    push (@$in,'') while ( @$in < 4 );

    is_deeply( $in, $l, 'plainbeaconlink + PREFIX + TARGET' );

    my @exp = @$in;
    my $id = $in->[0];
    $exp[0] = "http://example.org/$id";
    $exp[3] = "foo:$id";
    is_deeply( [$b->expanded], \@exp, 'plainbeaconlink + PREFIX + TARGET' );
}

@p = ( # with 'to' field
#    ["a","b","","u:ri"] => 'a|b|u:ri',
#    ["a","","",""] => 'a|u:ri',
    ["a","b","","foo:x"], "a|b|foo:x",
    ["a","","","foo:x"], "a|foo:x",
    ["a","b","c","foo:x"], "a|b|c|foo:x",
    #["x","a||","","http://example.com|"], "x|a|http://example.com",
    #["x","","|d","foo:bar"], "x||d|foo:bar",
    #["x","|","","http://example.com"], "x|http://example.com",
);
while (@p) {
    my $in = shift @p;
    my $out = shift @p;
    my $line = plainbeaconlink( @{$in} );
    is( $line, $out, 'plainbeaconlink');

    @$in = map { s/\|//g; $_; } @$in;
    $line = "#PREFIX: http://example.org/\n$line";
    $b = beacon( \$line );

    my $l = [$b->nextlink];
    #pop @$l; # fullid
    #pop @$l; # fulluri
    
    is_deeply($l, $in);
}

# ignore additional params
is('x', plainbeaconlink('x','','','','foo','bar'));

# link expansion

$b = beacon( \"#TARGET: http://foo.org/{LABEL}\nf:rom|x" );
is_deeply( [$b->nextlink], ['f:rom','x','',''] );
is_deeply( [$b->expanded], ['f:rom','x','',,'http://foo.org/x'] );

$b = beacon( \"#TARGET: http://foo.org/{ID}\nx:y" );
is_deeply( [$b->nextlink], ['x:y','','',''] );
is_deeply( [$b->expanded], ['x:y','','',,'http://foo.org/x:y'] );


$b = beacon( \"#PREFIX: u:\n#TARGET: z:{ID}\n\$1" );
is_deeply( [$b->nextlink], ['$1','','','']);
is_deeply( [$b->expanded], ['u:$1','','','z:$1'] );

$b = beacon( \"a:b|c:d" );
is_deeply( [$b->nextlink], ['a:b','','','c:d']);
is_deeply( [$b->expanded], ['a:b','','','c:d'] );

$b = beacon( \"#TARGET: f:{ID}\na:b|c:d" );
is_deeply( [$b->nextlink], ['a:b','c:d','',''] );
is_deeply( [$b->expanded], ['a:b','c:d','','f:a:b'], 'TARGET changes parsing' );

$b = beacon( \"#TARGET: f:{LABEL}\na:b|c:d" );
is_deeply( [$b->nextlink], ['a:b','c:d','','']);
is_deeply( [$b->expanded],['a:b','c:d','','f:c%3Ad'], 'TARGET changes parsing' );

# croaking link handler
$b = beacon( \"#TARGET: f:{LABEL}\na:b|c:d", links => sub { die 'bad' } );
ok(! $b->parse );
ok( $b->lasterror =~ /^link handler died: bad/, 'dead link handler' );

# pre meta fields
$b = beacon( 't/beacon1.txt', 'pre' => { 'BAR' => 'doz', 'prefix' => 'y:' } );
is( $b->meta('bar'), 'doz', 'pre meta fields' );
is( $b->meta('prefix'), 'x:' );
# is( $b->line, 0 ); # 6

$b->parse( \"#PREFIX: z:" );
is( $b->meta('bar'), 'doz' );
is( $b->meta('prefix'), 'z:' );

$b->parse( \"#PREFIX: z:", pre => undef );
is( $b->meta('bar'), undef );

done_testing;
