# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

BEGIN
{
    require 5.004_05;
}
use strict;
use ExtUtils::MakeMaker 5.16;


WriteMakefile(
	      'NAME'	      => 'CGI::Debug',
	      'VERSION_FROM'  => 'Debug.pm', # finds $VERSION
	      'PREREQ_PM'     =>
	      {
		  'CGI'          => 0,
		  'Mail::Send'   => 0,
		  'Data::Dumper' => 0,
		  'Time::HiRes'  => 0,
	      },
	      'dist'          =>
	      {
		  'COMPRESS' => 'gzip',
		  'SUFFIX'   => 'gz',
	      }
	      );

print "Provide an address for testing CGI error reporting by email.\n";
print "Will only send fake testing information. [jonas\@cpan.org] ";
my $email = <STDIN>;
chomp $email;

open TMPL, "<t/mail/send.tmpl" or die $!;
open OUT, ">t/mail/send.cgi" or die $!;

unless( $email =~ /\@/ )
{
    $email = "jonas\@cpan.org";
}
print "Using $email\n";

while( my $line = <TMPL> )
{
    $line =~ s/bogus\@out.in.space/$email/;
    print OUT $line;
}

close TMPL;
close OUT;


