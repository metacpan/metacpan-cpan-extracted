package Chef::Encoder;
$Chef::Encoder::VERSION = 1.1;

=pod

=head1 NAME

Chef::Encoder

=head1 VERSION

1.1

=head1 SYNOPSIS

 use Chef::Encoder;

 my $obj  = new Chef::Encoder
           ( 
             'data'             => $data
           , 'private_key_file' => ../data/private_key.pem
           );
           
    $obj->pki->sign     ( 'data' => $data );
    $obj->sha1->digest  ( 'data' => $data );
    $obj->base64->encode( 'data' => $data );
    $obj->base64->decode( 'data' => $data );
    
=head1 DESCRIPTION

This module imiplements methods that perform the encoding and decoding and signing of the header
once you load this module it will inturn load three classes

=over 

=item * Chef::Encode::pki

=item * Chef::Encode::sha1

=item * Chef::Encode::base64

=back

=begin html

+----------------+
|  Chef::Encode  |        
+---------------------+
|  Chef::Encode::pki  |
+----------------------+
|  Chef::Encode::sha1  |
+------------------------+
|  Chef::Encode::base64  |
+------------------------+

=end html    

=head1 METHODS

=head2 Chef::Encoder( %params )

return new object initialzied as per %params.

=head2 private_key_file 

returns $private_key_file 

=head2 private_key

returns $private_key

=head2 data

returns $data

=cut


my @base;
BEGIN {
use File::Basename qw { dirname };
use File::Spec::Functions qw { splitdir rel2abs };
 @base = ( splitdir ( rel2abs ( dirname(__FILE__) ) ) );
 pop @base; #Chef
 push @INC, '/', @base;
};

sub new {
  my $class = shift;
  my $param = {@_};
  my $self  = {};
  my $_tmp =  pop @base; #lib;  
  bless $self, $class;
    
    $self->{'data'            } = $param->{'data'} if defined $param->{'data'};
    $self->{'private_key_file'} = join '/' , @base , 'data', 'private_key.pem';
    $self->{'private_key_file'} = $param->{'private_key_file'} if defined $param->{'private_key_file'};

    push @base , $_tmp;
     
  return $self;
}

sub private_key_file {
  my $self = shift;
  return $self->{'private_key_file'};
}

sub private_key {
  my $self = shift;
  return $self->{'private_key'};
}

sub execute {
  my ($self , $command) = (@_);
  my $output = undef;
  eval {
  		$output = `$command`;
  		chomp($output);
  };
  return ($@) ? undef : $output;
}

sub data
{ $_[0]->{'data'} = $_[1] if defined $_[1]; return $_[0]->{'data'}; }

=pod

=head2 pki ( %params)

loads L<Chef::Encoder::pki> class and returns new object of class L<Chef::Encoder::pki>
it accepts ( 'private_key_file' => $private_key_file , 'private_key' => $private_key )
if none is provided it will try to use the values initialized from parent class L<Chef::Encoder>

=head3 NAME

Chef::Encoder::pki

=head3 VERSION

1.0

=head3 DESCRIPTION

This class provides siging request as per private key specified.

=head3 METHODS

=head4 B<sign>

returns signed data based on the private_key_file or privete_key

=cut

#----------------------------#
#  class Chef::Encoder::pki  #
#----------------------------#

sub pki {
  my $class = shift;
  my $param = {@_};
  
  package Chef::Encoder::pki;
  use parent qw{ Chef::Encoder };
  use Crypt::OpenSSL::RSA; 
  use File::Slurp;

  my $self = {};
  bless $self, qw { Chef::Encoder::pki };
  
  $self->{'private_key_file'} = (defined($param->{'private_key_file'}))?
                                         $param->{'private_key_file'}  :
                                         $class->private_key_file;
  $self->{'private_key'} = (defined($param->{'private_key'}))?
                                    $param->{'private_key'}  :
                                    $class->private_key;
  return $self;

    sub sign {
      my $self = shift;
      my $param = {@_};
      my $data = $param->{'data'};
      my $private_key = $self->private_key_file;

      return $self->execute("echo -n '$data'| openssl rsautl -sign -inkey $private_key| openssl enc -base64");
    }

    sub rsa_private {
      my $self = shift;
      my $param = {@_};
      $self->{'private_key'} = read_file( $param->{'private_key_file'} ) if
                                 defined( $param->{'private_key_file'} ) ;
                                 
      my $_openssl_rsa_obj;
      eval {
         $_openssl_rsa_obj = Crypt::OpenSSL::RSA->new_private_key( 
      								defined( $param->{'private_key'} ) ?
      								         $param->{'private_key'}   :
      								         $self->private_key 
                             );
      };
      return ($@)? $self : $_openssl_rsa_obj;
    }
    
    sub private_key {
      my $self = shift;

      if( !defined( $self->{'private_key'} ) ){
        $self->{'private_key'} = read_file( $self->private_key_file );
      }

      return $self->{'private_key'};
    }
    
    sub private_key_file {
      my $self = shift;
      return $self->{'private_key_file'};
    }

}# package pki ends

=pod

=head2 sha1 ( %params)

loads L<Chef::Encoder::sha1> class and returns new object of class L<Chef::Encoder::sha1>
it accepts ( 'data' => $data )
if none is provided it will try to use the values initialized from parent class L<Chef::Encoder>

=head3 NAME

Chef::Encoder::sha1

=head3 VERSION

1.0

=head3 DESCRIPTION

This class provides sha1 digest of the data initialized

=head3 METHODS

=head4 B<digest>

it accepts data as parameter $obj->digest( 'data' => $data )
returns sha1 digest in binary  encoded with base64 of the data passed.

=cut

#----------------------------#
#  class Chef::Encoder::sha1 #
#----------------------------#

sub sha1 {
  my $class = shift;
  my $param = {@_};

  package Chef::Encoder::sha1;
  
  use parent qw { Chef::Encoder };
  
  my $self = {};
    bless $self, qw { Chef::Encoder::sha1 };
  return $self;
      
    sub digest {
      my $self = shift;
      my $param = {@_};
      my $data = $param->{'data'};
     # return undef unless defined $data;
      return $self->execute("echo -n '$data'| openssl dgst -sha1 -binary| openssl enc -base64");
    }
    
}#sha1 package ends

=pod

=head2 base64 ( %params)

loads L<Chef::Encoder::base64> class and returns new object of class L<Chef::Encoder::base64>
it accepts ( 'data' => $data )
if none is provided it will try to use the values initialized from parent class L<Chef::Encoder>

=head3 NAME

Chef::Encoder::base64

=head3 VERSION

1.0

=head3 DESCRIPTION

This class provides base64 encoding and ecoding functionality 

=head3 METHODS

=head4 B<encode>

it accepts data as parameter $obj->encode( 'data' => $data )
returns base64 encoded value of data

=head4 B<decode>

it accepts data as parameter $obj->decode( 'data' => $data )
returns base64 decoded value of data

=cut

#-------------------------------#
#  class Chef::Encoder::base64  #
#-------------------------------#

sub base64 {
  my $class = shift;
  my $param ={@_};

  package Chef::Encoder::base64;
  use parent qw { Chef::Encoder };

  my $self = {};
  bless $self , qw{ Chef::Encoder::base64 };
  return $self;
 
   sub encode {
      my $self = shift;
      my $param = {@_};
      my $data = $param->{'data'};
      return undef unless defined $data;
      return $self->execute("echo '$data'| openssl enc -base64");
   }
   
   sub decode {
      my $self = shift;
      my $param = {@_};
      return undef unless defined $data;      
      return decode_base64( $param->{'data'} );
   }
                                
}# base64 package end


1;

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut
