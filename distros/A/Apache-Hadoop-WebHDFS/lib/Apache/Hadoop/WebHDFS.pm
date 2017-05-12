#!/usr/bin/perl
package Apache::Hadoop::WebHDFS;
our $VERSION = "0.04";      
use warnings;
use strict;
use lib '.';
use parent 'WWW::Mechanize';
use Carp;
use File::Map 'map_file';

# ###################
# WWW::Mech calls we care about
# $m -> get('http://url.com')  Does a get on that url
# $m -> put('http://blah.com', content=$content)
#
# $m -> success()  boolean if last request was success
# $m -> content()  content of request, which can be formated
# $m -> ct()       content type returned, ie: 'application/json'
# $m -> status()   HTTP status code of response

sub redirect_ok {
    # need to allow 'put' to follow redirect on 307 requests, per RFC 2616 section 10.3.8
    # redirect_ok is part of LWP::UserAgent which is subclassed 
    # by WWW:Mech and finally Apache::Hadoop::WebHDFS. 
    return 1;    # always return true.
}

sub new {
	# Create new WebHDFS object
    my $class = shift;
	my $namenode =  'localhost';
	my $namenodeport= 50070;
	my $authmethod = 'gssapi';                # 3 values: gssapi, unsecure, doas
	my ($url, $urlpre, $urlauth, $user, $doas_user)  = undef;
    
	if ($_[0]->{'doas_user'}) { $doas_user =  $_[0]->{'doas_user'}; }
	if ($_[0]->{'namenode'}) { $namenode =  $_[0]->{'namenode'}; }
	if ($_[0]->{'namenodeport'}) { $namenodeport =  $_[0]->{'namenodeport'}; }
    if ($_[0]->{'authmethod'}) { $authmethod =  $_[0]->{'authmethod'}; }
    if ($_[0]->{'user'}) { $user =  $_[0]->{'user'}; }

    # stack_depth set to 0 so we don't blow-up ram by saving content with each request.
    my $self = $class-> SUPER::new( agent=>"Apache_Hadoop_WebHDFS",
                                    stack_depth=>"0", 
    );

	$self->{'namenode'} = $namenode;
	$self->{'namenodeport'} = $namenodeport;
	$self->{'authmethod'} = $authmethod;
	$self->{'user'} = $user;
	$self->{'doas_user'} = $doas_user;
	return $self;
}

sub getdelegationtoken {
    # Fetch delegation token and store in object
    my ( $self ) = shift; 
    my $token = '';
	my $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1/?op=GETDELEGATIONTOKEN&renewer=' . $self->{'user'};
	if ($self->{'authmethod'} eq 'gssapi') {
      $self->get( $url );
      if ( $self->success() ) { 
        $token = substr ($self->content(), 23 , -3);
      }
      $self->{'webhdfstoken'}=$token;
	} else {
		carp "getdelgation token only valid when using GSSAPI" ;
	}
    return $self;    
}

sub canceldelegationtoken {
    # Tell namenode to cancel existing delegation token and remove token from object
    my ( $self ) = shift; 
	if ($self->{'authmethod'} eq 'gssapi') { if ( $self->{'webhdfstoken'} )  {
   	   my $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1/?op=CANCELDELEGATIONTOKEN&token=' . $self->{'webhdfstoken'};
          $self->get( $url );
          delete $self->{'webhdfstoken'} 
       } 
	} else {
		carp "canceldelgation token only valid when using GSSAPI";
	}
    return $self;    
}

sub renewdelegationtoken {
    # Tell namenode to cancel existing delegation token and remove token from object
    my ( $self ) = shift; 
	if ($self->{'authmethod'} eq 'gssapi') {
       if ( $self->{'webhdfstoken'} )  {
   	   my $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1/?op=RENEWDELEGATION&token=' . $self->{'webhdfstoken'};
          $self->get( $url );
          delete $self->{'webhdfstoken'} 
       } 
	} else {
		carp "canceldelgation token only valid when using GSSAPI";
	}
    return $self;    
}

sub Open {
	# curl -i -L "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=OPEN[&offset=<LONG>][&length=<LONG>][&buffersize=<INT>]"

    my $self = shift; 
    my ( $file, $offset, $length, $buffersize ) = undef;
    if ($_[0]->{'file'})       { $file       = $_[0]->{'file'};        } else { croak("No HDFS file given to open"); }
    if ($_[0]->{'offset'})     { $offset     = $_[0]->{'offset'};      } 
    if ($_[0]->{'length'})     { $length     = $_[0]->{'length'};      } 
    if ($_[0]->{'buffersize'}) { $buffersize = $_[0]->{'buffersize'};  } 

    my $url;
	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=OPEN';	
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=OPEN' . '&user.name=' . $self->{'user'};
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=OPEN' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}
    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }

    if ($offset) { 
        $url = $url . "&offset=" . $offset;
    }

    if ($length) { 
        $url = $url . "&length=" . $length;
    }

    if ($buffersize) { 
        $url = $url . "&buffersize=" . $buffersize;
    }

    $self->get( $url );
    return $self;
}

sub getfilestatus {
	# curl -i  "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETFILESTATUS"
    my ( $self, $file ) = undef;
    $self = shift;
    if ($_[0]->{'file'}) { $file = $_[0]->{'file'}; } else { croak ("Need HDFS filename before listing status") ;}
    
    my $url;
	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=GETFILESTATUS';	
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=GETFILESTATUS' . '&user.name=' . $self->{'user'};
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=GETFILESTATUS' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}
    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }
    $self->get( $url );
    return $self;
}

# Added as  LWP::UserAgent and WWW:Mechanize don't have delete 
# stolen from http://code.google.com/p/www-mechanize/issues/detail?id=219
sub _SUPER_delete {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::DELETE( @parameters ), @suff );
}

sub Delete {
	# curl -i -X DELETE "http://<host>:<port>/webhdfs/v1/<path>?op=DELETE[&recursive=<true|false>]"
    my ( $path, $recursive, $url ) = undef;
    my $self = shift; 

    if ($_[0]->{'path'})       { $path       = $_[0]->{'path'};     } else { croak("No HDFS path given to delete"); }
    if ($_[0]->{'recursive'})  { $recursive  = $_[0]->{'recursive'};} 

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=DELETE';	
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=DELETE' . '&user.name=' . $self->{'user'};
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=DELETE' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}
    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }

    if ($recursive) {
       $url = $url . "&recursive=true";
    } else {
       $url = $url . "&recursive=false";
    }

    $self->_SUPER_delete( $url );
    return $self;
}


sub create {
	# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=CREATE
	#                                         [&overwrite=<true|false>][&blocksize=<LONG>][&replication=<SHORT>]
	#                                         [&permission=<OCTAL>][&buffersize=<INT>]"
    my ( $self, $content, $file_src, $file_dest, $perms, $overwrite, $blocksize, $replication, $buffersize ) = undef;
    $self = shift; 
    if ($_[0]->{'permission'})  { $perms       = $_[0]->{'permission'};  } else { $perms = '000'; }
    if ($_[0]->{'overwrite'})   { $overwrite   = $_[0]->{'overwrite'};    } else { $overwrite='false'; } 
    if ($_[0]->{'srcfile'})     { $file_src    = $_[0]->{'srcfile'};      } else { croak ("Need local source file to copy to HDFS") ;}
    if ($_[0]->{'dstfile'})     { $file_dest   = $_[0]->{'dstfile'};      } else { croak ("Need HDFS destination before file create can happen") ;}
    if ($_[0]->{'blocksize'})   { $blocksize   = $_[0]->{'blocksize'};    }
    if ($_[0]->{'replication'}) { $replication = $_[0]->{'replication'};  }
    if ($_[0]->{'buffersize'})  { $buffersize  = $_[0]->{'buffersize'};   }
    my $url;
	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file_dest . '?op=CREATE&permission=' . $perms . '&overwrite=' . $overwrite ;	
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file_dest . '?op=CREATE&permission=' . $perms . '&overwrite=' . $overwrite . '&user.name=' . $self->{'user'};	
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file_dest . '?op=CREATE&permission=' . $perms . '&overwrite=' . $overwrite . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) { $url = $url . "&delegation=" . $self->{'webhdfstoken'};  }

    if ( $blocksize )   { $url = $url . "&blocksize="   . $blocksize   ; }
    if ( $replication ) { $url = $url . "&replication=" . $replication ; }
    if ( $buffersize )  { $url = $url . "&buffersize="  . $buffersize  ; }

    map_file($content => $file_src, "<");
    $self->put( $url, content => $content );
    return $self;
}

# TODO need to add 'append' method  - for people wanting to corrupt hdfs. :)

sub mkdirs {
	# curl -i -X PUT "http://<HOST>:<PORT>/<PATH>?op=MKDIRS[&permission=<OCTAL>]"
    my ( $self, $perms, $path, $url ) = undef;
    $self = shift; 
    if ($_[0]->{'path'})       { $path = $_[0]->{'path'};           } else { croak ("I need a HDFS location to create directory"); }
    if ($_[0]->{'permissons'}) { $perms = $_[0]->{'permisssions'};  } else { $perms = '000'; }


	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?&op=MKDIRS&permission=' . $perms ;
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?&op=MKDIRS&permission=' . $perms . '&user.name=' . $self->{'user'};	
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?&op=MKDIRS&permission=' . $perms . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }
    $self->put( $url );
    return $self;
}

sub getcontentsummary {
    # curl -i "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETCONTENTSUMMARY"
    my ( $self, $dir, $url ) = undef;
    $self = shift; 
    if ($_[0]->{'directory'}) { $dir = $_[0]->{'directory'};  } else { croak ("I need a HDFS directory to return content summary"); }

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $dir . '?op=GETCONTENTSUMMARY';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $dir . '?op=GETCONTENTSUMMARY' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $dir . '?op=GETCONTENTSUMMARY' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }
     
    $self->get( $url );
    return $self;
}


sub getfilechecksum {
    # get and return checksum for a file, curl -i  "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETFILECHECKSUM"
    my ( $self, $file, $url ) = undef;
    $self = shift; 
    if ($_[0]->{'file'}) { $file = $_[0]->{'file'};  } else { croak ("I need a HDFS filename to get checksum"); }

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=GETFILECHECKSUM';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=GETFILECHECKSUM' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $file . '?op=GETFILECHECKSUM' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }
     
    $self->get( $url );
    return $self;
}

sub gethomedirectory {
    # curl -i "http://<HOST>:<PORT>/webhdfs/v1/?op=GETHOMEDIRECTORY"
    my $self = shift; 
    my $url;

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1?op=GETHOMEDIRECTORY';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1?op=GETHOMEDIRECTORY' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1?op=GETHOMEDIRECTORY' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }
     
    $self->put( $url );
    return $self;
}

sub setpermission {
    # curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETPERMISSION[&permission=<OCTAL>]"
    my ( $self, $path, $url, $perms ) = undef;
    $self = shift; 
    if ($_[0]->{'path'}) { $path = $_[0]->{'path'};  } else { croak ("I need a HDFS path to set permmissions"); }
    if ($_[0]->{'permissison'}) { $perms = $_[0]->{'permisssion'};  } 

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETPERMISSION';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETPERMISSION' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETPERMISSION' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }

    if ($perms) {
        $url = $url . "&permission=" . $perms;
    }

    $self->put( $url );
    return $self;
}

sub setowner {
   # curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETOWNER[&owner=<USER>][&group=<GROUP>]"
    my ( $self, $path, $user, $group, $url ) = undef;
    $self = shift; 
    if ($_[0]->{'path'} )  { $path =  $_[0]->{'path'};  } else { croak ("I need a HDFS path before changing ownership"); }
    if ($_[0]->{'user'} )  { $user =  $_[0]->{'user'};  } 
    if ($_[0]->{'group'})  { $group = $_[0]->{'group'}; } 

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETOWNER';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETOWNER' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETOWNER' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ($user) {
        $url = $url . "&owner=" . $user;
    }
    if ($group) {
        $url = $url . "&group=" . $group;
    }

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }

    $self->put( $url );
    return $self;
}


sub setreplication {
  #curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETREPLICATION[&replication=<SHORT>]"
    my ( $self, $path, $rep,$url ) = undef;
    $self = shift; 
    if ($_[0]->{'path'} )  { $path =  $_[0]->{'path'};  } else { croak ("I need a HDFS path before changing ownership"); }
    if ($_[0]->{'replication'} )  { $rep =  $_[0]->{'replication'};  } 

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETREPLICATION';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETREPLICATION' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETREPLICATION' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ($rep) {
        $url = $url . "&replication=" . $rep;
    }

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }

    $self->put( $url );
    return $self;
}


sub settimes {
   # curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETTIMES[&modificationtime=<TIME>][&accesstime=<TIME>]"
   
    my ( $url, $self, $path, $modtime, $accesstime ) = undef;
    $self = shift; 
    if ($_[0]->{'path'} )  { $path =  $_[0]->{'path'};  } else { croak ("I need a HDFS path before changing ownership"); }
    if ($_[0]->{'modificationtime'} )  { $modtime =  $_[0]->{'modificationtime'};  } 
    if ($_[0]->{'accesstime'} )  { $accesstime =  $_[0]->{'accesstime'};  } 

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETTIMES';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETTIMES' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=SETTIMES' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ($modtime) {
        $url = $url . "&modificationtime=" . $modtime;
    }

    if ($accesstime) {
        $url = $url . "&accesstime=" . $accesstime;
    }

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }

    $self->put( $url );
    return $self;

}


sub liststatus {
    # list contents of directory, curl -i  "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=LISTSTATUS"
    my ( $self, $path, $url ) = undef;
    $self = shift; 
    if ($_[0]->{'path'}) { $path = $_[0]->{'path'};  } else { croak ("I need a HDFS pathname to get status"); }

	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=LISTSTATUS';
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=LISTSTATUS' .  '&user.name=' . $self->{'user'}; ;
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $path . '?op=LISTSTATUS' . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }
    $self->get( $url );
    return $self;
}

sub rename {
	# curl -i -X PUT "<HOST>:<PORT>/webhdfs/v1/<PATH>?op=RENAME&destination=<PATH>"
	#my $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $src . '?op=RENAME&destination=' . $dst;

    my ( $self, $src, $dst ) = undef;
    $self = shift; 
    if ($_[0]->{'srcfile'})     { $src  = $_[0]->{'srcfile'}; } else { croak ("Need HDFS source before rename can happen") ;}
    if ($_[0]->{'dstfile'})     { $dst = $_[0]->{'dstfile'}; } else { croak ("Need HDFS destination before rename can happen") ;}
	
    my $url;
	if ($self->{'authmethod'} eq 'gssapi') { 
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $src . '?op=RENAME&destination=' . $dst ;
	} elsif ( $self->{'authmethod'} eq 'unsecure' ) {
       croak ("I need a 'user' value if authmethod is 'none'") if ( !$self->{'user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $src . '?op=RENAME&destination=' . $dst . '&user.name=' . $self->{'user'};	
	} elsif ( $self->{'authmethod'} eq 'doas' ) {
       croak ("I need a 'user' value if authmethod is 'doas'") if ( !$self->{'user'} ) ;
       croak ("I need a 'doas_user' value if authmethod is 'doas'") if ( !$self->{'doas_user'} ) ;
       $url = 'http://' . $self->{'namenode'} . ':' . $self->{'namenodeport'} . '/webhdfs/v1' . $src . '?op=RENAME&destination=' . $dst  . '&user.name=' . $self->{'user'} . '&doas=' . $self->{'doas_user'};
	}

    if ( $self->{'webhdfstoken'} ) {
        $url = $url . "&delegation=" . $self->{'webhdfstoken'};
    }
    $self->put( $url );
}


=pod

=head1 NAME

Apache::Hadoop::WebHDFS - interface to Hadoop's WebHDS API that supports GSSAPI/SPNEGO (secure) access.

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

Hadoop's WebHDFS API, is a rest interface to HDFS.  This module provides 
a perl interface to the API, allowing one to both read and write files to 
HDFS.  Because Apache::Hadoop::WebHDFS supports GSSAPI, it can be used to 
interface with secure Hadoop Clusters.  This module also supports WebHDFS connections
with unsecure grids   

Apache::Hadoop::WebHDFS is a subclass of WWW:Mechanize, so one could 
reference WWW::Mechanize methods if needed.  One will note that 
WWW::Mechanize is a subclass of LWP, meaning it's possible to also reference 
LWP methods from Apache::Hadoop::WebHDFS.  For example to debug the GSSAPI
calls used during the request, enable LWP::Debug by adding 'use LWP::Debug qw(+);' to your script.

Content returned from WebHDFS is left in the native JSON format. Including your favorite JSON module like JSON::Any 
will help with mangaging the JSON output.   To get access to the content stored in your Apache::Hadoop::WebHDFS object,
use the methods provided by WWW::Mechanize, such as 'success', 'status', and 'content'.  Please see 'EXAMPLE' below
for how this is used.


=head1 METHODS 

=over 3

=item * new() - creates a new WebHDFS object. Required keys are 'user', 'namenode', 'namenodeport', and 'authmethod'.  Default values for 'namenode' and 'namenodeport' are listed below. The default value for authmethod is 'gssapi', which is used on grids where SPNEGO has been enabled.  The 'doasuser' is optional and intended to be used when proxying the WebHDFS request as another user.
         
       my $hdfsclient =  new({ namenode     => "localhost",
                               namenodeport => "50070",
                               authmethod   => "gssapi|unsecure|doas",
                               user         => 'user1',
                               doasuser     => 'user2',
                             });      
 

=item * getdelegationtoken() - gets a delegation token from the namenode.  This token is stored within the WebHDFS object and automatically appended to each WebHDFS request.   Delegation tokens are used on grids with security enabled.
    
       $hdfsclient->getdelegationtoken();

=item * renewdelegationtoken()  - renews a delegation token from the namenode. 

       $hdfsclient->renewdelegationtoken();

=item * canceldelegationtoken() - informs the namenode to invalidate the delegation token as it's no longer needed.   When calling this method, the delegation token is also removed from the perl WebHDFS object.

       $hdfsclient->canceldelegationtoken();

=item * Open() - opens file on HDFS and returns it's content The only required value for Open() is 'file', all others are optional.  The values, 'offset', 'length', and 'buffersize', are meant to be sized in bytes.

        $hdfsclient->Open({ file=>'/path/to/my/hdfs/file',
                            offset=>'1024',    
                            length=>'2048',
                            buffersize=>'1024',
                           });

=item * create() - creates and writes to a file on HDFS Required values for create are 'srcfile' which is local, and dstfile which is the path for the new file on HDFS.  'blocksize' is represented in bytes and 'overwrite' has two valid values of 'true' or 'false'. While not required, if permissions are not provided they will default to '000'.

         $hdfsclient->create({ srcfile=>'/my/local/file.txt',
                               dstfile=>'/my/hdfs/location/file.txt',
                               blocksize=>'524288',
                               replication=>'3',
                               buffersize=>'1024',
                               overwrite=>'true|false',
                               permission=>'644',
                              });

=item * rename()  - renames a file on HDFS.  Required values for rename are 'srcfile' and 'dstfile', both of which represent HDFS filenames.
  
         $hdfsclient->rename({ srcfile=>'/my/old/hdfs/file.txt',
                               dstfile=>'my/new/hdfs/file.txt',
                             });

=item * getfilestatus() - returns a json structure containing status of file or directory.  Required input is a HDFS path.
   
         $hdfsclient->getfilestatus({ file=>'/path/to/my/hdfs/file.txt' });

=item * liststatus() - returns a json structure of contents inside a directory.  Note the timestamps are java timestamps so divide by 1000 to convert to ctime before attempting to format time value.
   
         $hdfsclient->liststatus({ path=>'/path/to/my/hdfs/directory' });

=item *  mkdirs() - creates a directory on HDFS.  The only required input value is path.  Their is an optional input value named permissions and if not provided will default to '000'.

         $hdfsclient->mkdirs({ path=>'/path/to/my/hdfs/directory',
                               permissions=>'755', 
          });

=item * getfilechecksum() - gets HDFS checksum on file.  Note this is the crc32 checksum that HDFS uses to detect file corruption. It's not the checksum of the file itself.  The only required input value is 'file'.

         $hdfsclient->getfilechecksum({ file=>'/path/to/my/hdfs/directory' });

=item * Delete() - removes file or directories from HDFS.  The only required input value is 'path'.  The other optional value is 'recursive' which takes a 'true|false' arguement.

         $hdfsclient->Delete({ path=>'/path/to/my/hdfs/directory',
                               recursive=>'true|false',
         });

=item * getcontentsummary() - list metadata information on a directory. This includes things like file count and quota usage for that directory.   The only input value is a path to a HDFS directory.

         $hdfsclient->getcontentsummary({ directory=>'/path/to/my/hdfs/directory' });

=item * getfilestatus() - returns access times, blocksize, and permissions on a HDFS file.

         $hdfsclient->getfilestatus({ file=>'/path/to/my/hdfs/file' });

=item *  gethomedirectory() - returns path to the home directory for the user or 'proxy user'. There is no input for this method.

         $hdfsclient->gethomedirectory();

=item *  setowner() - changes owner and group ownership on a file or directory on HDFS.  The only required input is 'path'.

         $hdfsclient->setowner({ path=>'/path/to/my/hdfs/directory',
                               user=>'cartman',
                               group=>'fifthgraders',
         });

=item *  setpermission() - changes owner and group permissions on a file or directory on HDFS.  Path is required and permissions are optional.  

         $hdfsclient->setpermisssion({ path=>'/path/to/my/hdfs/directory',
                                       permisssion=>'640',
         });


=item *  setreplication() - changes replication count for a file on HDFS.  Path is required, replication is optional.

         $hdfsclient->setreplication({ path=>'/path/to/my/hdfs/directory',
                                       replication=>'10',
         });


=item *  settimes() - changes access and modifcation time for a file or directory on HDFS.   Path is required, both access and modification times are optional.  Remember these times are in java time, so make sure to convert ctime to java time by multiplying by 1000.

         $hdfsclient->setreplication({ path=>'/path/to/my/hdfs/directory',
                                       modificationtime=>$mymodtime,
                                       accesstime=>$myatime,
         });

=back


=head1 REQUIREMENTS

 Carp                   is used for various warnings and errors.
 WWW::Mechanize         is needed as this is a subclass.
 LWP::Debug             is required for debugging GSSAPI connections
 LWP::Authen::Negotiate is the magic sauce for working with secure hadoop clusters 
 parent                 included with Perl 5.10.1 and newer or found on CPAN for older versions of perl
 File::Map              required for reading contents of files into mmap'ed memory space instead of perl's symbol table.

=head1 EXAMPLE

=head2 list a HDFS directory on a secure hadop cluster

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Data::Dumper;
  use Apache::Hadoop::WebHDFS;
  my $username=getlogin();
  my $hdfsclient = Apache::Hadoop::WebHDFS->new( {namenode        =>"mynamenode.example.com",
                                                  namenodeport    =>"50070",
                                                  authmethod      =>"gssapi",
                                                  user            =>$username,
                                                 });
  $hdfsclient->liststatus( {path=>'/user/$username'} );        
  if ($hdfsclient->success()) {
     print "Request SUCCESS: ", $hdfsclient->status() , "\n\n";
     print "Dumping content:\n";
     print Dumper $hdfsclient->content() ;
  } else {
     print "Request FAILED: ", $hdfsclient->status() , "\n";
  } 

	  
=head1 AUTHOR

Adam Faris, C<< <apache-hadoop-webhdfs at mekanix.org> >>

=head1 BUGS

  Please use github to report bugs and feature requests 
  https://github.com/opsmekanix/Apache-Hadoop-WebHDFS/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache::Hadoop::WebHDFS


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache-Hadoop-WebHDFS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache-Hadoop-WebHDFS>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache-Hadoop-WebHDFS/>

=back


=head1 ACKNOWLEDGEMENTS

I would like to acknowledge Andy Lester plus the numerous people who have 
worked on WWW::Mechanize, Anchim Grolms and team for providing 
LWP::Authen::Negotiate, and the contributors to LWP.  Thanks for providing 
awesome modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Adam Faris.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut


return 1;
