use strict;
use warnings;
use CGI::Session;
use File::Path qw(rmtree);

use Test::More tests => 6;

my @tmpdirs = qw(tmp1 tmp2);
for (@tmpdirs) {
	mkdir($_) || die "Couldn't make dir $_: $!\n";
}

END {
	rmtree($_) for @tmpdirs;
}


my %args = (
	full => { 
		Layers => [
		   {
		     Driver    => 'file',
		     Directory => $tmpdirs[0],
		   },
		   {
		     Driver    => 'file',
		     Directory => $tmpdirs[1],
		   }
		]
	},
	half => {
		Layers => [
		   {
		     Driver    => 'file',
		     Directory => $tmpdirs[1],
                   },
                ],
	},
);


my $full = CGI::Session->new("driver:layered", undef, $args{full});
$full->flush;
my $half = CGI::Session->new("driver:layered", $full->id, $args{half});
$half->flush;

isa_ok($full, 'CGI::Session');
isa_ok($half, 'CGI::Session');


#diag(Dumper($full, $half));


$full->param(t1 => $$);
$full->flush;

is($full->param('t1'), $$);

$half->param(t1 => $$ + 1);
$half->flush;

is($half->param('t1'), $$ + 1);

# reload full and see if it gets the newer value
$full = CGI::Session->new("driver:layered", $full->id, $args{full});

is($full->param('t1'), $$ + 1);


my $new = CGI::Session->new("driver:layered", undef, $args{half});
$new->param(t2 => $$);
$new->flush;

my $try = CGI::Session->new("driver:layered", $new->id, $args{full});

is($try->param('t2'), $$);
