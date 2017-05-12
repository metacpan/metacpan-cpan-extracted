use strict;
use Cwd;
use File::Spec;

### Comment configuration ###
my $Conf = {
        C   => {
            start       => '/*',
            end         => '*/',
        },
        HTML    => {
            start       => '<!--',
            end         => '-->',
        },
        RUBY    => {
            start       => '=begin',
            end         => '=end',
            single      => '#',
        },
        JAVA    => {
            start       => '/*',
            end         => '*/',
            single      => '//',
        },
        PASCAL  => {
            start       => '(*',
            end         => '*)',
        },

        ALGOL  => {
            start       => "'comment'",
            end         => ';',
        },

        HUGO    => {
            start       => '!\\',
            end         => '\!',
        },

        BASIC   =>  {
            single      =>  q['],
        },
        PILOT   =>  {
            single      => '\/\/',
        },
        #BLUE   =>  {
        #    single      => '(?:==)|(?:--)',
        #},
        #INTERCAL    => {
        #    single  => '(?:\(\d+\)\s*)?DO NOTE THAT',
        #},
        FORTRAN     => {
            single  => '!',
        },
        PERL        => {
            single      => q[#],
        },
        ALAN        => {
            single      => "--",
        },
        ORTHOGONAL  => {
            single      => ";",
        },
        FOCAL  => {
            single      => "comment",
        },
        LATEX  => {
            single      => "%",
        },
        FOXBASE => {
            single      => '(?:\*)|(?:&&)',
        }     
};
### the comment styles for ADA and Basic are the same ###
for my $type(qw|ADA|)                               { $Conf->{$type} = $Conf->{'BASIC'} }

for my $type(qw|POSTSCRIPT|)                        { $Conf->{$type} = $Conf->{'LATEX'} }

for my $type(qw|ADVSYS LISP SCHEME|)                { $Conf->{$type} = $Conf->{'ORTHOGONAL'} }

for my $type(qw|EIFFEL HASKELL|)                    { $Conf->{$type} = $Conf->{'ALAN'} }

for my $type(qw|BETA BLISS JOY VAR'AQ|)             { $Conf->{$type} = $Conf->{'PASCAL'} }

for my $type(qw|B PL/I CHILL|)                      { $Conf->{$type} = $Conf->{'C'} }

for my $type(qw|C++ PHP C# CLEAN ELASTIC GUILE|)    { $Conf->{$type} = $Conf->{'JAVA'} }

for my $type(qw|PYTHON PARROT AWK UNLAMBDA E ICON|) { $Conf->{$type} = $Conf->{'PERL'} }

my $To_Test = [
    { one_line => 0, own_line => 1 },
    { one_line => 1, own_line => 1 },
    { one_line => 0, own_line => 0 },
    { one_line => 1, own_line => 0 },
];

### write our test suite dynamically ###
my $cwd = cwd();
for my $type (keys %$Conf) {

    my $name = $type;
    $name =~ s/\W//g;

    for my $test (@$To_Test) {

        ### filename to write to
        my $file = File::Spec->catfile(
                                    $cwd,
                                    "t",
                                    $name
                                    . '-' .
                                    'one_line_' .
                                    scalar $test->{one_line}
                                    . '-' .
                                    'own_line_' .
                                    scalar $test->{own_line}
                                    . '.t'
                                );

        ### status indication for Test::More ###
        my $what = "own_line: $test->{own_line}, one_line: $test->{one_line}";


        my $fh;
        unless(-e $file and -s $file) {

            open $fh, ">$file" or die qq[Could not open file $file for writing: $!];


            ### perl get's confused if we type 'use' like this, so we put it in a var.
            my $u = 'use';
            
            ### the dir to include to find our latest Acme::Comment ###
            my $dir = File::Spec->catdir( cwd, 'lib' );

            print $fh <<HERE;
BEGIN { unshift \@INC, '$dir'; }

$u strict;
$u Test::More q[no_plan];

$u Acme::Comment 1.01 type => "$type", one_line => $test->{one_line}, own_line => $test->{own_line};


HERE
            my $start   = $Conf->{$type}->{start};
            my $end     = $Conf->{$type}->{end};
            my $single  = $Conf->{$type}->{single};


            START_END: {
            if( $start && $end ) {

                OWNLINE: {
                if ( !$test->{own_line} ) {

                    ### ALGOL has ; to end it's comments
                    ### so you can't use it with own_line
                    if( $type eq 'ALGOL' ) {
                        print $fh "SKIP:{skip(q[You cannot use 'own_line' with ALGOL],3)}";
                        last START_END;
                    }

                    print $fh <<HERE;
SKIP: {
    ### Test 1 ###
    my \$one = 1;

    $start \$one = 2;
    $end

    ### Check Test 1 ###
    is(\$one, 1, "$type => $what: Standard Multiline");



    ### Test 2 ###
    my \$two = 2;

    $start \$two = 3; $start \$two = 4;
    $end \$two = 5; $end

    ### Check Test 2 ###
    is(\$two, 2, "$type => $what: Nested Multiline");



    ### Test 3 ###
    eval {
        $start this should break
        $end
        1;
    };

    ### Check 3 ###
    ok(!\$@, "$type => $what: Broken Syntax Ignored Multiline");
}
HERE

                } }

                ONELINE: {
                if( $test->{one_line} ) {

                    print $fh <<HERE;
SKIP: {
    ### Test 4 ###
    my \$four = 4;

    $start \$four= 5; $end

    ### Check Test 1 ###
    is(\$four, 4, "$type => $what: Standard Multiline");



    ### Test 5 ###
    my \$five = 5;

    $start \$five = 7; $start \$five = 8; $end \$five = 9; $end

    ### Check Test 5 ###
    is(\$five, 5, "$type => $what: Nested Multiline");


    ### Test 6 ###
    eval {
        $start this should break $end
        1;
    };

    ### Check 6 ###
    ok(!\$@, "$type => $what: Broken Syntax Ignored Multiline");
}
HERE
                } }

                STANDARD: {
                print $fh <<HERE;
### Test 7 ###
my \$seven = 7;

$start
    \$seven = 8;
$end

### Check Test 7 ###
is(\$seven, 7, "$type => $what: Standard Multiline");



### Test 8 ###
my \$eight = 8;

$start
    \$eight = 9;
    $start
        \$eight = 10;
    $end
    \$eight = 11;
$end

### Check Test 8 ###
is(\$eight, 8, "$type => $what: Nested Multiline");

### Test 9 ###
eval {
    $start
        this should break
    $end
    1;
};

### Check 9 ###
ok(!\$@, "$type => $what: Broken Syntax Ignored Multiline");

HERE
                }
            } }

            SINGLE: {
            if($single) {
                    print $fh <<HERE;

my \$ten = 10;
$single \$ten = 11;

is(\$ten, 10, "$type => $what: Standard Single Line");

HERE
            } }


        close $fh;
        }
    }

}

### write the Makefile ###
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'Acme::Comment',
	VERSION_FROM	=> 'lib/Acme/Comment.pm', # finds $VERSION
	
	PREREQ_PM		=> {
		'Filter::Simple'    => 0,
		'Test::More'        => 0,
    'Text::Balanced'    => 1.99,
	},
);
