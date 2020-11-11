use ExtUtils::MakeMaker;

my $module = 'Calendar::Schedule';
my $name   = 'Schedule.pm';
(my $dir = $module) =~ s/::/-/g;

WriteMakefile (
   'NAME'       => $module,
   'VERSION_FROM' => $name, # finds $VERSION
   'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
   'clean' => {FILES => "tmp* Calendar *~"},
   'LICENSE' => 'perl',
   'EXE_FILES' => [ 'bin/cal2html' ],	       
   'PREREQ_PM' => {
		   # Foo::Ey => '1.00',
		  },
   'PL_FILES' => {},
   ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => $name, # retrieve abstract from module
     AUTHOR     => 'Vlado Keselj vlado@dnlp.ca http://vlado.ca') : 
    ()
   ),
   (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
     'meta-spec' => { version => 2} ,
     resources => {
       repository => {
         type => 'git',
	 url => 'https://github.com/vkeselj/calendar-schedule.git',
         web => 'https://github.com/vkeselj/calendar-schedule',
	 }}}):() ));

open(M, ">>Makefile") or die;

if ( -f 'priv.make' ) { print M &getfile('priv.make') }

close(M);

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}
