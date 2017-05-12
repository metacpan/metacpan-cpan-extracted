use ExtUtils::MakeMaker;
use Config;
my $gccopt = "";
if (defined $Config{'gccversion'})
 {
  $ver = $Config{'gccversion'};
  if ($ver ge "2.8")
   {
    eval
     {
      if ((getpwuid($<))[6] =~ /Nick\s+Ing-Simmons/)
       {
        # This is the author - catch as many bugs as possible
        $gccopt .= "-Wall -W -Wsign-compare";
       }
     }
   }
 }


$VERSION = '0.002';

%define = ();
@libs   = ();
@clean  = qw(*% *.bak);
@deps   = "subdirs :: config\n";

sub MMutil::check_headers
{
 my $inc = $Config{'usrinc'};
 my $found = 0;
 while (@_)
  {
   my $hdr = shift;
   my $var = "HAVE_\U$hdr";
   $var =~ s,[/.],_,g;
   if (-f "$inc/$hdr")
    {
     warn "Have <$hdr>\n";
     $define{$var} = 1;
     $found++;
    }
   else
    {
     warn "Cannot find <$hdr>\n";
    }
  }
 return $found;
}

sub translate_osname
{
 my ($src,$dst) = @_;
 open(SRC,"<$src") || die "Cannot open $src:$!";
 open(DST,">$dst") || die "Cannot open $dst:$!";
 while (<SRC>)
  {
   s/#OSNAME#/$^O/g;
   print DST;
  }
 close(DST);
 close(SRC);
 push(@clean,$dst);
 push(@deps,"$dst : $src\n\t\$(PERL) -pe 's/#OSNAME#/$^O/g' $src > $dst\n");
 push(@deps,"config :: $dst\n\t\$(NOOP)\n");
}

my $driver = 'dummy';

foreach ($^O)
 {
  if (/^(linux)$/i)
   {
    if (MMutil::check_headers("alsa/asoundlib.h","alsa/pcm.h") == 2)
     {
      warn("Using ALSA driver\n");
      $driver = 'alsa';
      push(@libs,'-lasound');
      last;
     }
    $driver = 'oss';
   }
  elsif (/^(\w+bsd)$/i)
   {
    $driver = 'oss';
   }
  elsif (/^(sunos|solaris)$/i)
   {
    $driver = 'sun';
   }
  elsif (/^hpux$/i)
   {
    $driver = 'hpux';
   }
  elsif (/^irix$/i)
   {
    $driver = 'sgi';
   }
  elsif (/^next$/i)
   {
    $driver = 'next';
   }
  elsif (/^MSWin32$/i)
   {
    $driver = 'win32';
   }
 }

mkdir($^O,0777) unless (-d $^O);
translate_osname("config/${driver}.xs","$^O/$^O.xs");
my $pm = (-f "config/${driver}.pm") ? "config/${driver}.pm" : "config/generic.pm";
translate_osname($pm,"$^O/$^O.pm");


if (-f "config/${driver}.cfg")
 {
  eval { require "./config/${driver}.cfg" };
  die "config/${driver}.cfg $@" if $@;
 }

my $define = join(' ',map("-D$_",keys %define));
my $libs   = join(' ',@libs);

open(PL,">$^O/Makefile.PL") || die "Cannot open $^O/Makefile.PL:$!";
push(@clean,"$^O/Makefile.PL");
print PL "use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'Audio::Play::$^O',
    'DEFINE'   => '$define $gccopt',
    'LIBS'     => [ $libs ],
    'clean'    => {FILES => '*% *.bak'},
    'OBJECT'   => '\$(O_FILES)',
    'VERSION_FROM' => '../../Data/Data.pm',
    'TYPEMAPS' => [q[../../Data/typemap]],
);
";
close(PL);


WriteMakefile(
    'NAME'     => 'Audio::Play',
    'clean'    => {FILES => join(' ',@clean)},
    'dist'     => { COMPRESS => 'gzip -f', SUFFIX => 'gz' },
    OBJECT     => '',
    'VERSION_FROM' => '../Data/Data.pm',
    'linkext'  => { LINKTYPE => ''},
    DEFINE        => qq[$gccopt],
);

sub MY::postamble
{
 return join('',@deps);
}

