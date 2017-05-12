#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::MockObject;

use vars qw( @methods );
BEGIN {
  plan( tests => 19 );
  use_ok('CGI::Wiki::Simple');
  use_ok('CGI::Wiki::Simple::NoTemplates');

  @methods = qw(setup teardown inside_link decode_runmode);
};

my $wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {} } # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "Got a CGI::Wiki::Simple");
isa_ok($wiki, 'CGI::Application', "It's also a CGI::Application");

isa_ok($wiki->wiki, 'CGI::Wiki', '$wiki->wiki');

$wiki = CGI::Wiki::Simple::NoTemplates->new(
      PARAMS => { store => {} } # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple::NoTemplates', "Got a CGI::Wiki::Simple::NoTemplate");
isa_ok($wiki, 'CGI::Application', "It's also a CGI::Application");

can_ok($wiki, @methods);

isa_ok($wiki->wiki, 'CGI::Wiki', '$wiki->wiki');

# Now check our decode_runmode routine:

use vars qw( $path_info %node_info %params );

use vars qw( @runmodes );
@runmodes = qw(display preview commit);
                           
# Declare what we expect :
sub is_path_info($$$$) {
  my ($path_info,$expected_runmode,$expected_node_title,$comment) = @_;

  my %node_info = (content => 'Test content', checksum => 1);
  my $cgi = Test::MockObject->new()
                            ->set_always( param => undef )
                            ->mock( path_info => sub { $path_info } );
  my $self = Test::MockObject->new()
                             ->mock( param => sub { my $result = $params{$_[1]}; $params{$_[1]} = $_[2] if scalar @_ == 3; $result } )
                             ->mock( retrieve_node => sub { %node_info } )
                             ->set_always( format => undef )
                             ->set_always( query => $cgi )
                             ->set_list(run_modes => @runmodes );

  is(CGI::Wiki::Simple::decode_runmode($self),$expected_runmode,"$comment runmode");
  is($self->param("node_title"),$expected_node_title,"$comment node title");
};

is_path_info "","display","index","Default";

for (@runmodes) {
  is_path_info "/$_/foo","$_","foo","Explicit $_";
};

is_path_info "/nonexisting/foo", "display","index", "Unknown runmode";

