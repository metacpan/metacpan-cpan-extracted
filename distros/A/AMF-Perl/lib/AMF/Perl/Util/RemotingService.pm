package AMF::Perl::Util::RemotingService;


=head1 NAME

    AMF::Perl::Util::RemotingService

=head1 DESCRIPTION    

Wrapper for user-registered classes. This wrapper can respond
to the DecribeService service calls, going through the user
class and collecting its method descriptions.

=head1 CHANGES

=head2 Sun Jul 20 19:35:40 EDT 2003

=item Substituted "use vars qw($AUTOLOAD)" for "our $AUTOLOAD" to be backwards-compatible to Perl < 5.6

=head2 Sun Apr  6 14:24:00 2003

=item Created after AMF-PHP, though their dynamic inheritance is changed to wrapping.

=cut

use strict;

sub new 
{
	my ($proto, $name, $object) = @_;
	my $self = {};
	bless $self, $proto;
	$self->serviceName($name);
	$self->content($object);
	return $self;
}

sub content
{
    my $self = shift;
    if (@_) {$self->{content} = shift;}
    return $self->{content};
}

sub serviceName
{
    my $self = shift;
    if (@_) {$self->{serviceName} = shift;}
    return $self->{serviceName};
}

sub methodTable
{
	my ($self) = @_;
	my $methodTable = $self->content->methodTable();	

	my $newEntry = {
			"access" => "remote",
			"description" => "This is the main method that returns the descriptors for the service class."
	};
	$methodTable->{"__describeService"} = $newEntry;
	return $methodTable;
}

use vars qw($AUTOLOAD);

sub AUTOLOAD
{
    my ($self, @args) = @_;
    #our $AUTOLOAD;
    
    #Strip the class path and only leave the method name;
    my @path = split /:/, $AUTOLOAD;
    my $method = $path[-1];
    
    return if $method eq "DESTROY";
    
    if ($self->content->can($method))
    {    
        return $self->content->$method(@args);
    }
    else
    {
        print STDERR "\nUnknown method $method called:\n";
		die;
    }
}

	sub __describeService 
	{
		my ($self) = @_;
		my $description = {};
		$description->{"version"} = "1.0";
		$description->{"address"} = $self->serviceName();

		my @functions;
		
		foreach my $key (keys %{$self->methodTable})
		{
			my $method = $self->methodTable->{$key};
			if ($method->{"access"} eq "remote" && $key ne "__describeService")
			{
				push @functions,  {
					"description" => $method->{"description"},
					"name" => $key,
					"version" => "1.0",
					"returns" => "testing",
					#"arguments" => {} 
				};
			}
		}

		$description->{"functions"} = \@functions;
		return $description;		
	}

1;

