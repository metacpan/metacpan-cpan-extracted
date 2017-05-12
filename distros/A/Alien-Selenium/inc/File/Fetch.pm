#line 1 "inc/File/Fetch.pm - /Users/kane/sources/p4/other/file-fetch/lib/File/Fetch.pm"
package File::Fetch;

use strict;
use FileHandle;
use File::Copy;
use File::Spec 0.82;
use File::Spec::Unix;
use File::Fetch::Item;
use File::Basename              qw[dirname];

use Cwd                         qw[cwd];
use IPC::Cmd                    qw[can_run run];
use File::Path                  qw[mkpath];
use Params::Check               qw[check];
use Module::Load::Conditional   qw[can_load];

use vars    qw[ $VERBOSE $PREFER_BIN $FROM_EMAIL $USER_AGENT
                $BLACKLIST $METHOD_FAIL $VERSION $METHODS
                $FTP_PASSIVE $DEBUG
            ];

$VERSION        = 0.02;
$PREFER_BIN     = 0;        # XXX TODO implement
$FROM_EMAIL     = 'File-Fetch@example.com';
$USER_AGENT     = 'File::Fetch/$VERSION';
$BLACKLIST      = [qw|ftp|];
$METHOD_FAIL    = { };
$FTP_PASSIVE    = 1;
$DEBUG          = 0;

### methods available to fetch the file depending on the scheme
$METHODS = {
    http    => [ qw|lwp wget curl lynx| ],
    ftp     => [ qw|lwp netftp wget curl ncftp ftp| ],
    file    => [ qw|lwp| ],
    #rsync   => [ qw|rsync| ], # XXX TODO
};

### silly warnings ###
local $Params::Check::VERBOSE     = $Params::Check::VERBOSE     = 1;
local $Module::Load::Conditional  = $Module::Load::Conditional  = 0;

#line 88

sub new {
    my $class = shift;
    my %hash  = @_;
    
    my ($uri);
    my $tmpl = {
        uri => { required => 1, store => \$uri },
    };

    check( $tmpl, \%hash ) or return;

    ### parse the uri to usable parts ###
    my $href    = __PACKAGE__->_parse_uri( $uri ) or return;
    
    ### make it into a FFI object ###
    my $ffi     = File::Fetch::Item->new( %$href ) or return;


    ### return the object ###
    return $ffi;
}

### parses an uri to a hash structure:
###
### $class->_parse_uri( 'ftp://ftp.cpan.org/pub/mirror/index.txt' )
###
### becomes:
###
### $href = {
###     scheme  => 'ftp',
###     host    => 'ftp.cpan.org',
###     path    => '/pub/mirror',
###     file    => 'index.html'
### };
###
sub _parse_uri {
    my $self = shift;
    my $uri  = shift or return;
    
    my $href = { uri => $uri };
    
    ### find the scheme ###
    $uri            =~ s|^(\w+)://||;
    $href->{scheme} = $1;
  
    ### file:// paths have no host ###
    if( $href->{scheme} eq 'file' ) {
        $href->{path} = $uri;
        $href->{host} = '';
    
    } else {
        @{$href}{qw|host path|} = $uri =~ m|([^/]*)(/.*)$|s;
    }
 
    ### split the path into file + dir ###
    {   my @parts = File::Spec::Unix->splitpath( delete $href->{path} );
        $href->{path} = $parts[1];
        $href->{file} = $parts[2];
    }       
 
 
    return $href;
}

#line 162

sub fetch {
    my $self = shift or return;
    my %hash = @_;
    
    my $to;
    my $tmpl = {
        to  => { default => cwd(), store => \$to },       
    };
    
    check( $tmpl, \%hash ) or return;
    
    ### create the path if it doesn't exist yet ###
    unless( -d $to ) {             
        eval { mkpath( $to ) };
        if( $@ ) {
            warn "Could not create path '$to'\n";
            return;
        }
    }               
   
    ### set passive ftp if required ###
    local $ENV{FTP_PASSIVE} = $FTP_PASSIVE;

    ### 
    for my $method ( @{ $METHODS->{$self->scheme} } ) {
        my $sub =  '_'.$method.'_fetch';
        
        unless( __PACKAGE__->can($sub) ) {
            warn "Can not call method for '$method' -- WEIRD!\n";
            next;
        }

        ### method is blacklisted ###
        next if grep { lc $_ eq $method } @$BLACKLIST;

        ### method is known to fail ###
        next if $METHOD_FAIL->{$method};
             
        if(my $file = $self->$sub(to=>File::Spec->catfile($to,$self->file))){
            
            unless( -e $file && -s _ ) {
                warn "'$method' said it fetched '$file', ".
                     "but it was not created\n";

                ### mark the failure ###
                $METHOD_FAIL->{$method} = 1;
            
                next;
            
            } else {
            
                my $abs = File::Spec->rel2abs( $file );
                return $abs;
            }
        } 
    }
    
    
    ### if we got here, we looped over all methods, but we weren't able 
    ### to fetch it.
    return;
}        

#line 256

########################
### _*_fetch methods ###
########################

### LWP fetching ###
sub _lwp_fetch {
    my $self = shift;
    my %hash = @_;
    
    my ($to);
    my $tmpl = {
        to  => { required => 1, store => \$to }
    };     
    check( $tmpl, \%hash ) or return;

    ### modules required to download with lwp ###
    my $use_list = {
        LWP                 => '0.0',
        'LWP::UserAgent'    => '0.0',
        'HTTP::Request'     => '0.0',
        'HTTP::Status'      => '0.0',
        URI                 => '0.0',

    };

    if( can_load(modules => $use_list) ) {
      
        ### setup the uri object
        my $uri = URI->new( File::Spec::Unix->catfile(
                                    $self->path, $self->file
                        ) );

        ### special rules apply for file:// uris ###
        $uri->scheme( $self->scheme );
        $uri->host( $self->scheme eq 'file' ? '' : $self->host );                        
        $uri->userinfo("anonymous:$FROM_EMAIL") if $self->scheme ne 'file';

        ### set up the useragent object 
        my $ua = LWP::UserAgent->new();
        $ua->agent( $USER_AGENT );
        $ua->from( $FROM_EMAIL );
        $ua->env_proxy;
    
        my $res = $ua->mirror($uri, $to) or return;

        ### uptodate or fetched ok ###
        if ( $res->code == 304 or $res->code == 200 ) {
            return $to;
        
        } else {
            warn "Fetch failed! HTTP response code: '". $res->code ."' [".
            HTTP::Status::status_message($res->code). "]\n";     
            return;            
        }
    
    } else {       
        $METHOD_FAIL->{'lwp'} = 1;
        return;
    }
}          

### Net::FTP fetching    
sub _netftp_fetch {
    my $self = shift;
    my %hash = @_;
    
    my ($to);
    my $tmpl = {
        to  => { required => 1, store => \$to }
    };     
    check( $tmpl, \%hash ) or return;
    
    ### required modules ###
    my $use_list = { 'Net::FTP' => 0 };
                
    if( can_load( modules => $use_list ) ) {

        ### make connection ###    
        my $ftp;
        unless( $ftp = Net::FTP->new( $self->host ) ) {
            warn "Ftp creation failed: $@";
            return;
        }
        
        ### login ###
        unless( $ftp->login( anonymous => $FROM_EMAIL ) ) {
            warn "Could not login to '".$self->host."'\n";
            return;
        }
        
        ### set binary mode, just in case ###
        $ftp->binary;
        
        ### create the remote path ###
        my $remote = File::Spec->catfile( $self->path, $self->file );
    
        ### fetch the file ###
        my $target;
        unless( $target = $ftp->get( $remote, $to ) ) {
            warn "Could not fetch '$remote' from '".$self->host."'\n";
            return;
        }
        
        ### log out ###
        $ftp->quit;
        
        return $target;
        
    } else {       
        $METHOD_FAIL->{'netftp'} = 1;
        return;
    }    
}    

### /bin/wget fetch ###
sub _wget_fetch {    
    my $self = shift;
    my %hash = @_;
    
    my ($to);
    my $tmpl = {
        to  => { required => 1, store => \$to }
    };     
    check( $tmpl, \%hash ) or return;
    
    ### see if we have a wget binary ###
    if( my $wget = can_run('wget') ) {
        
        ### no verboseness, thanks ###
        my $cmd = [ $wget, '--quiet' ];
        
        ### run passsive if specified ###
        push @$cmd, '--passive-ftp' if $FTP_PASSIVE; 
        
        ### set the output document, add the uri ###
        push @$cmd, '--output-document', $to, $self->uri;                      

        ### shell out ###
        my $captured;
        unless( run( command => $cmd, buffer => \$captured, verbose => 0 ) ) {
            warn "Command failed: $captured";
            return;
        } 
    
        return $to;
    
    } else {
        $METHOD_FAIL->{'wget'} = 1;
        return;
    }            
}    


### /bin/ftp fetch ###
sub _ftp_fetch {    
    my $self = shift;
    my %hash = @_;
    
    my ($to);
    my $tmpl = {
        to  => { required => 1, store => \$to }
    };     
    check( $tmpl, \%hash ) or return;
    
    ### see if we have a wget binary ###
    if( my $ftp = can_run('ftp') ) {
        
        my $fh = FileHandle->new;

        local $SIG{CHLD} = 'IGNORE';
        
        unless ($fh->open("|$ftp -n")) {
            warn "/bin/ftp creation failed: $!\n";
            return;
        }

        my @dialog = (
            "lcd " . dirname($to),
            "open " . $self->host,
            "user anonymous $FROM_EMAIL",
            "cd /",
            "cd " . $self->path,
            "binary",
            "get " . $self->file . " " . $self->file,
            "quit",
        );

        foreach (@dialog) { $fh->print($_, "\n") }
        $fh->close;

        return $to;
    }
}

### lynx is stupid - it decompresses any .gz file it finds to be text
### use /bin/lynx to fetch files
sub _lynx_fetch {
    my $self = shift;
    my %hash = @_;
    
    my ($to);
    my $tmpl = {
        to  => { required => 1, store => \$to }
    };     
    check( $tmpl, \%hash ) or return;
    
    ### see if we have a wget binary ###
    if( my $lynx = can_run('lynx') ) {
        
        
        ### write to the output file ourselves, since lynx ass_u_mes to much 
        my $local = FileHandle->new(">$to") 
                        or (
                            warn ("Could not open '$to' for writing: $!\n"), 
                            return 
                        );
        
        ### dump to stdout ###
        my $cmd = [
            $lynx,
            '-source',
            "-auth=anonymous:$FROM_EMAIL",
            $self->uri
        ];
        
        ### shell out ###
        my $captured;
        unless(run( command => $cmd, 
                    buffer  => \$captured, 
                    verbose => $DEBUG ) 
        ) {
            warn "Command failed: $captured";
            return;
        } 
    
        ### print to local file ###
        $local->print( $captured );
        $local->close or return;
    
        return $to;
    
    } else {
        $METHOD_FAIL->{'lynx'} = 1;
        return;
    }            
}    

### use /bin/ncftp to fetch files
sub _ncftp_fetch {
    my $self = shift;
    my %hash = @_;
    
    my ($to);
    my $tmpl = {
        to  => { required => 1, store => \$to }
    };     
    check( $tmpl, \%hash ) or return;
    
    ### we can only set passive mode in interactive sesssions, so bail out
    ### if $FTP_PASSIVE is set
    return if $FTP_PASSIVE;
    
    ### see if we have a wget binary ###
    if( my $ncftp = can_run('ncftp') ) {
        
        my $cmd = [
            $ncftp,
            '-V',                   # do not be verbose
            '-p', $FROM_EMAIL,      # email as password
            $self->host,            # hostname
            dirname($to),           # local dir for the file
                                    # remote path to the file
            File::Spec::Unix->catdir( $self->path, $self->file ),
        ];
        
        ### shell out ###
        my $captured;
        unless(run( command => $cmd, 
                    buffer  => \$captured, 
                    verbose => $DEBUG ) 
        ) {
            warn "Command failed: $captured";
            return;
        } 
    
        return $to;
    
    } else {
        $METHOD_FAIL->{'ncftp'} = 1;
        return;
    }            
}    

### use /bin/curl to fetch files
sub _curl_fetch {
    my $self = shift;
    my %hash = @_;
    
    my ($to);
    my $tmpl = {
        to  => { required => 1, store => \$to }
    };     
    check( $tmpl, \%hash ) or return;
    
    if (my $curl = can_run('curl')) {

        ### these long opts are self explanatory - I like that -jmb
	    my $cmd = [ $curl ];

	    push(@$cmd, '--silent') unless $DEBUG;

        ### curl does the right thing with passive, regardless ###
    	if ($self->scheme eq 'ftp') {
    		push(@$cmd, '--user', "anonymous:$FROM_EMAIL");
    	}

        push @$cmd, '--fail', '--output', $to, $self->uri;

        my $captured;
        unless(run( command => $cmd,
                    buffer  => \$captured,
                    verbose => $DEBUG ) 
        ) {
        
            warn "command failed: $captured";
            return;
        }

        return $to;

    } else {
        $METHOD_FAIL->{'curl'} = 1;
        return;
    }
}


### use File::Copy for fetching file:// urls ###
### XXX file:// uri to local path conversion is just too weird...
### depend on LWP to do it for us
# sub _file_fetch {
#     my $self = shift;
#     my %hash = @_;
#     
#     my ($to);
#     my $tmpl = {
#         to  => { required => 1, store => \$to }
#     };     
#     check( $tmpl, \%hash ) or return;
#     
#     my $remote = File::Spec->catfile( $self->path, $self->file );
#     
#     ### File::Copy is littered with 'die' statements :( ###
#     my $rv = eval { File::Copy::copy( $remote, $to ) };
#     
#     ### something went wrong ###
#     if( !$rv or $@ ) {
#         warn "Could not copy '$remote' to '$to': $! $@";
#         return;
#     }
#     
#     return $to;
# }

1;

#line 778

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
         



