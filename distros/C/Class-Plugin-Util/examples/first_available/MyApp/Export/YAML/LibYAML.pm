   package MyApp::Export::YAML::LibYAML;
    use strict;
    use warnings;
    use base 'MyApp::Export::Base';
    {
        
        my @MODULES_REQUIRED = qw( YAML::LibYAML );

        sub transform {
            my ($self, $data_ref) = @_;

            return YAML::LibYAML::Dump($data_ref);
        }

        sub requires {
            return @MODULES_REQUIRED;
        }
    }

    1;
