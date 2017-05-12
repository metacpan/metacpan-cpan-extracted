package Class::STAF;
use strict;
use threads::shared;
use Class::STAF::Marshalled qw(:all);

our $VERSION = 0.02;
our @ISA = qw{Exporter};

our @EXPORT = qw{
    Marshall
    UnMarshall
};

our @EXPORT_OK = qw{
    get_staf_fields
    get_staf_class_name
};

my %thread_ref_count;
my $id_counter = 1;

sub new {
    my ($class, $processName) = @_;
    require PLSTAF;
    my $handle = STAF::STAFHandle->new($processName);
    if ($handle->{rc} != $STAF::kOk) {
        $! = $handle->{rc};
        return;
    }
    my $refcount : shared = 1;
    my $key = $id_counter++;
    $thread_ref_count{$key} = \$refcount;
    return bless {handle => $handle, refcount => $key}, $class;
}

sub CLONE {
    foreach (values %thread_ref_count) {
        lock $$_;
        $$_++;
    }
}

sub submit {
    my ($self, $location, $service, $request) = @_;
    my $result = $self->{handle}->submit($location, $service, $request);
    if ($result->{rc} != $STAF::kOk) {
        $! = $result->{rc};
        $self->{LastError} = $result->{result};
        return;
    } 
    return $result->{result};
}

sub submit2 {
    my ($self, $syncOption, $location, $service, $request) = @_;
    my $result = $self->{handle}->submit2($syncOption, $location, $service, $request);
    if ($result->{rc} != $STAF::kOk) {
        $! = $result->{rc};
        $self->{LastError} = $result->{result};
        return;
    } 
    return $result->{result};
}

sub host {
    my ($self, $hostname) = @_;
    return Class::STAF::Host->new($self, $hostname);
}

sub LastError {
    my $self = shift;
    return $self->{LastError};
}

sub DESTROY {
    my $self = shift;
    my $key = $self->{refcount};
    {
        my $ref = $thread_ref_count{$key};
        lock $$ref;
        $$ref--;
        delete $thread_ref_count{$key};
        return unless $$ref == 0;
    }
    my $rc = $self->{handle}->unRegister();
    if ($rc != $STAF::kOk) {
        warn "Failed to unRegister from STAF";
    }
}

package # hide?
    Class::STAF::Host;

sub new {
    my ($class, $parent, $hostname) = @_;
    my $self = { Parent => $parent, Host => $hostname };
    return bless $self, $class;
}

sub submit {
    my ($self, $service, $request) = @_;
    return $self->{Parent}->submit($self->{Host}, $service, $request);
}

sub submit2 {
    my ($self, $syncOption, $service, $request) = @_;
    return $self->{Parent}->submit2($syncOption, $self->{Host}, $service, $request);
}

sub LastError {
    my $self = shift;
    return $self->{Parent}->{LastError};
}

sub service {
    my ($self, $service) = @_;
    return Class::STAF::Service->new($self->{Parent}, $self->{Host}, $service);
}

package # hide?
    Class::STAF::Service;

sub new {
    my ($class, $parent, $hostname, $service) = @_;
    my $self = { Parent => $parent, Host => $hostname, Service => $service };
    return bless $self, $class;
}

sub submit {
    my ($self, $request) = @_;
    return $self->{Parent}->submit($self->{Host}, $self->{Service}, $request);
}

sub submit2 {
    my ($self, $syncOption, $request) = @_;
    return $self->{Parent}->submit2($syncOption, $self->{Host}, $self->{Service}, $request);
}

sub LastError {
    my $self = shift;
    return $self->{Parent}->{LastError};
}

1;

__END__

=head1 NAME

Class::STAF - Simplify version for the Perl STAF API

=head1 SYNOPSIS

    use Class::STAF;
    my $handle = Class::STAF->new("My Program")
        or die "Error: can not create handle. RC=$!";
    
    my $result = $handle->submit("local", "PING", "PING")
        or print "submit failed ($!): ", $handle->LastError, "\n";
    
    $service = $handle->host("local")->service("PING");
    $result = $service->submit("PING");

=head1 DESCRIPTION

This module is an alternative API for STAF - More Perlish.

For more info about STAF: http://staf.sourceforge.net/

Instead of checking for every request that the return code is zero, and only then
proceed, this API return the answer immidiatly. Only if the return code is not zero,
the submit will return undef. Then the return code is saved in $!, and the error message
can be retrived using $handle->LastError command.

Also export by default the Marshall and UnMarshall functions from L<Class::STAF::Marshalled>,
and will export by request the get_staf_fields and get_staf_class_name.

=head1 The Class::STAF object

The functions are similar to the original STAF API.
Creating:

    my $handle = Class::STAF->new("My Program")
        or die "Error: can not create handle. RC=$!";

The new function only return a return code.

Member functions:
    
    submit
    submit2

Will automatically un-register the STAF handle on destroy.

=head1 Creating Host and Service objects

    my $host = $handle->host("local");

will create an object to communicate with the local computer. usefull when you make
repeating request to the same computer. And using it is similar to how we use the
handle object, minus the host parameter:

    my $result = $host->submit("PING", "PING") or die "Oops\n";

Also, we can create a service object:

    my $service = $host->service("PING");

And use it:

    $service->submit("PING") or die "Ping is not working on that host?!";

=head1 Thread Safety

This module is thread safe by itself, but it is based on PLSTAF. It is still not clear
wether the PLSTAF module is thread safe or not.

Also, this warpper will automatically unregister the STAF Handle only after
it is released from all the threads that use it.

As result of this thread safety, this module support Perl 5.6.1 and up.

=head1 BUGS

Non known.

This is a first release - your feedback will be appreciated.

=head1 SEE ALSO

STAF homepage: http://staf.sourceforge.net/

The L<STAFService> CPAN module.

Object Marshalling API: L<Class::STAF::Marshalled>

=head1 AUTHOR

Fomberg Shmuel, E<lt>owner@semuel.co.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Shmuel Fomberg.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
