package Acme::Globus;

# ABSTRACT: Interface to the Globus research data sharing service

use strict;
use warnings;

use Carp ;
use JSON ;
use Net::OpenSSH ;

=pod

=head1 NAME

Globus - Object-Oriented interface to Globus

=head1 DESCRIPTION

Globus is a tool that allows the sharing of scientific data between 
researchers and institutions. Globus enables you to transfer your 
data using just a web browser, or using their SSH interface at 
cli.globusonline.org.

This is a client library for the Globus CLI.

For detailed documentation of the API, 
see L<http://dev.globus.org/cli/reference>.

=head1 CAVEATS

This code is a work in progress, focusing on my needs at the moment 
rather than covering all the capabilities of the Globus CLI. It is
therefore very stubtastic.

This module also relies very much on SSH, and thus the rules of 
private and public keys. Therefore, using it as a shared tool would
be ill-advised if not impossible.

=head1 SYNOPSIS

    my $g = Globus->new($username,$path_to_ssh_key) ;
    $g->endpoint_add_shared( 'institution#endpoint', $directory, $endpoint_name ) ;
    $g->acl_add( $endpoint . '/', 'djacoby@example.com' ) ;
    
=head1 METHODS

=head2 BASICS

=head3 B<new>

    Creates a new Globus object. Takes two options: 
    the username and path to the SSH key you use to connect to Globus.

=head3 B<set_username>

=head3 B<set_key_path>

=head3 B<get_username>

=head3 B<get_key_path>

    These commands return and change the username and keypath you use to 
    connect to Globus.

=cut

sub new {
    my ( $class, $username, $key_path ) = @_ ;
    my $self = {} ;
    bless $self, $class ;
    $self->{username} = $username || 'none' ;
    $self->{key_path} = $key_path || 'none' ;
    return $self ;
    }

sub set_username {
    my ( $self, $username ) = @_ ;
    $self->{username} = $username ;
    }

sub set_key_path {
    my ( $self, $key_path ) = @_ ;
    $self->{key_path} = $key_path ;
    }

sub get_username {
    my ($self) = @_ ;
    return $self->{username} || 'NO USER' ;
    }

sub get_key_path {
    my ($self) = @_ ;
    return $self->{key_path} || 'NO KEY PATH' ;
    }

=head2 TASK MANAGEMENT

=head3 B<cancel>

=head3 B<details>

=head3 B<events>

=head3 B<modify>

=head3 B<status>

=head3 B<wait>

We do not do much with task management, so these are currently stubs.

=cut

sub cancel  { }
sub details { }
sub events  { }
sub modify  { }
sub status  { }
sub wait    { }

=head2 TASK CREATION

=head3 B<delete>

=head3 B<rm>

Currently stubs

=head3 B<scp>

=head3 B<transfer>

Both commands take a source, or from path (including endpoint),
a destination, or to path (includint endpoint), and a boolean indicating
whether you're copying recursively or not.

=cut 

sub delete { }
sub rm     { }

sub scp {
    my ( $self, $from_path, $to_path, $recurse ) = @_ ;
    $recurse = $recurse ? '-r' : '' ;
    my $command = qq{scp $recurse $from_path $to_path} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

sub transfer {
    my ( $self, $from_path, $to_path, $recurse ) = @_ ;
    $recurse = $recurse ? '-r' : '' ;
    my $command = qq{transfer $from_path $to_path} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

=head2 FILE MANAGEMENT

=head3 B<ls>

Works?

=head3 B<rename>

=head3 B<mkdir>

Stubs

=cut

sub ls {
    my ( $self, $file_path ) = @_ ;
    my $command = qq{ls $file_path} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my @result = split m{\r?\n}, $result ;
    return wantarray ? @result : \@result ;
    }

sub mkdir  { }
sub rename { }

=head2 ENDPOINT MANAGEMENT

=head3 B<acl_add>

=head3 B<acl_list>

=head3 B<acl_remove>

acl-* is the way that Globus refers to permissions

By the interface, Globus supports adding shares by email address, 
by Globus username or by Globus group name. This module sticks to
using email address. acl_add() takes an endpoint, an email address 
you're sharing to, and a boolean indicating whether this share is
read-only or read-write. acl_add() returns a share id.

acl_remove() uses that share id to identify which shares are to be 
removed.

acl_list() returns an array of hashes containing the information about 
each user with access to an endpoint, including the share ID and permissions.

=cut

sub identity_details {
    my ( $self, $identity_id ) = @_ ;
    my $command = qq{identity-details $identity_id } ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return {} unless $result =~ m{\w} ;
    my $obj = decode_json $result ;
    return wantarray ? %$obj : $obj ;
    }

sub acl_add {
    my ( $self, $endpoint, $email, $rw ) = @_ ;
    my $readwrite = 'rw' ;
    $readwrite = 'r' unless $rw ;
    my $command
        = qq{acl-add $endpoint --identityusername=${email} --perm $readwrite }
        ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my ($id) = reverse grep {m{\w}} split m{\s}, $result ;
    return $id ;
    }

sub acl_list {
    my ( $self, $endpoint ) = @_ ;
    my $command = qq{acl-list $endpoint} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my $slist = decode_json $result ;
    my @list = grep { $_->{permissions} ne 'rw' } @$slist ;
    return wantarray ? @list : \@list ;
    }

sub acl_remove {
    my ( $self, $endpoint_uuid, $share_uuid ) = @_ ;
    my $command = qq{acl-remove $endpoint_uuid --id $share_uuid} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

=head3 B<endpoint_add_shared>

=head3 B<endpoint_list>

=head3 B<endpoint_search>

=head3 B<endpoint_remove>

endpoint_add_shared() handles the specific case of creating an endpoint 
from an existing endpoint, not the general case.  It takes the endpoint
where you're sharing from, the path you're sharing, and the endpoint 
you're creating. If you are user 'user' and creating the endpoint 'test',
the command takes 'test', not 'user#test'.

endpoint_remove and endpoint_list, however, take a full endpoint name, like 'user#test'.

Current usage is endpoint_list for a list of all our shares, and endpoint_search
for details of each individual share

=head3 B<list_my_endpoints>

=head3 B<search_my_endpoints>

list_my_endpoints() and search_my_endpoints() were added once I discovered
the failings of existing list and search. These tools return a hashref
of hashrefs holding the owner, host_endpoint, host_endpoint_name,
credential_status, and most importantly, the id, legacy_name and display_name.

For older shares, legacy_name will be something like 'purduegcore#hr00001_firstshare'
and display_name will be 'n/a', while for newer shares, legacy_name will be
'purduegcore#SAME_AS_ID' and display_name will be like older shares' legacy_name,
'purduegcore#hr99999_filled_the_space'. In both cases, the value you want
to use to get details or to remove a share is the id, which is a UUID. 

=cut

sub endpoint_add_shared {
    my ( $self, $sharer_endpoint, $path, $endpoint ) = @_ ;

    # my $command
    #     = qq{endpoint-add --sharing "$sharer_endpoint$path" $endpoint } ;
    # my $command
    #     = qq{endpoint-add -n $endpoint --sharing "$sharer_endpoint$path" } ;
    my $command = join ' ',
        q{endpoint-add},
        q{--sharing}, "$sharer_endpoint$path",
        q{-n},        $endpoint,
        ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

# sub endpoint_list {
#     my ( $self, $endpoint ) = @_ ;
#     my $command ;
#     if ($endpoint) {
#         $command = qq{endpoint-list $endpoint } ;
#         }
#     else {
#         $command = qq{endpoint-list} ;
#         }
#     my $result
#         = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
#     my @result = map { ( split m{\s}, $_ )[0] } split "\n", $result ;
#     return wantarray ? @result : \@result ;
#     }

#lists all my endpoint
sub endpoint_list {
    my ($self) = @_ ;
    my $command = 'endpoint-search --scope=my-endpoints' ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my @result = map { s{\s}{}g ; $_ }
        map   { ( reverse split m{:} )[0] }
        grep  {m{Legacy}}
        split m{\n}, $result ;
    return wantarray ? @result : \@result ;
    }

sub endpoint_search {
    my ( $self, $search ) = @_ ;
    return {} unless $search ;
    my $command = qq{endpoint-search $search --scope=my-endpoints} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my %result = map {
        chomp ;
        my ( $k, $v ) = split m{\s*:\s}, $_ ;
        $k => $v
        }
        split m{\n}, $result ;
    return wantarray ? %result : \%result ;
    }

sub list_my_endpoints {
    my ($self) = @_ ;
    my $command = 'endpoint-search --scope=my-endpoints' ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my %result = map {
        my $hash ;
        %$hash = map {
            my ( $k, $v ) = split m{\s*:\s*} ;
            $k =~ s{\s+}{_}gmx ;
            $k = lc $k ;
            $k => $v
            }
            split m{\n} ;
        my $id
            = $hash->{display_name} ne 'n/a'
            ? $hash->{display_name}
            : $hash->{legacy_name} ;
        $id => $hash ;
        }
        split m{\n\n}, $result ;
    return wantarray ? %result : \%result ;
    }

sub search_my_endpoints {
    my ( $self, $search ) = @_ ;
    my %result ;
    my $command = qq{endpoint-search $search --scope=my-endpoints} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    %result = map {
        my $hash ;
        %$hash = map {
            my ( $k, $v ) = split m{\s*:\s*} ;
            $k =~ s{\s+}{_}gmx ;
            $k = lc $k ;
            $k => $v
            }
            split m{\n} ;
        my $id
            = $hash->{display_name} ne 'n/a'
            ? $hash->{display_name}
            : $hash->{legacy_name} ;
        $id => $hash ;
        }
        split m{\n\n}, $result ;
    return wantarray ? %result : \%result ;
    }

sub endpoint_remove {
    my ( $self, $endpoint ) = @_ ;
    my $command = qq{endpoint-remove $endpoint} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    return $result ;
    }

# Sucks. Use endpoint_search instead
sub endpoint_details {
    my ( $self, $endpoint ) = @_ ;
    my $command = qq{endpoint-details $endpoint} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;

    my %result = map {
        chomp ;
        my ( $key, $value ) = split m{\s*:\s*}, $_ ;
        $key => $value
        } split m{\n}, $result ;

    return wantarray ? %result : \%result ;
    }

=head3 B<endpoint_activate>

=head3 B<endpoint_add>

=head3 B<endpoint_deactivate>

=head3 B<endpoint_modify>

=head3 B<endpoint_rename>

Stubs

=cut

sub endpoint_activate   { }
sub endpoint_add        { }
sub endpoint_deactivate { }
sub endpoint_modify     { }
sub endpoint_rename     { }

=head2 OTHER

=head3 B<help>   

=head3 B<history>

=head3 B<man>         

=head3 B<profile>

=head3 B<versions>

profile() returns information about the Globus user, including the email address 
and public key.

Otherwise stubs

=cut

sub profile {
    my ($self) = @_ ;
    my $command = qq{profile} ;
    my $result
        = _globus_action( $command, $self->{username}, $self->{key_path} ) ;
    my %output
        = map { my ( $k, $v ) = split m{:\s?}, $_ ; $k => $v } split m{\n},
        $result ;
    return wantarray ? %output : \%output ;
    }

sub help     { }
sub history  { }
sub man      { }
sub versions { }

sub _globus_action {
    my ( $command, $user, $key_path ) = @_ ;
    my $host = '@cli.globusonline.org' ;

    my $ssh = Net::OpenSSH->new(
        $user . $host,
        key_path => $key_path,
        async    => 0,
        ) ;

    $ssh->error
        and die "Couldn't establish SSH connection: " . $ssh->error ;

    my $debug = 0 ;

    say STDERR "\t" . '=' x 20 if $debug ;
    say STDERR "\t" . $command if $debug ;
    say STDERR "\t" . '-' x 20 if $debug ;

    my $response = $ssh->capture($command)
        or carp "remote command failed: " . $ssh->error ;

    return $response ;
    }

1 ;

=head1 LICENSE

Copyright (C) 2017, Dave Jacoby.

This program is free software, you can redistribute it and/or modify it 
under the terms of the Artistic License version 2.0.

=head1 AUTHOR

Dave Jacoby - L<jacoby.david@gmail.com>

=cut
