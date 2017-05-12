use ExtUtils::MakeMaker ();
use Cwd ;
use Data::Dumper ;

foreach my $f ('makepl_args.apache_dav', '../makepl_args.apache_dav')
    {
    if (-f $f)
        {
        do $f ;
        die $@ if ($@) ;
        last ;
        }
    }

push @apdirs, $ENV{APACHE_SRC} if ($ENV{APACHE_SRC}) ;
push @davdirs, $ENV{MODDAV_SRC} if ($ENV{MODDAV_SRC}) ;


while (my $a = shift @ARGV)
    {
    push @apdirs, shift if ($a eq 'APACHE_SRC') ;
    push @apdirs, $1 if ($a =~ /^APACHE_SRC=(.*?)$/) ;
    push @davdirs, shift if ($a eq 'MODDAV_SRC') ;
    push @davdirs, $1 if ($a =~ /^MODDAV_SRC=(.*?)$/) ;
    }


my $dir = getcwd ;
my $apdir;
my $davdir;

foreach (@apdirs)
{
    if (-d) {
	$apdir = $_;
	print "Will use Apache in $apdir\n";
	last;
    }
}

die "No Apache found!" unless $apdir;

foreach (@davdirs)
{
    if (-d) {
	$davdir = $_;
	print "Will use mod_dav in $davdir\n";
	last;
    }
}

die "No mod_dav found!" unless $davdir;

%MMARGS = (
           'INC'    => "-I\"$davdir\" -I\"$apdir/include\" -I\"$apdir/os/unix\" -I\"$dir/xs\"  -I\"$dir/xsinclude\"",
	   'OPTIMIZE' => '-ggdb',
	   ) ;


open FH, ">xs/mmargs.pl" or die "Cannot open xs/mmargs.pl ($!)" ;
print FH Data::Dumper -> Dump ([\%MMARGS], ['MMARGS']) ;
close FH ;


ExtUtils::MakeMaker::WriteMakefile(
    'NAME'    => 'Apache::DAV',
    'VERSION' => '0.13',
    %MMARGS,
    %ADDARGS,
);

