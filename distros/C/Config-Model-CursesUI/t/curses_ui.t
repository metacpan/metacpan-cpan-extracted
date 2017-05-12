# -*- cperl -*-

use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More ;
#use Struct::Compare ;
use Data::Dumper;
use Config::Model ;
use Config::Model::CursesUI ;
use Log::Log4perl qw(:easy) ;
use Curses::UI ;

use strict ;
use vars qw/$hw/;

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;
$log  = 1 if $arg =~ /l/;
$show = 1 if $arg =~ /s/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ( $log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init( $log ? $WARN : $ERROR );
}

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

warn "You can run the GUI with 'i' argument. E.g. 'perl t/curses_ui.t i'\n";

ok(1,"Config::Model::CursesUI loaded") ;

my $model = Config::Model -> new ( );

my $inst = $model->instance (root_class_name => 'Master',
		  model_file      => 't/test_model.pm',
		  instance_name   => 'test1');
ok($inst,"created dummy instance") ;


# re-direct errors
open (FH,">>stderr.log") || die $! ;
open STDERR, ">&FH";

warn "----\n";

$inst->config_root->load("hash_a:foo=bar") ;

if ($arg =~ /i/ ) {
    my $dialog = Config::Model::CursesUI-> new
      (
       permission => 'advanced',
       debug => 1,
      ) ;
    $dialog->start( $model )  ;
}

close FH ;

ok(1,"done") ;

done_testing;
