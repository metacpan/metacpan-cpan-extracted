package AMF::Perl::App::Executive;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http:#amfphp.sourceforge.net/)

=head1 NAME 

AMF::Perl::App::Executive

=head1 DESCRIPTION    

Executive package figures out whether to call an explicitly
registered package or to look one up in a registered directory.
Then it executes the desired method in the package.

=head1 CHANGES

=head2 Wed Apr 14 11:06:28 EDT 2004

=item Added return type determination for registered methods.

=head2 Sun Mar 23 13:27:00 EST 2003

=over 4

=item Synching with AMF-PHP:

=item Replaced packagepath, packagename, packageConstruct with classpath, classname, classConstruct.

=item Added _instanceName, _origClassPath and _headerFilter.

=item Added subs setHeaderFilter(), setInstanceName()

=item Renamed setClassPath to setTarget and removed extra junk from that function.

=item Eliminated _getPackage() and _getMethod().

=item Removed safeExecution().

=back

=head2 Tue Mar 11 21:59:27 EST 2003

=item Passing @$a instead of $a to user functions. $a always is an array.

=cut


use strict;
use AMF::Perl::Util::RemotingService;


#The above variable declarations are not needed, as hash keys are used. They are useful just for the comments.
# the directory which should be used for the basic packages default "../"
# my $_basecp = "../";
# the classpath which is the path of the file from $_basecp
#my $_classpath;
# the string name of the package derived from the classpath
#my $_classname;
# the object we build from the package
#my $_classConstruct;
# the method to execute in the construct
#my $_methodname;
# the defined return type
#my $_returnType;
# the instance name to use for this gateway executive
#my $_instanceName;
# the list with registered service-packagees
#my $services = {};
# The original incoming classpath
#my $_target;
# The original classpath
#my $_origClassPath;
# switch to take different actions based on the header
#my $_headerFilter;
        
# constructor
sub new
{
    my ($proto)=@_;
    my $self={};
    bless $self, $proto;
    return $self;
    # nothing really to do here yet?
}


# setter for the _headerFilter
sub setHeaderFilter 
{
    my ($self, $header) = @_;
    $self->{_headerFilter} = $header;
}

# Set the base classpath. This is the path from which will be search for the packagees and functions
# $basecp should end with a "/";
sub setBaseClassPath
{
    my ($self, $basecp) = @_; 
    $self->{_basecp} = $basecp; 
}

sub setInstanceName
{  
    my ($self, $name) = @_; 
    $self->{_instanceName} = $name;
}

# you pass directory.script.method to this and it will build
# the classpath, classname and methodname values
sub setTarget
{
    my ($self, $target)=@_;
    $self->{target} = $target;
    # grab the position of the last . char
    my $lpos = strrpos($target, ".");
    # there were none
    unless ($lpos) 
    {
        print STDERR "Service name $target does not contain a dot.\n";
        # throw an error because there has to be atleast 1
    } 
    else
    {
        # the method name is the very last part
        $self->{_methodname} = substr($target, $lpos+1);
    }
    # truncate the method name from the string
    my $trunced = substr($target, 0, $lpos);
    
    $self->{_classname} = $trunced;
}

sub registerService
{
    my ($self, $package, $servicepackage) = @_;
    $self->{services}->{$package} = $servicepackage;
}

# returns the return type for this method
sub getReturnType
{
    my ($self)=@_;
    return $self->{_returnType};
}

# execute the method using dynamic inclusion of Perl files
sub doMethodCall 
{
    my ($self, $a) = @_;
    
    #First try to call a registered class...
    my $package = $self->{_classname};
    my $method = $self->{_methodname};
    
    my $calledMethod = $method;
    
    if(exists $self->{services}->{$package})
    {    
        return $self->doMethodCall_registered($package, $method, $a);
    }
    
    #Otherwise, browse in the directory specified by the user.

    push @INC, $self->{_basecp};

    # build the class object
    
    $package =~ s#\.#::#g;
    
    unless (eval ("require " . $package))
    {
        # report back to flash that the class wasn't properly formatted
        print STDERR  "Class $package does not exist or could not be loaded.\n";
	print STDERR $@;
        return;
    }

    # build the construct from the extended class
    my $object = $package->new;
    
    # Check to see if the DescribeService header has been turned on
    if ($self->{_headerFilter} && $self->{_headerFilter} eq "DescribeService")
    {
        my $wrapper = new AMF::Perl::Util::RemotingService($package, $object);

        $self->{_classConstruct} = $wrapper;

        $method =  "__describeService";

# override the method name to the __describeService method
        $self->{_methodname} = $method;

# add the instance to the methodrecord to control registered discover
        my $methodTable = $self->{_classConstruct}->methodTable;
        $methodTable->{$method}{'instance'} = $self->{_instanceName};

    }
    else
    {
        $self->{_classConstruct} = $object;
    }

# was this defined in the methodTable -- required to enable AMF::Perl service approach
    if (exists ($self->{_classConstruct}->methodTable->{$method}))
    {
# create a shortcut to the methodTable
        my %methodrecord = %{$self->{_classConstruct}->methodTable->{$method}};

# check to see if this method name is aliased
        if (exists ($methodrecord{'alias'}))
        {
# map the _methodname to the alias
            $method = $methodrecord{'alias'};
        }

        if (exists($methodrecord{'instance'}))
        {
# check the instance names to see if they match.  If so, then let this happen
            if (!exists($methodrecord{'instance'}) || $self->{_instanceName} != $methodrecord{'instance'})
            {	
# if they don't match then print STDERR  with this error
            print STDERR  "Access error for " . $self->{_headerFilter} . ".\n";
            return;
            }
        }
        
        # check to see if an explicit return type was defined
        if (exists($methodrecord{'returns'}))
        {
            $self->{_returnType} = $methodrecord{'returns'};
        }
        # set the default return type of "unknown"
        else
        {
            $self->{_returnType} = "unknown";
        }
        # set to see if the access was set and the method as remote permissions.
        if ( (exists($methodrecord{'access'})) && (lc ($methodrecord{'access'}) eq "remote"))
        {
            # finally check to see if the method existed
            if ($self->{_classConstruct}->can($method))
            {
                # execute the method and return it's results to the gateway
                return $self->{_classConstruct}->$method(@$a);
            }
            else
            {
                # print STDERR  with error
                print STDERR  "Method " . $calledMethod . " does not exist in class ".$self->{_classConstruct}.".\n";
            }
        }
        else
        {
            # print STDERR  with error
            print STDERR  "Access Denied to " . $calledMethod . "\n";
        }
            
        
    }
    else
    {
        # print STDERR  with error
        print STDERR  "Function " . $calledMethod . " does not exist in class ".$self->{_classConstruct}.".\n";
    }

}

sub doMethodCall_registered
{
    my ($self, $package, $method, $a) = @_;
    
    my $serviceobject = $self->{services}->{$package};

    if(length($package) == 0)
    {
    # TODO: handle non packaged functions
    #trigger_error("ERROR: no package in call",E_USER_ERROR);
        return;
    } 
    elsif(!$serviceobject)
    {
        print STDERR "Package ".$package." not registerd on server\n";
        return;
    } 
    elsif(!$serviceobject->can($method))
    {
        print STDERR "Function ".$method." does not exist in package ".$package."\n";
        return;
    }
    else
    {
        $self->{_returnType} = "unknown";

    	if ($serviceobject->can("methodTable") && exists ($serviceobject->methodTable->{$method}))
    	{
			# create a shortcut to the methodTable
        	my %methodrecord = %{$serviceobject->methodTable->{$method}};
        	# check to see if an explicit return type was defined
        	if (exists($methodrecord{'returns'}))
        	{
            	$self->{_returnType} = $methodrecord{'returns'};
        	}
        	# set the default return type of "unknown"
        	else
        	{
            	$self->{_returnType} = "unknown";
        	}
		}
        return $serviceobject->$method(@$a);
    }    
}

sub strrpos
{
    my ($string)=@_;
    my $reversed = reverse $string;
    my $firstDotIndex = index($reversed, ".");
    return length($string)-$firstDotIndex-1;
}

1;
