use ExtUtils::MakeMaker;

use strict;
use mod_perl 1.16;
use 5.004_04;
use IO::File ();
use Apache::src ();

handlers2xsubs("handlers.xsubs");

my $src = Apache::src->new;

WriteMakefile(
    'NAME'	=> 'Apache::Module',
    'VERSION_FROM' => 'Module.pm', 
    'INC'       => $src->inc,	      
    'DEFINE' => $src->define,
    'dist'    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
        PREOP => 'pod2text Module.pm > README',
    },
   'macro' => {
	  CVSROOT => 'modperl.com:/local/cvs_repository',
   },
);

sub MY::postamble { 
    return <<'EOF'; 

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) . 
	@echo update Module.pm VERSION now 
EOF
}

my %not_imp;
BEGIN {
%not_imp = map {$_,1} qw{
 child_init
 child_exit
 init
 create_dir_config
 merge_dir_config
 create_server_config
 merge_server_config
};
}
sub handlers2xsubs {
    my $file = shift;
    require './Module.pm';
    my $fh = IO::File->new(">$file") or 
	die "can't open $file $!";

    for my $handler (Apache::Module->methods) {
	my($type, $trans);
	if ($not_imp{$handler}) {
	    $type = "int";
	    $trans = "member_boolean";
	}
	else {
	    $type = "SV *";
	    $trans = "handler2cvrv";
	}

	print $fh <<EOF;
$type
$handler(modp)
    Apache::Module modp

    CODE:
    $trans(modp->$handler);

    OUTPUT:
    RETVAL

EOF
     }
}

package Apache::Module;


my %request_method_desc = (
 translate_handler => "URI Translate",
 post_read_request => "Post Read Request",
 header_parser => "Header Parser",
 check_user_id => "Authentication",
 auth_checker => "Authorization",
 access_checker => "Access Check",
 type_checker => "Type Checker",
 fixer_upper => "Fixups",
 logger => "Logging",
);

my %config_method_desc = (
 child_init => "Child Init",
 child_exit => "Child Exit",
 init => "Module Init",
 create_dir_config => "Create Directory Config",
 merge_dir_config => "Merge Directory Configs",
 create_server_config => "Create Server Config",
 merge_server_config => "Merge Server Configs",
);

sub request_methods { 
    my @request_methods = qw{
 post_read_request
 translate_handler
 header_parser
 access_checker
 check_user_id
 auth_checker
 type_checker
 fixer_upper
 logger
 };
    @request_methods;
}

sub config_methods { 
    my @config_methods = qw{
 init
 child_init
 create_dir_config
 merge_dir_config
 create_server_config
 merge_server_config
 child_exit
 };
    @config_methods;
}

sub methods { request_methods(), config_methods() }

sub method_desc {
    my($self, $method) = @_;
    $request_method_desc{$method} || $config_method_desc{$method};
}







