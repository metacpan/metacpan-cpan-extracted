# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
use Storable qw(dclone);
BEGIN { plan tests => 12 };
use Data::SearchReplace;
ok(1); # If we made it this far, we're ok.

#########################

my %VAR = (
        ARRAY_TEST   => [qw(hi goodday greetings peace)],
        HASH_TEST    => { me => 'steve', myself => 'stephen', i => 'dead meat'},        SCALAR_TEST  => 'hello there',
        IMBED_ARRAY  => [[qw(hi hello)],[qw(pizza hut)]],
        IMBED_HASH   => { hello => { pizza => 'hut' },
                          bye   => { outa  => 'here' } },
        DEEP_IMBED   => { deep => { inside => [qw(the pit of dispair)],
                                    outside => { freedom => 'a dream' },
                                    upside  => [  ({ hi => 'there',
                                                     bi => 'not me' },
                                                   'hello world')],
                                  },
                          shallow => 'very shallow' } );
my @VAR = (
	   { microwave => ['hot stuff','small goodbye','radioactive'],
	     television => { meaning => 'long sight',
			     tele    => [qw(distance distant)],
			     vision  => "the faculty of sight" } },
	   'wonderful',
	   [qw(interesting side effects)] );

# 2.  quick test of sr exported...
my %test2 = %{dclone(\%VAR)};
Data::SearchReplace::sr({SEARCH => 'there', REPLACE => 'HERE'}, \%test2);
ok($test2{DEEP_IMBED}->{deep}->{upside}->[0]->{hi}, 'HERE');

# 3.  OO TEST
my $sr = Data::SearchReplace->new({SEARCH => 'here', REPLACE =>'THERE'});

my %test3 = %{dclone(\%VAR)};
   $sr->sr(\%test3);
ok($test3{IMBED_HASH}->{bye}->{outa}, 'THERE');

# 4.  on a second variable...
my %test4 = %{dclone(\%VAR)};
   $sr->sr(\%test4);
ok($test4{IMBED_HASH}->{bye}->{outa}, 'THERE');

# 5.  FULL REGEX TEST
my %test5 = %{dclone(\%VAR)};
   Data::SearchReplace::sr({REGEX => 's/\s(\w)/uc(" $1")/ge'}, \%test5);
ok($test5{HASH_TEST}->{i}, 'dead Meat');

# 6.  FULL REGEX and OO TEST
my %test6 = %{dclone(\%VAR)};
my $full_reg = Data::SearchReplace->new({ REGEX => 's/(\w+).*/$1/g' },
					  \%test6);
   $full_reg->sr(\%test6);
ok($test6{DEEP_IMBED}->{deep}->{upside}->[1], 'hello');

# 7.  on a second variable...
my %test7 = %{dclone(\%VAR)};
   $full_reg->sr(\%test7);
ok($test7{DEEP_IMBED}->{shallow}, 'very');

# 8.  array test
my @test8 = @{dclone(\@VAR)};
   $full_reg->sr(\@test8);
ok($test8[0]->{television}->{vision}, 'the');

# 9.  reference test
my $test9 = dclone(\@VAR);
   Data::SearchReplace::sr({ SEARCH => 'sight', REPLACE => 'vision' }, $test9);
ok($test9->[0]->{television}->{meaning}, 'long vision');

# 10. toss in an object and be sure it still works
my @test10 = @{dclone(\@VAR)};
   splice(@test10, 1,0,bless {});
   Data::SearchReplace::sr({ SEARCH => 'sight', REPLACE => 'vision'}, \@test10);
ok($test10[0]->{television}->{meaning}, 'long vision');

# 11. test of the CODE function
my @test11 = @{dclone(\@VAR)};
   Data::SearchReplace::sr({ CODE => sub { uc($_[0]) } }, \@test11);
ok($test11[0]->{television}->{tele}->[1], 'DISTANT');

# 12. counter test
my %test12 = %{dclone(\%VAR)};
my $count = $sr->sr(\%test12);
ok($count == 3);
