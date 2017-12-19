package Data::EDI::X12;
use strict;

use YAML qw(LoadFile Load);
use IO::File;

our $VERSION = '0.09';

=head1 NAME

Data::EDI::X12 - EDI X12 Processing for Perl

=cut

=head1 SYNOPSIS

 my $x12 = Data::EDI::X12->new({ spec_file => 'edi.yaml', new_lines => 1, truncate_null => 1, hide_empty_sections => 1 });
 my $data = $x12->read_record(...);
 print $x12->write_record($data);
 
=head1 METHODS

=cut

sub debug { shift->{debug} }

my $DEFAULT_CONFIG = {
    ISA => {
        definition => [
            {
                type => 'text',
                name => 'authorization_information_qualifier',
                value => '00',
                bytes => 2,
            },
            {
                type => 'filler',
                bytes => 10,
                value => ' ',
            },
            {
                type => 'text',
                name => 'security_information_qualifier',
                value => '00',
                bytes => 2,
            },
            {
                type => 'filler',
                bytes => 10,
                value => ' ',
            },
            {
                type => 'text',
                name => 'interchange_id_qualifier_1',
                value => '00',
                bytes => 2,
            },
            {
                type => 'text',
                name => 'interchange_id_1',
                value => '00',
                bytes => 15,
            },
            {
                type => 'text',
                name => 'interchange_id_qualifier_2',
                value => '00',
                bytes => 2,
            },
            {
                type => 'text',
                name => 'interchange_id_2',
                value => '00',
                bytes => 15,
            },
            {
                type => 'text',
                name => 'date',
                value => '',
                bytes => 6,
            },
            {
                type => 'text',
                name => 'time',
                value => '',
                bytes => 4,
            },
            {
                type => 'text',
                name => 'repetition_separator',
                value => 'U',
                bytes => 1,
            },
            {
                type => 'text',
                name => 'control_version_number',
                bytes => 5,
            },
            {
                type => 'text',
                name => 'control_number',
                bytes => 9,
                format => '%09i',
            },
            {
                type => 'text',
                name => 'acknowledgment_requested',
                bytes => 1,
            },
            {
                type => 'text',
                name => 'usage_indicator',
                bytes => 1,
                value => 'P',
            },
            {
                type => 'text',
                bytes => 1,
                value => '>',
            }
        ],
    },
    IEA => {
        definition => [
            {
                name => 'total',
                min => 1,
                max => 10,
            },
            {
                name => 'control_number',
                min => 4,
                max => 9,
                format => '%09i',
            },
        ],
    },
    GS => {
        definition => [
            {
                type => 'text',
                name => 'type',
                value => '00',
                bytes => 2,
            },
            {
                type => 'text',
                name => 'sender_code',
                bytes => 9,
            },
            {
                type => 'text',
                name => 'receiver_code',
                bytes => 9,
            },
            {
                type => 'text',
                name => 'date',
                value => '',
                bytes => 8,
            },
            {
                type => 'text',
                name => 'time',
                value => '',
                bytes => 4,
            },
            {
                type => 'text',
                name => 'control_number',
                bytes => 9,
                format => '%09i',
            },
            {
                type => 'text',
                name => 'agency_code',
                bytes => 1,
                value => 'X',
            },
            {
                type => 'text',
                name => 'version_number',
                bytes => 6,
            },
        ],
    },
    ST => {
        definition => [
            {
                name => 'identifier_code',
                min => 3,
                max => 3,
            },
            {
                name => 'control_number',
                min => 4,
                max => 9,
                format => '%04i',
            },
        ],
    },
    SE => {
        definition => [
            {
                name => 'total',
                min => 1,
                max => 10,
            },
            {
                name => 'control_number',
                min => 4,
                max => 9,
                format => '%04i',
            },
        ],
    },
    GE => {
        definition => [
            {
                name => 'total',
                min => 1,
                max => 10,
            },
            {
                name => 'control_number',
                min => 4,
                max => 9,
                format => '%09i',
            },
        ],
    },
};

=head2 new

 my $x12 = Data::EDI::X12->new({ spec_file => 'edi.yaml', new_lines => 1, truncate_null => 1 });

=cut

sub new
{
    my ($class, $args) = @_;

    my $yaml_spec;
    if ($args->{spec})
    {
        $yaml_spec = $args->{spec};
    }
    elsif ($args->{yaml_spec})
    {
        $yaml_spec = Load($args->{spec});
    }
    elsif ($args->{spec_file})
    {
        $yaml_spec = LoadFile($args->{spec_file});
    }
    else
    {
        die sprintf("[%s] args spec or spec_file must be specified", __PACKAGE__);
    }

    my $spec = {
        %$DEFAULT_CONFIG,
        %$yaml_spec,
    };

    my $config_terminator;
    $config_terminator = $spec->{config}{config_terminator}
        if $spec->{config} and $spec->{config}{config_terminator};

    my $config_separator;
    $config_separator = $spec->{config}{config_separator}
        if $spec->{config} and $spec->{config}{config_separator};

    my $config_strict_ascii = $args->{strict_ascii};
    $config_strict_ascii = $spec->{config}{strict_ascii}
        if $spec->{config} and exists($spec->{config}{strict_ascii});

    my $config_truncate_null = $args->{truncate_null};
    $config_truncate_null = $spec->{config}{truncate_null}
        if $spec->{config} and exists($spec->{config}{truncate_null});

    my $config_hide_empty_sections = $args->{hide_empty_sections};
    $config_hide_empty_sections = $spec->{config}{hide_empty_sections}
        if $spec->{config} and exists($spec->{config}{hide_empty_sections});
    

    my $self = {
        spec                => $spec,
        debug               => $args->{debug},
        terminator          => $config_terminator || $args->{terminator} || '~',
        separator           => $config_separator  || $args->{separator}  || '*',
        error               => '',
        new_lines           => $args->{new_lines},
        truncate_null       => $config_truncate_null       || 0,
        hide_empty_sections => $config_hide_empty_sections || 0,
        strict_ascii        => $config_strict_ascii        || 0,
    };
    bless($self);

    return $self;
}

=head2 read_record

 my $record = $x12->read_record($string);

=cut

sub read_record
{
    my ($self, $string) = @_;

    my $record = { };

    # strip newlines if applicable
    $string =~ s/[\r\n]//g
        unless $self->{terminator} =~ /[\r\n]/;

    open(my $fh, "<", \$string);

    #$self->_parse_transaction_set({
    $self->_parse_edi({
        fh         => $fh,
        string     => $string,
        record     => $record,
    });
        
    return $record;
}

=head2 write_record

 my $string = $x12->write_record($record);

=cut

sub write_record
{
    my ($self, $record) = @_;

    my $string = '';
    open(my $fh, ">", \$string);
    $self->_write_edi({
        fh         => $fh,
        string     => $string,
        record     => $record,
    });
        
    return $string;
}

sub _split_string
{
    my ($self, $string) = @_;
    my $term_val = quotemeta($self->{terminator});
    my $sep_val  = quotemeta($self->{separator});

    my @records;
    push @records, [ split(/$sep_val/, $_) ]
        for split(/$term_val/, $string);

    return @records;
}

sub _parse_definition
{
    my ($self, $params) = @_;

    my $record = { };

    my $definition     = $params->{definition};

    my $segments       = $params->{segments};
    my $type           = $params->{type};

    for my $def (@{ $definition || [ ] })
    {
        my $segment = shift(@$segments);
        $segment =~ s/\s+$//g;
                
        $record->{$def->{name}} = $segment
            if $def->{name};
    }

    return $record;
}

sub _parse_edi
{
    my ($self, $params) = @_;

    my $fh             = $params->{fh};
    my $record         = $params->{record};
    my $definition     = $params->{definition};
    my $string         = $params->{string};

    my $IN_ISA = 0;
    my $IN_GS = 0;
    my $IN_ST = 0;
    my $IN_DETAIL = 0;
    my $IN_FOOTER = 0;

    my $IN_LOOP;
    my $LOOP_SECTION;
    my %LOOP_SEGMENTS;

    my ($current_group, $current_set, $current_record);

    $record->{GROUPS} = [ ]
        unless exists $record->{GROUPS};

    for my $segments ($self->_split_string($string))
    {
        my $type = uc(shift(@$segments));

        if ($type eq 'ISA')
        {
            $record->{ISA} = $self->_parse_definition({
                definition => $self->{spec}->{ISA}->{definition},
                segments   => $segments,
                type       => $type,
            });
            $IN_ISA = 1;

            %LOOP_SEGMENTS = ();
            $LOOP_SECTION = undef;
            $IN_LOOP = undef;

            $IN_DETAIL = 0;
            $IN_FOOTER = 0;
        }
        elsif ($type eq 'IEA')
        {
            $IN_ISA = 0;

            %LOOP_SEGMENTS = ();
            $LOOP_SECTION = undef;
            $IN_LOOP = undef;

            $IN_DETAIL = 0;
            $IN_FOOTER = 0;
        }
        elsif ($type eq 'GS')
        {
            my $new_group = $self->_parse_definition({
                definition => $self->{spec}->{GS}->{definition},
                segments   => $segments,
                type       => $type,
            });

            $new_group->{SETS} = [ ];

            $IN_GS = 1;

            %LOOP_SEGMENTS = ();
            $LOOP_SECTION = undef;
            $IN_LOOP = undef;

            $IN_DETAIL = 0;
            $IN_FOOTER = 0;

            $current_group = $new_group;
        }
        elsif ($type eq 'GE')
        {
            push @{ $record->{GROUPS} }, \%$current_group;

            %LOOP_SEGMENTS = ();
            $LOOP_SECTION = undef;
            $IN_LOOP = undef;

            $IN_DETAIL = 0;
            $IN_FOOTER = 0;

            $IN_GS = 0;
        }
        elsif ($type eq 'ST')
        {
            my $new_set = $self->_parse_definition({
                definition => $self->{spec}->{ST}->{definition},
                segments   => $segments,
                type       => $type,
            });

            $IN_ST = 1;

            %LOOP_SEGMENTS = ();
            $LOOP_SECTION = undef;
            $IN_LOOP = undef;

            $IN_DETAIL = 0;
            $IN_FOOTER = 0;

            $current_set = $new_set;
            $current_record = $new_set;
        }
        elsif ($type eq 'SE')
        {
            push @{ $current_group->{SETS} }, \%$current_set;

            %LOOP_SEGMENTS = ();
            $LOOP_SECTION = undef;
            $IN_LOOP = undef;

            $IN_GS = 0;
            $IN_DETAIL = 0;
            $IN_FOOTER = 0;
        }
        else
        {
            my $doc_id = $current_set->{identifier_code};
            my $spec   = $self->{spec}->{$doc_id};

            # parse a record
            my %segment_to_section;
            my %loop_def;
            for my $section (keys %{ $spec->{structure} || { } })
            {
                for my $segment (@{ $spec->{structure}{$section} || [ ] })
                {
                    if (ref($segment) and ref($segment) eq 'HASH')
                    {
                        for my $key (keys(%$segment))
                        {
                            $loop_def{$key} = $segment->{$key};
                            $segment_to_section{$key} = uc($section);
                        }
                    }
                    else
                    {
                        $segment_to_section{$segment} = uc($section);
                    }
                }
            }

            # state machine bingo!
            my $section  = $segment_to_section{$type};

            if ($section eq 'DETAIL')
            {
                $IN_DETAIL = 1;
            }
            elsif ($section eq 'HEADER' and $IN_DETAIL)
            {
                $section = 'DETAIL';
            }
            elsif ($section eq 'FOOTER')
            {
                $IN_FOOTER = 1;
            }
            elsif ($section eq 'DETAIL' and $IN_FOOTER)
            {
                $section = 'FOOTER';
            }

            my $mod_record;

            # track tree depth
            # and dump results in loop portion?
            {
               if (my $type_def = $spec->{segments}{uc($type)})
               {
                   if ($section eq 'DETAIL' or $LOOP_SECTION eq 'DETAIL')
                   {
                       $current_record->{DETAIL} = [{}]
                           unless exists $current_record->{DETAIL};

                       # START THE LOOPING
                       if ($loop_def{$type} and not $IN_LOOP)
                       {
                           $IN_LOOP = $type;
                           $LOOP_SECTION = $section;
                           %LOOP_SEGMENTS = map { $_ => 1 } @{ $loop_def{$type} || [] };
                       }

                       # END THE LOOPING
                       if ($IN_LOOP and not $LOOP_SEGMENTS{$type})
                       {
                           %LOOP_SEGMENTS = ();
                           $LOOP_SECTION = undef;
                           $IN_LOOP = undef;
                       }

                       if ($IN_LOOP)
                       {
                           $current_record->{DETAIL}->[-1]->{$IN_LOOP} = [{}]
                               unless exists $current_record->{DETAIL}->[-1]->{$IN_LOOP};

                           push @{ $current_record->{DETAIL}->[-1]->{$IN_LOOP} }, {}
                               if exists($current_record->{DETAIL}->[-1]->{$IN_LOOP}->[-1]->{$type});

                           $current_record->{DETAIL}->[-1]->{$IN_LOOP}->[-1]->{$type} = $self->_parse_definition({
                               definition => $type_def->{definition},
                               segments   => $segments,
                               type       => $type,
                           });
                       }
                       else
                       {
                           push @{ $current_record->{DETAIL} }, {}
                               if exists($current_record->{DETAIL}->[-1]->{$type});

                           $current_record->{DETAIL}->[-1]->{$type} = $self->_parse_definition({
                               definition => $type_def->{definition},
                               segments   => $segments,
                               type       => $type,
                           });
                       }
                   }
                   else
                   {
                       $current_record->{$section} = {}
                           unless exists $current_record->{$section};

                       my $structure = $spec->{structure}{lc($section)};

                       # END THE LOOPING
                       if ($IN_LOOP and not $LOOP_SEGMENTS{$type})
                       {
                           %LOOP_SEGMENTS = ();
                           $LOOP_SECTION = undef;
                           $IN_LOOP = undef;
                       }

                       # START THE LOOPING
                       if ($loop_def{$type} and not $IN_LOOP)
                       {
                           $IN_LOOP = $type;
                           $LOOP_SECTION = $section;
                           %LOOP_SEGMENTS = map { $_ => 1 } @{ $loop_def{$type} || [] };

                       }

                       if ($IN_LOOP)
                       {
                           $current_record->{$LOOP_SECTION}->{$IN_LOOP} = [{}]
                               unless exists $current_record->{$LOOP_SECTION}->{$IN_LOOP};

                           push @{ $current_record->{$LOOP_SECTION}{$IN_LOOP} }, {}
                               if exists($current_record->{$LOOP_SECTION}->{$IN_LOOP}->[-1]->{$type});

                           $current_record->{$LOOP_SECTION}->{$IN_LOOP}->[-1]->{$type} = $self->_parse_definition({
                               definition => $type_def->{definition},
                               segments   => $segments,
                               type       => $type,
                           });
                       }
                       else
                       {
                           $current_record->{$section}->{$type} = $self->_parse_definition({
                               definition => $type_def->{definition},
                               segments   => $segments,
                               type       => $type,
                           });
                       }
                   }
               }
           }
        }
    }
}

sub _write_spec
{
    my ($self, %params) = @_;
    my $type_def = $params{type_def};
    my $record   = $params{record};
    my @line     = ($params{type});
    my $term_val = $self->{terminator};
    my $sep_val  = $self->{separator};

    for my $def (@{ $type_def->{definition} || [ ] })
    {
        next unless ref($record) eq 'HASH';

        my $value = ($def->{name} and exists($record->{$def->{name}})) ?
            $record->{$def->{name}} : $def->{value};

        $value = '' unless defined $value;

        $def->{bytes} ||= '';

        # deal with minimum
        $def->{bytes} = $def->{min}
            if $value ne '' and not($def->{bytes}) and $def->{min} and length($value) < $def->{min};

        $def->{bytes} = '-' . $def->{bytes}
            if $def->{bytes};

        my $format = $def->{format} || "\%$def->{bytes}s";
                
        # deal with maximum limits
        $value = substr($value, 0, $def->{max})
            if $def->{max};

        # stop stupidity
        $value =~ s/\Q$term_val\E//g if $value;
        $value =~ s/\Q$sep_val\E//g  if $value;

        # strip all non-ascii
        $value =~ s/[^[:ascii:]]//g if $self->{strict_ascii};

        push @line, sprintf($format, $value);
    }

    
    if ($self->{truncate_null})
    {
        for my $val (reverse @line)
        {
            last if $val ne '';

            pop(@line);
        }
    }    
    
    my $string = join($sep_val, @line);
    $string   .= $term_val;
    $string   .= "\n" if $self->{new_lines};

    return $string;
}

sub _write_edi
{
    my ($self, $params) = @_;

    my $fh             = $params->{fh};
    my $record         = $params->{record};
    my $definition     = $params->{definition};
    my $string         = $params->{string};

    my $buffer = '';

    my $term_val = $self->{terminator};
    my $sep_val  = $self->{separator};

    my $hide_empty_sections = $self->{hide_empty_sections};

    $record->{ISA}{control_number} = 1
        unless exists $record->{ISA}{control_number};

    # write ISA header
    print $fh $self->_write_spec(
        type     => 'ISA',
        type_def => $self->{spec}->{ISA},
        record   => $record->{ISA},
    );

    my $group_count = 0;
    # iterate through document structure
    for my $group (@{ $record->{GROUPS} || [ ] })
    {
        $group_count++;

        $group->{control_number} = $group_count unless exists $group->{control_number};

        # process GS line
        print $fh $self->_write_spec(
            type     => 'GS',
            type_def => $self->{spec}->{GS},
            record   => $group,
        );

        my $set_count = 0;

        for my $set (@{ $group->{SETS} || [ ] })
        {
            my $record_count = 1;

            # you don't want to know why this exists...
            if ($self->{spec}->{RECORD_OFFSET_COUNT})
            {
                $record_count = $record_count + $self->{spec}->{RECORD_OFFSET_COUNT};
            }

            $set_count++;

            $set->{control_number} = $set_count
                unless exists $set->{control_number};

            # process ST line
            print $fh $self->_write_spec(
                type     => 'ST',
                type_def => $self->{spec}->{ST},
                record   => $set,
            );

            ######
            # process actual set
            my $doc_id = $set->{identifier_code};
            my $spec   = $self->{spec}->{$doc_id};

            die "cannot find spec for $doc_id"
                unless $spec;

            # process set header
            for my $section (@{ $spec->{structure}{header} || [ ] })
            {
                if (ref($section) and ref($section) eq 'HASH')
                {
                    my ($loop_name) = keys(%$section);
                    my $loop_structure = $section->{$loop_name};

                    for my $record (@{ $set->{HEADER}{$loop_name} || [] })
                    {
                        for my $structure (@{ $loop_structure || []})
                        {
                            next if $hide_empty_sections and not exists $record->{$structure};

                            $record_count++;

                            print $fh $self->_write_spec(
                                type     => $structure,
                                type_def => $spec->{segments}{$structure},
                                record   => $record->{$structure},
                            );
                        }
                    }
                }
                else
                {
                    next if $hide_empty_sections and not exists $set->{HEADER}{$section};

                    $record_count++;
                    print $fh $self->_write_spec(
                        type     => $section,
                        type_def => $spec->{segments}{$section},
                        record   => $set->{HEADER}{$section},
                    );
                }
            }

            # process set details
            for my $detail (@{ $set->{DETAIL} || [ ] })
            {
                for my $section (@{ $spec->{structure}{detail} || [ ] })
                {
                    if (ref($section) and ref($section) eq 'HASH')
                    {
                        my ($loop_name) = keys(%$section);
                        my $loop_structure = $section->{$loop_name};

                        for my $sub_record (@{ $detail->{$loop_name} || [] })
                        {
                            for my $structure (@{ $loop_structure || []})
                            {
                                next if $hide_empty_sections and not exists $sub_record->{$structure};

                                $record_count++;
                                print $fh $self->_write_spec(
                                    type     => $structure,
                                    type_def => $spec->{segments}{$structure},
                                    record   => $sub_record->{$structure},
                                );
                            }
                        }
                    }
                    else
                    {
                        next if $hide_empty_sections and not exists $detail->{$section};

                        $record_count++;
                        print $fh $self->_write_spec(
                            type     => $section,
                            type_def => $spec->{segments}{$section},
                            record   => $detail->{$section},
                        );
                    }
                }
            }
            

            # process set footer
            for my $section (@{ $spec->{structure}{footer} || [ ] })
            {
                if (ref($section) and ref($section) eq 'HASH')
                {
                    my ($loop_name) = keys(%$section);
                    my $loop_structure = $section->{$loop_name};

                    for my $record (@{ $set->{FOOTER}{$loop_name} || [] })
                    {
                        for my $structure (@{ $loop_structure || []})
                        {
                            next if $hide_empty_sections and not exists $record->{$structure};

                            $record_count++;
                            print $fh $self->_write_spec(
                                type     => $structure,
                                type_def => $spec->{segments}{$structure},
                                record   => $record->{$structure},
                            );
                        }
                    }
                }
                else
                {
                    next if $hide_empty_sections and not exists $set->{FOOTER}{$section};

                    $record_count++;
                    print $fh $self->_write_spec(
                        type     => $section,
                        type_def => $spec->{segments}{$section},
                        record   => $set->{FOOTER}{$section},
                    );
                }
            }

            ######

            # process SE line
            $record_count++;
            print $fh $self->_write_spec(
                type     => 'SE',
                type_def => $self->{spec}->{SE},
                record   => {
                    total          => $record_count,
                    control_number => $set->{control_number},
                },
            );
        }

        # process GE line
        print $fh $self->_write_spec(
            type     => 'GE',
            type_def => $self->{spec}->{GE},
            record   => {
                control_number => $group->{control_number},
                total          => $set_count,
            },
        );
    }

    # write IEA header
    print $fh $self->_write_spec(
        type     => 'IEA',
        type_def => $self->{spec}->{IEA},
        record   => {
            control_number => $record->{ISA}{control_number},
            total          => $group_count,
        },
    );    
}

=head1 EXAMPLES

=head2 SPEC FILE EXAMPLE

 850:
     structure:
         header:
             - BEG
             - DTM
             - N9
             - N1
         detail:
             - PO1
             - PID
         footer:
             - CTT
     segments:
         BEG:
             definition:
                 - name: purpose_codse
                   min: 2
                   max: 2
                 - name: type_code
                    min: 2
                   max: 2
                 - name: order_number 
                   min: 1
                   max: 22
                 - type: filler
                  - name: date
                   min: 8
                   max: 8
         DTM:
             definition:
                 - name: qualifier
                   min: 3
                   max: 3
                 - name: date
                   min: 8
                   max: 8
         N9:
             definition:
                 - name: qualifier
                   min: 2
                   max: 3
                 - name: identification
                   min: 1
                   max: 50
         N1:
             definition:
                 - name: identifier
                   min: 2
                   max: 3
                 - name: name
                   min: 1
                   max: 60
                 - name: identification_code_qualifier
                   min: 1
                   max: 2
                 - name: identification_code
                   min: 2
                   max: 80
         PO1:
             definition:
                 - type: filler
                 - name: quantity
                   min: 1
                   max: 15
                 - name: unit_of_measure
                   min: 2
                   max: 2
                 - name: unit_price
                   min: 1
                   max: 17
                 - type: filler
                 - name: id_qualifier
                   min: 2
                   max: 2
                 - name: product_id
                   min: 1
                   max: 48
                 - name: id_qualifier_2
                   min: 2
                   max: 2
                 - name: product_id_2
                   min: 1
                   max: 48
                 - name: id_qualifier_3
                   min: 2
                   max: 2
                 - name: product_id_3
                   min: 1
                   max: 48
         PID:
             definition:
                 - name: type
                 - type: filler
                 - type: filler
                 - type: filler
                 - name: description
                   min: 1
                   max: 80
         CTT:
             definition:
                 - name: total_items
                   min: 1
                   max: 6
                 - name: hash_total
                   min: 1
                   max: 10

=head2 PERL EXAMPLE

 use Data::EDI::X12;
 
 my $string = q[ISA*00*          *00*          *01*012345675      *01*987654321      *140220*1100*^*00501*000000001*0*P*>~
 GS*PO*012345675*987654321*20140220*1100*000000001*X*005010~
 ST*850*0001~
 BEG*00*KN*1136064**20140220~
 DTM*002*20140220~
 N9*ZA*0000010555~
 N1*ST*U997*92*U997~
 PO1**1*EA*1.11**UC*000000000007*PI*000000000000000004*VN*113~
 PID*F****Test Product 1~
 PO1**1*EA*2.22**UC*000000000008*PI*000000000000000005*VN*114~
 PID*F****Test Product 2~
 CTT*4*4~
 SE*12*0001~
 GE*1*000000001~
 IEA*1*000000001~
 ];
 
 my $x12 = Data::EDI::X12->new({ spec_file => 't/spec.yaml', new_lines => 1, truncate_null => 1 });
 
 my $record = $x12->read_record($string);
 my $out = $x12->write_record($record);

=head2 LOOPS

 Both implicit and explicit loop segments are also supported by this module.

 Loops are specified within the structure segment of the spec definition.

 Example:

 850:
     structure:
         header:
             - BEG
             - DTM
             - N9
             - N1:
                 - N1
                 - N2
         detail:
             - PO1
             - PID
         footer:
             - CTT

  In this structure, the N1 element would load as an arrayref of both N1 and N2 hasherefs.

  


=head1 HISTORY

This module was authored for L<Bizowie|http://bizowie.com/>.

=head1 AUTHOR

Bizowie

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, 2015, 2016 Bizowie

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.14.2 or, at your option, any later version of Perl 5 you may have available.

=cut

1;
