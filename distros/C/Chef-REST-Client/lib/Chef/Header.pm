package Chef::Header;

=pod

=head1 NAME

Chef::Header - Class that will generate Chef::Headers 

=head1 VERSION

1.0

=cut

$Chef::Header::VERSION = 1.0;

my @base;
BEGIN {
use File::Basename qw { dirname };
use File::Spec::Functions qw { splitdir rel2abs };
 @base = ( splitdir ( rel2abs ( dirname(__FILE__) ) ) );
 pop @base; #Chef
 push @INC, '/', @base;
};

use parent qw { Chef };
use Chef::Encoder;

=pod

=head1 DESCRIPTION

This class inherites from Chef. This class will generate encrypted headers as described in the 
L<ChefHeaderDocumentation|http://docs.opscode.com/api_chef_server.html/>

Once you call L<header> method it will load L<Chef::Header::header> class . Which will generate and fill up
User Agent with appropriate Chef Headrs as specified in the above documentation.

=begin html

+---------------+
|  Chef::Header |
+-----------------------+
|  Chef::Header::header | 
+-----------------------------------+
|  Chef::Header::header::chefheader |
+-----------------------------------+

=end html

=head2 header

loads L<Chef::Header::header> class and returns an object.

=head2 Methods of B<L<Chef::Header::header>> class

=over

=item  Method( $Method )

set internally to either 'GET' or 'POST'

=item HashedPath ( $path )

calcualtes hash of end point for chef

=item XOpsContentHash ( $content )

calculdates hash of the content

=item XOpsUserId ( $class->name )

initialized user-id field sets to the user_id or client-name.

=item Host( $server )

initialized Host parameter of UA to chef server

=item XChefVersion ( $chef_server_version )

initialized Chef server Version to use

=item XOpsSign( $XOpsSign )

initializes to 'version=1.0' as specified in the chef API documentation.

=item XOpsTimestamp

initialized the request timestamp for http request to now

=item header

returns all the headers 

=item hash

returns hash of all the headers , initialized so far.

=item header_to_string

return a comma seperated list of keys and values of the header

=back 

=cut
  
  sub header {
    my $class = shift;
    my $param = {@_};
    
    package Chef::Header::header;

    use parent -norequire,qw { Chef::Header };
       
    my $self = new Chef::Header::header();

    $self->_chef_encoder( new Chef::Encoder( 'private_key_file'  => $class->private_key ) );
    
    $self->Method          ($param->{'Method'         });
    $self->HashedPath      ($param->{'Path'           });
    $self->XOpsContentHash ($param->{'Content'        });
    #$self->XOpsTimestamp   ($param->{'X-Ops-Timestamp'  });
    $self->XOpsUserId      ($class->name               );
  
    #default_values
    #$self->Accept          ($param->{'Accept'         });
    $self->Host            ($class->server             );
    $self->XChefVersion    ($class->chef_version       );
    $self->XOpsSign        ($param->{'XOpsSign'       });
    $self->Accept          ($param->{'Accept'         });    

    return $self;
  
  	 sub _chef_encoder {
		my $self = shift;
		my $obj  = shift;
		       $self->{'header_chef_encoder'} = $obj if defined $obj;
		return $self->{'header_chef_encoder'};
  	 }
  	 
    sub XOpsSign
    {
      my ($self, $x_ops_sign) = (@_);
             $self->header->{'X-Ops-Sign'} = $x_ops_sign if defined $x_ops_sign;
             $self->header->{'X-Ops-Sign'} = 'version=1.0;' unless 
     defined $self->header->{'X-Ops-Sign'};
      return $self->header->{'X-Ops-Sign'};  
    }

    sub XChefVersion
    {
      my ($self, $x_chef_version) = (@_);
             $self->header->{'X-Chef-Version'} = $x_chef_version if defined $x_chef_version;
      return $self->header->{'X-Chef-Version'};  
    }

    sub Host 
    {
      my ($self, $host) = (@_);
      if( defined ($host) ){
        $host =~ s/^(http|https):\/\/(.*)/$2/;
        $self->header->{'Host'} = $host;
      }
      return $self->header->{'Host'};  
    }

    sub Accept 
    {
      my ($self, $accept) = (@_);
             $self->header->{'Accept'} = $method if defined $accept;
             $self->header->{'Accept'} = 'application/json' unless 
     defined $self->header->{'Accept'};           
      return $self->header->{'Accept'};  
    }

    sub Method 
    {
      my ($self, $method) = (@_);
             $self->header->{'Method'} = $method if defined $method;
      return $self->header->{'Method'};
    }

    sub HashedPath
    {  
      my ($self,$path) = (@_);
			
      if (defined ($path) )
      {
         my $end_point = ($path =~ m/^\//) ? $path : "/$path";
         my $chef_encoder = $self->_chef_encoder();
         $self->header->{'Hashed Path'} = $chef_encoder->sha1
                                                        ->digest( 'data' => $end_point );
      }
            
      return $self->header->{'Hashed Path'};
    }

    sub XOpsContentHash 
    {
      my ($self,$content) = (@_);
      my $chef_encoder = $self->_chef_encoder();         
        
         $self->header->{'X-Ops-Content-Hash'} = $chef_encoder->sha1
                                                              ->digest( 'data' => $content );
      return $self->header->{'X-Ops-Content-Hash'};
    }
    
    sub XOpsTimestamp 
    {
      my ($self,$x_ops_timestamp) = (@_);
             $self->header->{'X-Ops-Timestamp'} = $x_ops_timestamp 
                                       if defined $x_ops_timestamp;
                                             
         if (!$self->header->{'X-Ops-Timestamp'}){
       		$self->header->{'X-Ops-Timestamp'} = `date -u "+%Y-%m-%dT%H:%M:%SZ"`;         
       	}
       	chomp( $self->header->{'X-Ops-Timestamp'} );
      return $self->header->{'X-Ops-Timestamp'};
		      
    }

    sub XOpsUserId 
    {
      my ($self,$x_ops_user_id) = (@_);
             $self->header->{'X-Ops-UserId'} = $x_ops_user_id 
                                    if defined $x_ops_user_id;
      return $self->header->{'X-Ops-UserId'};
    }  

    sub header 
    {
      my $self = shift;
             $self->{'header'} = {} unless defined $self->{'header'};
      return $self->{'header'};
    }

    sub hash{
      my $self = shift;
      
      return { 
      	'Accept'          => $self->Accept       ,
      	'Host'            => $self->Host         ,
      	'X-Chef-Version'  => $self->XChefVersion ,
      	'X-Ops-Userid'    => $self->XOpsUserId   ,
      	'X-Ops-Timestamp' => $self->XOpsTimestamp,
      	'X-Ops-Sign'      => $self->XOpsSign     ,
      	'X-Ops-Content-Hash' => $self->XOpsContentHash,
      	%{$self->chef_header->XOpsAuthorization} 
        } ;
    }

    sub header_to_string 
    {
      my $self = shift;
      return ( $self->{'header'} );
    }  
    
=pod
    
=head2 Methods of B<L<Chef::Header::header::chefheader>>

=over

=item Method ( $method )

initialized chefheader with $method . either 'GET' or 'POST'

=item HashedPath ( $hashed_path )

initializes hashed path and 'Hashed Path' heder value.

=item XOpsContentHash ( $content_hash )

initializes content hash and 'X-Ops-Content-Hash' header.

=item XOpsTimestamp 

initializes X-Ops-Timestamp values

=item XOpsUserId

initialized X-Ops-UserId value

=item XOpsAuthorization

initializes X-Ops-Authorization-xxxx values . for more details refere to chef header API

=item split_60

split the heder in chuncks of 60 characters 

=item hash

return chef_header in hash format

=item to_string

returns chef_header in string format . directly insertable to UserAgent headers.

=back

=cut 
    
    #-----------------------------------------#
    #  class Chef::Header::header::chefheader #
    #-----------------------------------------#

    sub chef_header {
       my $class = shift;

       package Chef::Header::header::chefheader;
       
       my $self = {};
       bless $self, qw { Chef::Header::header::chefheader };
      
       $self->_chef_encoder( $class->_chef_encoder );        
	    $self->Method          ( $class->Method          );
       $self->HashedPath      ( $class->HashedPath      );
       $self->XOpsContentHash ( $class->XOpsContentHash );                     
       $self->XOpsTimestamp   ( $class->XOpsTimestamp   );
       $self->XOpsUserId      ( $class->XOpsUserId      );
       
	    return $self;
	  	 sub _chef_encoder {
			my $self = shift;
			my $obj  = shift;
	  	          $self->{'header_chef_encoder'} = $obj if defined $obj;
			return $self->{'header_chef_encoder'};
  	 	}
  	 	    
       sub Method {
         my ($self,$method) = (@_);
                $self->{'chef_header'}->{'Method'} = $method if
                                             defined $method;
         return $self->{'chef_header'}->{'Method'};
       }

       sub HashedPath {
         my ($self,$hashed_path) = (@_);
                $self->{'chef_header'}->{'Hashed Path'} = $hashed_path if
                                                  defined $hashed_path;
         return $self->{'chef_header'}->{'Hashed Path'};
       }

       sub XOpsContentHash {
         my ($self,$x_ops_content_hash) = (@_);
                $self->{'chef_header'}->{'X-Ops-Content-Hash'} = $x_ops_content_hash if
                                                         defined $x_ops_content_hash;
         return $self->{'chef_header'}->{'X-Ops-Content-Hash'};
       }                     

       sub XOpsTimestamp {
         my ($self,$x_ops_Timestamp) = (@_);
                $self->{'chef_header'}->{'X-Ops-Timestamp'} = $x_ops_Timestamp if
                                                      defined $x_ops_Timestamp;
         return $self->{'chef_header'}->{'X-Ops-Timestamp'};
       }

       sub XOpsUserId {
         my ($self,$x_ops_user_id) = (@_);
                $self->{'chef_header'}->{'X-Ops-UserId'} = $x_ops_user_id if
                                                   defined $x_ops_user_id;
         return $self->{'chef_header'}->{'X-Ops-UserId'};
       }

       sub hash {
         my $self = shift;
         return $self->{'chef_header'};
       } 
			
       sub to_string{
         my $self = shift;
		   return undef unless defined $self->Method 
		                    && defined $self->HashedPath
		                    && defined $self->XOpsContentHash
		                    && defined $self->XOpsTimestamp
		                    && defined $self->XOpsUserId;
		                      
         return join "\n", ( 	'Method:'             . $self->Method          ,
  										'Hashed Path:'        . $self->HashedPath      ,                     
                             	'X-Ops-Content-Hash:' . $self->XOpsContentHash ,
                             	'X-Ops-Timestamp:'    . $self->XOpsTimestamp   ,
                             	'X-Ops-UserId:'       . $self->XOpsUserId      ,
                           );
       }

       sub XOpsAuthorization {
         my $self = shift;
         my $chef_encoder = $self->_chef_encoder();
         my $canonical_headers = $self->to_string;
         my $raw_header = $chef_encoder->pki->sign( 'data' => $canonical_headers );

				chomp($raw_header);
								                
         my $authorization_header = {};
         my $authorization_header_count = 1;
			
         foreach my $line (@{$self->split_60($raw_header,[])}){
         	chomp($line);
              $authorization_header->{ "X-Ops-Authorization-$authorization_header_count"} 
                                   = $line;
              $authorization_header_count++;
         }
         
         return $authorization_header;
       }

       sub split_60 {
         my ($self,$string,$result) = (@_);

         return $result unless defined $string;
         $string =~ s/\n//g if defined $string;
 
         my $fp = substr $string , 0 , 60;
         my $sp = substr $string , 60;
           push @{$result} , $fp if defined $fp;
           $self->split_60( $sp,$result) if defined $sp;

         return $result;
      }
      
    }#chef_header ends.  
  
  }#header
  
#}# new

1;

=pod

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut