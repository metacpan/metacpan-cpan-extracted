use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Carp qw/confess cluck/;
use CPAN;

my $pre_reqs = {
		'Cache::Memcached::Fast' => '0.21' , 
		'Moose' => 0 , 
        'Data::UUID::MT' => 0,
        'feature' => 0,
		'Data::Serializer' => 0,
		'Test::More' => 0,
		'common::sense' => 0,
		
		};

#foreach my $module(keys %{$pre_reqs}){
#	if($pre_reqs->{$module}){
#        print "\nchecking $module";
#		eval "use $module";
#		if($@){
#			eval {
#				print "Instalando o modulo $module\n";
#				CPAN::install $module;
#			};
#			if($@){
#				cluck "Problems to install module '$module' - $@";
#			}
#			else {
#				print "'$module' was installed!\n";
#			}
#		}
#		else {
#			print "\nModule '$module' ok!";
#		}
#	}
#}



WriteMakefile(
    NAME                => 'Cache::Memcached::Queue',
    AUTHOR              => q{Andre Garcia Carneiro <andregarciacarneiro@gmail.com>},
    VERSION_FROM        => 'lib/Cache/Memcached/Queue.pm',
#    ABSTRACT_FROM       => 'lib/Cache/Memcached/Queue.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {'Test::More' => 0,
                  'Moose' => 0,
                  'Cache::Memcached::Fast' => 0,
                  'Data::UUID::MT' => 0,
                  'feature' => 0,
				  'Data::Serializer' => 0,
				  'Test::More' => 0,
				  'common::sense' => 0,
                }, 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cache-Memcached-Queue-*' },
);




