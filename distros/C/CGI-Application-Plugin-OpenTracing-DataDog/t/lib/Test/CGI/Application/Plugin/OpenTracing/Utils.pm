package Test::CGI::Application::Plugin::OpenTracing::Utils;

use strict;
use warnings;

use Test::Most;
use Test::WWW::Mechanize::CGIApp;
use Test::MockModule;

use Exporter qw/import/;

our @EXPORT = qw/cgi_implementation_params_ok use_throws_ok/;

sub cgi_implementation_params_ok {
    my $cgi     = shift;
    my $params  = shift;
    my $message = shift ||
        "Works with '$cgi', and passes on the expected params";
    
    my $mock = Test::MockModule->new('OpenTracing::Implementation');
    $mock->mock(
        '_build_tracer' => sub {
            cmp_deeply( \@_, $params, $message );
            return;
        }
    );
    
    my $mech = Test::WWW::Mechanize::CGIApp->new( app => $cgi );
    
    $mech->get();
    
}

sub use_throws_ok {
    my $module  = shift;
    my $regex   = shift;
    my $message = shift || "use throws $module";
    
    my $eval_code = "use $module;";
    my($eval_result, $eval_error) = _eval($eval_code);
    like $eval_error, $regex, $message;
}

sub _eval {
    my( $code, @args ) = @_;
 
    # Work around oddities surrounding resetting of $@ by immediately
    # storing it.
    my( $sigdie, $eval_result, $eval_error );
    {
        local( $@, $!, $SIG{__DIE__} );    # isolate eval
        $eval_result = eval $code;              ## no critic (BuiltinFunctions::ProhibitStringyEval)
        $eval_error  = $@;
        $sigdie      = $SIG{__DIE__} || undef;
    }
    # make sure that $code got a chance to set $SIG{__DIE__}
    $SIG{__DIE__} = $sigdie if defined $sigdie;
 
    return( $eval_result, $eval_error );
}


1;
