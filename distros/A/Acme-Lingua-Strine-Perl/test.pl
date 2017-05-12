# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

package PrintHandle;
require Tie::Handle;

@ISA = (Tie::Handle);

sub TIEHANDLE 
{
	my $string;
	bless \$string, shift;
}

sub READLINE
{
	my $self = shift;
	return $$self;
}

sub PRINT 
{
	my $self = shift; 
	
	$$self = join $, ,  @_;

}

1;



######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use English;
use Acme::Lingua::Strine::Perl;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my @arr = qw (data munging with damian);

if (cadge @arr eq 'data')
{
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

eval 
{
	spit the dummy "strewth\n";

};
if ($@)
{
	print "ok 3\n";
} else {
	print "not ok 3\n";
}


$_ = shift @arr;

if (celador eq 'munging')
{
	print "ok 4\n";
} else {
	print "not ok 4\n";
}


if (bangers and mash == $FORMAT_PAGE_NUMBER)
{
	print "ok 5\n";
} else {
	print "not ok 5\n";
}


my $warned = 0;

my $old_sig = $SIG{__WARN__};
$SIG{__WARN__} = sub { $warned=1 };
 
eval 
{
	chyachk "crikey";
};

if ($warned) 
{
	print "ok 6\n";
} else {
	print "not ok 6\n";
}

$SIG{__WARN__} = $old_sig;



eval
{
	jack up;
};
unless ($@)
{
	print "ok 7\n";
} else {
	print "not ok 7\n";
}




if (bangers and mash == $FORMAT_PAGE_NUMBER)
{
	print "ok 8\n";
} else {
	print "not ok 8\n";
}

if (pash "uppercase" eq "UPPERCASE")
{
	print "ok 9\n";
} else {
	print "not ok 9\n";
}

if (squib "LOWERCASE" eq "lowercase")
{
	print "ok 10\n";
} else {
	print "not ok 10\n";
}

sub throw_another_shrimp_on_the_barbie
{
	my $return;
	rack off "ok";
	$return  = "not ok\n";

}

if (throw_another_shrimp_on_the_barbie() eq "ok")
{
	print "ok 11\n";
} else {
	print "not ok 11\n";
}

eval 
{
	my $yabber = "briiiiiiisveeeeegas";
	suss $yabber;
};
unless ($@)
{
	print "ok 12\n";	
} else {

	print "not ok 12\n";
}


tie (*FH, 'PrintHandle');

jeer FH "mucker";
if (<FH> eq "mucker")
{
	print "ok 13\n";
} else {
	print "not ok 13\n";
}

jeer FH "roo";
if (<FH> eq "roo")
{
	print "ok 14\n";
} else {
	print "not ok 14\n";
}

jeer FH "outback";
if (<FH> eq "outback")
{
	print "ok 15\n";
} else {
	print "not ok 15\n";
}



# no way to test to see if an exit 
# has succeeded /shurg/ (sic)
#eval 
#{
#	nick off;
#};
#unless ($@)
#{
#	print "ok 13\n";	
#} else {
#
#	print "not ok 13\n";
#}

