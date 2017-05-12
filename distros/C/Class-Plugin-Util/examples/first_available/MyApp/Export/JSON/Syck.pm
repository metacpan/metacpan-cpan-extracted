   package MyApp::Export::JSON::Syck;
    use strict;
    use warnings;
    use base 'MyApp::Export::Base';
    {
    
        my @MODULES_REQUIRED = qw( JSON::Syck );

        sub transform {
            my ($self, $data_ref) = @_;

            return JSON::Syck::Dump($data_ref);
        }

        sub requires {
            return @MODULES_REQUIRED;
        }
    }

    1;
