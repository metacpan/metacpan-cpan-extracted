BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;
use bytes;

use Test::More ;
use CompTestUtils;


BEGIN {
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 82 + $extra ;

    use_ok('Archive::Zip::SimpleZip') ;
}


{
    use Compress::Raw::Zlib;
    
    my @all = @Compress::Raw::Zlib::DEFLATE_CONSTANTS;
    
    my %all;
    for my $symbol (@Compress::Raw::Zlib::DEFLATE_CONSTANTS)
    {
        eval "defined Compress::Raw::Zlib::$symbol" ;
        $all{$symbol} = ! $@ ;
    }   
           
   
   my $pkg = 1;

    {
        ++ $pkg ; 
        eval <<EOM;
            package P$pkg;
            use Test::More ;
            use CompTestUtils;
        
            use Archive::Zip::SimpleZip () ;
        
            ::title "Archive::Zip::SimpleZip - no import" ;       
EOM
        is $@, "", "create package P$pkg";
        for my $symbol (@Compress::Raw::Zlib::DEFLATE_CONSTANTS, @{ $Archive::Zip::SimpleZip::EXPORT_TAGS{zip_method} })
        {
            if ( $all{$symbol})
            {
                eval "package P$pkg; defined Archive::Zip::SimpleZip::$symbol ;";            
                is $@, "", "  has $symbol";
            }
            else
            {
                ok 1, "  $symbol not available";
            }
        }        
    }    
    

    {
        for my $label (keys %Compress::Raw::Zlib::DEFLATE_CONSTANTS)
        {
            ++ $pkg ; 

            eval <<EOM;
                package P$pkg;
                use Test::More ;
                use CompTestUtils;
            
                use Archive::Zip::SimpleZip qw(:$label) ;
            
                ::title "Archive::Zip::SimpleZip - import :$label" ; 
          
EOM
            is $@, "", "create package P$pkg";
            
            for my $symbol (@{ $Compress::Raw::Zlib::DEFLATE_CONSTANTS{$label} } )
            {
                if ( $all{$symbol})
                {
                    eval "package P$pkg; defined $symbol ;";            
                    is $@, "", "  has $symbol";
                }
                else
                {
                    ok 1, "  $symbol not available";
                }  
               
            }   
        }     
    }       
    
    {
        for my $label ('zip_method')
        {
            ++ $pkg ; 

            eval <<EOM;
                package P$pkg;
                use Test::More ;
                use CompTestUtils;
            
                use Archive::Zip::SimpleZip qw(:$label) ;
            
                ::title "Archive::Zip::SimpleZip - import :$label" ; 
          
EOM
            is $@, "", "create package P$pkg";
            
            for my $symbol (@{ $Archive::Zip::SimpleZip::EXPORT_TAGS{$label} } )
            {
                 eval "package P$pkg; defined $symbol ;";               
                 is $@, "", "  has $symbol";
               
            }   
        }     
    }       
}

