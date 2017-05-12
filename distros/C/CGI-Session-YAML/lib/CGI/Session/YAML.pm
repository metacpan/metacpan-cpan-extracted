package CGI::Session::YAML;

=head1 NAME

CGI::Session::YAML - A session-handling module that uses YAML for storage.

=head1 SYNOPSIS

    use CGI::Session::YAML;
    my $query = CGI::Session::YAML->new('/var/tmp/mysessiondir');

    $query->param(-name => 'foo', -value => 'bar');

    $query->commit();

=head1 DESCRIPTION

This module is a CGI module proxy that overrides the basic param handling
methods in the CGI module, and causes them to be saved in a YAML storage file
for reloading afterwards.

The session id is stored in the CGI parameter .id, with a new one being
created if not supplied. The ID is a 128-bit UUID created via Data::UUID.

The session is not saved until the commit() method is called. Conversely the
constructor will load an existing session file if there is one to load, based
on the session ID and the session directory. As the session directory does
default to the /tmp directory, supplying a different one is recommended.

=cut

use YAML;
use CGI;
use Data::UUID;

our @ISA = qw(CGI);
our $VERSION = 0.3;

=head2 new

This is the class constructor. It takes an optional parameter, which is the
session directory. It is highly recommended to provide one with the proper
permissions for your setup, as opposed to using the default of /tmp. 

The constructor will look in the session directory, and check for an .id CGI
parameter, and load $sessiondir/$id as its initial session, if it exists. If
.id does not exist, it will create a new session.

=cut

sub new
{
    my $proto = shift;
    my $sessiondir = shift || '/tmp';
    my $class = ref($proto) || $proto;
    my $self = CGI->new(@_);
    $self->{paramshash} = {};
    $self->{sessiondir} = $sessiondir;
    $self->{sessionid} = $self->param('.id');
    # sessionid may not cross directory boundaries, it must be a file.
    if ($self->{sessionid} =~ m#/#)
    {
        die "sessionid cannot cross directory boundaries";
    }
    unless ($self->{sessionid})
    {
        my $u = Data::UUID->new();
        $self->{sessionid} = lc $u->to_string($u->create);
        $self->{sessionid} =~ s/-//g;
    }

    $self->{sessionfile} = $self->{sessiondir} . '/' . $self->{sessionid};

    if (-f $self->{sessionfile})
    {
        $self->{paramshash} = YAML::LoadFile($self->{sessionfile});
        foreach my $param (keys %{ $self->{paramshash} })
        {
            $self->param(-name => $param, -value => $self->{paramshash}{$param});
        }
    }

    foreach my $param ($self->param)
    {
        $self->{paramshash}{$param} = $self->param($param);
    }

    # Rebless CGI horribly because it apparently doesn't inherit properly.
    bless $self, $class;
    return $self;
}

=head2 param

This is a proxy to CGI::param, but it intercepts CGI parameters being set so
that it may update storage.

=cut

sub param
{
    my $self = shift;
    my %args = ();
    if ((@_) && (@_ % 2 == 0))
    {
        %args = @_;

        if ($args{-name})
        {
            $self->{paramshash}{$args{-name}} = $args{-value};
        }
    }
    return $self->SUPER::param(@_);
}

=head2 delete

This is a proxy to CGI::delete, but it intercepts CGI parameters being deleted
so that it may update storage.

=cut

sub delete
{
    my $self = shift;
    if (@_)
    {
        delete $self->{paramshash}{$_[0]};
    }
    return $self->SUPER::delete(@_);
}

=head2 delete_all

This is a proxy to CGI::delete_all, but it intercepts CGI parameters being
deleted so that it may update storage.

=cut

sub delete_all
{
    my $self = shift;
    $self->{paramshash} = {};
    return $self->SUPER::delete_all();
}

=head2 commit

This method causes the session file to be updated with the latest cached CGI
parameters.

=cut

sub commit
{
    my $self = shift;
    my $file = $self->{sessiondir} . '/' . $self->{sessionid};

    YAML::DumpFile($file, $self->{paramshash});
}

=head1 AUTHOR

Michael P. Soulier <msoulier@digitaltorque.ca>

=head1 COPYRIGHT

Copyright 2007 Michael P. Soulier. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

CGI, Data::UUID

=cut
