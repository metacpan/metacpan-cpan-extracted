package CGI::Debug;

use strict;
use vars qw( $VERSION $Module $File_base $Control $Reference 
	     $Content_type $Body_length $Done $DEBUG $Started);
$VERSION = '1.00';

sub BEGIN
{
    $DEBUG = 0;  # <-- DEBUG
    print "Content-Type: text/plain\n\n" if $DEBUG >2; # DEBUG
    $Module = __PACKAGE__;


    sub import_error
      {
	my( $error, $paramsref ) = @_;
	print "Content-Type: text/html\n\n";
	print "<html><head><title>$Module response</title></head><body>";

	print "<p>You got an error!\n";

	if( ref $paramsref and eval{ require "Data/Dumper.pm" } )
	  {
	    print "<pre>\n", Data::Dumper::Dumper( $paramsref ), "</pre>\n\n";
	  }

	print "<p>$error\n";
	print "</body></html>\n";

	# Set error flag, for not go into END
	# This avoid a perl core dump under 5.005_02
	$Done = 1;
      }


    unless( eval{ require 5.004_05 } )
    {
	&import_error("You must at least have perl v 5.004_05 to use $Module");
    }

    if( exists $ENV{'GATEWAY_INTERFACE'} and
	$ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl/
	)
    {
	my $modfile = $Module;
	$modfile =~ s/::/\//g;

	my($i,$p,$filename)=0;
	while( ($p,$filename) = caller(++$i) )
	{
	    last unless $filename =~ /\/$modfile\.pm$/;
	}

	warn "$filename: $Module can't be used under mod_perl\n";

	return;
    }

    unless( eval{ require 'CGI.pm' } )
    {
	&import_error("You must have the CGI module to use $Module");
    }
    $CGI::NO_DEBUG = 1; #Do not use STDIN debugging!

    if( eval{ require 'Time/HiRes.pm' } )
    {
	import Time::HiRes 'time';
	$Started = Time::HiRes::time();
    }
    else
    {
	$Started = $^T;
    }


    $Control = {};
    $File_base = "/tmp/$Module";
    $File_base =~ s/::/-/g;

    # Redirect STDERR to a temporary file
    unless( $DEBUG > 1 )
    {
	open(OLDERR, ">&STDERR");  # Save real STDERR
	open (STDERR,">${File_base}-error-$$")
	    or &import_error( "Could not write to file ${File_base}-error-$$: $!\n" );
    }

    $/ ||= "\n"; # Bug in perl 5.005_02 !!!
}


END
{
    return if $Done; # This avoids a perl core dump under 5.005_02
    &cleanup;
}

sub CHECK
{
    return if $Done; # This avoids a perl core dump under 5.005_02
    if( -s "$File_base-error-$$" )
    {
	&cleanup;
	$Done=1;
    }
}


sub import
{
    my( $self, @list ) = @_;


    if( exists $ENV{'GATEWAY_INTERFACE'} and
	$ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl/
	)
    {
	$Done = 1;
	return;
    }

    # Check if @list is in pairs
    @list % 2 and &import_error("The param list to $Module must be in key/value pairs");
    my %params = @list;

    # Build referense structure
    $Reference = 
    {
	report => [qw( errors empty_body time params cookies
		       environment html_compliance everything internals
		       )],
	on     => [qw( fatals warnings anything )],
	to     =>
	{
	    browser => "",
	    log     => "",
	    file    => [],
	    mail    => [],
	},
	header => [qw( control ignore minimal )],
	set    =>
	{
	    param_length   => "",
	    error_document => "",
	},
    };

    eval { $Control = &unravel( \%params, $Reference ) };
    $@ and &import_error( $@, \%params );

    # All other defaults is determined later


    # The priority is 1) cookies, 2) env variables
    # 3) import parameters, and 4) default
    my $module_name = $Module;
    $module_name =~ s/::/-/g;
    foreach( CGI::cookie("${module_name}-header"),
	     (exists $ENV{"${module_name}-header"}
	      and $ENV{"${module_name}-header"}),
	     )
    {
	$_ and $Control->{'header'}{$_}=1 and last;
    }
    $Control->{'header'} or $Control->{'header'}{'control'}=1;



    if( $Control->{'header'}{'minimal'} )
    {
	print "Content-Type: text/html\n\n";
	$Content_type = 'text/html';
    }
    elsif( $Control->{'header'}{'control'} )
    {
	unless( $DEBUG > 1 ) # Eating STDOUT
	{
	    open(OLDOUT, ">&STDOUT");  # Save real STDOUT
	    open(STDOUT, ">${File_base}-out-$$")
		or &import_error( "Could not write to file ${File_base}-out-$$: $!\n" );
	}
    }
}

sub cleanup
{
    my $errfile = &set_defaults;
    my $out_ref = undef;

    unless( $DEBUG > 1 )
    {
	close STDERR;
	open( STDERR, ">&OLDERR" );

	if( open ERR, "${File_base}-error-$$" )
	{
	    $errfile .= join '', <ERR>;
	    close ERR;
	    unlink "${File_base}-error-$$" or
		$errfile .= "\nCouldn't delete ${File_base}-error-$$: $!\n";
	}
	else
	{
	    $errfile .= "\nCouldn't open ${File_base}-error-$$: $!\n";
	}
    }

    if( $Control->{'header'}{'control'} )
    {
	my $header_error;
	($header_error, $out_ref) = &header_control;
	$errfile .= $header_error;
    }

    my $info = "";
    $info .= &report_time        if $Control->{'report'}{'time'};
    $info .= &report_params      if $Control->{'report'}{'params'};
    $info .= &report_cookies     if $Control->{'report'}{'cookies'};
    $info .= &report_environment if $Control->{'report'}{'environment'};
#    $info .= &HTML_complians    if $Control->{'report'}{'HTML_complians'};


    if( $Control->{'report'}{'internals'} or $DEBUG )
    {
	if( eval{ require 'Data/Dumper.pm' } )
	{
	    $info .= "\n\nControl:\n".&Data::Dumper::Dumper($Control)."\n\n";
	}
	else
	{
	    $info .= "Data::Dumper not found\n";
	}
    }


    if( $? or (defined $Body_length and $Body_length == 0) or
	$Control->{'on'}{'warnings'} && $errfile or
	$Control->{'on'}{'anything'}
	)
    {
	my $script_name = $ENV{SCRIPT_NAME} || $0 || "Script without name";

	if( $Control->{'to'}{'log'} )
	{
	    my $date = localtime;
	    print STDERR "\n","-"x60, "\n\n";
	    print STDERR "File: $script_name\n";
	    print STDERR "Date: $date\n\n";
	    print STDERR $errfile;
	    print STDERR $info;
	    print STDERR "\n<EOF>\n";
	}

	if( $Control->{'to'}{'file'} )
	{
	    foreach my $file ( @{ $Control->{'to'}{'file'} } )
	    {
		if( open FILE, ">$file" )
		{
		    my $date = localtime;
		    print FILE "File: $script_name\n";
		    print FILE "Date: $date\n\n";
		    print FILE $errfile;
		    print FILE $info;
		    print FILE "\n<EOF>\n";
		    close FILE;
		}
		else
		{
		    $Control->{'to'}{'browser'} = 1;
		    $errfile .= "\n$Module: Couldn't write to '$file': $!\n\n";
		}
	    }
	}

	if( $Control->{'to'}{'mail'} )
	{
	    if( eval{ require "Mail/Send.pm" })
	    {
		foreach my $recipient ( @{ $Control->{'to'}{'mail'} } )
		{
		    if( not eval
			{ 
			    my $server_admin = $ENV{ SERVER_ADMIN } || 'root';
			    my $msg = new Mail::Send;
			    $msg->to( $recipient );
			    $msg->subject( "Error in $script_name" );
#	Doesn't work :-(    $msg->set('From' => "$Module <$server_admin>");

			    my $fh = $msg->open;
			    print $fh "File: $script_name\n\n";
			    print $fh $errfile;
			    print $fh $info;
			    print $fh "\n<EOF>\n";

			    $fh->close;
			})
		    {
			$Control->{'to'}{'browser'} = 1;
			$errfile .= "\n$Module (Mail::Send):\n$@" if $@;
			$errfile .= "\n$Module: Could not mail to '$recipient'\n\n";
		    }
		}
	    }
	    else
	    {
		$Control->{'to'}{'browser'} = 1;
		$errfile .= "\n$Module: $@\n\n";
	    }
	}

	if( $Control->{'to'}{'browser'} or $DEBUG )
	{
	    if( defined $Body_length and $Body_length == 0 )
	    {
		print "Content-type: text/html\n\n";
		print "<html><head><title>$Module response</title></head><body>\n";
		print "<h2>$script_name</h2>\n";
		print "<plaintext>\n";
	    }
	    elsif( defined $Content_type and $Content_type eq "text/html")
	    {
		print $$out_ref if defined $$out_ref;

		if( not defined $Body_length or $Body_length )
		{
		    print "<hr>";
		}

		print "<h2>$script_name</h2>\n";
		print "<plaintext>\n";
	    }
	    else
	    {
		print $$out_ref if defined $$out_ref;


		print "\n\n";
		print "<PLAINTEXT>\n" if not defined $Content_type;
		print("-"x60,"\n\n") if not defined $Body_length or $Body_length;
		print "\t$script_name\n\n\n";
	    }

	    print $errfile;
	    print $info;

	    print "\n<EOF>\n";
	}
	elsif( defined $Body_length and $Body_length == 0 )
	{
	    if( defined $Control->{'set'}{'error_document'} )
	    {
		print "Status: 302 Moved\nLocation: $Control->{'set'}{'error_document'}\n\n";
	    }
	    else
	    {
		print "Content-type: text/html\n\n";
		print "<html><head><title>CGI Error</title></head><body>\n";
		print "<h1>CGI Error</h1>\n";
		print "<p>An error occured while generating this page.\n";
		print "The webmaster has now been notified.\n";
		print "</body></html>\n";
	    }
	}
	else
	{
	    # Errors - no HTML output
	    #
	    print $$out_ref if defined $$out_ref;
	}

	$?=1; # Indicate the error
    }
    else
    {
	# No errors
	#
	print $$out_ref if defined $$out_ref;
    }

    unless( $DEBUG > 1 )
    {
	select OLDERR; # To get rid of warnings...
	select OLDOUT; # To get rid of warnings...

	close OLDOUT;
    }
    select STDOUT;

    close STDOUT; 
    #
    # Sometimes, there are some stuff left in the buffer. Strange!!!
    # This is for 5.005_02. There seem to be output from print
    # statements, that should never have been executed, because of
    # compile errors. This close stops that text from getting out.
    #
    # The value of $? seems to be used for determining if there was a
    # compile error or not. If not setting $? to 1, perl vill execute
    # the program AFTER this END. (On some systems)
}

sub key_values
{
    my( $name, $hashr ) = @_;
	my @keys = sort keys %$hashr;

	my $key_length = 0;
	foreach( @keys )
	{
	    $key_length = length if length > $key_length;
	}

	my $info = "\n".$name."\n".('-'x length($name))."\n";
	foreach my $key ( @keys )
	{
	    my $p_length = $Control->{'set'}{'param_length'};

	    # Take arrayrefs or a scalar value
	    my $valuesr = ( ref $hashr->{$key} ? $hashr->{$key} : [$hashr->{$key}] );
	    foreach my $val ( @$valuesr )
	    {
		my( $value, $tot, $trunc);
		if( not defined $val )
		{
		    $value = "";
		    $tot = 0;
		    $trunc = " undefined";
		}
		else
		{
		    $value = substr( $val, 0, $p_length );
		    $tot = length( $val );
		    $trunc = ( $tot>$p_length ? '...' : '' );
		}
		$info .= sprintf("%-*s =%4s[%.*s]%s\n",
				 $key_length, $key, $tot,
				 $p_length, $value, $trunc);
	    }
	}
	$info .= "\n";

	return $info;
}

sub report_params
{
    return &key_values( 'Parameters', { map{ $_, [&CGI::param($_)] } &CGI::param } );
}

sub report_cookies
{
    return &key_values( 'Cookies', { map{ $_, &CGI::cookie($_) } &CGI::cookie() } );
}

sub report_environment
{
    return &key_values( 'Environment', \%ENV );
}

sub header_control
{
    my $outfile = "";
    my $errfile = "";

    unless( $DEBUG > 1 )
    {
	close STDOUT;
	open( STDOUT, ">&OLDOUT" );

	if( open OUT, "${File_base}-out-$$" )
	{
	    $outfile = join '', <OUT>;
	    close OUT;
	    unlink "${File_base}-out-$$" or
		$errfile .= "\n\nCouldn't delete ${File_base}-out-$$: $!\n";
	}
	else
	{
	    $errfile .= "\nCouldn't open ${File_base}-out-$$: $!\n";
	}
    }

    ($Content_type, $Body_length) = &header_ok( \$outfile );
    $errfile .= "Body_length UNDEF\n" if not defined $Body_length;

    if( $Content_type )
    {
	# NOP
    }
    elsif( length $outfile == 0 )
    {
	$errfile .= "\nYour program doesn't produce ANY output!\n\n";
    }
    else
    {
	if( not $? )
	{
	    $errfile .= "\nMalformed header!\n\n";
	    $errfile .= "--- Program output below  -----------------------\n";
	    $errfile .= $outfile."\n";
	    $errfile .= "-------------------------------------------------\n\n";
	}
    }

    if( (defined $Body_length and $Body_length == 0) and
	$Control->{'report'}{'empty_body'} and
	$Content_type and not $? )
    {
	$errfile .= "\nEmpty body!\n\n";
	$errfile .= "--- Here is the header --------------------------\n";
	$errfile .= $outfile."\n";
	$errfile .= "-------------------------------------------------\n\n";
    }

    return( $errfile, \$outfile );
}

sub header_ok
{
    my( $ofr ) = @_;  # Output file reference

    my $token = '[\x21\x23-\x27\x2A\x2B\x2D\x2E0-9A-Z\x5E-z\x7E]+';
    my $nctl  = '[\x20-\x7E]*';
    my $crlf = '(\r\n|\r|\n)';
    my $content = 'unknown'; #Default
    my $lcrlf = $crlf;
    my $length = length($$ofr);

    if( $$ofr =~ m/\G($token):($nctl)($crlf)/gmco )
    {
	my $name = $1;
	my $val  = $2;
	my $pos = pos($$ofr);
	$lcrlf = $3;

	while()
	{
	    if( $$ofr =~ m/\G[ \t]+($nctl)$lcrlf/gmco )
	    {
		$val .= $1;
		next;
	    }
	    if( $name =~ m/content-type/i )
	    {
		$content = 'text/html' if $val=~ m/\btext\/html\b/sio;
		$content = 'text/plain' if $val=~ m/\btext\/plain\b/sio;
	    }

	    $$ofr =~ m/\G($token):($nctl)$lcrlf/gmco;
	    $name = $1; $val = $2;

	    last if $pos == pos($$ofr);
	    $pos = pos($$ofr);
	}

	$length = length($$ofr)-$pos || 0;
    }

    if( $$ofr =~ /\G($lcrlf)/gmco )
    {
	return( $content, $length-length($1) );
    }
    return(undef, 0);
}

sub report_time
{
    return sprintf("\nThis program finished in %.3f seconds.\n",
		   time-$Started);
}



sub unravel
{
    # Recursivly set up a stucture in the image of a template structure.
    # The template consist of legal values. If the input structure has
    # a string, there it should be a HASH och ARRAY, it is constructed
    # with an undefined value.
    #   Hashes can consist of other hashes or arrays or strings. Arrays
    # can only consist of strings, that represent the legal values. Empty
    # string values in the template, permits any scalar value, except
    # references. Undefined values or empty hashes permits any thing.
    # Arrays will be converted to a hash with the key value set to 1,
    # but only if the template array is empty.
    #   After this preparation of the input structure, another algoritm
    # could be used to give default values to the undefined nodes.

    my( $params, $struct, $name ) = @_;
    my $result = undef;
    my $params_ref = ref $params;
    my $struct_ref = ref $struct;
    $name ||= "the ref";

    if( not defined $struct )
    {
	return $params;
    }
    elsif( not $struct_ref )
    {
	if( $params_ref )
	{
	    die "'$name' must be scalar...\n";
	}

	return $params;
    }
    elsif( $struct_ref eq 'ARRAY' )
    {
	if( not $params_ref )
	{
	    if( not defined $params ) # Changed...
	    {
		$result = undef;
	    }
	    else
	    {
		$result = [ $params ];
	    }
	}
	elsif( $params_ref eq 'ARRAY' )
	{
	    $result = $params;
	}
	elsif( $params_ref eq 'HASH' )
	{
	    my @list = ();
	    foreach my $thing ( keys %$params )
	    {
		if( $params->{$thing} == 1 )
		{
		    push @list, $thing;
		}
		else
		{
		    die "'$name $thing' must be a simple 1...\n";
		}
	    }
	    $result = \@list;
	}
	else
	{
	    die "'$name' must be scalar or array ref...\n";
	}

	if( @$struct )
	{
	    my $newref = {};
	    foreach my $val ( @$result )
	    {
		next unless defined $val;
		if( ref $val )
		{
		    die "'$name' must be scalar...\n";
		}
		elsif( not grep { $val eq $_ } @$struct )
		{
		    my @sortstruct = sort @$struct;
		    die "'$val' in '$name' not one of qw(@sortstruct)\n";
		}
		$newref->{$val} = 1;
	    }
	    return $newref;
	}
	else
	{
	    return undef unless defined $result; # Do not expand undefined branches

	    my $newref = [];
	    foreach my $val ( @$result )
	    {
		next unless defined $val;
		if( ref $val )
		{
		    die "'$name' must be scalar...\n";
		}
		push @$newref, $val;
	    }
	    return $newref;
	}
    }
    elsif( $struct_ref eq 'HASH' )
    {
	if( not $params_ref )
	{
	    $result = { $params => undef }; # The "undef" will later be defined
	}
	elsif( $params_ref eq 'HASH' )
	{
	    $result = $params;
	}
	elsif( $params_ref eq 'ARRAY' )
	{
	    $result = {};
	    foreach my $key ( @$params )
	    {
		$result->{$key} = undef;
	    }
	}
	else
	{
	    die "'$name' must be scalar or hash ref...\n";
	}

	my $newref = {};
	foreach my $key ( keys %$result )
	{
	    next unless defined $key;
	    my @struct_keys = keys %$struct;
	    if( @struct_keys and not grep { $key eq $_ } @struct_keys )
	    {
		my @sorted = sort @struct_keys;
		die "'$key' in '$name' not one of qw(@sorted)\n";
	    }

	    $newref->{$key} = &unravel( $result->{$key}, $struct->{$key}, $key );
	}

	return $newref;
    }

    die "Internal error: ${Module}::unravel only supports scalars, hashes and arrays";
}

sub set_defaults
{
    my $module_name = $Module;
    $module_name =~ s/::/-/g;

    my $uid = (stat( $0 ))[4];
    my $user = getpwuid($uid);

    ### Control to
    #
    my %default_to = (
		      browser => 1,
		      log     => 1,
		      file    => ["${File_base}-error.txt"],
		      mail    => [$user],
		      );
    foreach my $pref (keys %default_to)
    {
	foreach( CGI::cookie("${module_name}-to-$pref"),
		 (exists $ENV{"${module_name}-to-$pref"}
		  and $ENV{"${module_name}-to-$pref"} ),
		 )
	{
	    $_ and $Control->{'to'}{$pref}=$_ and last;
	}
	if( exists $Control->{'to'} and
	    exists $Control->{'to'}{$pref} and
	    not defined $Control->{'to'}{$pref})
	{
	    $Control->{'to'}{$pref} = $default_to{$pref};
	}
    }


    ### Control
    #
    my %default = (
		   report => 'environment',
		   on     => 'warnings',
		   to     => 'browser',
		   );
    foreach my $pref ('report','on')
    {
	foreach( CGI::cookie("${module_name}-$pref"),
		 (exists $ENV{"${module_name}-$pref"}
		  and $ENV{"${module_name}-$pref"} ),
		 )
	{
	    $_ and $Control->{$pref}{$_}= 1 and last;
	}
	$Control->{$pref}
	or $Control->{$pref}{$default{$pref}} = 1;
    }

    ### Default for  Control to
    #
    foreach( CGI::cookie("${module_name}-to"),
	     (exists $ENV{"${module_name}-to"}
	      and $ENV{"${module_name}-to"} ),
	     )
    {
	$_ and $Control->{'to'}{$_}= $default_to{$_} and last;
    }
    $Control->{'to'} or $Control->{'to'}{$default{'to'}} =
	$default_to{$default{'to'}};


    ### Control set
    #
    my %default_set = (
		       param_length => 60,
		       );
    foreach my $pref (keys %default_set)
    {
	foreach( CGI::cookie("${module_name}-set-$pref"), 
		 (exists $ENV{"${module_name}-set-$pref"} and $ENV{"${module_name}-set-$pref"} ),
		 )
	{
	    $_ and $Control->{'set'}{$pref}=$_ and last;
	}
	$Control->{set}{$pref} 
	or $Control->{set}{$pref} = $default_set{$pref};
    }




    # Set implications. ( If one option is alias for a group )  --> Not completed

    $Control->{'report'}{'everything'}=1 if $Control->{'report'}{'internals'};
    $Control->{'report'}{'environment'}=1 if $Control->{'report'}{'everything'};
    $Control->{'report'}{'html_compliance'}=1 if $Control->{'report'}{'everything'};
    if( $Control->{'report'}{'environment'} )
    {
	$Control->{'report'}{$_}=1 foreach qw( empty_body time params cookies );
    }
    $Control->{'on'}{'warnings'} = 1 if $Control->{'on'}{'anything'};
    $Control->{'on'}{'fatals'} = 1;


    # Sanitycheck on values
    eval { &unravel( $Control, $Reference ) };
    if($@)
    {
	%{$Control->{'report'}} = ( 'internals' => 1 );
	$Control->{'on'}{'warnings'} = 1;
	$Control->{'to'}{'browser'} = 1;
	return "$@\n\n";
    }
    return "";
}

1;

__END__

=head1 NAME

CGI::Debug - module for CGI programs debugging

=head1 SYNOPSIS

 use CGI::Debug;

 use CGI::Debug( report => ['errors', 'empty_body', 'time', 
			    'params', 'cookies', 'environment',
			    ],
		 on     => 'fatals',
		 to     => { browser => 1,
			     log     => 1,
			     file    => '/tmp/my_error',
			     mail    => ['staff@company.orb',
					 'webmaster',
					 ],
			 },
		 header => 'control',
		 set    => { error_document => 'oups.html' },
		 );

=head1 DESCRIPTION

CGI::Debug will catch (almost) all compilation and runtime errors and
warnings and will display them in the browser.

Just "use CGI::Debug" on the second row in your program.  The module
will not change the behaviour of your cgi program. As long as your
program works, you will not notice the modules presence.

At any time you can remove the "use CGI::Debug" without changing the
behaviour of your program. It will only start faster.

The actions of CGI::Debug is determined by, in order:
  1. cookie control variables
  2. environment control variables
  3. the import control parameters
  4. the defaults

=head2 Default behaviour

Report to browser:

=over

=item *

bad HTTP-headers

=item *

empty HTTP-body

=item *

warnings and errors

=item *

elapsed time

=item *

query parameters

=item *

cookies

=item *

environment variables (max 60 chars in value)

=back

=head1 EXAMPELS

Only report errors:
    use CGI::Debug( report => 'errors' );

Do not bother about warnings:
    use CGI::Debug( on => 'fatals' );

Allways show complete debugging info:
    use CGI::Debug( report => 'everything', on => 'anything' );

Send debug data as mail to file owner:
    use CGI::Debug( to => 'mail' );

=head1 CONTROL PARAMETERS

Cookie control variables makes it possible to control the debugging
environment from a program in another browser window. This would be
prefereble with complex web pages (framesets, etc). The page is viewd
as normal in one window. All debugging data is shown i another window,
that also provides controls to alter the debugging environment. (But
this external debugging program is not yet implemented.)

Environment control variables makes it more easy to globaly set the
debugging environment for a web site. It is also a way for the target
program to control the CGI::Debug module actions.

The four methods can be mixed. (Cookies, enviroment, import parameters
and defaults.) The module will try to make sense with whatever you
give it. The possibilites of control are more limitied in the Cookie /
ENV version.

=head2 report errors

  Cookie / ENV: CGI-Debug-report=errors

  Import: report => 'errors'
	  report => [ 'errors', ... ]

Report the content of STDERR. 

This will allways be reported. This control is for saying that none of
the other defualt things will be reported. This will only override the
default. Other report controls will be accumulated.

=head2 report empty_body

  Cookie / ENV: CGI-Debug-report=empty_body

  Import: report => 'empty_body'
	  report => [ 'empty_body', ... ]

Report if HTTP-body is empty.

This requires that "header control" is set.

=head2 report time

  Cookie / ENV: CGI-Debug-report=time

  Import: report => 'time'
	  report => [ 'time', ... ]

Report the elapsed time from beginning to end of execution.

If Time::Hires is found, this will be given with subsecond precision.

=head2 report params

  Cookie / ENV: CGI-Debug-report=params

  Import: report => 'params'
	  report => [ 'params', ... ]

Report a table of all name/value pairs, as given by the CGI module.

Multiple values will be reported as distinct pairs, in order.  Values
will be truncated to the "set param_length" number of chars. The total
length is shown for each value.

=head2 report cookies

  Cookie / ENV: CGI-Debug-report=cookies

  Import: report => 'cookies'
	  report => [ 'cookies', ... ]

Report a table of all cookies, as given by the CGI module.

Multiple values will be reported as distinct pairs, in order.  Values
will be truncated to the "set param_length" number of chars. The total
length is shown for each value.

=head2 report environment

  Cookie / ENV: CGI-Debug-report=environment

  Import: report => 'environment'
	  report => [ 'environment', ... ]

Report a table of all environment varialbes
INCLUDING empty_body, time, params, cookies.

=head2 report everything

  Cookie / ENV: CGI-Debug-report=everything

  Import: report => 'everything'
	  report => [ 'everything', ... ]

Report environment and all what that includes.

(The plan is for this control to include the contorl of HTML
compliance.)

=head2 report internals

  Cookie / ENV: CGI-Debug-report=internals

  Import: report => 'internals'
	  report => [ 'internals', ... ]

Report data for the debugging of the module itself, including
everything else.  Data::Dumper will be used, if found.

If the module itself dies, you will probably not get any output at al.
You can check for errors in the file /tmp/CGI-Debug-error-$$.  In
order to see what error CGI::Debug is generating, you could changing
$DEBUG to 2 or more, in the module file itself. Please email the
author about any problems.


=head2 on fatals

  Cookie / ENV: CGI-Debug-on=fatals

  Import: on => 'fatals'

Only deliver report on fatal errors.

This will ignore warnings. CGI::Debug checks the exit value.  Reports
will also be delivered if an empty body is detected, in case "header
control" is set.

=head2 on warnings

  Cookie / ENV: CGI-Debug-on=warnings

  Import: on => 'warnings'

Only deliver report on fatals or if there was any output to STDERR.

=head2 on anything

  Cookie / ENV: CGI-Debug-on=anything

  Import: on => 'anything'

Always deliver reports, even if there was no errors.

=head2 to browser

  Cookie / ENV: CGI-Debug-to=browser

  Import: to => 'browser'
          to => [ 'browser', ... ]
          to => { 'browser' => 1, ... }

Send report to browser.

The report will come after any program output. The module will assume
the page is in text/html, unless "header control" is set, in case this
will be checked. (In none HTML mode, the header and delimiter will be
ASCII.)

There is many cases in which faulty or bad HTML will hide the
report. This could be controled with "report html_compliance" (which is
not yet implemented).

=head2 to log

  Cookie / ENV: CGI-Debug-to=log

  Import: to => 'log'
          to => [ 'log', ... ]
          to => { 'log' => 1, ... }

Send report to the standard error log.

This will easily result in a huge log.

=head2 to file

  Cookie / ENV: CGI-Debug-to=file
                CGI-Debug-to-file=filename

  Import: to => 'file'
          to => [ 'file', ... ]
          to => { 'file' => 'filename', ... }
          to => { 'file' => [ 'filename1', 'filename2', ... ] ... }

Save report to filename.

Default filename is "/tmp/CGI-Debug-error.txt". The file will be
overwritten by the next report. This solution is to be used for
debugging with an external program. (To be used with cookies.)

This will not work well with framesets that generates multipple
reports at a time. The action of this control may change in future
versions.

=head2 to mail

  Cookie / ENV: CGI-Debug-to=mail
                CGI-Debug-to-mail=mailaddress

  Import: to => 'mail'
          to => [ 'mail', ... ]
          to => { 'mail' => 'mailaddress', ... }
          to => { 'mail' => [ 'mailaddress1', 'mailaddress2', ... ] ... }

Send report with email.

The default mailaddress is the owner of the cgi program.  This
function requires the Mail::Send module. If there is any problem with
the default behaviour of Mail::Send, set the enviroment variables, as
described in the POD for Mail::Mailer, either for the HTTP server, or
before "use CGI::Debug" in a BEGIN block.

The idea is to specify an email address that will be used if anybody
besides yourself is getting an error. You will not get your own
errors as email if you overide that action with a control cookie.

=head2 header control

  Cookie / ENV: CGI-Debug-header=control

  Import: header => 'control'

Controls that the HTTP-header is correct.

This control will follow the HTTP RFC to the point. It reports if the
header is ok, if the content-type is text/html, and the length of the
HTTP-body. That information will be used by other parts of
CGI::Debug.  This is done by redirecting STDOUT to a temporary file.
This is the only control that must be set in the beginning of the
program.  All other controls can be changed during before the end of
the program.

=head2 header ignore

  Cookie / ENV: CGI-Debug-header=ignore

  Import: header => 'ignore'

Assume that the HTTP-header is correct and specifies text/html.

This will tell CGI::Debug to ignore the STDOUT. A server generated
error response will result if the program compile ok but does not
produce a valid HTTP-header.

=head2 header minimal

  Cookie / ENV: CGI-Debug-header=minimal

  Import: header => 'minimal'

Generates a simple text/html HTTP-header for you.

This is the only action that CHANGES THE BEHAVIOUR of your program.
You will have to insert your own header if you remove the CGI::Debug
row. But this action will guarantee that you have a valid header,
without the need to save STDOUT to a temporary file.

=head2 set param_length

  Cookie / ENV: CGI-Debug-set-param_length=value

  Import: set => { param_length => 'value', ... }

Set the max length of the parameter values.

The default length is 60 chars. This is used for query parameters,
cookies and environment. The purpose is to give you a table that looks
good.

=head2 set error_document

  Cookie / ENV: CGI-Debug-set-error_document=value

  Import: set => { error_document => 'value', ... }

Set what page to redirect to if there was an error report, not sent to
browser.

This will show up in the browser if the error is going somewhere
else.  If no page is specified, a short generic CGI error response
will show up. But if the CGI program succeeded in printing a valid
http header and something in the body, that will be showed instead,
even if the program later crashed.

=head1 MOD_PERL

CGI::Debug will not function under mod_perl. The only solution to get
similar functionality is to develop a replacement for
Apache::Registry, with integrated debugging features.  The
configuration interface can not include the "use CGI::Debug ( report
=> ... )" style, in a mod_perl version.

If you run CGI::Debug under mod_perl, it will do nothing, except
sending a warning to STDERR.


=head1 TODO

These are things that could be done to make CGI::Debug even better.  I
have no plan to add new features myself.  Feel free to contribute.

=over

=item *

Clean up and generalize configuration

=item *

Test on non-*nix platforms

=item *

Implement HTML_compliance controls (using HTML::validate)

=item *

Implement function for debugging in a separate window


=back

=head1 COPYRIGHT

Copyright (c) 1999-2000 Jonas Liljegren. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Jonas Liljegren E<lt>jonas@paranormal.seE<gt>

=head1 SEE ALSO

CGI, Mail::Send, Time::Hires, Data::Dumper, perl

=cut 


plans
-----

           HTML_complians






The control variables, with defaults:
    REPORT = "environment",
    ON = "fatals"
    TO = "browser",
    TO_LOG = "STDERR",
    TO_FILE = "/tmp/cgi_error",
    TO_MAIL = file_owner,
    HEADER = "control",
    SET_PARAM_LENGTH = 20

Behaviour is determined by, in order:
  1. the control variables, as cookies
  2. the control variables as env variables
  3. the import parameters
  4. the defaults


The header
----------
            generic-message = start-line
                             *message-header
                             CRLF
                             [ message-body ]
          message-header = token ":" *TEXT CRLF

          token          = 1*<any CHAR except CTLs or tspecials>

          tspecials      = "(" | ")" | "<" | ">" | "@"
                         | "," | ";" | ":" | "\" | <">
                         | "/" | "[" | "]" | "?" | "="
                         | "{" | "}" | SP | HT

          TEXT           = <any OCTET except CTLs,
                           but including LWS>
          LWS            = [CRLF] 1*( SP | HT )
          OCTET          = <any 8-bit sequence of data>
          CHAR           = <any US-ASCII character (octets 0 - 127)>
          CTL            = <any US-ASCII control character
                           (octets 0 - 31) and DEL (127)>




