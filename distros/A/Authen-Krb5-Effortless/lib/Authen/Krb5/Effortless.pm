#!/usr/bin/perl
use strict;
use warnings;

package Authen::Krb5::Effortless;
our $VERSION = "0.02";
use Carp;
use parent qw(Authen::Krb5);

sub new {
    my $class = shift();
    my $self  = {};
    my $a     = Authen::Krb5::init_context();    # initialize module
    if ( !$a ) { confess( "Unable to initialize Authen::Krb5 module" ); }
    bless( $self, $class );
    return $self;
}

sub read_cache {
    my $self = shift();
    my ( $cc, $cache_pointer, $cache_object );
    $cc            = Authen::Krb5::cc_default();    # load krb5 cache into mem
    $cache_pointer = $cc->start_seq_get();          # create a cache pointer
    if ( $cache_pointer ) {
        $cache_object            = $cc->next_cred( $cache_pointer );    # fetch copy of object from cache
        $self->{'cache_present'} = 1;                                   # flag to show cache is found
        $self->{'starttime'}     = $cache_object->starttime();          # start time of credential
        $self->{'authtime'}      = $cache_object->authtime();
        $self->{'endtime'}       = $cache_object->endtime();
        $self->{'principal'}     = $cache_object->client();             # prints principal name
        $cc->end_seq_get( $cache_pointer );                             # destroy pointer
    } else {
        $self->{'cache_present'} = 0;                                   # cache not found
    }
    return $self;
}

sub clear_cache {
    my $self = shift();                                                 # clear cache if it exists
    my ( $cc );
    $cc = Authen::Krb5::cc_default() or confess( "KRB5 Cache error:", Authen::Krb5::error() );
    if ( $cc ) {
        $cc->destroy() or carp( "KRB5 Cache warn: ", Authen::Krb5::error() );
    }

    return "True";

}

sub fetch_TGT_KEYTAB {
    my $self     = shift();
    my $keytab   = shift();
    my $username = shift();
    my ( $TGT, $cc, $principal );
    $keytab = Authen::Krb5::kt_resolve( $keytab );    # load keytab into mem
    if ( !$keytab ) { croak( "KRB5 Keytab error: ", Authen::Krb5::error() ); }

    $cc = Authen::Krb5::cc_default();                 # initialize default cache
    if ( !$cc ) { croak( "KRB5 Cache error: ", Authen::Krb5::error() ); }

    $principal = Authen::Krb5::parse_name( $username );    # initialize principal name
    if ( !$principal ) { croak( "KRB5 Principal error: ", Authen::Krb5::error() ); }

    $TGT = Authen::Krb5::get_init_creds_keytab( $principal, $keytab );    # Fetch TGT
    if ( !$TGT ) { croak( "KRB5 TGT error: ", Authen::Krb5::error() ); }

    $cc->initialize( $principal );                                        # store TGT
    Authen::Krb5::Ccache::store_cred( $cc, $TGT );
    return "True";
}

sub fetch_TGT_PW {
    my $self     = shift();
    my $pw       = shift();
    my $username = shift();
    my ( $TGT, $cc, $principal );

    $cc = Authen::Krb5::cc_default();                                     # initialize default cache
    if ( !$cc ) { croak( "KRB5 Cache error: ", Authen::Krb5::error() ); }

    $principal = Authen::Krb5::parse_name( $username );                   # initialize principal name
    if ( !$principal ) { croak( "KRB5 Principal error: ", Authen::Krb5::error() ); }

    $TGT = Authen::Krb5::get_init_creds_password( $principal, $pw );      # Fetch TGT
    if ( !$TGT ) { croak( "KRB5 TGT error: ", Authen::Krb5::error() ); }

    # store TGT
    $cc->initialize( $principal );
    Authen::Krb5::Ccache::store_cred( $cc, $TGT );
    return "True";
}

return 1;

=pod

=head1 NAME

Authen::Krb5::Effortless - This module is a subclass to Authen::Krb5, adding 'Effortless' ways to authenticate against a Kerberos Domain Controller.

=head1 VERSION

Version 0.02

=cut

=head1 Description

Authen::Krb5::Effortless is more then a 'Simple' module, as it supports both pass-phrase and key-tab based authorization.   

=head1 Methods

=over 3

=item new()              - Initializes Authen::Krb5  and returns a Authen::Krb5::Effortless object.

=item fetch_TGT_KEYTAB() - Uses a keytab file to get a Kerberos credential.

=item fetch_TGT_PW()     - Will use a password to get and cache a Kerberos credential.

=item clear_cache()      - Will clear your local cache of all stored principals.

=item read_cache()       - Will read your Kerberos  cache and return the following values from the cache:

=over 6

=item cache_present:   returns 0 or 1 if the cache is present

=item starttime:       epoch time when ticket is good from  

=item authtime:        epoch time when authentication occured 

=item endtime:         epoch time when the ticket expires 

=item principal:       name of the principal contained in the cache

=back

=back

=head1 EXAMPLES

A keytab example:

  use Authen::Krb5::Effortless;
  my $username  =  getlogin();                            
  my $keytab    =  "/path/to/my/keytab";
  my $krb5      =  Authen::Krb5::Effortless->new();
  $krb5->fetch_TGT_KEYTAB($keytab, $username);


A password example:

  use Authen::Krb5::Effortless;
  my $username = getlogin();
  my $krb5   = Authen::Krb5::Effortless->new();
  $krb5->fetch_TGT_PW('sekret_phss_wurd', $username);


A example for reading cache:

  use Authen::Krb5::Effortless;
  my $krb5  = Authen::Krb5::Effortless->new();
  $krb5->read_cache();
  if ($krb5->{'cache_present'}) { 
    print $krb5->{'principal'}, "\n";
  }


A example for deleting the cache:

  use Authen::Krb5::Effortless;
  my $krb5  = Authen::Krb5::Effortless->new();
  $krb5->clear_cache();

=head1 REQUIREMENETS

Authen::Krb5 needs to be installed for this module to work.  In addition, because I'm using a pragma introduced with perl 5.10.1, I am requireing the use of perl 5.10.1 or newer. 

=head1 AUTHOR

Adam Faris, C<< <authen-krb5-effortless at mekanix dot org> >> 

=head1 BUGS

Bugs are tracked at github.  Please report any bugs to L<https://github.com/opsmekanix/Authen-Krb5-Effortless/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::Krb5::Effortless


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-Krb5-Effortless>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-Krb5-Effortless>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-Krb5-Effortless/>

=back


=head1 ACKNOWLEDGEMENTS

I would like to acknowledge Jeff Horwitz, Doug MacEachern, Malcolm Beattie, and Scott Hutton 
for their work on Authen::Krb5.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Adam Faris.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

