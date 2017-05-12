#$Id: Language.pm,v 1.18 1999/04/18 22:03:35 gozer Exp $
package Apache::Language;

use strict;
use DynaLoader ();
use vars qw(%CACHE $VERSION @ISA $DEBUG $DEFAULT_HANDLER $AUTOLOAD %DEBUG);

use Apache::Language::Constants;
use Apache::ModuleConfig;
use IO::File;
use Data::Dumper;
use I18N::LangTags qw(is_language_tag similarity_language_tag same_language_tag);

@ISA = qw(DynaLoader);
$VERSION = '0.14';
$DEBUG=0;

#print STDERR "Apache::Language $VERSION (gozer-devel) loaded\n";

$DEFAULT_HANDLER =  __PACKAGE__ . "::PlainFile";
eval "use $DEFAULT_HANDLER";
die "Can't load default LanguageHandler : $@" if $@;

if ($ENV{'MOD_PERL'}){
        __PACKAGE__->bootstrap($VERSION);
        if (Apache->module('Apache::Status')) {
		Apache::Status->menu_item('Language' => 'Apache::Language status', \&status);
		}
    }

sub CLEAR { warn "CLEAR method is not implemented in ",__PACKAGE__};
sub DELETE { warn "DELETE method is not implemented in ",__PACKAGE__};
#sub DESTROY { die "DESTROY method is not implemented in ",__PACKAGE__};

sub FIRSTKEY {
    warning("FIRSTKEY",L_TRACE);   
    my $self = shift;
    unless ($self->{Listed}){
        foreach my $container (@ {$self->{Handlers}}){
            $self->{Listed} = $container if $self->{$container}{listable};
            last if $self->{Listed};
            }
    }
    return undef unless $self->{Listed};
    my $conthash = $self->{$self->{Listed}}{DATA};
    return $self->{Listed}->firstkey($self,$self->{$self->{Listed}}{DATA});
    }

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    warning("NEXTKEY($lastkey)",L_TRACE);
    return undef unless $self->{Listed};
    return $self->{Listed}->nextkey($self,$self->{$self->{Listed}}{DATA});
    }

sub FETCH {
    my ($self, $key, $test) = @_;
    warning("FETCH($key)",L_TRACE);
    #$key =~ m|^([^/]*)(/(.*))?$|;
    
    $key =~ m{^(([^\\/]|\\/|\\)*)/?(.*)$};
    $key = $1;
    my $lang = $3;
    
    $key =~ s|\\/|/|g;


    my $value;
    foreach my $container (@ {$self->{Handlers}}){
        warning("${container}::fetch($key)",L_MAX);
        my $conthash = $self->{$container}{DATA};
        $value ||= $container->fetch($self,$conthash,$key,$lang);
        #Configurable default language/s
        if (not defined $lang and not defined $value){
            foreach my $default (@ {$self->{Config}{LanguageDefault}}){
                $value ||= $container->fetch($self,$conthash,$key,$default);
                last if $value;
                }
            }
        last if $value;
        }
		
	if($value)
		{
			$value = $DEBUG{prefix} . $value if(exists $DEBUG{prefix});
			$value = $value . $DEBUG{postfix} if(exists $DEBUG{postfix});
			return $value;
		}
    elsif($test) #we didn't find any match.  If testing, return undef, else return at least the key
		{
			return undef;
		}
	else      
		{
		$key = $DEBUG{notfoundprefix} . $key if(exists $DEBUG{notfoundprefix});
		$key = $key . $DEBUG{notfoundpostfix} if(exists $DEBUG{notfoundpostfix});
		return $key;	
		}


    }

sub STORE {
    my ($self, $key, $value) = @_;
    warning("STORE($key/$value)",L_TRACE);
    $key =~ m|^([^/]*)(/(.*))?$|;
    my $result;
    foreach my $container (@ {$self->{Handlers}}){
        my $conthash = $self->{$container}{DATA};
        next unless $self->{$container}{storable};
        warning("STORE needs a language specification to work") unless defined $3;
        $result = $container->store($self,$conthash,$1,$3,$value);
        last if (L_OK == $result);
        }
    return $result;
}

sub EXISTS {
    my ($self, $key) = @_;
    warning("EXISTS($key)",L_TRACE);
    $key =~ m|^([^/]*)(/(.*))?$|;
    #call FETCH in test mode just to know if it could be fetched
    return FETCH($self,$key,'test');
    }

sub TIEHASH {
    my $class = shift;
    my $r = shift;
    my $package = shift;
    my $filename = shift;
    my @extra_args = @_;
    unless (defined $package) {
        die __PACKAGE__ . " can't be directly tied to, try the new() function instead";
        }
    my $cfg = Apache::ModuleConfig->get($r);
    my $modified=1;
    ##This is a real mess, clean-up required in the handling of the cache
    
     if (exists $CACHE{$package}) {
        $modified = 0;
        $CACHE{$package}{Request} = $r;
        $CACHE{$package}{Config} = $cfg;
        $CACHE{$package}{Extra_Args} = [@extra_args];
        foreach my $handler (@ {$CACHE{$package}{Handlers}}){
            if ($handler->modified($CACHE{$package},$CACHE{$package}{$handler}{DATA})){
                warning("re-init on $handler/$package",L_VERBOSE);
                $handler->initialize($CACHE{$package},$CACHE{$package}{$handler}{DATA});
                }
            }
        
        }
     
	 if ($modified)	{
        #warn "Initializing!";
		#Populate new object with useful information
       
        my $config =	{
				Filename	=> $filename,
				Package		=> $package,
                };
                
        $CACHE{$package} = bless $config, $class;
        
        my @handler_list = ();
        my @handler_ok = ();
        
        @handler_list =  @ {$cfg->{handlers}}if ($cfg->{handlers});
        push @handler_list, $DEFAULT_HANDLER ;
        $CACHE{$package}{Request} = $r;
        $CACHE{$package}{Config} = $cfg;
        $CACHE{$package}{Extra_Args} = [@extra_args];
        foreach my $container (@handler_list)
            {
            if ($container->can('initialize')){
               $CACHE{$package}{$container}{DATA} = {};
                my $return = $container->initialize($CACHE{$package}, $CACHE{$package}{$container}{DATA});
                if (L_OK == $return){
                    warning("$container Initialized",L_VERBOSE);
                    push @handler_ok, $container;
                    #These could be cached
                    $CACHE{$package}{$container}{storable} = 1 if $container->can('store');
                    $CACHE{$package}{$container}{listable} = 1 if $container->can('firstkey') && $container->can('nextkey');
                    $CACHE{$package}{$container}{deletable} = 1 if $container->can('delete');
                    }
               
                unless (L_OK == $return)
                    {
                    warning("$container rejected $package",L_VERBOSE);
                    delete $CACHE{$package}{$container};
                    }
                }
            else {
                warning("$container->initialize not defined");
                }
            }
        $CACHE{$package}{Handlers} = \@handler_ok;        
        }
    $CACHE{$package}{Request} = $r;
    $CACHE{$package}{Config} = $cfg;
    $CACHE{$package}{Lang} = get_lang($r, $cfg);
    $CACHE{$package}{Extra_Args} = [@extra_args];
    
    return $CACHE{$package};
}


#parses the HTTP headers the client sent to figure out what languages are wanted.
sub get_lang {
	#What language this request should be served with ?
	my ($r, $cfg) = @_;
   my %args = $r->args;
	my $value = 1;	
	my %pairs;
	foreach (split(/,/, $r->header_in("Accept-Language"))){
		s/\s//g;	#strip spaces
		if (m/;q=([\d\.]+)/){	
			#is it in the "en;q=0.4" form ?
			$pairs{lc $`}=$1 if $1 > 0;
			}
		else	{
			#give the first one a q of 1
			$pairs{lc $_} = $value;
			#and the others .001 less every time
			$value -= 0.001;
			}
		}
     my @language_list = sort {$pairs{$b} <=> $pairs{$a}} keys %pairs;    
     
     unshift @language_list, @ { $cfg->{LanguageForced}} if defined $cfg->{LanguageForced};
     unshift @language_list, $args{'lang'} if is_language_tag($args{'lang'}) ;
       
return \@language_list;
}

#CLASS METHODS
sub new {
    my $class = shift;
    my $r = Apache->request;
    my ($package, $filename, $line) = caller;
    my $hash = {};
    tie (%$hash, __PACKAGE__, $r, $package, $filename, @_);  
    return bless $hash, $class;
    }  

#Old call preserved for compatibility.
sub message {
    my ($self, $key, @args) = @_;
    return sprintf $self->{$key}, @args;
    }  
    
#returns the list of requested languages by the client    
sub lang {
    my $self = shift;
    $self = tied %$self if tied %$self;
    return $self->{Lang};
    }
#returns Apache $r
sub request {
    my $self = shift;
    $self = tied %$self if tied %$self;
    return $self->{Request};
    }
sub extra_args {
    my $self = shift;
    $self = tied %$self if tied %$self;
    return $self->{Extra_Args};
    }
#returns the handler stack
sub handlers {
    my $self = shift;
    $self = tied %$self if tied %$self;
    return @ {$self->{Handlers}};
    }
#returns the filename of the calling Module/Script
sub filename {
    my $self = shift;
    $self = tied %$self if tied %$self;
    return $self->{Filename};
    }

#returns the package name of the calling Module/Script
sub package {
    my $self = shift;
    $self = tied %$self if tied %$self;
    return $self->{Package};
    }
    
#Dumps the language object for debugging purposes.
sub dump {
    my $self = shift;
    $self = tied %$self if tied %$self;
    print "<PRE>";
    print Dumper $self;
    print "</PRE>";
    }

#given an ordered list of knowns languages, returns the best language 
#choice according to the client request
#Called mostly by LanguageHandlers to figure out what language to pick
sub best_lang {
    my ($self,@offered) = @_;
    my ($result, $language);

    $self = tied %$self if tied %$self;
    foreach my $want (@ {$self->{Lang}}) {
        foreach my $offer (@offered) {
            my $similarity = similarity_language_tag($offer, $want);
            if ($similarity){
                return $offer if same_language_tag($offer, $want);
                }
            if ($similarity > $result){
                $result = $similarity;
                $language = $offer;
                }
        }
    }
    return $language;
}

sub AUTOLOAD {
      my $self = shift;
      my $untiedself = tied %$self if tied %$self;
      my $name = $AUTOLOAD;
      return if $name =~ /::DESTROY$/;
      
      my $type = ref($self) || die "$self is not an object";
      
      $name =~ s/.*://;
      
      foreach my $container (@ {$untiedself->{Handlers}}){
         my $conthash = $untiedself->{$container}{DATA};
         return $container->$name($untiedself, $conthash, @_) if ($container->can($name));
         }
      warning( "No $name defined in any LanguageHandlers, sorry.",1);
      return undef;
}


#TEST HANDLER
sub handler {
    my $r = shift;
   
    my $test = Apache::Language->new($r);
    $r->send_http_header('text/html');
    print "Hello<BR>";
    #foreach (keys %$test){
    #    print "$_ is " . $test->{$_} . "<BR>";
     #   }
     print $test->{'Parent'};
    print "<HR><PRE>";
    print Dumper %CACHE;
    print "</PRE>";
    #delete $test->{'voo1'};
    #%$test = ();
    }



#STATUS
sub status {
	#Produce nice information if Apache::Status is enabled
	my ($r, $q) = @_;
	my @s;
	my $cfg = Apache::ModuleConfig->get($r);
    
	push (@s, "<B>" , __PACKAGE__ , " (ver $VERSION) statistics</B><BR>");
	
	
	#then list each module that has a language definition
	push (@s, "<HR><UL>");
	foreach my $module( sort keys %CACHE) {
		my $uri = $r->uri;
		my $name = $module;
		if ($name =~ /^Apache::ROOT/)
			{
			#print the nicer filename instead of the module name
			$name = $CACHE{$module}{Filename};
			}	
		push (@s, "<LI><A HREF=\"$uri?$module\">" . $name . "</A></LI>");

		{   
            push (@s, "<UL>");
            my %hash = {};    
            tie (%hash, __PACKAGE__, $r, $module, $CACHE{$module}{Filename});
            my $stuff;
            foreach (keys %hash) {
                $stuff=1;
                push (@s, "<LI>", $_ , "</LI>");
                }
            push (@s, "<LI>[<I>Module unlistable</I>]</LI>") unless $stuff;
            push (@s, "</UL>");
        }
            }
	push (@s, "</UL>");
	
   
    #my $dump = Dumper %CACHE;
    #push (@s, "<HR><PRE>$dump</PRE>");
	#smile!
	return \@s;
	}
    

##CONFIGURATION DIRECTIVES
use Apache::Constants qw(OK DECLINE_CMD);

sub DIR_CREATE {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{LanguageDefault} = [ 'en' ];
    $self->{handler_del} = [];
    $self->{handler_add} = [];
    $self->{LanguageDefaultActive} = 0;
    return $self;
    }
    
sub DIR_MERGE {
    my ($parent, $current) = @_;
    my $new_list;
    my @parent_list = ();
    @parent_list = @ {$parent->{handlers}} if $parent->{handlers};
   
	if (not defined $current->{handlers}){
        if (0 < scalar @ {$current->{handler_del}}){
            my @del_list;
            foreach my $parent_handler (@parent_list){
                my $found;
                foreach my $current_handler (@ {$current->{handler_del}}){
                    $found = 1 if $parent_handler eq $current_handler;
                    last if $found;
                    }
                push @del_list, $parent_handler unless $found;
                }
            @parent_list = @del_list;
            }
        
        if (0 < scalar @ {$current->{handler_add}}){
            $new_list =  [@parent_list, @ {$current->{handler_add}}] ;
            }
        
        $current->{handlers} = $new_list;
        }
    
    return $current;
}

sub LanguageForced($$@) {
    my ($cfg, $parms, $language) = @_;
    if(is_language_tag($language)){
        push @ {$cfg->{LanguageForced}}, $language;
        }
    else {
        warning("Bad Language Tag $language");
        }
return OK;
}

sub DefaultLanguage($$$:*){
    #piggy-back mod_mime settings.
     my ($cfg, $parms, $string) = @_;
     foreach my $language ( split /\s+/, $string ){
        if(is_language_tag($language)){
            if (exists $cfg->{LanguageDefaultActive}){
                delete $cfg->{LanguageDefaultActive};
                delete $cfg->{LanguageDefault};
                }
            unshift @ {$cfg->{LanguageDefault}}, $language;
            }
        else {
            warning("Bad Language Tag $language");
            }
        }
return Apache->module('mod_mime.c') ? DECLINE_CMD : OK;
}

sub LanguageDefault($$@) {
    my ($cfg, $parms, $language) = @_;
    if(is_language_tag($language)){
        if (exists $cfg->{LanguageDefaultActive}){
                delete $cfg->{LanguageDefaultActive};
                delete $cfg->{LanguageDefault};
                }
        push @ {$cfg->{LanguageDefault}}, $language;
        }
    else {
        warning("Bad Language Tag $language");
        }
return OK;
}

#LanguageDebug
# NotFoundPrefix=--> 
# NotFoundPostfix=<-- 
# Prefix=']'
# Postfix=']'
# Verbose=digit

sub LanguageDebug($$$) {
    my ($cfg, $parms, $debug) = @_;

	#print STDERR "LanguageDebug ($debug)\n";

	if($debug =~ /\d+/)
		{
    	$DEBUG = $debug;
		print STDERR "Debug level set to $debug\n";
		}
		
	elsif($debug =~ /(\w+)\s*=\s*(.+)/)
		{
		my ($cmd,$value) = ($1,$2);
		#print STDERR "Read ($cmd,$value)\n";
		$DEBUG{lc $cmd} = $value;
		}
			
    return OK;
}

sub LanguageHandler($$$;*){
    my ($cfg, $parms, $directives, $cfg_fh) = @_;
    foreach my $module (split /\s+/, $directives)
        {
        (my $action, $module ) = $module =~ /(\+|-)?(.*)/;
        
        $module = __PACKAGE__ . "::$module" unless $module =~ /^Apache::Language/;
        eval "use $module";
        if ($@){
            warning($@);
            next;
            }
        
        if (not $action) {
            push @ {$cfg->{handlers}}, $module ;
            }
        #this is not implemented yet...
        elsif ($action eq '-'){
            push @ {$cfg->{handler_del}}, $module ;
            }
        else {
            push @ {$cfg->{handler_add}}, $module ;
            }
        }
    return OK;
}
1;
__END__
