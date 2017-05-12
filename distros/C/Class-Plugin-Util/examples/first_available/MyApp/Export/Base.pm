    package MyApp::Export::Base;                                                                                                          
    use strict;                                                                                                                           
    use warnings;                                                                                                                         
    use Carp;                                                                                                                             
    use Class::Plugin::Util;                                                                                                              
    {                                                                                                                                      
        sub new {
            my ($class, $arg_ref) = @_;                                                                                                   
                                                                                                                                          
            # All MyApp::Export:: classes should have a requires method which returns                                                     
            # a list of all modules it requires to do it's work.                                                                          
            my @this_handler_requires = $class->requires;                                                                                 
                                                                                                                                          
            # check if we're missing any modules.                                                                                         
            my $missing_module = Class::Plugin::Util::doesnt_support(@this_handler_requires);                                                     
                                                                                                                                          
            if ($missing_module) {                                                                                                        
                carp    "$class requires $missing_module, " .                                                                             
                        "please install from CPAN."         ;                                                                             
            }                                                                                                                             
                                                                                                                                          
            my $self = { };                                                                                                               
            bless $self, $class;                                                                                                          
                                                                                                                                          
            return $self;                                                                                                                 
        }                                                                                                                                 
                                                                                                                                          
        # transform is the function exporters should use to transform the data to it's format.                                            
        sub transform {                                                                                                                   
            croak 'You cannot use MyApp::Export::Base directly. Subclass it!';                                                            
        }                                                                                                                                 
                                                                                                                                          
        # the list of modules we require.                                                                                                 
        sub requires {                                                                                                                    
            croak 'You cannot use MyApp::Export::Base directly. Subclass it!';                                                            
        }                                                                                                                                 
                                                                                                                                          
        sub export {                                                                                                                      
            my ($self, $data) = @_;                                                                                                       
            return if not $data;                                                                                                          
                                                                                                                                          
            return $self->transform($data);                                                                                               
        }                                                                                                                                 
    }                                                                                                                                     
                                                                                                                                          
    1;
