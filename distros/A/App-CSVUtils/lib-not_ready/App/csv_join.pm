package App::CSVUtils::csv_join;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

use App::CSVUtils qw(
                        gen_csv_util
                );

gen_csv_util(
    name => 'csv_join',
    summary => 'Join fields from one CSV to another',
    #XXX Update to cover --regex, --fuzzy-fill, --inner
    description => <<'MARKDOWN',

Example input:

    # report.csv
    client_id,followup_staff,followup_note
    101,Jerry,not renewing,
    299,Jerry,still thinking over,
    734,Elaine,renewing,

    # clients.csv
    id,name,email,phone
    101,Andy,andy@example.com,555-2983
    102,Bob,bob@acme.example.com,555-2523
    299,Cindy,cindy@example.com,555-7892
    400,Derek,derek@example.com,555-9018
    701,Edward,edward@example.com,555-5833
    734,Felipe,felipe@example.com,555-9067

To add `client_email` and `client_phone` fields to `report.csv` from `clients.csv`, we can use:

    % csv-join -i --lookup-fields client_id:id --regex product:PDT --regex-fill --inner --fill-fields email,phone report.csv clients.csv

The result will be:

    client_id,followup_staff,followup_note,client_email,client_phone
    101,Jerry,not renewing,andy@example.com,555-2983
    299,Jerry,still thinking over,cindy@example.com,555-7892
    734,Elaine,renewing,felipe@example.com,555-9067

Note: The headers for the the target look-up fields are not required to exist, but will be used if present.
this permits you to control the placement of the new data. If the headers are absent, the new fields will
be appended to right of the the existing the fields.

MARKDOWN

    add_args => {
        fill_fields => {
            summary => 'List of source fields to add to target',
            schema => ['str*'],
            req => 1,
            cmdline_aliases => { select=>{} },
        },
        lookup_fields => {
            summary => 'Field(s) used to match source records to target',
            schema => ['str*'],
            req => 1,
            cmdline_aliases => { lookup_field=>{}, key=>{}, keys=>{}, on=>{}, where=>{} },
        },
        ignore_case => {
            summary => 'Case insensitive matching of lookup-fields',
            schema => 'bool*',
            cmdline_aliases => { ci=>{}, i=>{} },
        },
        regex => {
            summary=>'Fuzzy match for specified lookup-fields using Tie::Hash::Regex',
            schema => ['str*'],
            cmdline_aliases => { fuzzy=>{} },
        },
        regex_fill => {
            summary => 'Add fuzzy/regex matched source fields to target',
            schema => 'bool*',
            cmdline_aliases => { fuzzy_fill=>{} },
        },
        inner => {
            summary => 'Returns all possible fuzzy matching fill-fields',
            schema => 'bool*',
        },
        key_record_separator => {
            summary=> 'User definable lookup-field key record separator, analogous to perl -0',
            schema => 'str*',
            cmdline_aliases => {'key-sep'=>{}, sep=>{}, 0=>{} },
        },
        count => {
            summary => 'Do not output rows, just report the number of rows filled',
            schema => 'bool*',
            cmdline_aliases => { c=>{} },
        }
    },

    reads_multiple_csv => 1,

    tags => ['category:templating'],

    on_begin => sub {
        my $r = shift;

        # check arguments
        @{ $r->{util_args}{input_filenames} } == 2
            or die [400, "Please specify exactly 2 files: target and source"];
	#XXX no overlap between --lookup-fields and --regex?

        my @lookup_fields; # elem = [fieldname-in-target, fieldname-in-source]
        {
            my @ff = ref($r->{util_args}{lookup_fields}) eq 'ARRAY' ?
                @{$r->{util_args}{lookup_fields}} : split(/,/, $r->{util_args}{lookup_fields});
            for my $field_idx (0..$#ff) {
                my @ff2 = split /:/, $ff[$field_idx], 2;
                if (@ff2 < 2) {
                    $ff2[1] = $ff2[0];
                }
                $lookup_fields[$field_idx] = \@ff2;
            }

        }
        my @fuzzy; # elem = [fieldname-in-target, fieldname-in-source]
        {
            my @ff = ref($r->{util_args}{regex}) eq 'ARRAY' ?
                @{$r->{util_args}{regex}} : split(/,/, $r->{util_args}{regex});
            for my $field_idx (0..$#ff) {
                my @ff2 = split /:/, $ff[$field_idx], 2;
                if (@ff2 < 2) {
                    $ff2[1] = $ff2[0];
                }
                $fuzzy[$field_idx] = \@ff2;
            }
        }
	my %fuzzy = map {$_->[0]=>1, $_->[1]=>1} @fuzzy;
	map { die [400, "Cannot use the same field for both exact and fuzzy expression matching"] if
		  $fuzzy{$_->[0]} or  $fuzzy{$_->[1]} } @lookup_fields;

        my %fill_fields; # key=fieldname-in-target, val=fieldname-in-source
        {
            my @ff = ref($r->{util_args}{fill_fields}) eq 'ARRAY' ?
                @{$r->{util_args}{fill_fields}} : split(/,/, $r->{util_args}{fill_fields});
            for my $field_idx (0..$#ff) {
                my @ff2 = split /:/, $ff[$field_idx], 2;
                if (@ff2 < 2) {
                    $ff2[1] = $ff2[0];
                }
                $fill_fields{ $ff2[0] } = $ff2[1];
            }
        }

        # these are the keys that we add to the stash
        $r->{lookup_fields} = \@lookup_fields;
	$r->{fuzzy} = \@fuzzy;
        $r->{fill_fields} = \%fill_fields;
        $r->{source_fields_idx} = [];
        $r->{source_fields} = [];
        $r->{source_data_rows} = [];
        $r->{target_fields_idx} = [];
        $r->{target_fields} = [];
        $r->{target_data_rows} = [];
    },

    on_input_header_row => sub {
        my $r = shift;

	#TARGET
        if ($r->{input_filenum} == 1) {
	    #JDP: Optionally append fuzzy matched target fields
	    if( $r->{util_args}{regex_fill} ){
		$r->{fill_fields}->{ join '.', @{$_} }=$_->[1] foreach
		    @{$r->{fuzzy}};
	    }

	    #JDP: lookup-fields has undocumented expectation of headers for
	    #     empty target columns. This provides more DWIM behavior by
	    #     patching in implicit headers a la csv-add-fields
	    my $target_count = @{ $r->{input_fields} };
	    my %target_fields = map {$_=>1} @{ $r->{input_fields} };
	    foreach my $field ( keys %{ $r->{fill_fields} } ){
		unless( exists($target_fields{$field}) ){
		    push @{ $r->{input_fields} }, $field;
		    $r->{input_fields_idx}->{$field}=$target_count++;
		}
	    }

	    $r->{target_fields}     = $r->{input_fields};
	    $r->{target_fields_idx} = $r->{input_fields_idx};
	    $r->{output_fields}     = $r->{input_fields};

	    #JDP: Check join field names exist
	    #XXX Case-insensitivity?
	    foreach( @{$r->{lookup_fields}}, @{$r->{fuzzy}} ){
		my $out = $_->[0];
		die [404, "Unknown target field: $out"] unless
		    $r->{input_filenum}==1 && exists $r->{target_fields_idx}->{$out};
	    }
	    foreach my $k ( keys %{$r->{fill_fields}} ){
		die [404, "Unknown target fill field: $k"] unless
		    $r->{input_filenum}==1 && exists $r->{target_fields_idx}->{$k};
	    }

	#SOURCE
	} else {
            $r->{source_fields}     = $r->{input_fields};
            $r->{source_fields_idx} = $r->{input_fields_idx};

	    #JDP: Check join field names exist
	    #XXX Case-insensitivity?
	    foreach( @{$r->{lookup_fields}}, @{$r->{fuzzy}} ){
		my $src = $_->[1];
		die [404, "Unknown source field: $src"] unless
		$r->{input_filenum}==2 && exists $r->{source_fields_idx}->{$src};
	    }
	    foreach my $v ( values %{$r->{fill_fields}} ){
		die [404, "Unknown source fill field: $v"] unless
		    $r->{input_filenum}!=1 && exists $r->{source_fields_idx}->{$v};
	    }

	}

    },

    on_input_data_row => sub {
        my $r = shift;
        if ($r->{input_filenum} == 1) {
            push @{ $r->{target_data_rows} }, $r->{input_row};
        } else {
            push @{ $r->{source_data_rows} }, $r->{input_row};
        }
    },


    after_close_input_files => sub {
        my $r = shift;

        my $ci = $r->{util_args}{ignore_case};
        #my $fuzzy = exists($r->{util_args}{regex}) ? 1 : 0;
        my $fuzzy = scalar @{ $r->{fuzzy} };

        #Prep key separator. Original use of | is a bad option for fuzzy regex mode
        my $keySepIN = $r->{util_args}{key_record_separator};
        my $keySep = eval{chr("0$1")} if defined($keySepIN) && $keySepIN =~ /^0(x\{?[0-9a-fA-F]+\}?|[0-9+]{2})$/;
        $keySep = "\000" if $@;
        $keySep //= "\000";

        my @inner;
        my $inner = $r->{util_args}{inner};
        eval 'use Storable' if $inner;
        if( $@ ){
            warn "Cannot load Storable, unable to fulfill --inner: $@\n";
            $inner = 0;
        }

        # build lookup table w/ C-style loop for efficiency on large files
        my %lookup_table; # key = joined lookup fields, val = source row idx
        for(my $row_idx=0; $row_idx<=$#{$r->{source_data_rows}}; $row_idx++) {
            my($row, $key1, $key2);
            $row = $r->{source_data_rows}[$row_idx];
            $key1 = join $keySep, map {
                my $field = $r->{lookup_fields}[$_][1];
                my $field_idx = $r->{source_fields_idx}->{$field};
                my $val = defined $field_idx ? $row->[$field_idx] : "";
                $val = lc $val if $ci;
                $val;
            } 0..$#{ $r->{lookup_fields} };
            if( $fuzzy ){
                $key2 = join $keySep, map {
                    my $field = $r->{fuzzy}[$_][1];
                    my $field_idx = $r->{source_fields_idx}{$field};
                    my $val = defined $field_idx ? $row->[$field_idx] : '';
                    $val = lc $val if $ci;
                } 0..$#{ $r->{fuzzy} };
            } else {
                $key2 = 'STATIC';
            }
            #JDP: Split key greatly improves fuzzy match performance by binning data,
            #     thereby reducing pool of values to check with any given regexp
            $lookup_table{$key1}->{$key2} //= $row_idx;
            #warn "Prepped key1($key1)\tkey2($key2) for $row_idx\n"# unless $row_idx %20;
        }
        #use DD; dd { lookup_fields=>$r->{lookup_fields}, fill_fields=>$r->{fill_fields}, lookup_table=>\%lookup_table };

        # fill target csv
        my $rows_filled = 0;

        for(my $i=0; $i<=$#{ $r->{target_data_rows} }; $i++){
            my $row = $r->{target_data_rows}->[$i];
            my($key1, $key2);

            $key1 = join $keySep, map {
                my $field = $r->{lookup_fields}[$_][0];
                my $field_idx = $r->{target_fields_idx}{$field};
                my $val = defined $field_idx ? $row->[$field_idx] : "";
                $val = lc $val if $ci;
                $val;
            } 0..$#{ $r->{lookup_fields} };
            if( $fuzzy ){
                $key2 = join '.*?'.$keySep, map {
                    my $field = $r->{fuzzy}[$_][0];
                    my $field_idx = $r->{target_fields_idx}{$field};
                    my $val = defined $field_idx ? $row->[$field_idx] : '';
                    $val = lc $val if $ci;
                    #JDP: Wrapping is superfluous if single fuzzy key,
                    #     as is explicit match anything at beginning and ending of key
                    #     post-wrap is handled in join to reduce testing of $_
                    my $prewrap  = $_==0 ? '' : '.*?';
                    $fuzzy >1 ? $prewrap . quotemeta($val) : quotemeta($val);
                } 0..$#{ $r->{fuzzy} };
            } else {
                $key2 = 'STATIC';
            }

            #say "D:looking up '$key1'\t'$key2' ...";
            my(@row_idx, $K1LUT);
            #JDP: explore MCE for performance boost?
            if( defined($K1LUT = $lookup_table{$key1}) ){
                #warn "Matched $key1\n";
                unless( $fuzzy ){
                    @row_idx = ($K1LUT->{STATIC}) }
                else{
                    $key2 = qr/$key2/;
                    foreach my $TK2 ( keys %{$K1LUT} ){
                        push(@row_idx, $K1LUT->{$TK2}) if $TK2 =~ /$key2/;
                        #warn "$key1: Testing $TK2 =~ /$key2/ (@{[ $TK2 =~ /$key2/ ]})\t$K1LUT->{$TK2}\n" if $key1 == 734;

                        #JDP: Short-circuit unless inner join requested
                        last if scalar @row_idx && !$inner;
                    }
                }

                #say "  D:found";
                for(my $j=0; $j<=$#row_idx; $j++ ){
                    my $row = $row;
                    my $fields_filled;
                    my $row_idx = $row_idx[$j];
                    my $source_row = $r->{source_data_rows}[$row_idx];

                    $row = Storable::dclone($r->{target_data_rows}->[$i]) if $fuzzy && $j && $inner;

                    for my $field (keys %{$r->{fill_fields}}) {
                        my $target_field_idx = $r->{target_fields_idx}{$field};
                        #JDP: Why is this being checked every time? $r->{target_fields_idx} does not change.
                        #     There isn't even a clear way for its values to be undef
                        #next unless defined $target_field_idx;

                        my $source_field_idx = $r->{source_fields_idx}{ $r->{fill_fields}{$field} };
                        #JDP: Why is this being checked every time? $r->{source_fields_idx} does not change
                        #     There isn't even a clear way for its values to be undef
                        #next unless defined $source_field_idx;

                        $row->[$target_field_idx] = $source_row->[$source_field_idx];
                        $fields_filled++;
                    }

                    push @inner, $row if $fuzzy && $j && $inner;
                    $rows_filled++ if $fields_filled;
                }
            }

            #XXX: would be VERY nice to print as we go rather than spool everything, esp. for large files
            unless ($r->{util_args}{count}) {
                $r->{code_print_row}->($row);
            }
        } # for target data row


        #JDP: Inner fill, append multi-matched fuzzy source rows
        if( $inner ){
            foreach my $row ( @inner ){
                $r->{code_print_row}->($row);
            }
        }

        if ($r->{util_args}{count}) {
            $r->{result} = [200, "OK", $rows_filled];
        }
    }
);

1;
# ABSTRACT:
