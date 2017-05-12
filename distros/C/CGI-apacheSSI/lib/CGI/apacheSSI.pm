package CGI::apacheSSI;
use strict;
#use warnings;

# CHANGES for 0.95:

# DONE:
# include virtual should not be making http requests to other servers.. 
# include virtual can be absolute.. 
# include file cannot be absolute.. 
# flastmod, fsize

# TODO:
# move up the  %allowed_tag_count;
# $allowed_tag_count{'if'}=["expr"]; should use arrays: @allowed_tag_count{'if'}=("expr");
# handle encoding in echo()
# PROPER VIRTUAL CALLS TO CGI SCRIPTS AND mod_rewrite URLS


use File::Spec::Functions; # catfile()
use HTTP::Response;
use HTTP::Cookies;
use Date::Format;
use Cwd;

our $VERSION = '0.96';

our $DEBUG = 0;

sub import {
    my($class,%args) = @_;
    return unless exists $args{'autotie'};
    $args{'filehandle'} = $args{'autotie'} =~ /::/ ? $args{'autotie'} : caller().'::'.$args{'autotie'};
    no strict 'refs';
    my $self = tie(*{$args{'filehandle'}},$class,%args);
    return $self;
}

my($gmt,$loc,$lmod);

			# NOTE: check for escaped \( or \), what should it do? -- DONE?
our $L; # used to return the brackets count
our $RE_parens_2C = qr/
      (	  # g1, everything inside the brackets, incl brackets
      \(
	( (?:	  # g2, everything inside the brackets
	  (?{ $L = 1 })	  #  $L counts ('s inside pattern
	      (?:
		  (?:"[^"\\]*  (?: \\.[^"\\]* )* ")
		| (?:'[^'\\]*  (?: \\.[^'\\]* )* ')
		| (?:`[^`\\]*  (?: \\.[^`\\]* )* `)
		| (?:[^"'`)(])
		| (?:  \(
		      (?{ local  $L=$L+1; })	  # new set of nested parens
		  )
		| (?:  \)
		      (?{ local  $L=$L-1; })	  # close a set of nested parens
		      (?(?{ $L==0 })(?!))	  #  ...if there was no matching open paren...
		  )
	      )*
	  )* )   # end g2
      \)
      )   # end g1
      /x;

our $RE_quote_dbl_NC		  = qr/(?:"[^"\\]*  (?: \\.[^"\\]* )* ")/x;
our $RE_quote_single_NC		  = qr/(?:'[^'\\]*  (?: \\.[^'\\]* )* ')/x; 
our $RE_quote_backtick_NC	  = qr/(?:`[^`\\]*  (?: \\.[^`\\]* )* `)/x;
our $RE_all_quote_NC		  = qr/$RE_quote_dbl_NC|$RE_quote_single_NC|$RE_quote_backtick_NC/;
our $RE_all_no_quote_NC		  = qr/$RE_all_quote_NC|[^'"`]/;
our $RE_all_no_paren_NC		  = qr/$RE_all_quote_NC|[^()'"`]/;
our $RE_all_no_paren_noop_NC	  = qr/$RE_all_quote_NC | [^()'"`&\|] | &[^&] | \|[^\|]/x;
our $RE_single_quote_false_NC	  = qr/^ (?:\s*'')+\s* [']* $
				      |^ '? (?:\\')* $/x; 
					# empty, or 1+ unspaced single quotes,  trivially false
					# pairs of empty single quotes,  false
					# alternating backslash-single quotes,  false


  # apache's own, special way of quoting strings
our $RE_apache_expr_quote	  = qr/ (?:"(?:[^"\\]|[\\]+[^\\])*?")
				       |(?:'(?:[^'\\]|[\\]+[^\\])*?')
				       |(?:`(?:[^`\\]|[\\]+[^\\])*?`)
				      /x;

# NOTE: quotes that would be openers which are immediately preceeded by \w are treated as \w
	  # NOTE: needs to be preceeded by \s or =, otherwise becomes part of token (parsing oddity with apache 2.2.22)
our $RE_apache_expr_quote_all	  = qr/  $RE_apache_expr_quote | [^'"`\s]/x;
our $RE_runaway   =  qr/ \s+  \w+['"`]\S*\s+[^'"`]+['"`]+  /x;
our $RE_token_NC  =  qr{[[:alpha:]]\S+? (?:\s+ $RE_apache_expr_quote_all*? )*?   $RE_runaway? }x; 


sub new {
    my($class,%args) = @_;
    my $self = bless {}, $class;

    $self->{'_handle'}        = undef;
    my $script_name = '';
    if(exists $ENV{'SCRIPT_NAME'}) {
        ($script_name) = $ENV{'SCRIPT_NAME'} =~ /([^\/]+)$/;
    }

    tie $gmt, 'CGI::apacheSSI::Gmt', $self;
    tie $loc, 'CGI::apacheSSI::Local', $self;
    tie $lmod, 'CGI::apacheSSI::LMOD', $self;

    # $ENV{'DOCUMENT_ROOT'} ||= '';
    $self->{'_variables'}     = {
        DOCUMENT_URI    =>  ($args{'DOCUMENT_URI'} || $ENV{'SCRIPT_NAME'}),
        DOCUMENT_NAME   =>  ($args{'DOCUMENT_NAME'} || $script_name),
        DOCUMENT_ROOT   =>  ($args{'DOCUMENT_ROOT'} || $ENV{'DOCUMENT_ROOT'} || cwd()),
        DATE_GMT        =>  $gmt,
        DATE_LOCAL      =>  $loc,
                                };

    $self->{_timefmt_default} = "%A, %d-%B-%Y %T %Z"; # APACHE DEFAULT https://httpd.apache.org/docs/2.2/mod/mod_include.html#ssitimeformat
    
    $self->{'_config'}        = {  # NOTE: TODO: get these from apache config
        errmsg  =>  ($args{'errmsg'}  || '[an error occurred while processing this directive]'),
        sizefmt =>  ($args{'sizefmt'} || 'abbrev'),
        timefmt =>  ($args{'timefmt'} ||  $self->{_timefmt_default}),
        SSIUndefinedEcho =>  ($args{'SSIUndefinedEcho'} ||  '(none)'),
        _enable_exec_cmd  =>  ($args{'_enable_exec_cmd'}  ||  0),
        _verbose_errors  =>  ($args{'_verbose_errors'}  ||  0)
                                };
                                
    
    $self->{'_variables'}->{LAST_MODIFIED}   =  $lmod; # needs to be specified after the above, since it requires DOCUMENT_ROOT to be populated

    $self->{_max_recursions} = $args{MAX_RECURSIONS} || 100; # no "infinite" loops
    $self->{_recursions} = {};

    $self->{_cookie_jar}  = $args{COOKIE_JAR} || HTTP::Cookies->new();

    $self->{'_in_if'}     = 0;
    $self->{'_suspend'}   = [0];
    $self->{'_seen_true'} = [1];

    return $self;
}

sub _enable_exec_cmd {
    my $self = shift;
    $self->{'_config'}->{'_enable_exec_cmd'} = $_[0];
}

sub TIEHANDLE {
    my($class,%args) = @_;
    my $self = $class->new(%args);
    $self->{'_handle'} = do { local *STDOUT };
    my $handle_to_tie = '';
    if($args{'filehandle'} !~ /::/) {
		$handle_to_tie = caller().'::'.$args{'filehandle'};
    } else {
		$handle_to_tie = $args{'filehandle'};
    }
    open($self->{'_handle'},'>&'.$handle_to_tie) or die "Failed to copy the filehandle ($handle_to_tie): $!";
    return $self;
}

sub PRINT {
    my $self = shift;
    print {$self->{'_handle'}} map { $self->process($_) } @_;
}

sub PRINTF {
    my $self = shift;
    my $fmt  = shift;
    printf {$self->{'_handle'}} $fmt, map { $self->process($_) } @_;
}

sub CLOSE {
    my($self) = @_;
    close $self->{'_handle'};
}

sub SSI_WARN {
    my($self,$msg) = @_;
    warn ref($self)." warn: $msg\n";
}

sub SSI_ERROR {
    (my $self, $@) = @_;
    warn ref($self)." error: $@\n";
    return;	# returning false here allows us to do one line error returns.
}

sub SSI_ERROR_FLUSH {
    my($self,$msg) = @_;
    if ($msg) {$self->SSI_ERROR($msg);}
    $msg=$@;					# NOTE: DEBUG ONLY!
    undef $@;
    return "[SSI ERROR=[$msg]]" if $self->{'_config'}->{'_verbose_errors'}; # NOTE: DEBUG ONLY!
    return $self->{'_config'}->{'errmsg'}; 
}
    



# NOTE: "if" allows expr="myexpr1" expr="myexpr2" where myexpr2 overwrites myexpr1. 

sub process {		# NOTE: -- FIXME -- this fails if we comment out the tokens.. ie <!-- <!--#if -->
			# NOTE: -- FIXME -- this should fail if we have any open quotes (ie, the --> doesnt magically close the tag.. in apache 2.2 at least)
    my($self,@shtml) = @_;
    my $processed = '';

	  # NOTE: FIXME: would this be easier with a global replace  s///ge ?
    @shtml = split(m/(<!--\#$RE_token_NC-->)/sx, join '',@shtml); # this will slurp up anything inside quotes, single or double

    my $count=0;
    for my $token (@shtml) {
        if($token =~ /^<!--\#($RE_token_NC)-->$/sx) {
	    $processed .= $self->_process_ssi_text($1);
	} else {
	    next if $self->_suspended;
	    $processed .= $token;
	}
    }
    return $processed;
}



sub _process_ssi_text {
    my($self,$text) = @_;

    # what's the first \S+?
    if($text !~ s/^(\S+)\s*//) 
	{ return $self->SSI_ERROR_FLUSH("failed to find method name at beginning of string: '$text'."); }

    my $method = $1;
    if (! $self->can($method) )
	{ return $self->SSI_ERROR_FLUSH("unknown directive \"$method\" in parsed doc."); }

	# are we suspended?
    return '' if($self->_suspended and $method !~ /^(?:if|else|elif|endif)\b/);

    my $res = $self->$method( $self->parse_args($text, $method) );
    if ($@) { return $self->SSI_ERROR_FLUSH();}
    return $res; 
}



# many thanks to HTML::SimpleParse, with a couple of modifications
sub parse_args {
    my ($self, $str, $method) = @_;
    my @returns;
  
    # Make sure we start searching at the beginning of the string
    pos($str) = 0;
  
    while (1) {
        next if $str =~ m/\G\s+/gc;  # Get rid of leading whitespace
    
        if ( $str =~ m/\G
            ([\w.-]+)\s*=\s*			 # the key
            (?:
               # ($RE_all_quote_NC) \s*		 # anything in quotes
               ($RE_apache_expr_quote_all) \s*   # anything in quotes
               |				 #  or
               ([^\s>]*) \s*			 # anything else, without whitespace or >
             )/gcx ) {
            my ($key, $val) = ($1, $+);
                  # ----- NOTE: if $key is not "expr" trim the quotes.. 
                  # ----- (apache evaluates differently depending on the type of quotes)
            if ($key ne "expr") {$val =~ s/^['"`]?(.*?)['"`]?$/$1/;}
            push @returns,  $key, $val;
        } elsif ( $str =~ m,\G/?([\w.-]+)\s*,gc ) {
            push @returns,  $1  , undef;
        } else {
            if ($str =~ m/\G(.+)/gc)  # anything left over??
                  {
                  $self->SSI_ERROR("missing argument name for value to tag \"$method\" in");
                  # NOTE: notice this is NOT a "return".. we want processing to continue normally
                  }
            last;
        }
    }
  
# too many arguments for if element in
# else/endif/printenv directive does not take tags in
my %allowed_tag_count;			# NOTE: this needs to be moved up
$allowed_tag_count{'if'}=["expr"];
$allowed_tag_count{'else'}=[];

        if (defined $allowed_tag_count{$method})
            {
            if (@returns > 2 * @{ $allowed_tag_count{$method} })
                {
                if (@{ $allowed_tag_count{$method} } == 0)
                    { $self->SSI_ERROR("\"$method\" directive does not take tags in");}
                else
                    { $self->SSI_ERROR("too many arguments for \"$method\" element in");}
                }
            elsif (@returns < 2 * @{ $allowed_tag_count{$method} })
                { $self->SSI_ERROR("missing arguments for directive \"$method\"");} # NOTE: fix this error message
            }

  return @returns;
}


sub _interp_vars {
    local $^W = 0;
    my($self,$text,$setcmd) = @_;
    
                # NOTE: var name in ${} MUST start with at least one \w
    $text =~ s{ ((\\*) ((\\)|(\$)) (\{)?(\w (?(6)(.*)\}|(\w*)) )) }
          {
          my ($all,$slashes, $slash,$dollar, $lbrak,$var)=($1,$2, $4,$5, $6,$7);
          $slashes .= $slash;							   #  NOTE: this can be improved
          if ($lbrak) {chop $var};
      
          if (! $setcmd)
              { chop($slashes); }
          
          if ($dollar && ! $slashes)
              { $var = $self->_echo($var); }
          else 
              {
              $var = "{$var}" if ($lbrak) ;
              $var = $dollar.$var;
              }
          $slashes.$var
          }exg;
        
    return $text;
}



# for internal use only - returns the thing passed in if it's not defined. echo() returns '' in that case.
sub _echo {
    my($self,$key,$var) = @_;
    $var = $key if @_ == 2;

    if($var eq 'DATE_LOCAL') {
        return $loc;
    } elsif($var eq 'DATE_GMT') {
        return $gmt;
    } elsif($var eq 'LAST_MODIFIED') {
        return $lmod;
    }

    return $self->{'_variables'}->{$var} if exists $self->{'_variables'}->{$var};
    return $ENV{$var} if exists $ENV{$var};
    return '';
}

#
# ssi directive methods
#

sub config {
    my($self,$type,$value) = @_;
    if($type =~ /^timefmt$/i) {
        $self->{'_config'}->{'timefmt'} = $value;
    } elsif($type =~ /^sizefmt$/i) {
        if(lc $value eq 'abbrev') {
            $self->{'_config'}->{'sizefmt'} = 'abbrev';
        } elsif(lc $value eq 'bytes') {
            $self->{'_config'}->{'sizefmt'} = 'bytes';
        } else {
                return $self->SSI_ERROR_FLUSH("value for sizefmt is '$value'. It must be 'abbrev' or 'bytes'.");
        }
    } elsif($type =~ /^errmsg$/i) {
        $self->{'_config'}->{'errmsg'} = $value;
    } elsif($type =~ /^_verbose_errors/i) {
        $self->{'_config'}->{'_verbose_errors'} = $value;
    } else {
        return $self->SSI_ERROR_FLUSH("arg to config is '$type'. It must be one of: 'timefmt', 'sizefmt', or 'errmsg'.");
    }
    return '';
}

sub set {
    my($self,%args) = @_;
    if(scalar keys %args > 1) {
        $self->{'_variables'}->{$args{'var'}} = $self->_interp_vars($args{'value'}, 1);
    } else { # var => value notation
        my($var,$value) = %args;
        $self->{'_variables'}->{$var} = $self->_interp_vars($value, 1);
    }
    return '';
}

sub escaped {
    my ($t)=@_;
    $t =~ s/\\\$/\$/g;
    return $t ;
}

sub echo {
    my($self,$key,$var) = @_;
    $var = $key if @_ == 2;
    my $encoding;
    if ($key eq 'encoding') {
        $encoding = $var;		 # NOTE: TODO: handle encoding.
        ($key,$var) = @_[3,4];
        $var = $key if (!defined($var));
    }
    
    if($var eq 'DATE_LOCAL') {
          return $loc;
    } elsif($var eq 'DATE_GMT') {
          return $gmt;
    } elsif($var eq 'LAST_MODIFIED') {
          return $lmod;
    }
        # it seems apache's "echo" command escapes out instances of "\$" to display just "$"
    return &escaped($self->{'_variables'}->{$var}) if exists $self->{'_variables'}->{$var};
    return &escaped($ENV{$var}) if exists $ENV{$var};
    return $self->{'_config'}->{'SSIUndefinedEcho'};
}

sub printenv {
    return join "\n",map {"$_=$ENV{$_}"} keys %ENV;
}

sub include {
	$DEBUG and do { local $" = "','"; warn "DEBUG: include('@_')\n" };
    my($self,$type,$filename) = @_;
    
    $self->_init_CWD;

    if(lc $type eq 'file') {
          return $self->_include_file($filename);
    } elsif(lc $type eq 'virtual') {
          return $self->_include_virtual($filename);
    } else {
          return $self->SSI_ERROR_FLUSH("arg to include is '$type'. It must be one of: 'file' or 'virtual'.");
    }
}
sub _load_file {
    my($self,$filename) = @_;
    
    unless (-e $filename) {
        return $self->SSI_ERROR("File does not exist: $filename");
        }
    
        # open the file, or warn and return an error
    my $fh = do { local *STDIN };
    open($fh,$filename) or do {
        return $self->SSI_ERROR_FLUSH("failed to open file ($filename): $!");
    };
    return join '',<$fh>;
}

#   http://httpd.apache.org/docs/2.2/howto/ssi.html
# The *file* attribute is a file path, relative to the current directory.
# That means that it cannot be an absolute file path (starting with /), nor can it contain ../ as part of that path.

sub _include_file {
    $DEBUG and do { local $" = "','"; warn "DEBUG: _include_file('@_')\n" };
    my($self,$filename) = @_;

    if ($filename =~ m{(^/|\.\.)}) {
        return $self->SSI_ERROR_FLUSH("unable to include '$filename' in parsed file"); 
        }
    my $filepath = catfile($self->{_CWD},$filename);
    return $self->_load_file($filepath) ||  $self->SSI_ERROR_FLUSH("unable to include \"$filename\" in parsed file ");
}

#
#   http://httpd.apache.org/docs/2.2/howto/ssi.html
# The *virtual* attribute is probably more useful, and should specify a URL relative to the _document being served_.
# It can start with a /, but _must be on the same server_ as the file being served.

		# NOTE: This could be greatly affected by mod_rewrite
		
sub _include_virtual {
    $DEBUG and do { local $" = "','"; warn "DEBUG: _include_virtual('@_')\n" };
    my($self,$filename) = @_;
    my $file;

    if($filename =~ m|^/(.+)|) { # could be on the local server: absolute filename, relative to ., relative to $ENV{DOCUMENT_ROOT}
       $file = catfile($self->{'_variables'}->{'DOCUMENT_ROOT'},   $1);
    }
    else {
       $file = catfile($self->{_CWD},   $filename);
    }

        # if we've reached MAX_RECURSIONS for this filename, warn and return the error
    if(++$self->{_recursions}->{$file} >= $self->{_max_recursions}) {
        return $self->SSI_ERROR_FLUSH("the maximum number of 'include virtual' recursions has been exceeded for '$filename'.");
    }
            
    if (-e $file) {
        my $dir = ( File::Spec->splitpath( $file ) )[1];
        local $self->{_CWD} = $dir; # set the current working directory, because subsequent includes are relative to that..
                
        # process the included file and return the result
        if (my $file_conts = $self->_load_file($file)) {
            return $self->process($file_conts);
        }
        else {
            return $self->SSI_ERROR_FLUSH("unable to include \"$filename\" in parsed file ");
        }
    }
    else {
         return $self->SSI_ERROR_FLUSH("File does not exist: $file"."\nunable to include \"$filename\" in parsed file "); 
    }
}


sub cookie_jar {
    my $self = shift;
    if(my $jar = shift) {
        $self->{_cookie_jar} = $jar;
    }
    return $self->{_cookie_jar};
}

sub exec {
    my($self,$type,$filename) = @_;
    if(lc $type eq 'cmd') {
        return $self->_exec_cmd($filename);
    } elsif(lc $type eq 'cgi') {
        return $self->_exec_cgi($filename);
    } else {
        return $self->SSI_ERROR_FLUSH("arg to exec() is '$type'. It must be one of: 'cmd' or 'cgi'.");
    }
}

sub _exec_cmd {
    my($self,$filename) = @_;
    
    unless ($self->{'_config'}->{'_enable_exec_cmd'}) {
        return $self->SSI_ERROR_FLUSH("directive 'exec cmd' is disabled. Set '_enable_exec_cmd' to 1 to enable. ");
    }

    # have we reached MAX_RECURSIONS?
    if (++$self->{_recursions}->{$filename} >= $self->{_max_recursions}) {
        return $self->SSI_ERROR_FLUSH("the maximum number of 'exec cmd' recursions has been exceeded for '$filename'.");
    }

    my $output = `$filename`; # NOTE: security here is mighty bad.

    # was the command a success?
    if($?) {
        return $self->SSI_ERROR_FLUSH("exec cmd of `$filename` was not successful."); # NOTE: FIXME msg
    }

    return $output;
}

sub _exec_cgi {
    my($self,$filename) = @_;
    return $self->_include_virtual($filename);  # NOTE: FIXME -- exec cgi is simply an alias to include virtual!!
}

sub flastmod {
    my($self,$type,$filename) = @_;

    $self->_init_CWD;
    
    if(lc $type eq 'file') {
        $filename = catfile($self->{_CWD},$filename) unless -e $filename;
    } elsif(lc $type eq 'virtual') {
        $filename = catfile($self->{'_variables'}->{'DOCUMENT_ROOT'},$filename)
        unless $filename =~ /$self->{'_variables'}->{'DOCUMENT_ROOT'}/;
    } else {
        return $self->SSI_ERROR_FLUSH("the first argument to flastmod is '$type'. It must be one of: 'file' or 'virtual'.");
    }
    
    unless(-e $filename) {
        return $self->SSI_ERROR_FLUSH("flastmod failed to find '$filename'.");
        }

    my $flastmod = (stat $filename)[9];

    my @localtime = localtime($flastmod); # need this??
    return Date::Format::strftime($self->{'_config'}->{'timefmt'} || $self->{_timefmt_default} , @localtime); 
}

sub fsize {
    my($self,$type,$filename) = @_;

    $self->_init_CWD;
    
    if(lc $type eq 'file') {
        $filename = catfile($self->{_CWD},$filename) unless -e $filename;
    } elsif(lc $type eq 'virtual') {
        $filename = catfile($self->{'_variables'}->{'DOCUMENT_ROOT'},$filename) unless $filename =~ /$self->{'_variables'}->{'DOCUMENT_ROOT'}/;
    } else {
        return $self->SSI_ERROR_FLUSH("the first argument to fsize is '$type'. It must be one of: 'file' or 'virtual'.");
    }
    unless(-e $filename) {
        return $self->SSI_ERROR_FLUSH("fsize failed to find '$filename'.");
    }
        
    my $fsize = (stat $filename)[7];
    
    if(lc $self->{'_config'}->{'sizefmt'} eq 'bytes') {
        1 while $fsize =~ s/^(\d+)(\d{3})/$1,$2/g; # add commas to the 10^3 position markers
        return $fsize;
    } else { # abbrev
        # ---------------
        # adapted from the horrific code in apache itself            
        # http://svn.apache.org/viewvc/apr/apr/trunk/strings/apr_strings.c  # apr_strfsize
            
        return sprintf("%3d",$fsize)  if ($fsize < 973); # bytes
        my $remain;
        foreach my $units (qw(K M G T P E)) {
            $remain = $fsize % 1024;
            $fsize >>= 10; # /1024 ie, 2^10
            next if ($fsize >= 973);
            if ($fsize < 9 || ($fsize == 9 && $remain < 973)) { # < 9973?
                if ( ($remain = (($remain * 5) + 256) / 512) >= 10)
                    { return sprintf("%d.0%s", ++$fsize, $units); }
                return sprintf("%d.%d%s", $fsize, $remain, $units);
                }
            if ($remain >= 512) # >= 10512?
                { $fsize++; } # round up?
            return sprintf("%3d%s", $fsize, $units);
            }
    }
}


sub _init_CWD {
    my($self) = @_;
    my $req = $ENV{REQUEST_URI} || '';
    my $dr = $self->{'_variables'}->{'DOCUMENT_ROOT'};
    unless (defined($self->{_CWD}))
        { $self->{_CWD} = ( File::Spec->splitpath( $dr . $req) )[1] ;}
}



#
# if/elsif/else/endif and related methods
#
                # NOTE: anything calling _test should check $@
sub _test {
    my($self,$test) = @_;
    my $quote;
    my ($pound, $pounds);

    $test =~ s/^(['"`])\s*(.*?)\s*(\1)$/$2/; # trim off surrounding (matching) quotes, and whitespace
    $quote= $1;

            # trivial test returns:
    return 0 if $test =~ /$RE_single_quote_false_NC/;    
    return 1 if $test =~ /^["`]+$/;  # 1+ double quotes or backticks, trivially true    
    return 1 if $test =~ /^[\s`'"]*?([`'"])?[\s]+?\1$/; # whitespace inside second set of quotes, trivially true 
    return 1 if $test =~ /^[\w]+$/; # bareword (alphanum) trivially true

    if (1) # ($test =~ m{^\(})
        { # need to do this otherwise it creates infinite loop for some reason
        if ($test =~ m{
                    ((?:\!\s*)*) \s*	  # $1
                    (	  		  # $2
                      $RE_parens_2C	  # ($3, $4) has 2 capture groups
                      |
                      (?:$RE_all_no_paren_noop_NC)*
                    ) \s*
                    (?:
                      (\&\& | \|\| )? \s*   # $5
                      (.*)	 	    # $6
                    )? \s*
                    }x)
            {
            # $1 is pound,    $4 is inside the brackets, $5 is the op, $6 is the RHS
            my $LHS=$2;
            my $LHS_parens=$4;	# inside parentheses, does not include the parentheses
            my $OP=$5;
            my $RHS=$6;
            # expr="x == '\\x'" is split into:    LHS=[ x == ]    RHS=[ '\\x' ]
            $pounds=$pound=$1;
            $pound=~s/(?:\!\s*\!\s*)*//;	  # remove even # of !s, as these cancel out
   
            # if no op, and LHS and RHS, FAIL... because (x) b..  -- can be no LHS but RHS and noop
            # if no op and no $RHS, return pound != test(LHS)
            # if op, and no RHS or no LHS, FAIL
            # if op, do op.. return [pound != test(LHS)] op [test(LHS)]
            if ($OP) {
                 # LOGICAL COMPARISON && and ||
                    # NOTE:  && and || have equal precedence

                if ($LHS=~/^\s*$/) {
                    return $self->SSI_ERROR("empty logical comparison in expr.");
                    }
                if ($RHS=~/^\s*$/) {
                    return $self->SSI_ERROR("empty logical comparison in expr.");
                    }

                if ($LHS_parens) {$LHS = $LHS_parens;}  # needs to be done here, because of empty comparison checker
                $LHS = $self->_test($quote.$LHS.$quote);

                if ($@) {return;} # there were errors in the test

                if ($pound) {$LHS = !$LHS;}
                $RHS = $quote.$RHS.$quote;

                if ($OP eq "&&")
                    { return ($LHS && $self->_test($RHS)); } # short circuits, faster
                else # ($OP eq "||")
                    { return ($LHS || $self->_test($RHS)); } # short circuits, faster
                }
            else {
                # NO OP
                if ($LHS && $RHS) {
                    if ($LHS_parens) {
#                    	return $self->SSI_ERROR("error in expression."); # NOTE: FIXME: improve this error msg.. 
#                    	return $self->SSI_ERROR("error in expression. LHS and RHS but no OP"); # NOTE: FIXME: improve this error msg.. 
                        return $self->SSI_ERROR("error in expression. LHS [$LHS] and RHS [$RHS] but no OP"); # NOTE: FIXME: improve this error msg.. 
                        }
                    $test = $LHS.$RHS;
                    }
                elsif ($LHS)  # brackets or balanced quotes
                    {
                    if ($LHS_parens)
                        {
                        $LHS = $self->_test($quote.$LHS_parens.$quote);
                        if ($pound) {$LHS = !$LHS;}
                        return $LHS;
                        }
                    $test = $LHS;  # NOTE: is this redundant?
                    }
                elsif ($RHS)  # unbalanced quotes
                    { $test = $RHS; }  # NOTE: is this redundant?
                }
            }
        else {
            return $self->SSI_ERROR("unknown error in expression."); # SHOULD NOT REACH THIS
            }
        }


    #--------------------------
    # BAREWORD (no comparison sign)
   if ($test =~ /^(?:$RE_all_quote_NC|(?:[^=<>\/]|[\\]\/)*)$/)	# BAREWORD  
        {
        if ($test =~ /^(['])(.*?)(?:\1)$/)  {$test=$2;} # need to trim surrounding single quotes
        if ($test =~ /^$/)   {return ($pound);} # no need to parse 
        if ($test =~ /^["]/) {return (! $pound);} # no need to parse 

        my $interp_test = $self->_interp_vars($test);
        my $RET = ($interp_test =~ /[^']+/);
        if ($interp_test ne $test)
            {	# var interpolation occurred, NOTE: apache deems only '' or empty to be false in this case.
            $test = ($interp_test !~ /^$/) ;
            return (($pound) xor ($test));
            }
        return (($pound) xor ($RET));	# non empty string is true, 
        }


    #--------------------------
    # STRING COMPARISON  >,<,==,!=,=~
    if ($test  =~ m{  \s*((?:$RE_all_quote_NC|[^<>=])*?)\s*([<>=!]=?)\s*([^<>=]*)\s*   }x)
        {
        if ($pounds)
            { return $self->SSI_ERROR("invalid expression $quote$test$quote in file"); } # NOTE: FIXME   

        my ($s1,$cmp,$s2)=($1, $2, $3);
        if ($s1=~/^\s*$/)
            { return $self->SSI_ERROR("problem in REGEX. blank comparison \$s1"); } 	# NOTE: FIXME   
        if ($s2=~/^\s*$/)
            { return $self->SSI_ERROR("problem in REGEX. blank comparison \$s2"); } 	# NOTE: FIXME  

        if ($s2 =~ m{^  \s* (?: (?:/\s*[^/]*) | // ) \s* $}x)	# NOTE: what about escaped or stringed
            {
            if ($cmp =~ m/^==?$/)	{return 1;}
            elsif ($cmp =~ m/^!=$/)	{return;}
            else  { return $self->SSI_ERROR("Invalid expression $quote$test$quote in string comparison."); }
            }

        $s1=$self->_interp_vars($s1);
        if ($s1 =~ /^(['"`])(.*?)(?:\1)$/)  {$s1=$2;} # trim off surrounding (matching) quotes

              # REGEX
        if  ($s2 =~ m{^\s* / ((?:(?:(?:\\\\)*\\/) | [^/] )*) / (.*?)\s*$}x) # wrapped by /xx/
            {
            if ($2)
                { return $self->SSI_ERROR("problem in REGEX. s2=[$s2] extra stuff=[$2]"); }		# NOTE: FIXME
            $s2=qr/$1/; # regex s2
            $s2 = $self->_interp_vars($s2);
            if ($cmp =~ m/^==?$/)
                { return  ($s1 =~ m/$s2/);}
            elsif ($cmp eq "!=") 
                { return ($s1 !~ $s2); }	# NOTE: FIXME!!!
            }
        else {
            if ($s2=~m|^[^\s/]+\s+/|) # unquoted, unescaped slash
                { return $self->SSI_ERROR("problem in REGEX unquoted slash. s2=[$s2]"); }		# NOTE: FIXME

            $s2 = $self->_interp_vars($s2);
            if ($s2 =~ /^(['"])(.*?)(\1)$/)  {$s2 = $2;} # trim off surrounding (matching) quotes
            }

        my $ret;
        $ret = $s1 cmp $s2;

        if ($cmp =~ m/^==?$/)	{$ret = ($ret eq 0);}
        elsif ($cmp =~ m/^!=$/)	{$ret = ($ret ne 0);}

        elsif ($cmp =~ m/^<$/)	{$ret = ($ret lt 0);}
        elsif ($cmp =~ m/^<=$/)	{$ret = ($ret le 0);}

        elsif ($cmp =~ m/^>$/)	{$ret = ($ret gt 0);}
        elsif ($cmp =~ m/^>=$/)	{$ret = ($ret ge 0);}

        else { return $self->SSI_ERROR("unknown comparison"); } # UNKNOWN COMPARISON -- should never reach this

        return $ret;
        }
    else {
        if ($test =~ m{[^/]+\s+/})	# NOTE: UNFINISHED!! FIXME non empty unrecognized string that didnt fail
            { return $self->SSI_ERROR("error in expression, regex found in string"); }
        return 1;
        }

   return; # return false.. it seems none of the ops applied.. 
}

sub _entering_if {
    my $self = shift;
    $self->{'_in_if'}++;
    $self->{'_suspend'}->[$self->{'_in_if'}] = $self->{'_suspend'}->[$self->{'_in_if'} - 1];
    $self->{'_seen_true'}->[$self->{'_in_if'}] = 0;
}

sub _seen_true {
    my $self = shift;
    return $self->{'_seen_true'}->[$self->{'_in_if'}];
}

sub _suspended {
    my $self = shift;
    return $self->{'_suspend'}->[$self->{'_in_if'}];
}

sub _leaving_if {
    my $self = shift;
    $self->{'_in_if'}-- if $self->{'_in_if'};
}

sub _true {
    my $self = shift;
    return $self->{'_seen_true'}->[$self->{'_in_if'}]++;
}

sub _suspend {
    my $self = shift;
    $self->{'_suspend'}->[$self->{'_in_if'}]++;
}

sub _resume {
    my $self = shift;
    $self->{'_suspend'}->[$self->{'_in_if'}]--
        if $self->{'_suspend'}->[$self->{'_in_if'}];
}

sub _in_if {
    my $self = shift;
    return $self->{'_in_if'};
}

sub if {
    my($self,$expr,$test) = @_;
    $expr = $test if @_ == 3;
    $self->_entering_if();
    
    my $res=$self->_test($expr);

    if($@) {
        $self->_true();
        return;
        } # any errors cause the expr to evaluate to true..??
    
    if($res) {
        $self->_true();
    } else {
        $self->_suspend();
    }
    return '';
}

sub elif {
    my($self,$expr,$test) = @_;
    
    if (! $self->_in_if() ) {
        $self->SSI_WARN("Incorrect use of elif ssi directive: no preceeding 'if'."); # NOTE: just a "warn"
        $self->_suspend() unless $self->_suspended();  
        return;
        }

    if ($self->_seen_true()) {
        $self->_suspend() unless $self->_suspended();  
        return;
        }
        
    $expr = $test if @_ == 3;
    

    my $res= $self->_test($expr);

    if($@) {
        $self->_suspend() unless $self->_suspended();
        return;
        }
    
    if($res) {
        $self->_true();
        $self->_resume();
    } else {
        $self->_suspend() unless $self->_suspended();
    }
    return '';
}

sub else {
    my $self = shift;
    
    if (! $self->_in_if() ) {
        $self->SSI_WARN("Incorrect use of else ssi directive: no preceeding 'if'."); # NOTE: just a "warn"
        $self->_suspend() unless $self->_suspended();  
        return;
        }
    if ($self->_seen_true()) {
        $self->_suspend() unless $self->_suspended(); }
    else {
        $self->_resume(); }
    return '';
}

sub endif {
    my $self = shift;
    if (! $self->_in_if() ) {
        $self->SSI_WARN("Incorrect use of endif ssi directive: no preceeding 'if'."); # NOTE: just a "warn"
        }
    else
        { $self->_leaving_if(); }
    $self->_resume() if $self->_suspended();	# might be suspended even if not in "if"
    return '';
}

#
# if we're called like this, it means that we're to handle a CGI request ourselves.
# that means that we're to open the file and process the content, sending it to STDOUT
# along with a standard HTTP content header
#
unless(caller) {
        goto &handler;
}

sub handler {
        eval "use CGI qw(:standard);";
        print header();

        unless(UNIVERSAL::isa(tied(*STDOUT),'CGI::apacheSSI')) {
              tie *STDOUT, 'CGI::apacheSSI', filehandle => 'main::STDOUT';
        }

        my $filename = "$ENV{DOCUMENT_ROOT}$ENV{REQUEST_URI}";
        if(-f $filename) {
              open my $fh, '<', $filename or die "Failed to open file ($filename): $!";
              print <$fh>;
        } else {
              print "Failed to find file ($filename).";
        }

        exit;
}

#
# packages for tie()
#

package CGI::apacheSSI::Gmt;

sub TIESCALAR { bless [@_], shift() }
sub FETCH {
    my $self = shift;
    if($self->[-1]->{'_config'}->{'timefmt'}) {
          my @gt = gmtime;
          return Date::Format::strftime($self->[-1]->{'_config'}->{'timefmt'},@gt);
    } else {
          return scalar gmtime;
    }
}

package CGI::apacheSSI::Local;

sub TIESCALAR { bless [@_], shift() }
sub FETCH {
    my $self = shift;
    if($self->[-1]->{'_config'}->{'timefmt'}) {
          my @lt = localtime;
          return Date::Format::strftime($self->[-1]->{'_config'}->{'timefmt'},@lt);
    } else {
          return scalar localtime;
    }
}

package CGI::apacheSSI::LMOD;

sub TIESCALAR { bless [@_], shift() }
sub FETCH {
    my $self = shift;
        return $self->[-1]->flastmod('file', $ENV{'SCRIPT_FILENAME'} || $ENV{'PATH_TRANSLATED'} || '');
}

1;
__END__


=head1 NAME

CGI::apacheSSI - Parse apache SSI directives in your CGI scripts

=head1 SYNOPSIS

The simplest use case is something like this:

   require CGI::apacheSSI;
   my $ssi = CGI::apacheSSI->new();
   $ssi->set('MY_SSI_VAR' => "this var can be accessed in /myfile.shtml");
   print $ssi->include(virtual => '/myfile.shtml');

C<autotie> STDOUT or any other open filehandle:

   use CGI::apacheSSI (autotie => 'STDOUT');

   print $shtml; # browser sees resulting HTML

or tie it yourself to any open filehandle:

   use CGI::apacheSSI;

   open(FILE,'+>'.$html_file) or die $!;
   $ssi = tie(*FILE, 'CGI::apacheSSI', filehandle => 'FILE');
   print FILE $shtml; # HTML arrives in the file

or use the object-oriented interface:

   use CGI::apacheSSI;

   $ssi = CGI::apacheSSI->new();

   $ssi->if('"$varname" =~ /^foo/');
      $html .= $ssi->process($shtml);
   $ssi->elsif($virtual);
      $html .= $ssi->include(virtual => $filename);
   $ssi->else();
      $html .= $ssi->include(file => $filename);
   $ssi->endif();

   print $ssi->exec(cgi => $url);
   print $ssi->flastmod(file => $filename);

or roll your own favorite flavor of SSI:

   package CGI::apacheSSI::MySSI;
   use CGI::apacheSSI;
   @CGI::apacheSSI::MySSI::ISA = qw(CGI::apacheSSI);

   sub include {
      my($self,$type,$file_or_url) = @_; 
      # my idea of include goes something like this...
      return $html;
   }
   1;

or use .htaccess to include all files in a dir:

   # in .htaccess:
   Action cgi-ssi /cgi-bin/ssi/process.cgi
   <FilesMatch "\.shtml">
      SetHandler cgi-ssi
   </FilesMatch>


   # in /cgi-bin/ssi/process.cgi:
   
   #!/usr/local/bin/perl 
   use CGI::apacheSSI;
   CGI::apacheSSI->handler();

=head1 DESCRIPTION

CGI::apacheSSI is a fork of the CGI::SSI project, with the intention of
making it function more like Apache's SSI parser, C<mod_include>, and fixing a few
other long standing bugs along the way. The largest changes are the complete overhaul of
the parsing engine and test expression code, which is now no longer "perlish". A future
feature could be added to do perlish expressions via something like a "perl_expr" directive,
but since I didn't need it, I didn't implement it. The rest is basically the same,
so a lot of the documentation below is taken directly from CGI::SSI. 

Needless to say: B<"USE AT YOUR OWN RISK">.

CGI::apacheSSI is meant to be an easy way to add the ability to filter and parse (even nested!)
existing shtml in CGI scripts without the need to modify any of the files to be parsed.

Limitations in a CGI script's knowledge of how the server behaves make some SSI
directives impossible to imitate from a CGI script, but this module is a valiant
attempt at it, nonetheless. Please also note that the main target of emulation 
(ie, the version used to test against during development) was Apache 2.2.22, and
there are differences between how it parses certain things and how Apache 2.4.x
does (not to mention all the undocumented behavior). But it shouldn't be noticeable
except in fringe cases (like magical flying quotes that cause parsing errors).
You might never run into these differences until you have (very specific) errors
in your SSI markup.

Be aware that Apache's C<mod_include> treats single quotes ' slightly differently than
double quotes " and backticks ` when you use those to wrap your expressions, and therefore
so will CGI::apacheSSI.

I'm sure there are some interesting applications of this module so please do let me know if you
use it for anything or if you cannibalized any of the code for a different project.

=head1 UNIMPLEMENTED FEATURES AND IMPORTANT INFO

There are many features not currently implemented, but these are some of the ones I am aware of
that will definitely impede your ability to use this module as a faithful emulator of
C<mod_include>.

=head2 All server configuration directives are ignored

That means things like C<Options IncludesNOEXEC> are not taken into consideration, and you might
end up parsing pages you might not otherwise be able to.

=head2 C<include virtual> for cgi scripts and mod_rewrite urls

The C<include virtual> call cannot currently handle calls to cgi scripts or mod_rewrite urls.
It is completely file-based, and is not currently capable of doing apache internal calls.

=head2 C<exec cgi> is simply an alias to C<include virtual>

In general, you are always advised to avoid the C<exec> directive, and C<apache::SSI> implements
C<exec cgi> as an alias for C<include virtual>.

=head2 C<exec cmd> needs to be explicitly enabled

Given the above, C<exec cmd> is disabled by default, since, when enabled, it is simply a sub-call using
backticks ``, leading to a big security liability. This can be set as follows:

    my $ssi = CGI::apacheSSI->new('_enable_exec_cmd' => 1);   # at instantiation time
    
    # or during usage: 
    $ssi->_enable_exec_cmd(1);    # to enable
    $ssi->_enable_exec_cmd(0);    # to disable

=head2 C<echo> encoding

The C<echo> command silently ignores "encoding" specifications.

=head1 USAGE

Most of the time, you'll simply want to filter shtml through STDOUT 
or some other open filehandle. C<autotie> is available for STDOUT, 
but in general, you'll want to tie other filehandles yourself:

    $ssi = tie(*FH, 'CGI::apacheSSI', filehandle => 'FH');
    print FH $shtml;

Note that you'll need to pass the name of the filehandle to C<tie()> as 
a named parameter. Other named parameters are possible, as detailed 
below. These parameters are the same as those passed to the C<new()> 
method. However, C<new()> will not tie a filehandle for you.

You may create and use multiple CGI::apacheSSI objects; they will not 
step on each others' variables.

Object-Oriented methods use the same general format so as to imitate 
SSI directives:

    <!--#include virtual="/foo/bar.footer" -->

would be

    $ssi->include(virtual => '/foo/bar.footer');

likewise,

    <!--#exec cgi="/cgi-bin/foo.cgi" -->

would be

    $ssi->exec(cgi => '/cgi-bin/foo.cgi');

Usually, if there's no chance for ambiguity, the first argument may 
be left out:

    <!--#echo var="var_name" -->

could be either

    $ssi->echo(var => 'var_name');

or

    $ssi->echo('var_name');

Likewise,

    $ssi->set(var => $varname, value => $value)

is the same as 

    $ssi->set($varname => $value)

=over 4

=item $ssi->new([%args])

Creates a new CGI::apacheSSI object. The following are valid (optional) arguments: 

 DOCUMENT_URI    => $doc_uri,
 DOCUMENT_NAME   => $doc_name,
 DOCUMENT_ROOT   => $doc_root,
 errmsg          => $oops,
 sizefmt         => ('bytes' || 'abbrev'),
 timefmt         => $time_fmt,
 MAX_RECURSIONS  => $default_100, # when to stop infinite loops w/ error msg
 COOKIE_JAR      => HTTP::Cookies->new,
 _verbose_errors  => 0 || 1,
 
=item C<_verbose_errors>

The C<_verbose_errors> option was introduced to enable the output of more verbose
errors directly to the browser (instead of the standard 
C<[an error occurred while processing this directive]> message),
which can be quite useful when debugging. This can be changed during
script execution via $ssi->config('_verbose_errors', 1) to enable or
$ssi->config('_verbose_errors', 0) to disable. Default is 0.

=item $ssi->config($type, $arg)

$type is either 'sizefmt', 'timefmt', 'errmsg', or '_verbose_errors'. $arg is similar to 
those of the SSI C<spec>, referenced below.

=item $ssi->set($varname => $value)

Sets variables internal to the CGI::apacheSSI object. (Not to be confused 
with the normal variables your script uses!) These variables may be used 
in test expressions, and retreived using $ssi->echo($varname). These
variables also will not be available in external, included resources.

=item $ssi->echo($varname)

Returns the value of the variable named $varname. Such variables may 
be set manually using the C<set()> method. There are also several built-in 
variables:

 DOCUMENT_URI  - the URI of this document
 DOCUMENT_NAME - the name of the current document
 DATE_GMT      - the same as 'gmtime'
 DATE_LOCAL    - the same as 'localtime'
 LAST_MODIFIED - the last time this script was modified

=item $ssi->exec($type, $arg)

$type is either 'cmd' or 'cgi'. $arg is similar to the SSI C<spec> 
(see below).

=item $ssi->include($type, $arg)

Similar to C<exec>, but C<virtual> and C<file> are the two valid types.
SSI variables will not be available outside of your CGI::apacheSSI object, 
regardless of whether the virtual resource is on the local system or
a remote system.

=item $ssi->flastmod($type, $filename)

Similar to C<include>.

=item $ssi->fsize($type, $filename)

Same as C<flastmod>.

=item $ssi->printenv

Returns the environment similar to Apache's mod_include.

=item $ssi->cookie_jar([$jar])

Returns the currently-used HTTP::Cookies object. You may optionally
pass in a new HTTP::Cookies object. The jar is used for web requests
in exec cgi and include virtual directives.

=back

=head2 FLOW-CONTROL METHODS

The following methods may be used to test expressions. During a C<block> 
where the test $expr is false, nothing will be returned (or printed, 
if tied).

=over 4

=item $ssi->if($expr)

The expr can be any Apache mod_include expression as you would use in:

 <!--#if expr="'\$varname' =~ /^foo$/" -->ok<!--#endif -->

The $varname is expanded as you would expect. (We escape it so as to use 
the C<$varname> within the CGI::apacheSSI object, instead of that within our 
progam.) But the C<$/> inside the regex is also expanded. This is fixed 
by escaping the C<$>:

 <!--#if expr="'\$varname' =~ /^value\$/" -->ok<!--#endif -->

NOTE: Although "C<if>" allows multiple C<expr>'s:

 <!--#if  expr="$myexpr1" expr="$myexpr2" -->ok<!--#endif -->
 
only the last expression (C<$myexpr2>) is what is used for evaluation. 

=item $ssi->elif($expr)

=item $ssi->else

=item $ssi->endif

=back

=head1 SEE ALSO

C<CGI::SSI>, C<Apache::SSI> and the SSI C<spec> at
http://www.apache.org/docs/mod/mod_include.html

=head1 AUTHOR

(c) 2000-2005 James Tolley <james@bitperfect.com>, et al., All Rights Reserved.

(c) 2013-2014 insaner <apacheSSI-PLEASE-NOSPAM@insaner.com>, (rewrite of eval engine and original fork), All Rights Reserved.

This is free software. You may copy and/or modify it under the terms of the GPL.
USE AT YOUR OWN RISK.
If your server explodes and invests all your money on penny stocks, don't blame me.
But if this module was of any use to you and you would like to show your gratitude
with a financial contribution, that would be most graciously received.

=head1 CREDITS

Many Thanks to all contributors to CGI::SSI, Apache::SSI and HTML::SimpleParse.

And now that you have read all the documentation, go out there and find (and fix) all those bugs!
