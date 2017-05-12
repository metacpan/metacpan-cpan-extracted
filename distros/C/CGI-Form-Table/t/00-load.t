use Test::More tests => 2;

BEGIN {
  use_ok('CGI::Form::Table');
  use_ok('CGI::Form::Table::Reader');
}

diag( "Testing CGI::Form::Table $CGI::Form::Table::VERSION" );
