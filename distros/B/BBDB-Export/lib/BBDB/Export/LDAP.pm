package BBDB::Export::LDAP;
use strict;
use warnings;

our $VERSION = '0.015';


use BBDB::Export::LDIF;

our @ISA = qw(BBDB::Export);

use Data::Dumper;


#
#_* process_record
#

sub process_record
{
    my ( $self, $record ) = @_;

    my ( $text, $data ) = BBDB::Export::LDIF::process_record( $self, $record );

    my $tmpfile = $self->{'data'}->{'output_file'};
    return unless $tmpfile;

    my $dc = $self->{'data'}->{'dc'};
    return unless $dc;

    open ( my $out_fh, ">", $tmpfile ) or die "Unable to create temp file $tmpfile";

    print $out_fh $text;

    close $out_fh;

    my $dn = $data->{'dn'};

    my $ldappass = $self->{'data'}->{'ldappass'};
    unless ( $ldappass )
    {
        $self->error( "ldappass not specified" );
        die;
    }

    $self->info( "Deleting dn: $dn" ) if $self->{'data'}->{'verbose'};
    $self->run_command( qq(ldapdelete -x -w $ldappass -D "cn=Manager,$dc" "$dn"), 1 );

    $self->info( "Adding dn: $dn" ) if $self->{'data'}->{'verbose'};
    my $add_cmd = qq(ldapadd -x -w $ldappass -D "cn=Manager,$dc" -f $tmpfile);
    $self->run_command( $add_cmd );

}

#
#_* post_processing
#

sub post_processing
{
    my ( $self, $output ) = @_;
    return 1;
}



1;


