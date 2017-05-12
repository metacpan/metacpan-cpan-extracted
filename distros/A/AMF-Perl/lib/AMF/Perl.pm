package AMF::Perl;

use 5.00000;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use AMF::Perl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(amf_throw);

$VERSION = '0.15';


=head1 NAME

AMF::Perl - Flash Remoting in Perl
Translated from PHP Remoting v. 0.5b from the -PHP project.

Main gateway class.  This is always the file you call from flash remoting-enabled server scripts.

=head1 SYNOPSIS

This code should be present in your AMF::Perl gateway script, the one called by the Flash client.
    
To enable the client to call method bar() under service Foo,
make sure MyCLass has a method called bar() and register an instance of your class.

        my $object = new MyClass();
        my $gateway = AMF::Perl->new;
        $gateway->registerService("Foo",$object);
        $gateway->service();

Or, if you have many services to register, create a package corresponding to each service
and put them into a separate directory. Then register this directory name. 

In the example below directory "services" may contain Foo.pm, Bar.pm etc.
Therefore, services Foo and Bar are available. However, these packages must have a function
called methodTable returning the names and descriptions of all possible methods to invoke.
See the documentation and examples for details.

	my $gateway = AMF::Perl->new;
	$gateway->setBaseClassPath('./services');
	$gateway->service();



=head1 ABSTRACT

    Macromedia Flash Remoting server-side support.

=head1 DESCRIPTION

	This file accepts the  data and deserializes it using the InputStream and Deserializer classes.
    Then the gateway builds the executive class which then loads the targeted class file
    and executes the targeted method via flash remoting.
    After the target uri executes the the gateway determines the data type of the data
    and serializes and returns the data back to the client.


=head2 EXPORT

None by default.

=head1 SEE ALSO

There is a mailing list for AMF::Perl. You can subscribe here:
http://lists.sourceforge.net/lists/listinfo/flaph-general

The web page for the package is at:
http://www.simonf.com/flap

=head1 AUTHOR

Vsevolod (Simon) Ilyushchenko, simonf@simonf.com

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
The code is based on the -PHP project (http://amfphp.sourceforge.net/)

ORIGINAL PHP Remoting CONTRIBUTORS
    Musicman - original design
    Justin - gateway architecture, class structure, datatype io additions
    John Cowen - datatype io additions, class structure
    Klaasjan Tukker - modifications, check routines, and register-framework

==head1 CHANGES

=head2 Sun Jul 11 18:45:40 EDT 2004

=item Chaned eval{} and amf_throw() to enable die() to work as well (instead of amf_throw()).

=head2 Sun Jun 20 13:32:31 EDT 2004

=over 4

=item Made printing output a separate function, requested by Scott Penrose.

=item Wrote exportable amf_throw() for exception handling.

=back

=head2 Thu Apr 29 17:20:07 EDT 2004

=over 4

=item Changed "use Apache2" to "require Apache2" to avoid breaking on non-modperl systems.

=back

=head2 Sat Apr 24 20:41:10 EDT 2004

=over 4

=item Another patch from Kostas Chatzikokolakis fixing MP2 issues.

=back

=head2 Sat Mar 13 16:25:00 EST 2004

=over 4

=item Patch from Kostas Chatzikokolakis handling encoding.

=item Changed non-mod_perl behavior for reading POST data from using <> to using read()
to work around a bug in IIS

=item Joined code for mod_perl 1 and 2. Separated the output code for the mod_perl and non-mod_perl
cases.

=back

=head2 Sat Aug  2 14:01:15 EDT 2003

=over 4

=item Changed new() to be invokable on objects, not just strings.

=back

=head2 Sun Jul 20 19:27:44 EDT 2003

=over 4

=item Added "binmode STDIN" before reading input to prevent treating 0x1a as EOF on Windows.

=back

=head2 Wed Apr 23 19:22:56 EDT 2003

=over 4

=item Added "binmode STDOUT" before printing headers to prevent conversion of 0a to 0d0a on Windows.

=item Added modperl 1 support and (so far commented out) hypothetical modperl 2 support.

=back

=head2 Sun Mar  23 13:27:00 EST 2003

=over 4

=item Synching with AMF-PHP:

Added functions debugDir() and log() (debug() in PHP), added reading headers to service().
Added fromFile() to enable parsing traffic dumps.

=back
    
=cut

use Devel::StackTrace;
use Exception::Class ('AMFException');

# load the required system packagees
use AMF::Perl::IO::InputStream;
use AMF::Perl::IO::Deserializer;
use AMF::Perl::App::Executive;
use AMF::Perl::IO::Serializer;
use AMF::Perl::IO::OutputStream;
use AMF::Perl::Util::Object;

# constructor
sub new
{
    my ($proto) = @_;
	my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{exec} = new AMF::Perl::App::Executive();
	$self->{"response"} = "/onResult";
    $self->{debug}=0;
    return $self;
}

sub debug
{
    my $self = shift;
    if (@_) {$self->{debug} = shift;}
    return $self->{debug};
}

sub service
{
    my ($self)=@_;

    my $inputStream;
    my $content = "";
	
	#Otherwise Apache on Windows treats 0x1a as EOF.
	binmode STDIN;

    if($ENV{MOD_PERL})
    {
        require mod_perl;
        my $MP2 = ($mod_perl::VERSION >= 1.99);
		if ($MP2)
		{
			require Apache2;
			require Apache::RequestUtil;  # needed for Apache->request
		}
        my $r = Apache->request();
        $r->read($content, $r->headers_in->{'Content-Length'});
    }
    else
    {
        #$content = do { local $/, <> }; #This does not work under IIS
        read(STDIN, $content, $ENV{'CONTENT_LENGTH'});
		#read the whole STDIN into one variable
    }

    $self->_service($content);

}

sub fromFile
{
    my ($self, $file) = @_;

    $file = $self->debugDir."input.amf" unless $file;

    # temporary load the contents from a file
    my $content = $self->_loadRawDataFromFile($file);

    # build the input stream object from the file contents
    my $inputStream = new AMF::Perl::IO::InputStream($content);
    
    # build the deserializer and pass it a reference to the inputstream
    my $deserializer = new AMF::Perl::IO::Deserializer($inputStream, $self->{encoding});
    
    # get the returned Object
    my $amfin = $deserializer->getObject();

    return $amfin;
}

sub _service
{
    my ($self, $content) = @_;
    
    if($self->debug)
    {
        # WATCH OUT, THIS IS NOT THREAD SAFE, DON'T USE IN CONCURRENT ENVIRONMENT
    	# temporary load the contents from a file
    	$content = $self->_loadRawDataFromFile($self->debugDir."/input.amf");
    
        # save the raw amf data to a file
        #$self->_saveRawDataToFile ($self->debugDir."/input.amf", $content);
    }
    
    # build the input stream object from the file contents
    my $inputStream = new AMF::Perl::IO::InputStream($content);
    
    # build the deserializer and pass it a reference to the inputstream
    my $deserializer = new AMF::Perl::IO::Deserializer($inputStream, $self->{encoding});
    
    # get the returned Object
    my $amfin = $deserializer->getObject();
    
    # we can add much functionality with the headers here, like turn on server debugging, etc.
    my $headercount = $amfin->numHeader();
    
    for (my $i=0; $i<$headercount; $i++)
    {
        my $header = $amfin->getHeaderAt($i);
        if ($header->{'key'} eq "DescribeService")
        {
            $self->{exec}->setHeaderFilter("DescribeService");
        }
        # other headers like net debug config
        # and Credentials
    }

    
    # get the number of body elements
    my $bodycount = $amfin->numBody();
    
    # create Object for storing the output
    my $amfout = new AMF::Perl::Util::Object();
    
    # loop over all of the body elements
    for (my $i=0; $i<$bodycount; $i++)
    {
        my $body = $amfin->getBodyAt($i);
        # set the packagePath of the executive to be our method's uri
        #Simon - unused for now
        $self->{exec}->setTarget( $body->{"target"} );
        #/Simon
        # execute the method and pass it the arguments
        
       	my ($results, $returnType);

        # try
        eval
        {
           $results =  $self->{exec}->doMethodCall( $body->{"value"} );
           # get the return type
           $returnType = $self->{exec}->getReturnType();
        };

        
        if ( $@ )
        {
            $results = UNIVERSAL::isa( $@, 'AMFException' ) ?  $@->error : constructException($@);
            $self->{"response"} = "/onStatus";
            $returnType = "AMFObject"; 
        } 

        # save the result in our amfout object
        $amfout->addBody($body->{"response"}.$self->{"response"}, "null", $results, $returnType);
    }
    
    # create a new output stream
    my $outstream = new AMF::Perl::IO::OutputStream ();

    # create a new serializer
    my $serializer = new AMF::Perl::IO::Serializer ($outstream, $self->{encoding});
    
    # serialize the data
    $serializer->serialize($amfout);

    if(0)
    {
        # save the raw data to a file for debugging
        $self->_saveRawDataToFile ($self->debugDir."/results.amf", $outstream->flush());
    }

    # send the correct header
    my $response = $outstream->flush();

	#Necessary on Windows to prevent conversion of 0a to 0d0a.
	binmode STDOUT;

	$self->output($response);

	return $self;
}

sub output
{
	my ($self, $response) = @_;

    my $resLength = length $response;

    if($ENV{MOD_PERL})
    {
        my $MP2 = ($mod_perl::VERSION >= 1.99);
        my $r = Apache->request();
		#$r->header_out("Content-Length", $resLength);
        #$r->send_http_header("application/x-amf");
        $r->content_type("application/x-amf");
        $r->headers_out->{'Content-Length'} = $resLength;
        $r->send_http_header unless $MP2;
        $r->print($response);

    }
	else
	{
		print <<EOF;
Content-Type: application/x-amf
Content-Length: $resLength

$response
EOF
	}
}

sub debugDir
{
    my ($self, $dir) = @_;
    $self->{debugDir} = $dir if $dir;
    return $self->{debugDir};
}


sub setBaseClassPath
{
    my ($self, $path) = @_; 
    if (-d $path)
    {
        $self->{exec}->setBaseClassPath($path);
    }
    else
    {
        print STDERR "Directory $path does not exist and could not be registered.\n";
        die;
    }
}

sub registerService
{
    my ($self, $package, $servicepackage) = @_;
    $self->{exec}->registerService($package, $servicepackage);
}


sub constructException
{
    my ($description) = @_;
    my $stack = Devel::StackTrace->new();

    my %result;
    $description = "An error occurred" unless $description;
    $result{"description"} = $description;
    $result{"exceptionStack"} = $stack->as_string;
    my @frames = $stack->frames;
    $result{"details"} = $frames[1]->filename();
    $result{"line"} = $frames[1]->line();
    $result{"level"} = "Error";
    $result{"code"} = "1";
    return \%result;
}


sub amf_throw
{
    my ($description) = @_;

    AMFException->throw( error => constructException($description) );
}


sub setSafeExecution
{
    my ($self, $safe) = @_;
    print STDERR "There is no need to call setSafeExecution anymore!\n";
}

sub encoding
{
	my $self = shift;
	$self->{encoding} = shift if @_;
	return $self->{encoding};
}

#    usefulldebugging method 
#    You can save the raw  data sent from the
#    flash client by calling
#    $self->_saveRawDataToFile("file.amf",  $contents);

sub _saveRawDataToFile
{
    my ($self, $filepath, $data)=@_;
    # open the file for writing
    if (!open(HANDLE, "> $filepath"))
    {
        die "Could not open file $filepath: $!\n";
    }
    # write to the file
    if (!print HANDLE $data)
    {
        die "Could not print to file $filepath: $!\n";
    }
    # close the file resource
    close HANDLE;
}

sub _appendRawDataToFile 
{
    my ($self, $filepath, $data) = @_;
    # open the file for writing
    if (!open (HANDLE, ">>$filepath"))
    {
        die "Could not open file $filepath: $!\n";
    }
    # write to the file
    if (!print HANDLE $data)
    {
        die "Could not print to file $filepath: $!\n";
    }
    # close the file resource
    close HANDLE;
}


# get contents of a file into a string
sub _loadRawDataFromFile
{
    my ($self, $filepath)=@_;
    # open a handle to the file
    open (HANDLE, $filepath);
    # read the entire file contents
    my @contents = <HANDLE>;
    # close the file handle
    close HANDLE;
    # return the contents
    return join "", @contents;
}

sub log
{
    my ($self, $content) = @_;
    $self->_appendRawDataToFile ($self->debugDir."processing.txt",$content."\n");
}

1;
__END__
