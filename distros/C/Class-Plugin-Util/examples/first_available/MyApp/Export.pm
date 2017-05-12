  package MyApp::Export;
    use strict;
    use warnings;
    use Class::Plugin::Util qw( first_available_new );
    {

        my @LIST_OF_YAML_HANDLERS = qw(
            MyApp::Export::YAML::LibYAML
            MyApp::Export::YAML::Syck
            MyApp::Export::YAML
        );

        my @LIST_OF_JSON_HANDLERS = qw(
            MyApp::Export::JSON::Syck
            MyApp::Export::JSON::PC
            MyApp::Export::JSON
        );

        my %FORMAT_TO_HANDLER = (
            'JSON'  => [ @LIST_OF_JSON_HANDLERS ],
            'YAML'  => [ @LIST_OF_YAML_HANDLERS ],
        ); 
        
        sub new {
            my ($class, $arg_ref) = @_;
           
            # The format argument decides which format we choose. 
            my $format = uc( $arg_ref->{format} );
            # Default format is YAML.
            $format  ||= 'YAML',
    
            my $select_ref = $FORMAT_TO_HANDLER{$format};                                                                                 
                                                                                                                                          
            my $object = Class::Plugin::Util::first_available_new($select_ref, $arg_ref);                                                 
                                                                                                                                          
            return $object;                                                                                                               
        }                                                                                                                                 
    }                                                                                                                                     
                                                                                                                                          
    1;
