package TestApache::subclass;
use strict;
use warnings FATAL => 'all';

use base qw(Apache2::SQLRequest);
use Apache2::Log ();

use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

use Data::Dumper qw(Dumper);

sub handler : method {
    my $r = shift->SUPER::new(shift);
    $r->log->warn("this should crash me :(");
    $r->print(Dumper($r));
    return Apache2::Const::OK;
}

1;

#package TestApache2::subclass::Config;

#use Apache2::Module      ();
#use Apache2::CmdParms    ();

#use Apache2::Const -compile => qw(OR_ALL ITERATE);

#our @APACHE_MODULE_COMMANDS;

#push @APACHE_MODULE_COMMANDS => {
#        name            => 'DirectoryIndex',
#        func            => "Apache2::SQLRequest::Config" . '::_set_scalar',
#        args_how        => Apache2::ITERATE,
#        req_override    => Apache2::OR_ALL,
#        cmd_data        => 'dir_index',
#};

#Apache2::Module::add(__PACKAGE__, \@APACHE_MODULE_COMMANDS)
#    if ($mod_perl::VERSION >= 1.99_18 and Apache2::Module->can('add'));

#1;
