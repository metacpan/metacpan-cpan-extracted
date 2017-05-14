
# Base class for Chronic.  

package Schedule::Chronic::Base; 


sub debug { 

    my ($self, $msg) = @_;
    my ($package, $filename, $line, $sub, @foo) = caller(1);
    $sub =~ s/Schedule::Chronic:://;
    $self->{logger}->logthis("$msg");

}


sub fatal { 

    my ($self, $msg) = @_;
    print STDOUT "FATAL ERROR: $msg\n";
    die("\n");

}


sub which { 

    my ($self, $app) = @_;

    my $path = `which $app`;
    chomp $path;

    if ($path =~ /no $app/) { 
        return;
    } 

    return $path;

}


1;

