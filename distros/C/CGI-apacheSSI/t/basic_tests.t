# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl basic_tests.t'

#########################

use strict;
use warnings;
# use warnings FATAL => 'all'; # https://rt.cpan.org/Public/Bug/Display.html?id=108412#txn-1587110

use Test::More tests => 15;

use List::Util qw(sum);
use File::Temp qw(tempfile tempdir);
use IO::File;

# 1
use_ok('CGI::apacheSSI');
#########################
# all these tests were part of the CGI::SSI test vector, with a couple of edits (eg, removed deprecated calls)
#########################

# 2
# set and echo

{
    my $ssi = CGI::apacheSSI->new();
    $ssi->set(var => 'value');
    my $value = $ssi->echo('var');
    ok($value eq 'value','set/echo 1');
}

# 3
# other ways to call set and echo

{
    my $ssi = CGI::apacheSSI->new();
    $ssi->set(var => "var2", value => "value2");
    my $value = $ssi->echo(var => 'var2');
    ok($value eq 'value2','set/echo 2');
}

# 4
# objects don't crush each other's vars.

{
    my $ssi = CGI::apacheSSI->new();
    my $ssi2 = CGI::apacheSSI->new();

    $ssi->set(var => "value");
    $ssi2->set(var => "value2");

    my $value  = $ssi->echo("var");
    my $value2 = $ssi2->echo("var");

    ok($value eq "value" && $value2 eq "value2",'data encapsulation');
}

# 5
# args to new()

{
    my $ssi = CGI::apacheSSI->new(
			    DOCUMENT_URI  => "doc_uri",
			    DOCUMENT_NAME => "doc_name",
			    DOCUMENT_ROOT => "/",
			    errmsg        => "[ERROR!]",
			    sizefmt       => "bytes",
                timefmt       => "%B",
			    );
    ok(   ($ssi->echo("DOCUMENT_URI")  eq "doc_uri"
       and $ssi->echo("DOCUMENT_NAME") eq "doc_name"
       and $ssi->echo("DOCUMENT_ROOT") eq "/"),'new()');
}

# 6,7,8
# config

{
    my %months = map { ($_,1) } qw(January February March April May June 
                                   July August September October November December);

        # create a tmp file for testing.
   # use POSIX qw(tmpnam); # Calling POSIX::tmpnam() is deprecated In perl 5.22    
    my($fh,$filename) = File::Temp::tempfile();
    print $fh ' ' x 10;

    my $ssi = CGI::apacheSSI->new();
    $ssi->config(timefmt => "%B");
# 6
    ok($months{ $ssi->flastmod(file => $filename) },'config 1');

    $ssi->config(sizefmt => "bytes"); # TODO: combine these calls to config.

    my $size = $ssi->fsize(file => $filename);
# 7
    ok($size eq int $size,'config 2');

    $ssi->config(errmsg => "error"); # TODO combine config calls

	# close STDERR for this test
	open COPY,'>&STDERR' or die "no copy of STDERR: $!";
	close STDERR;

	# perform the test
# 8
    ok($ssi->flastmod("") eq "error",'config 3');

	# re-open STDERR and continue
	open STDERR,">&COPY" or die "no reassign to STDERR: $!";

    unlink $filename;
}


# flastmod - different input
# fsize - different input

# derive a class, and do something simple (empty class)

# 9
{
    package CGI::apacheSSI::Empty;
    @CGI::apacheSSI::Empty::ISA = qw(CGI::apacheSSI);

    package main;

    my $empty = CGI::apacheSSI::Empty->new();
    my $html = $empty->process(q[<!--#set var="varname" value="foo" --><!--#echo var="varname" -->]);
    ok($html eq "foo",'inherit 1');
}

# 10
# derive a class, and do something simple (altered class)
{
    package CGI::apacheSSI::UCEcho;
    @CGI::apacheSSI::UCEcho::ISA = qw(CGI::apacheSSI);

    sub echo {
		return uc shift->SUPER::echo(@_);
    }

    package main;

    my $echo = CGI::apacheSSI::UCEcho->new();
    my $html = $echo->process(q[<!--#set var="varname" value="foo" --><!--#echo var="varname" -->]);
    ok($html eq "FOO",'inherit 2');
}

# 11
# DATE_LOCAL/DATE_GMT with config{timefmt}
{
    my $ssi = new CGI::apacheSSI (timefmt => '%Y');
    ok($ssi->echo('DATE_LOCAL') =~ /^\d{4}$/,'config{timefmt}');
}

# 12
{
  # timefmt applied to LAST_MODIFIED
  my $ssi = CGI::apacheSSI->new();
  my $html = $ssi->process('<!--#config timefmt="%m/%d/%Y %X" --><!--#echo var="LAST_MODIFIED" -->');
  like($html, qr{^\d\d/\d\d/\d{4} \d\d:\d\d:\d\d$}, 'timefmt applied to LAST_MODIFIED');
}

# 13
{
  # newlines in directives
  my $ssi = CGI::apacheSSI->new();
  my $html = $ssi->process('<!--#config 
 timefmt="%m/%d/%Y %X" --><!--#echo var="LAST_MODIFIED" -->');

  like($html, qr{^\d\d/\d\d/\d{4} \d\d:\d\d:\d\d$}, 'newlines in directives');
}


# 14,15
#SKIP: { # yet, skip here doesnt work?
{
	# tie by hand & close
    my($dir) = tempdir();
#	print $dir,"\n";
	open FH, "+>$dir/AfDCSd43.tmp" or skip('failed to open tempfile',2);
	my $ssi = tie *FH, 'CGI::apacheSSI', filehandle => 'FH';
# 14
	isa_ok(tied(*FH),'CGI::apacheSSI','tied object');

	print FH "this is the first test\n";

	close FH;
	eval { print FH "this is the second test\n" or die "FH is closed" };
# 15
	ok($@ =~ /^FH is closed/,'close()');
}

# autotie ?


__END__
