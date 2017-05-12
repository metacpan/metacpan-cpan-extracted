#!perl
use 5.012;
use strict;
use warnings;
use File::ShareDir;
use App::CELL::Load;
use App::CELL::Log qw( $log );
use App::CELL::Message;
#use App::CELL::Test::LogToFile;
use Data::Dumper;
use Test::More;
use Test::Warnings;

$log->init( ident => 'CELLtest', debug_mode => 1 );
$log->info("----------------------------------------------- ");
$log->info("---             005-message.t               ---");
$log->info("----------------------------------------------- ");

is_deeply( App::CELL::Message::supported_languages(), [ 'en' ], 
    "Hard-coded list of supported languages consists of just 'en'" );
ok( App::CELL::Message::language_supported( 'en' ), 
    "English is a supported language" );

# N.B.: App::CELL is not initialized at this point, so no messages or
# config params have been loaded

my $status = App::CELL::Message->new();
#diag( Dumper $status );
ok( $status->not_ok, "Message->new with no code is not OK");
ok( $status->level eq 'ERR', "Message->new with no code returns ERR status");
is( $status->code, 'CELL_MESSAGE_NO_CODE', "Error message code is correct" );
is( $status->text, 'CELL_MESSAGE_NO_CODE', "Error message text is correct" );
#diag( $message->stringify );

$status = App::CELL::Message->new( code => undef );
ok( $status->not_ok, "Message->new with no code is not OK");
ok( $status->level eq 'ERR', "Message->new with no code returns ERR status");
is( $status->code, 'CELL_MESSAGE_CODE_UNDEFINED', "Error message code is correct" );
is( $status->text, 'CELL_MESSAGE_CODE_UNDEFINED', "Error message text is correct" );

$status = App::CELL::Message->new( code => 'UNGHGHASDF!*' );
ok( $status->ok, "Message->new with unknown code is OK");
my $message = $status->payload();
is( $message->code, 'UNGHGHASDF!*', "Unknown message codes are passed through" );
#diag( "Text of " . $message->code . " message is ->" . $message->text . "<-" );

$status = App::CELL::Message->new( 
            code => "Pre-init message w/arg ->%s<-",
            args => [ "CONTENT" ],
                             );
ok( $status->ok, "Message->new with unknown code and arguments is OK");
$message = $status->payload();
is( $message->text, "Pre-init message w/arg ->CONTENT<-", "Pre-init unknown message codes can contain arguments" );
$log->debug( $message->text );
#diag( "Text of " . $message->code . " message is ->" . $message->text . "<-" );

done_testing;
