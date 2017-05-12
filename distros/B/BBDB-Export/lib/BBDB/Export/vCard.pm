package BBDB::Export::vCard;
use strict;
use warnings;

our $VERSION = '0.015';


our @ISA = qw(BBDB::Export);

use Data::Dumper;
use Text::vFile::asData;

#
#_* To Do
#
#   BDAY                    birthday
#   MAILER
#   TZ                      timezone
#   TITLE
#   ROLE
#   PRODID
#   REV
#   SORT-STRING
#   UID
#   URL
#   CLASS
#   NICKNAME
#   PHOTO

#
#_* config
#

# supported keys, in preferred order
# TODO: make this configurable
my @keys = qw( begin version fn n org note tel email end);

#
#_* process_record
#

sub process_record
{
    my ( $self, $record ) = @_;

    my $vcard = Text::vFile::asData->new();


    my $data;
    $data->{'properties'}->{'begin'}   = [  { value => "vcard" } ];
    $data->{'properties'}->{'version'} = [  { value => "3.0" } ];
    $data->{'properties'}->{'fn'}      = [  { value => $record->{'full'} } ];
    $data->{'properties'}->{'n'}       = [  { value => join ";", (
                                                                  $record->{'last'},
                                                                  $record->{'first'},
                                                                  "",
                                                                  "",
                                                                  ""
                                                                 )
                                                              } ];
    $data->{'properties'}->{'org'} = [  { value => $record->{'company'} } ];
    $data->{'properties'}->{'note'} = [  { value => $record->{'notes'} } ];
    $data->{'properties'}->{'tel'} = [
                                    {
                                     value => $record->{'phone'}->{'home' },
                                     param => {
                                                type => "home",
                                               }
                                    },

                                    {
                                     value => $record->{'phone'}->{'work' },
                                     param => {
                                                type => "work",
                                               }
                                    },

                                    {
                                     value => $record->{'phone'}->{'mobile' },
                                     param => {
                                                type => "mobile",
                                               }
                                    },

                                    {
                                     value => $record->{'phone'}->{'fax' },
                                     param => {
                                                type => "fax",
                                               }
                                    },

                                     ];


    if ( $record->{ 'net' } && ref $record->{ 'net' } eq "ARRAY" )
    {
        for my $index ( 0 .. $#{ $record->{ 'net' } } )
        {
            push @{ $data->{'properties'}->{'email'} }, {
                                                         value => $record->{'net'}->[$index],
                                                         param => {
                                                                   type => "internet",
                                                                  }
                                                        };
        }
    }


    $data->{'properties'}->{'end'} = [  { value => "vcard" } ];

    my @lines = $self->_generate_lines( $data );

    my $return = join( "\n", @lines );

    if ( my $dir = $self->{'data'}->{'output_dir'} )
    {
        my $file = join ( "_", ( $record->{'first'}, $record->{'last'} ) );
        $file =~ tr,A-Za-z\-_,,cd;
        $file = $dir . "/" . $file; 
        $file .= ".vcf";
        print "Writing file: $file\n";
        open ( my $vcard_fh, ">", $file ) or die "Unable to write vcard: $file: $!";
        print $vcard_fh $return, "\n";
        close ( $vcard_fh ) or die "Error writing vcard: $file: $!";
    }

    return $return;
}

#
#_* Text::vFile::asData::generate_lines needs a little work
#
sub _generate_lines
{
    my ( $self, $data ) = @_;

    my @lines;

    push @lines, "BEGIN:$data->{type}" if exists $data->{type};
    if (exists $data->{properties})
    {
        # TODO: handle properties that are not listed in global @keys
        for my $name ( @keys )
        {
            next unless $data->{properties}->{ $name };
            my $v = $data->{properties}->{ $name };

            for my $value (@$v) {
                next unless $value->{'value'};
                # XXX so we're taking params in preference to param,
                # let's be sure to document that when we document this
                # method
                my $param = join ';', '', map {
                    my $hash = $_;
                    map {
                        "$_" . (defined $hash->{$_} ?  "=" . $hash->{$_} : "")
                    } keys %$hash
                } @{ $value->{params} || [ $value->{param} ] };
                push @lines, "$name$param:$value->{value}";
            }
        }
    }

    if (exists $data->{objects}) {
        push @lines, $self->generate_lines( $_ ) for @{ $data->{objects} }
    }
    push @lines, "END:$data->{type}" if exists $data->{type};
    return @lines;
}

#
#_* post_processing
#

# no post processing necessary for vcard since there is one entry per
# file.
sub post_processing
{
    my ( $self, $output ) = @_;
    return $output;
}

1;


