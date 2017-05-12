package Amazon::MWS::Exception;

use Exception::Class (
    Amazon::MWS::Exception,
    "Amazon::MWS::Exception::MissingArgument" => {
        isa    => Amazon::MWS::Exception,
        fields => 'name',
        alias  => 'arg_missing',
    },
    "Amazon::MWS::Exception::Invalid" => {
        isa    => Amazon::MWS::Exception,
        fields => [qw(field value message)],
	alias  => 'list_error', 
    },
    "Amazon::MWS::Exception::Transport" => {
        isa    => Amazon::MWS::Exception,
        fields => [qw(request response)],
        alias  => 'transport_error',
    },
    "Amazon::MWS::Exception::Response" => {
        isa    => Amazon::MWS::Exception,
        fields => [qw(errors xml)],
        alias  => 'error_response',
    },
    "Amazon::MWS::Exception::BadChecksum" => {
        isa    => Amazon::MWS::Exception,
        fields => 'request',
        alias  => 'bad_checksum',
    },
    "Amazon::MWS::Exception::Throttled" => {
        isa    => Amazon::MWS::Exception,
        fields => [qw(errors xml)],
        alias  => 'throttled',
    },

);

1;
