
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);



use ExtUtils::MakeMaker;
use Config;

use Cwd;
my $pwd = fastcwd;
$MY_LD_RUN_PATH = "$Config{installsitearch}/auto/libawperl:$pwd";


WriteMakefile(
	'NAME'		=> 'libawperl',
	'VERSION_FROM'	=> '../lib/Aw.pm', # finds $VERSION
	'LINKTYPE'	=> 'static',
	'DEFINE'	=> ($] >= 5.008 ? '-DPERL58_COMPAT' : ''),
	#
	# Uncomment for 3.0
	#
	# 'INC'		=> '-I./../include -I/opt/active30/include -I/opt/active30/samples/adapter_devkit/c_lib',
	#
	# Uncomment for 4.0
	#
	'INC'		=> '-I../include -I/opt/active40/include -I/opt/active40/samples/adapter_devkit/c_lib',
	'OBJECT'	=> '$(O_FILES)',
	'AUTHOR'	=> "Daniel Yacob <Yacob\@wMUsers.Com>",
	'ABSTRACT'	=> "Interface to the ActiveWorks Libraries.",
);

$ENV{LD_RUN_PATH} = 
    "$ENV{LD_RUN_PATH}:$Config{installsitearch}/auto/libawperl:$pwd";

sub MY::top_targets {
    my $self = shift;
    my $string = $self->MM::top_targets;
    my $libapreq = <<"EOF";
LD_RUN_PATH = $ENV{LD_RUN_PATH}
EOF

    my $so = "\n".'$(DLBASE).$(DLEXT): $(INST_DYNAMIC)'."\n";

    $string =~ s/(pure_all\s+::\s+)(.*)/$1 static $2/;
    return $libawperl . $so . $string;
}



sub no_MY {
    for (keys %MY::) {
        if (defined &{ $MY::{$_} }) {
            next if $_ eq 'dynamic';
            undef &{ $MY::{$_} };
            delete $MY::{$_};
        }
    }
}
