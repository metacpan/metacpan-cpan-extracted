use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # package Aion::Env::Etc;
# 
# use common::sense;
# 
# use YAML::Syck qw//;
# 
# use Aion::Env AION_ENV_ETC_PATH => (default => 'etc/include.yml');
# use Aion::Env APP_ENV => (default => 'prod');
# 
# our %ETC = -e AION_ENV_ETC_PATH? _parse(AION_ENV_ETC_PATH): ();
# 
# sub import {
#     my ($cls, $name, %kw) = @_;
#     my $isa = delete $kw{isa};
#     my $is_default = exists $kw{default};
#     my $default = delete $kw{default};
#     my $key = delete $kw{key} // lc($name) =~ y/_/./r;
#     die sprintf "Unknown keyword%s: %s",
#     	scalar keys %kw == 1? '': 's',
#      	join ", ", sort keys %kw if keys %kw;
#       
#       die "$name is'nt defined!" if !exists $ETC{$key} and !$is_default;
#   
#       my $pkg = caller;
#       my $val = exists $ETC{$key}? $ETC{$key}: $default;
#   
#       if($isa) {
#       	if(UNIVERSAL::isa($isa, "Aion::Type")) { $isa->validate($val, $name) }
#        	else {
# 	    	local $_ = $val;
# 	    	die UNIVERSAL::can($isa, "get_message")? $isa->get_message($val): "$name type is'nt isa!" unless $isa->();
# 		}
#       }
#       
#       constant->import("$pkg\::$name", $val);
# }
# 
# # Считывает и парсит конфигурационный файл с включениями
# sub _parse {
# 	my ($path) = @_;
# 
# 	my %etc;
# 	my @S = ["", $path];
# 	while(@S) {
# 		my ($key, $path) = @{shift @S};
# 		open my $f, '<:utf8', $path or die "$path :$!"; 
# 		my $etc = YAML::Syck::Load($path);
# 		my $include = $etc->{include};
# 		push @S, ["$key.$_", "$path/$include->{$_}"] for keys %$include;
# 		%$etc = (%$etc, %{$etc->{'when@' . APP_ENV}});
# 		die "$key exists. $path" if exists $etc{$key};
# 		$etc{$key} = $etc;
# 	}
# 
# 	%etc
# }
# 
# 1;

::done_testing;
