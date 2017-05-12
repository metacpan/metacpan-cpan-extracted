package BBDB::Export;
use strict;
use warnings;

our $VERSION = '0.015';


#
#_* Config
#

# TODO: make this configurable
my %colors = (
              info    => 'green',
              command => 'bold yellow',
              error   => 'red',
              verbose => 'blue',
              );

#
#_* Libraries
#
use BBDB;
use Term::ANSIColor;
use Data::Dumper;

#
#_* new
#

sub new
{
    my ( $class, $data ) = @_;

    my $objref = ( { data => $data } );

    bless $objref, $class;

    return $objref;
}

#
#_* get_record_hash
#
sub get_record_hash
{
    my ( $self, $record ) = @_;

    return unless ( $record );

    # store record data
    my %record;

    # get entire data structure
    my $data = $record->part('all');

    # first/last names
    $record{'first'} = $data->[0];
    $record{'last'}  = $data->[1];
    $record{'full' } = join( " ", ( $record{'first'}, $record{'last'} ) );
    $record{'full' } =~ s|^\s+||;
    $record{'full' } =~ s|\s+$||;

    # nicks
    @{$record{'aka'}} = @{ $data->[2] } if $data->[2] && $data->[2]->[0];

    # company
    $record{'company'} = $data->[3];

    # phone numbers
    if ( $data->[4] && $data->[4]->[0] )
    {
        for my $phone ( @{ $data->[4] } )
        {
            my $loc = $phone->[0];

            my @numbers = @{ $phone->[1] };
            pop @numbers;

            my $number;

            if ( $#numbers == 2 )
            {
                $number = "(" . $numbers[0] . ") " . $numbers[1] . "-" . $numbers[2];
            }
            else
            {
                $number = join( "-", @numbers );
            }

            $record{'phone'}->{ $loc } = $number;
        }
    }

    # TODO: addresses

    # nicks
    @{$record{'net'}} = @{ $data->[6] } if $data->[6] && $data->[6]->[0];


    # notes
    if ( $data->[7] && $data->[7]->[0] )
    {
        for my $note ( @{ $data->[7] } )
        {
            $record{ $note->[0] } = $note->[1];
        }
    }

    return \%record;
}

#
#_* process_record
#


#
#_* export
#
sub export
{
    my ( $self ) = @_;

    unless ( $self->{'data'}->{'bbdb_file'} )
    {
        $self->error( "export called but bbdb_file not specified" );
        return;
    }

    unless ( -r $self->{'data'}->{'bbdb_file'} )
    {
        $self->error( "export called but bbdb_file not readable" );
        return;
    }

    my $return = "";

    for my $record ( @{BBDB::simple( $self->{'data'}->{'bbdb_file'} )} )
    {
        my $record_hash = $self->get_record_hash( $record );
        unless ( $record_hash )
        {
            $self->error( "No data returned from record" );
            next;
        }

        my ( $output ) = $self->process_record( $record_hash );
        $return .= $output if $output;
    }

    $self->post_processing( $return );

    return $return;
}


#
#_* output
#

sub info
{
    my ( $self, @info ) = @_;

    return if $self->{'data'}->{'quiet'};

    print color $colors{'info'};
    print join ( "\n", @info ) if $info[0];
    print color 'reset';
    print "\n";
}

sub error
{
    my ( $self, @error ) = @_;

    return if $self->{'data'}->{'quiet'};

    print color $colors{'error'};
    print join ( "\n", @error ) if $error[0];
    print color 'reset';
    print "\n";
}

sub verbose
{
    my ( $self, @verbose ) = @_;

    return if $self->{'data'}->{'quiet'};
    return unless $self->{'verbose'};

    print color $colors{'verbose'};
    print join ( "\n", @verbose ) if $verbose[0];
    print color 'reset';
    print "\n";
}

#
#_* spawn external command, e.g. ldapadd
#
sub run_command
{
    my ( $self, $command, $supress_error ) = @_;

    $self->verbose("COMMAND: $command");

    open( my $run_fh, "-|", "$command 2>&1" );
    my $out = join( "\n", <$run_fh> );

    if ( close $run_fh )
    {
        if ( $self->{'verbose'} )
        {
            print color $colors{'command'};
            print $out;
            print color 'reset';
        }

        return $out;
    }
    else
    {
        unless ( $self->{'data'}->{'supress_error'} )
        {
            $self->error( $out );
        }

        return;
    }
}


1;
__END__

=head1 NAME

BBDB::Export - export data from The Insidious Big Brother Database.

=head1 VERSION

version 0.015

=head1 SYNOPSIS

  use BBDB::Export;

  # export to LDIF
  my $exporter = BBDB::Export::LDIF->new(
                                         {
                                          bbdb_file   => "/path/to/.bbdb",
                                          output_file => "export.ldif",
                                          dc          => "dc=geekfarm, dc=org",
                                         }
                                          );
  $exporter->export();

  # sync with ldap via ldapadd and ldapdelete
  my $exporter = BBDB::Export::LDAP->new(
                                         {
                                          bbdb_file   => "/path/to/.bbdb",
                                          output_file => "/tmp/tempfile",
                                          dc          => "dc=geekfarm, dc=org",
                                          ldappass    => "supersecret",
                                         }
                                          );

  $exporter->export();

  # export to vcards
  my $exporter = BBDB::Export::vCard->new(
                                          {
                                           bbdb_file   => "/path/to/.bbdb",
                                           output_dir  => "/some/path/",
                                          }
                                           );

  $exporter->export();

  # create .mail_aliases
  my $exporter = BBDB::Export::MailAliases->new(
                                                {
                                                 bbdb_file   => "/path/to/.bbdb",
                                                 output_file => ".mail_aliases",
                                                }
                                                 );

  $exporter->export();


=head1 DESCRIPTION

This module was designed to export to your bbdb data to a wide array
of formats, and also to make it easy to write new modules to export to
new formats.  Current export options include building an LDIF, vCard,
or .mail_aliases, and automatically updating an ldap server.

For a fully functional command line converter, see the bbdb-export
script that comes with this module.

BBDB::Export should not be used directly.  Use any of the available
subclasses using the examples above.  For more examples of using
BBDB::Export, see the test cases.

=head1 EXTENDING

When writing a new class, you can define the following subroutines:

=over 8

=item get_record_hash

given a record hash, create or modify any keys and values that are
needed to export your data.  If the fields already provided are
sufficient, you don't need to define this method.  If you do define
this method, you'll need to call this method from the superclass
first, e.g.

    my ( $self, $record ) = @_;
    $record = $self->SUPER::get_record_hash( $record );

=item process_record

given a record hash, generate exported data.  Also perform any
per-record actions.  For example, if you are creating one export file
per record, write the current record to a file in this method.

=item post_processing

run any processing that needs to be done after all records have been
processed.  For example, if you are creating one file containing all
records, write the file in this method.

=back

=head1 SUBROUTINES/METHODS

=over 8

=item new

=item export

=item run_command

run an external command, e.g. ldapadd

=item $obj->info( @lines )

report informational messages to the user.

=item $obj->error( @lines )

report error messages to the user.

=item $obj->verbose( @lines )

report debugging info to user.  this information will only be
displayed if verbose output is enabled.

=back

=head1 SEE ALSO

- bbdb - an emacs mode for managing information about contacts

- BBDB - perl module for parsing bbdb data files.

- OpenLDAP - open source ldap implementation

- http://www.onlamp.com/pub/a/onlamp/2003/03/27/ldap_ab.html - how to
  set up ldap.

- http://www.geekfarm.org - bbdb2ldap.

- PlannerMode - also on geekfarm.  A module for exporting emacs todo
  lists and schedule info to other clients including palm.

=head1 AUTHOR

 wu <VVu@geekfarm.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005, VVu@geekfarm.org
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

- Neither the name of the geekfarm.org nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut