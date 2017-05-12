package Data::Presenter;
#$Id: Presenter.pm 1218 2008-02-10 00:11:59Z jimk $
$VERSION = 1.03;    # 02-10-2008
use strict;
use warnings;
use List::Compare::Functional qw( is_LsubsetR );
use Carp;
use Data::Dumper;

############################## Package Variables ##############################

our %fp = ();
our %fieldlabels = ();
our %reserved = map {$_ => 1} qw( fields parameters index options );

our %gt_lt_ops = map {$_ => 1} (
    q{<}, q{lt}, q{>}, q{gt}, q{<=}, q{le}, q{>=}, q{ge},
);

my %eq = map {$_, 'eq'} (
    q{eq}, q{equals}, q{is}, q{is equal to}, q{is a member of}, q{is part of}, q{=}, q{==},
);
my %ne = map {$_, 'ne'} (
    q{ne}, q{is not}, q{is not equal to}, q{is not a member of}, q{is not part of}, q{is less than or greater than}, q{is less than or more than}, q{is greater than or less than}, q{is more than or less than}, q{does not equal}, q{not}, q{not equal to}, q{not equals}, q{!=}, q{! =}, q{!==}, q{! ==}, q{<>},
);
my %lt = map {$_, 'lt'} (
    q{<}, q{lt}, q{is less than}, q{is fewer than}, q{before},
);
my %gt = map {$_, 'gt'} (
    q{>}, q{gt}, q{is more than}, q{is greater than}, q{after},
);
my %le = map {$_, 'le'} (
    q{<=}, q{le}, q{is less than or equal to}, q{is fewer than or equal to}, q{on or before}, q{before or on},
);
my %ge = map {$_, 'ge'} (
    q{>=}, q{ge}, q{is more than or equal to}, q{is greater than or equal to}, q{on or after}, q{after or on},
);

our %all_relations;
foreach my $rel ( \%eq, \%ne, \%lt, \%gt, \%le, \%ge) {
    foreach my $key (keys %{$rel}) {
        $all_relations{$key} = $rel->{$key};
    }
}

our %sortclass = (
    eq => { a => q{eq}, s => q{eq}, n => q{==} },
    ne => { a => q{ne}, s => q{ne}, n => q{!=} },
    lt => { a => q{lt}, s => q{lt}, n => q{<}  },
    gt => { a => q{gt}, s => q{gt}, n => q{>}  },
    le => { a => q{le}, s => q{le}, n => q{<=} },
    ge => { a => q{ge}, s => q{ge}, n => q{>=} },
);

################################# Constructor #################################

sub new {
    my ($inputs, $class, $source, $fieldsref, $paramsref,
        $index, $self, $dataref, $datapoints, @defective_records);
    $inputs = scalar(@_);

    if ($inputs == 5) {
        # regular Data::Presenter object immediately validates data
        ($class, $source, $fieldsref, $paramsref, $index) = @_;
        _validate_fields($fieldsref);
        _validate_parameters($fieldsref, $paramsref);
        _validate_index($fieldsref, $index);
    } elsif ($inputs == 2) {
        # Data::Presenter::Combo object:  data already validated
        ($class, $source) = @_;
    } else {
        my ($package) = caller;
        croak 'Wrong number of inputs to ', $package, '::new', "$!";

    }

    # bless a ref to an empty hash into the invoking class
    # which is somewhere below this one in the hierarchy
    $self = bless( {}, $class );

    # prepare the database by using &_init from package somewhere below
    # this one
    if ($inputs == 5) {
        $dataref = $self->_init($source, $fieldsref, $paramsref,
            $index, \%reserved);
    } else {
        $dataref = $self->_init($source);
    }

    # carp if, other than reserved words, the object has 0 records
    # croak if, other than reserved words, the object has records with
    # undefined elements
    foreach my $rec (keys %$dataref) {
        unless ($reserved{$rec}) {
            $datapoints++;
            my $undefcount = 0;
            foreach my $el ( @{ $dataref->{$rec} } ) {
                $undefcount++ if not defined $el;
            }
            push @defective_records, $rec if $undefcount;
        }
    }
    carp "Object initialized, $class, contains 0 data elements: $!"
        unless ($datapoints);
    croak "Records @defective_records have undefined elements;\n    consider revising initialization subroutine: $!"
        if @defective_records;

    # prepare 2 hashes which will be needed in selecting rows and
    # sorting columns
    _make_labels_params(
        \@{${$dataref}{'fields'}}, \@{${$dataref}{'parameters'}});

    # initialize the object from the prepared values (Damian, p. 98)
    %$self = %$dataref;
    return $self;
}

################################################################################
##### Subroutines called from with &new (constructor)
################################################################################

sub _validate_fields {
    my $fieldsref = shift;
    my %seen = ();
    foreach my $field (@$fieldsref) {
        # Note:  Assuming that _init() has been written correctly in the
        # Data::Presenter::subclass in which the object is created, the
        # 'croak' branch below will never be reached.
        $seen{$field} ? croak "$field is a duplicated field in \@fields:  $!"
                      : $seen{$field}++;
    }   # Confirmed:  there exist no duplicated fields in @fields.
}

sub _validate_parameters {
    my ($fieldsref, $paramsref) = @_;
    my @fields = @$fieldsref;
    my %parameters = %$paramsref;
    my ($i, $badvalues);
    for ($i = 0; $i < scalar(@fields); $i++) {
        my @temp = @{$parameters{$fields[$i]}};
        $badvalues .= '    ' . $fields[$i] . "\n"
            if ($temp[0] !~ /^\d+$/    # 1st element must be numeric
                ||
                $temp[1] !~ /^[UD]$/i  # 2nd element must be U or D (lc or uc)
                ||
                $temp[2] !~ /^[ans]$/i    # 3rd element must be a, n or s
            );
    }
    croak "Need corrected values for these keys:\n$badvalues:$!" if ($badvalues);
}

sub _validate_index {
    my ($fieldsref, $index) = @_;
    my @fields = @$fieldsref;
    croak "\$index must be a numeral:  $!"
        unless ($index =~ /^\d+$/);
    croak "\$index must be < number of elements in \@fields:  $!"
        unless $index <= $#fields;
}

sub _make_labels_params {
     my ($fieldsref, $paramsref) = @_;
     my @fields = @$fieldsref;
     my @aryparams = @$paramsref;
     %fp = ();
     my %temp = ();
     for (my $i = 0; $i < scalar(@fields); $i++) {
         $fp{$fields[$i]} = [@{$aryparams[$i]}];
         $temp{$fields[$i]} = $i;
     }
     %fieldlabels = %temp;
}

################################################################################
##### Subroutines to get information on the Data::Presenter object
################################################################################

sub get_data_count {
    my $self = shift;
    _count_engine($self);
}

sub print_data_count {
    my $self = shift;
    print 'Current data count:  ', _count_engine($self), "\n";
}

sub _count_engine {
    my $self = shift;
    my %data = %$self;
    my ($count);
    foreach (keys %data) {
        $count++ unless ($reserved{$_});
    }
    $count ? $count : 0;
}

sub get_keys {
    my $self = shift;
    my %data = %$self;
    my @keys = ();
    foreach (keys %data) {
        push(@keys, $_) unless ($reserved{$_});
    }
    return [ sort @keys ];
}

sub get_keys_seen {
    my $self = shift;
    my %data = %$self;
    my (%seen);
    foreach (keys %data) {
        $seen{$_}++ unless ($reserved{$_});
    }
    return \%seen;
}

################################################################################
##### &sort_by_column:  called from package main to select particular fields
#####                   to be displayed in output
##### Subroutines called from within &sort_by_column
################################################################################

sub sort_by_column {
    my $self = shift;
    my $columns_selected_ref = shift;
    my %data = %{$self};
    _validate_args($columns_selected_ref, \%fp);
    $columns_selected_ref =
        _verify_presence_of_index(\%data, $columns_selected_ref);
    my @records;
    foreach my $k (keys %data) {
        push (@records, $data{$k}) unless ($reserved{$k});
    }
    my $sortref = _sort_maker(
        map { _make_single_comparator( $_ ) }
            @{$columns_selected_ref}
    );

    return _extract_columns_selected(
        [ sort $sortref @records ],
        $columns_selected_ref,
    );
}

sub _verify_presence_of_index {
    my $dataref = shift;
    my $columns_selected_ref = shift;
    my @fields = @{$dataref->{fields}};
    my $index  = ${$dataref}{index};
    my @columns_selected = @{$columns_selected_ref};
    my %cols = map {$_, 1} @columns_selected;
    unless ($cols{$fields[$index]}) {   # line 205
        carp "Field '$fields[$index]' which serves as unique index for records must be one of the columns selected for output; adding it to end of list of columns selected: $!";
        push @columns_selected, $fields[$index];
    }
    return [ @columns_selected ];
}

sub _sort_maker {
    my @littlesubs = @_;
    sub {
        foreach my $sub (@littlesubs) {
            my $result = $sub->();
            return $result if $result;
        }
    };
}

sub _make_single_comparator {
    my $field      = shift;
    my $sort_order = $fp{$field}->[1];
    my $sort_type  = $fp{$field}->[2];
    my $idx        = $fieldlabels{$field};

    no warnings qw(uninitialized numeric);
    my %subs = (
        U => {
            a => sub { lc($a->[$idx]) cmp lc($b->[$idx]) },
            n => sub {    $a->[$idx]  <=>    $b->[$idx]  },
            s => sub {    $a->[$idx]  cmp    $b->[$idx]  },
        },
        D => {
            a => sub { lc($b->[$idx]) cmp lc($a->[$idx]) },
            n => sub {    $b->[$idx]  <=>    $a->[$idx]  },
            s => sub {    $b->[$idx]  cmp    $a->[$idx]  },
        },
    );
    $subs{$sort_order}{$sort_type};
}

sub _extract_columns_selected {
    my ($intermed_ref, $columns_selected_ref) = @_;
    my @results;
    foreach my $record (@{$intermed_ref}) {
        my @temp;
        foreach my $col (@{$columns_selected_ref}) {
            push @temp, $record->[$fieldlabels{$col}];
        }
        push @results, [ @temp ];
    }
    return [ @results ];
}

sub seen_one_column {
    my $self = shift;
    my %data = %$self;
    croak "Invalid number of arguments to seen_one_column():  $!"
        unless @_ == 1;
    my $columnref = [ shift ];
    _validate_args($columnref, \%fp);
    my (%seen);
    foreach (keys %data) {
        unless ($reserved{$_}) {
            $seen{ $data{$_}[ $fieldlabels{ ${$columnref}[0] } ] }++;
        }
    }
    return \%seen;
}

sub _validate_args {
    my ($columns_selected_ref, $fpref) = @_;
    my @columns_selected = @{$columns_selected_ref};
    my (%seen, %unseen, @unseen);
    foreach my $col (@columns_selected) {
        foreach my $field (keys %$fpref) {
            if ($col eq $field) {
                $seen{$col} = 1;
                last;
            }
        }
       $unseen{$col}++ unless $seen{$col};
    }
    @unseen = sort { lc($a) cmp lc($b) } (keys %unseen);
    croak "Invalid column selection(s):  @{unseen}:  $!"
        if (@unseen);
}

################################################################################
##### &select_rows:  called from package main to select a particular range of
#####                entries from data source
##### Subroutines called within &select_rows
################################################################################

sub select_rows {
    my ($self, $column, $relation, $choicesref) = @_;
    my $dataref = q{};
    $dataref = $self->_extract_rows(
        $column, $relation, $choicesref, \%fp, \%fieldlabels,
            \&_analyze_relation, \&_strip_non_matches);
    %$self = %$dataref;
    return $self;
}

sub _analyze_relation {    # Analysis of $relation:  passed by ref to subclass
    my ($relation_raw, $sorttype) = @_;
    my ($type, $relation_confirmed);
    croak "Relation \'$relation_raw\' has not yet been added to\nData::Presenter's internal specifications. $!"
        unless $all_relations{$relation_raw};
    $type = $sortclass{$all_relations{$relation_raw}}{$sorttype};
    croak "Problem with sort type $type: $!"
        unless $type;
    $relation_confirmed = $type;
    return ($relation_confirmed, \%gt_lt_ops);
}

sub _action {
    my ($relation, $seenref, $item, $dataref, $record, $correctedref) = @_;
    my %delete_instructions = (  # dispatch table
        'eq'  => sub { delete ${$dataref}{$record}
                    unless exists ${$seenref}{$item} },
        '=='  => sub { delete ${$dataref}{$record}
                    unless exists ${$seenref}{$item} },
        'ne'  => sub { delete ${$dataref}{$record}
                    unless ! exists ${$seenref}{$item} },
        '!='  => sub { delete ${$dataref}{$record}
                    unless ! exists ${$seenref}{$item} },
        'lt'  => sub { delete ${$dataref}{$record}
                    unless $item lt ${$correctedref}[0] },
        '<'   => sub { delete ${$dataref}{$record}
                    unless $item <  ${$correctedref}[0] },
        'gt'  => sub { delete ${$dataref}{$record}
                    unless $item gt ${$correctedref}[0] },
        '>'   => sub { delete ${$dataref}{$record}
                    unless $item >  ${$correctedref}[0] },
        'le'  => sub { delete ${$dataref}{$record}
                    unless $item le ${$correctedref}[0] },
        '<='  => sub { delete ${$dataref}{$record}
                    unless $item <= ${$correctedref}[0] },
        'ge'  => sub { delete ${$dataref}{$record}
                    unless $item ge ${$correctedref}[0] },
        '>='  => sub { delete ${$dataref}{$record}
                    unless $item >= ${$correctedref}[0] },
    );
    &{$delete_instructions{$relation}};
}
sub _strip_non_matches {
    my ($dataref, $flref, $column, $relation, $correctedref, $seenref) = @_;
    foreach my $record (keys %{$dataref}) {
        unless ($reserved{$record}) {
            my $item = ${$dataref}{$record}[${$flref}{$column}];
            _action( $relation, $seenref, $item, $dataref,
                $record, $correctedref);
        }
    }
    return $dataref;
}

################################################################################
##### Methods for simple output
##### and subroutines called within those methods
################################################################################

sub print_to_screen {
    my $class = shift;
    my %data = %$class;
    _print_engine(\%data, \%reserved);
    return 1;
}

sub print_to_file {
    my ($class, $outputfile) = @_;
    my %data = %$class;
    my $OUT;
    my $oldfh = select $OUT;
    open($OUT, ">$outputfile")
        || croak "Cannot open $outputfile for writing:  $!";
    _print_engine(\%data, \%reserved);
    close($OUT) || croak "Cannot close $outputfile:  $!";
    select($oldfh);
    return 1;
}

sub _print_engine {
    my ($dataref, $reservedref) = @_;
    my %data = %$dataref;
    my %reserved = %$reservedref;
    local $_;
    foreach my $i (sort keys %data) {
        unless ($reserved{$i}) {
            print "$_;" foreach (@{$data{$i}});
            print "\n";
        }
    }
}

sub print_with_delimiter {
    my ($class, $outputfile, $delimiter) = @_;
    my %data = %$class;
    open (my $OUT, ">$outputfile")
        || croak "Cannot open $outputfile for writing:  $!";
    foreach my $i (sort keys %data) {
        unless ($reserved{$i}) {
            my @fields = @{$data{$i}};
            for (my $j=0; $j < scalar(@fields); $j++) {
                if ($j < scalar(@fields) - 1) {
                    if ($fields[$j]) {
                        print $OUT $fields[$j], $delimiter;
                    } else {
                        print $OUT $delimiter;
                    }
                } else {
                    print $OUT $fields[$j] if ($fields[$j]);
                }
            }
            print $OUT "\n";
        }
    }
    close ($OUT) || croak "Cannot close $outputfile:  $!";
    return 1;
}

sub full_report {
    my ($class, $outputfile);
    my %data = ();
    my @fields = ();
    ($class, $outputfile) = @_;
    %data = %$class;
    @fields = @{$data{'fields'}};
    open (my $OUT, ">$outputfile")
        || croak "Cannot open $outputfile for writing:  $!";
    foreach my $i (sort keys %data) {
        unless ($reserved{$i}) {
            print $OUT "$i\n";
            for (my $j=0; $j <= $#fields; $j++) {
                print $OUT "    $fields[$j]", ' ' x (24 - length($fields[$j]));
                print $OUT "$data{$i}[$j]\n";
            }
            print $OUT "\n";
        }
    }
    close ($OUT) || croak "Cannot close $outputfile:  $!";
    return 1;
}

################################################################################
##### Methods which output data like Perl formats
##### and subroutines called from within those methods
################################################################################

our %keys_needed_to_write = (
    'Data::Presenter::writeformat'
        => [ qw| sorted columns file | ],
    'Data::Presenter::writeformat_plus_header'
        => [ qw| sorted columns file title | ],
    'Data::Presenter::writeformat_with_reprocessing'
        => [ qw| sorted columns file       reprocess | ],
    'Data::Presenter::writeformat_deluxe'
        => [ qw| sorted columns file title reprocess | ],
    'Data::Presenter::writedelimited'
        => [ qw| sorted         file                 delimiter | ],
    'Data::Presenter::writedelimited_plus_header'
        => [ qw| sorted columns file                 delimiter | ],
    'Data::Presenter::writedelimited_with_reprocessing'
        => [ qw| sorted columns file       reprocess delimiter | ],
    'Data::Presenter::writedelimited_deluxe'
        => [ qw| sorted columns file       reprocess delimiter | ],
    'Data::Presenter::writeHTML'
        => [ qw| sorted columns file title | ],
);

sub _validate_write_args {
    my $callingsub = (caller(1))[3];
    my @incoming = @_;
    croak "Method $callingsub needs even number of arguments: $!"
        if (@incoming % 2);
    my %args = @incoming;
    croak "Method $callingsub needs key-value pairs:\n    @{ $keys_needed_to_write{$callingsub} } \n       $!"
        unless (is_LsubsetR( [
             $keys_needed_to_write{$callingsub},
             [ keys %args ],
        ] ) );
    return %args;
}

sub writeformat {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my $picline = _format_picture_line($args{columns});
    open (my $REPORT, ">$args{file}") || croak "cannot create $args{file}: $!";
    foreach my $record (@{$args{sorted}}) {
        local $^A = q{};
        formline($picline, @{$record});
        print $REPORT $^A, "\n";
    }
    close ($REPORT) || croak "can't close $args{file}:$!";
    return 1;
}

sub writeformat_plus_header {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my $title_out = _format_title($args{title});
    my $argument_line_top_ref =
        _format_argument_line_top($args{columns});
    my $hyphen_line = _format_hyphen_line($args{columns});
    my $picline = _format_picture_line($args{columns});
    open (my $REPORT, ">$args{file}") || croak "cannot create $args{file}: $!";
    print $REPORT $title_out, "\n\n";
    print $REPORT "$_\n" foreach (@{$argument_line_top_ref});
    print $REPORT $hyphen_line, "\n";
    foreach my $record (@{$args{sorted}}) {
        local $^A = q{};
        formline($picline, @{$record});
        print $REPORT $^A, "\n";
    }
    close ($REPORT) || croak "can't close $args{file}:$!";
    return 1;
}

sub writeformat_with_reprocessing {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my %data = %$self;

    my ($substr_data_ref, $picline) = _prepare_to_reprocess(
        $args{reprocess}, \%fp, \%data, $args{columns});

    open (my $REPORT, ">$args{file}") || croak "cannot create $args{file}: $!";
    foreach my $record (@{$args{sorted}}) {
        local $^A = q{};
        formline($picline, @{$record});
        my $line = $self->_reprocessor(
            $^A,                # the formed line
            $substr_data_ref,   # the points at which I have to splice out
                                # text from the formed line and amount thereof
        );
        print $REPORT $line, "\n";
    }
    close ($REPORT) || croak "can't close $args{file}:$!";
    return 1;
}

sub writeformat_deluxe {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my %data = %$self;

    my ($substr_data_ref, $picline) = _prepare_to_reprocess(
        $args{reprocess}, \%fp, \%data, $args{columns});

    my (@header, @accumulator);
    my $title_out = _format_title($args{title});
    my $argument_line_top_ref =
        _format_argument_line_top($args{columns}, $args{reprocess});
    my $hyphen_line = _format_hyphen_line($args{columns}, $args{reprocess});
    @header = ($title_out, q{}, @{$argument_line_top_ref}, $hyphen_line);

    foreach my $record (@{$args{sorted}}) {
        local $^A = q{};
        formline($picline, @{$record});
        my $line = $self->_reprocessor(
            $^A,                # the formed line
            $substr_data_ref,   # the points at which I have to splice out
                                # text from the formed line and amount thereof
        );
        push @accumulator, $line;
    }
    open (my $REPORT, ">$args{file}") || croak "cannot create $args{file}: $!";
    print $REPORT $_, "\n" foreach (@header, @accumulator);
    close ($REPORT) || croak "can't close $args{file}:$!";
    return 1;
}

sub _prepare_to_reprocess {
    my ($reprocessref, $fpref, $dataref, $columns_selected_ref) = @_;
    my %reprocessing_info = %{$reprocessref};
    my %fp = %{$fpref};
    my %data = %{$dataref};
    my @columns_selected = @{$columns_selected_ref};

    # We must validate the info passed in thru $reprocessref.
    # This is a multi-stage process.
    # 1:  Verify that the fields requested for reprocessing exist as
    #     fields in the configuration file.
    my @fields_for_reprocessing = sort keys %reprocessing_info;
    _validate_args(\@fields_for_reprocessing, \%fp);


    # 2:  Verify that there exists a subroutine named &reprocess_[field]
    #     whose name has been stored as a key in defined in
    #     %{$data{'options'}{'subs'}}.
    my @confirmed_subs =
        grep {s/^reprocess_(.*)/$1/} keys %{$data{'options'}{'subs'}};
    croak "You are trying to reprocess fields for which no reprocessing subroutines yet exist: $!"
        unless (is_LsubsetR( [
             \@fields_for_reprocessing,
             \@confirmed_subs
        ] ) );

    # 3:  Verify that we can tap into the data sources referenced in
    #     %{$data{'options'}{'sources'}} for each field needing reprocessing
    my @available_sources = sort keys %{$data{'options'}{'sources'}};
    croak "You are trying to reprocess fields for which no original data sources are available: $!"
        unless (is_LsubsetR( [
             \@fields_for_reprocessing,
             \@available_sources
        ] ) );

    # 4:  Verify that the file mentioned in the values-arrays of
    #     %reprocessing_info exists, and that appropriate digits are entered
    #     for the fixed-length of the replacement string.
    foreach (sort keys %reprocessing_info) {
        croak "Fixed length of replacement string is misspecified;\n  Must be all digits:  $!"
            unless $reprocessing_info{$_} =~ /^\d+$/;
    }

    my %args_indices = ();
    for (my $h=0; $h<=$#columns_selected; $h++) {
        $args_indices{$columns_selected[$h]} = $h;
    }

    my %substr_data = ();
    foreach (sort keys %reprocessing_info) {
        # 1st:  Determine the position in the formed string where the
        #       old field began, as well as its length
        # Given that I used a single whitespace to separate fields in
        # the formed line, the starting position is the sum of the number of
        # fields preceding the target field in the formed line
        # PLUS the combined length of those fields
        my ($comb_length, $start);

        if ($args_indices{$_} == 0) {
            $start = $args_indices{$_};
        } else {
            for (my $j=0; $j<$args_indices{$_}; $j++) {
                $comb_length += $fp{$columns_selected[$j]}[0];
            }
            $start = $args_indices{$_} + $comb_length;
        }
        $substr_data{$start} = [
            $_,
            $fp{$_}[0],
            $reprocessing_info{$_},
            \%{ $data{'options'}{'sources'}{$_} },
            $dataref,    # new in v0.51
        ];
    }
    my $picline = _format_picture_line(\@columns_selected);
    return (\%substr_data, $picline);
}

################################################################################
##### Methods which output data with delimiters between fields
##### and subroutines called within those methods
################################################################################

sub writedelimited {
    my $self = shift;
    my %args = _validate_write_args(@_);
    open (my $REPORT, ">$args{file}") || croak "cannot create $args{file}: $!";
    foreach my $record (@{$args{sorted}}) {
        print $REPORT join($args{delimiter}, @{$record}), "\n";
    }
    close ($REPORT) || croak "can't close $args{file}:$!";
    return 1;
}

sub writedelimited_plus_header {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my $header =
        _format_argument_line_top_delimited($args{columns}, $args{delimiter});
    open (my $REPORT, ">$args{file}") || croak "cannot create $args{file}: $!";
    print $REPORT "$header\n";
    foreach my $record (@{$args{sorted}}) {
        print $REPORT join($args{delimiter}, @{$record}), "\n";
    }
    close ($REPORT) || croak "can't close $args{file}:$!";
    return 1;
}

sub writedelimited_with_reprocessing {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my $dataref = \%{$self};

    _prepare_to_reprocess_delimit(
        $args{reprocess}, \%fp, $dataref, $args{columns});

    my %cols_select_labels = ();
    for (my $i = 0; $i <= $#{$args{columns}}; $i++) {
        $cols_select_labels{${$args{columns}}[$i]} = $i;
    }
    my @revised;
    foreach my $record (@{$args{sorted}}) {
        push @revised, $self->_reprocessor_delimit(
            $record, $args{reprocess}, \%cols_select_labels, $dataref);
    }
    open my $OUT, ">$args{file}"
        or croak "Couldn't open $args{file} for writing: $!";
    foreach my $rev (@revised) {
        print $OUT (join $args{delimiter}, @{$rev}), "\n";
    }
    close $OUT or croak "Couldn't close $args{file} after writing: $!";
    return 1;
}

sub writedelimited_deluxe {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my $dataref = \%{$self};

    _prepare_to_reprocess_delimit(
        $args{reprocess}, \%fp, $dataref, $args{columns});

    my %cols_select_labels = ();
    for (my $i = 0; $i <= $#{$args{columns}}; $i++) {
        $cols_select_labels{${$args{columns}}[$i]} = $i;
    }
    my @revised;
    foreach my $record (@{$args{sorted}}) {
        push @revised, $self->_reprocessor_delimit(
            $record, $args{reprocess}, \%cols_select_labels, $dataref);
    }
    my $header = _format_argument_line_top_delimited(
        $args{columns}, $args{delimiter}
    );
    open my $OUT, ">$args{file}"
        or croak "Couldn't open $args{file} for writing: $!";
    print $OUT "$header\n";
    foreach my $rev (@revised) {
        print $OUT (join $args{delimiter}, @{$rev}), "\n";
    }
    close $OUT or croak "Couldn't close $args{file} after writing: $!";
    return 1;
}

sub _prepare_to_reprocess_delimit {
    my ($reprocessref, $fpref, $dataref, $columns_selected_ref) = @_;
    my %fp = %{$fpref};
    my %data = %{$dataref};
    my @columns_selected = @{$columns_selected_ref};

    # We must validate the info passed in thru $reprocessref.
    # This is a multi-stage process.
    # 1:  Verify that the fields requested for reprocessing exist as
    #     fields in the configuration file.
    _validate_args($reprocessref, \%fp);

    # 2:  Verify that there exists a subroutine named
    #     &reprocess_delimit_[field]
    #     whose name has been stored as a key in defined in
    #     %{$data{'options'}{'subs'}}.
    my @confirmed_subs =
        grep {s/^reprocess_delimit_(.*)/$1/} keys %{$data{'options'}{'subs'}};
    croak "You are trying to reprocess fields for which no reprocessing subroutines yet exist: $!"
        unless (is_LsubsetR( [
             $reprocessref,
             \@confirmed_subs,
        ] ) );

    # 3:  Verify that we can tap into the data sources referenced in
    my @available_sources = sort keys %{$data{'options'}{'sources'}};
    croak "You are trying to reprocess fields for which no original data sources are available: $!"
        unless (is_LsubsetR( [
             $reprocessref,
             \@available_sources,
        ] ) );
}

sub _format_title {
    my $title_raw = shift;
    my $title = $title_raw;
    return $title;
}

sub _format_argument_line_top {
    my $columns_selected_ref = shift;
    my $reprocessref = shift if $_[0];
    my @args = @$columns_selected_ref;
    my @lines = ();
    my $j = q{};    # index of the arg requested for printout currently
                   # being processed
    for ($j = 0; $j < scalar(@args); $j++) {
        my $n = 0; # current line being assigned to, starting with 0
        my $label = $fp{$args[$j]}[3];    # easier to read
        my $max = defined ${$reprocessref}{$args[$j]}
                ? ${$reprocessref}{$args[$j]}
                : $fp{$args[$j]}[0];
        my $remain = $label;    # at the outset, the entire label
                                # remains to be allocated to the proper line
        my @overage = ();
        # first see if any words in $remain need to be truncated
        my @remainwords = split(/\s/, $remain);
        foreach my $word (@remainwords) {
            $word = substr($word, 0, $max) if (length($word) > $max);
        }
        $remain = join ' ', @remainwords;
        while ($remain) {
            if (length($remain) <= $max) {
                # entire remainder of label will be placed on current line
                $lines[$n][$j] = $remain . ' ' x ($max - length($remain));
                $remain = q{};
            } else {
                # entire remainder of label cannot fit on current line
                my $word = q{};
                my @labelwords = split(/\s/, $remain);
                until (length($remain) <= $max) {
                    $word = shift(@labelwords);
                    push (@overage, $word);
                    $remain = join ' ', @labelwords;
                }
                $lines[$n][$j] = $remain . ' ' x ($max - length($remain));
                $remain = join ' ', @overage ;
                @overage = ();
                $n++;
            }
        }
    }
    my (@column_heads);
    foreach my $p (reverse @lines) {
        for ($j = 0; $j < scalar(@args); $j++) {
            my $max = defined ${$reprocessref}{$args[$j]}
                    ? ${$reprocessref}{$args[$j]}
                    : $fp{$args[$j]}[0];
            if (! ${$p}[$j]) {
                ${$p}[$j] = ' ' x $max;
            }
        }
        my $part = join ' ', @$p;
        push @column_heads, $part;
    }
    return \@column_heads;
}

sub _format_argument_line_top_delimited {
    my ($columns_selected_ref, $delimiter) = @_;
    my @temp;
    foreach my $col (@{$columns_selected_ref}) {
        push @temp, $fp{$col}[3];
    }
    my $header = join($delimiter, @temp);
    return $header;
}

sub _format_hyphen_line {
    my $columns_selected_ref = shift;
    my $reprocessref = shift if $_[0];
    my $hyphen_line_length = 0;
    my $hyphen_line = q{};
    foreach my $h (@$columns_selected_ref) {
        $hyphen_line_length += defined ${$reprocessref}{$h}
                             ? (${$reprocessref}{$h} + 1)
                             : ($fp{$h}->[0] + 1);
    }
    $hyphen_line = '-' x ($hyphen_line_length - 1);
    return $hyphen_line;
}

sub _format_picture_line {
    my $columns_selected_ref = shift;
    my $line = q{};
    my $g = 0;      # counter
    foreach my $h (@$columns_selected_ref) {
        my $picture = q{};
        if ($fp{$h}[2] =~ /^n$/i) {
            $picture = '@' . '>' x ($fp{$h}[0] - 1);
        } else {
            $picture = '@' . '<' x ($fp{$h}[0] - 1);
        }
        if ($g < $#{$columns_selected_ref}) {
            $line .= $picture . q{ };
            $g++;
        } else {
            $line .= $picture;
        }
    }
    return $line;
}

################################################################################
##### Subroutines involved in writing HTML
################################################################################

sub writeHTML {
    my $self = shift;
    my %args = _validate_write_args(@_);
    my %max = ();    # keys will be indices of @{$args{columns}};
                    # values will be max space allocated from %parameters
    for (my $j = 0; $j < scalar(@{$args{columns}}); $j++) {
        $max{$j} = $fp{${$args{columns}}[$j]}[0];
    }
    croak "Name of output file must end in .html or .htm  $!"
        unless ($args{file} =~ /\.html?$/);
    open(my $HTML, ">$args{file}")
        || croak "cannot open $args{file} for writing: $!";
    print $HTML <<END_OF_HTML1;
<HTML>
    <HEAD>
    <TITLE>$args{title}</TITLE>
    </HEAD>
    <BODY BGCOLOR="FFFFFF">
        <TABLE border=0  cellpadding=0 cellspacing=0 width=100%>
            <TR>
                <TD valign=middle width="100%"
                bgcolor="#cc0066"> <font face="sans-serif" size="+1"
                color="#ff99cc">&nbsp;&nbsp;&nbsp;$args{title}</font>
                </TD>
            </TR>
        </TABLE>
END_OF_HTML1
        my $argument_line_top_ref =
            _format_argument_line_top($args{columns});
        my $hyphen_line = _format_hyphen_line($args{columns});
        print $HTML '            <PRE>', "\n";
        print $HTML $_, '<BK>', "\n" foreach (@{$argument_line_top_ref});
        print $HTML "$hyphen_line",  '<BK>', "\n";
        foreach my $row (@{$args{sorted}}) {
            my @values = @{$row};
            my @paddedvalues = ();
            for (my $j = 0; $j < scalar(@{$args{columns}}); $j++) {
                my $newvalue = q{};
                if ($fp{${$args{columns}}[$j]}[2] =~ /^n$/i) {
                    $newvalue =
                        (' ' x ($max{$j} - length($values[$j]))) .
                         $values[$j] . ' ';
                } else { #
                    $newvalue =
                        $values[$j] .
                        (' ' x ($max{$j} - length($values[$j]) + 1));
                }
                push(@paddedvalues, $newvalue);
            }
            chop $paddedvalues[(scalar(@{$args{columns}})) - 1];
            print $HTML @paddedvalues, '<BK>', "\n";
        }
        print $HTML '            </PRE>', "\n";
        print $HTML <<END_OF_HTML2;
    </BODY>
</HTML>
END_OF_HTML2
    close($HTML) || croak "cannot close $args{file}: $!";
    return 1;
}

1;

######################################################################
##### DOCUMENTATION #####
######################################################################

=head1 NAME

Data::Presenter - Reformat database reports

=head1 VERSION

This document refers to version 1.03 of Data::Presenter, which consists of
Data::Presenter.pm and various packages subclassed thereunder, most notably
Data::Presenter::Combo.pm and its subclasses
Data::Presenter::Combo::Intersect.pm and Data::Presenter::Combo::Union.pm.
This version was released February 10, 2008.

=head1 SYNOPSIS

    use Data::Presenter;
    use Data::Presenter::[Package1];  # example:  use Data::Presenter::Census

    our (@fields, %parameters, $index);
    $configfile = 'fields.XXX.data';
    do $configfile;

    $dp1 = Data::Presenter::[Package1]->new(
        $sourcefile, \@fields,\%parameters, $index
    );

    $data_count = $dp1->get_data_count();

    $dp1->print_data_count();

    $keysref = $dp1->get_keys();

    $seenref = $dp1->get_keys_seen();

    $dp1->print_to_screen();

    $dp1->print_to_file($outputfile);

    $dp1->print_with_delimiter($outputfile, $delimiter);

    $dp1->full_report($outputfile);

    $dp1->select_rows($column, $relation, \@choices);

    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $seen_hash_ref = $dp1->seen_one_column($column);

    $dp1->writeformat(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
    );

    $dp1->writeformat_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => $title,
    );

    %reprocessing_info = (
        lastname    => 17,
        firstname   => 15,
    );

    $dp1->writeformat_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        reprocess   => \%reprocessing_info,
    );

    $dp1->writeformat_deluxe(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => $title,
        reprocess   => \%reprocessing_info,
    );

    $dp1->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => $delimiter,
    );

    $dp1->writedelimited_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => $delimiter,
    );

    @reprocessing_info = qw( instructor timeslot room );

    $dp1->writedelimited_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => $delimiter,
        reprocess   => \@reprocessing_info,
    );

    $dp1->writedelimited_deluxe(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => $delimiter,
        reprocess   => \@reprocessing_info,
    );

    $dp1->writeHTML(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => 'somename.html',
        title       => $title,
    );

Data::Presenter::Combo objects:

    use Data::Presenter;
    use Data::Presenter::[Package1];  # example:  use Data::Presenter::Census
    use Data::Presenter::[Package2];  # example:  use Data::Presenter::Medinsure

    our (@fields, %parameters, $index);
    $configfile = 'fields.XXX.data';
    do $configfile;

    $dp1 = Data::Presenter::[Package1]->new(
        $sourcefile, \@fields,\%parameters, $index
    );

    # different source file and configuration file

    $configfile = 'fields.YYY.data';
    do $configfile;

    $dp2 = Data::Presenter::[Package2]->new(
        $sourcefile, \@fields,\%parameters, $index);

    @objects = ($dp1, $dp2);
    $dpC = Data::Presenter::Combo::Intersect->new(\@objects);
    $dpC = Data::Presenter::Combo::Union->new(\@objects);

=head2 Notice of Changes of Interface

If you have I<not> used Data::Presenter prior to version 1.0, skip this
section.

=head3 C<writeformat()>-Family of Methods Now Takes List of Key-Value Pairs

Since the last publicly available version of Data::Presenter (0.68), the
interface to nine of its public methods has been changed.  Previously, methods
in the C<writeformat()>-family of methods took a list of arguments which had
to be provided in a very specific order.  For example, C<writeformat_deluxe()>
took five arguments:

    $dp1->writeformat_deluxe(
        $sorted_data,
        \@columns_selected,
        $outputfile,
        $title,
        \%reprocessing_info
    );

As the number of elements in the list of arguments increases, it becomes more
difficult to remember the order in which they must be passed.  At a certain
point it becomes easier to pass the arguments in the form of key-value pairs.
As long as each pair is correctly specified, the order of the pairs no longer
matters.  C<writeformat_deluxe()>, for example, now has this interface:

    $dp1->writeformat_deluxe(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => $title,
        reprocess   => \%reprocessing_info,
    );

Please study the L<"SYNOPSIS"> above to see how to revise your calls to
methods with C<writeformat>, C<writedelimited> or C<writeHTML> in their names.

=head3 Change in Assignment of C<$index> in C<Data::Presenter::[Package1]::_init()>

Data::Presenter is used by writing and using a subclass in which a new object
is created.  Each such subclass must hold an C<_init()> method and each such
C<_init()> method must accomplish certain tasks.  One of these tasks is to
store the value of C<$index> (found in the configuration file) in the object
being created.  In versions 0.68 and earlier, the code which did this looked
like this:

    $data{'index'} = [$index];

In other words, C<$index> was not directly assigned to the hash holding the
Data::Presenter::[Package1] object's data.  Instead, a reference to a
one-element array holding C<$index> was passed.

This has now been simplified:

    $data{'index'} = $index;

In other words, simply assign C<$index>; no reference is needed.  See the
sample packages included under the F<t/> directory in this distribution for a
live presentation of this change.

=head1 PREREQUISITES

Data::Presenter requires Perl 5.6 or later.  The module and its test suite
require the following modules from CPAN:

=over 4

=item List::Compare

By the same author as Data::Presenter:
L<http://search.cpan.org/dist/List-Compare>.

=item IO::Capture

Used only in the test suite to capture output printed to screen by
Data::Presenter methods.  By Mark Reynolds and Jon Morgan.
L<http://search.cpan.org/dist/IO-Capture>.

=item IO::Capture::Extended

Used only in the test suite to capture output printed to screen by
Data::Presenter methods.  By the same author as Data::Presenter.  Has
IO::Capture (above) as prerequisite.
L<http://search.cpan.org/dist/IO-Capture-Extended>.

=item Tie::File

Used only in the test suite to validate text printed to files by
Data::Presenter methods.  By Mark-Jason Dominus.  Distributed with Perl since
5.7.3; otherwise, available from CPAN:  L<http://search.cpan.org/dist/Tie-File>.

=back

Each of the prerequisites is pure Perl and should install with the
F<cpan> shell by typing 'y' at the prompts as needed.

=head1 DESCRIPTION

Data::Presenter is an object-oriented module useful for the
reformatting of already formatted text files such as reports generated by
database programs.  If the data can be represented by a
row-column matrix, where for each data entry (row):

=over 4

=item *

there are one or more fields containing data values (columns); and

=item *

at least one of those fields can be used as an index to uniquely identify
each entry,

=back

then the data structure is suitable for manipulation by Data::Presenter.
In Perl terms, if the data can be represented by a I<hash of arrays>, it is
suitable for reformatting with Data::Presenter.

Data::Presenter can be used to output some fields (columns) from a database
while excluding others (see L<"sort_by_column()"> below).  It can also be used
to select certain entries (rows) from the database for output while excluding
other entries (see L<"select_rows()"> below).

In addition, if a user has two or more database reports, each of which has
the same field serving as an index for the data, then it is possible to
construct either a:

=over 4

=item *

L<Data::Presenter::Combo::Intersect|"Data::Presenter::Combo Objects"> object
which holds data for those entries found in common in all the source
databases (the I<intersection> of the entries in the source databases); or a

=item *

L<Data::Presenter::Combo::Union|"Data::Presenter::Combo Objects"> object
which holds data for those entries found in any of the source databases (the
I<union> of the entries in the source databases).

=back

Whichever flavor of Data::Presenter::Combo object the user creates, the
module guarantees that each field (column) found in any of the source
databases appears once and once only in the Combo object.

Data::Presenter is I<not> a database module I<per se>, nor is it an interface
to databases in the manner of DBI.  It cannot used to enter data into a
database, nor can it be used to modify or delete data.  Data::Presenter
operates on I<reports> generated from databases and is designed for the user
who:

=over 4

=item *

may not have direct access to a given database;

=item *

receives reports from that database generated by another user; but

=item *

needs to manipulate and re-output that data in simple, useful ways such as
text files, Perl formats and HTML tables.

=back

Data::Presenter is most appropriate in situations where the user either has
no access to (or chooses not to use) commercial desktop database programs such
as I<Microsoft Access>(r) or open source database programs such as I<MySQL>(r).
Data::Presenter's installation and preparation require moderate knowledge of
Perl, but the actual running of Data::Presenter scripts can be delegated to
someone with less knowledge of Perl.

=head1 DEFINITIONS AND EXAMPLES

=head2 Definitions

=head3 Administrator

The individual in a workplace responsible for the
installation of Data::Presenter on the system or network, analysis of
sources, preparation of Data::Presenter configuration files and preparation
of Data::Presenter subclass packages other than Data::Presenter::Combo and
its subclasses.  (I<Cf.> L<"Operator">.)

=head3 Entry

A row in the L<source|"Source"> containing the values of the
fields for one particular item.

=head3 Field

A column in the L<source|"Source"> containing a value for each
entry.

=head3 Index

The column in the L<source|"Source"> whose values uniquely
identify each entry in the source.  Also referred to as ''unique ID.''    (In
the current implementation of Data::Presenter, an index must be a strictly
numerical value.)

=head3 Index Field

The column in the L<source|"Source"> containing a unique
value (L<"index">) for each entry.

=head3 Metadata

Entries in the Data::Presenter object's data structure which
hold information prepared by the administrator about the data structure and
output parameters.

In the current version of Data::Presenter, metadata is extracted from the
variables C<@fields>, C<%parameters> and C<$index> found in the configuration
file F<fields.XXX.data>.  The metadata is first stored in package variables in
the invoking Data::Presenter subclass package and then entered into the
Data::Presenter object as hash entries keyed by C<'fields'>, C<'parameters'>
and C<$index>, respectively.  (The word 'options' has also been reserved for
future use as the key of a metadata entry in the object's data structure.)

=head3 Object's Current Data Structure

Non-L<metadata|"Metadata"> entries found
in the Data::Presenter object at the point a particular selection, sorting or
output method is called.

The object's current data structure may be thought of as the result of the
following calculations:

            construct a Data::Presenter::[Package1] object

    less:   entries excluded by application of selection criteria found
                in C<select_rows>

    less:   metadata entries in object keyed by 'fields', 'parameters' or
                'fields'

    result: object's current data structure

=head3 Operator

The individual in a workplace responsible for running a
Data::Presenter script, including:

=over 4

=item *

selection of sources;

=item *

selection of particular entries and fields from the source for presentation
in the output; and

=item *

selection of output formats and names of output files.  (I<Cf.>
L<"Administrator">.)

=back

=head3 Source

A report, typically saved in the form of a text file, generated
by a database program which presents data in a row-column format.  The source
may also contain other information such as page headers and footers and table
headers and footers.  Also referred to herein as ''source report,'' ''source
file'' or ''database source report.''

=head2 Examples

Sample files are included in the archive file in which this documentation is
found.  Three source files, F<census.txt>, F<medinsure.txt> and F<hair.txt>,
are included, as are the corresponding Data::Presenter subclass packages
(F<Census.pm>, F<Medinsure.pm> and F<Hair.pm>) and configuration files
(F<fields.census.data>, F<fields.medinsure.data> and F<fields.hair.data>).

=head1 USAGE:  Administrator

This section addresses those aspects of the usage of Data::Presenter which
must be implemented by the L<administrator|"Administrator">:

=over 4

=item *

L<installation|"Installation"> of Data::Presenter on the system;

=item *

analysis of L<sources|"Analysis of Source Files">;

=item *

preparation of Data::Presenter L<configuration|"Preparation of Configuration
File (fields.XXX.data)"> files; and

=item *

preparation of Data::Presenter L<subclass packages|"Preparation of
Data::Presenter Subclasses"> other than Data::Presenter::Combo and its
subclasses.

=back

If Data::Presenter has already been properly configured by your administrator
and you are simply concerned with using Data::Presenter to generate reports,
you may skip ahead to L<"USAGE: Operator">.

=head2 Installation

Data::Presenter installs in the same way as other Perl extensions available
from CPAN:  either automatically via the CPAN shell or manually with these
commands:

    % gunzip Data-Presenter-1.03.tar.gz
    % tar xf Data-Presenter-1.03.tar
    % cd Data-Presenter-1.03
    % perl Makefile.PL
    % make
    % make test
    % make install

This will install the following directory tree in your ''site perl''
directory, I<i.e.,> a directory such as
F</usr/local/lib/perl5/site_perl/5.8.7/>:

    Data/
        Presenter.pm
        Presenter/
            Combo.pm
            Combo/
                Intersect.pm
                Union.pm


Once the Administrator has installed Data::Presenter, she must then decide
which location on the network will be used to hold Data::Presenter::[Package1]
subclass packages, where [Package1] is a Data::Presenter subclass in which a
new object will be created.  That location could be the F<Data/Presenter/>
directory listed above or it could be some other location which users can
access in a Perl program via the C<use lib ()> pragma.

The Administrator must also decide on a location on the network which will be
used to hold the Data::Presenter configuration files -- one for each data
source to be used by Data::Presenter.  By convention, each configuration file
is named by some variation on the theme of F<fields.XXX.data>.

Suppose, for instance, that F</usr/share/datapresenter/> is the directory
created to hold Data::Presenter-related files accessible to all users.
Suppose, further, that in this business two database reports, I<census> and
I<medinsure>, will be processed via Data::Presenter.  The Administrator would
then create a directory tree like this:

    /usr/share/datapresenter/
        Data/
            Presenter/
                Census.pm
                Medinsure.pm
        config/
            fields.census.data
            fields.medinsure.data

The Administrator could also create a directory called F<source/> to hold the
source files to be processed with Data::Presenter, and she could also create a
directory called F<results/> to hold files created via Data::Presenter -- but
neither of these are strictly necessary.

=head2 Analysis of Source Files

Successful use of Data::Presenter assumes that the administrator is able to
analyze a report generated from a database, distinguish key structural
features of such a source report and write Perl code which will extract the
most relevant information from the report.  A complete discussion of these
issues is beyond the scope of this documentation.  What follows is a taste of
the issues involved.

Structural features of a database report are likely to include the following:
report headers, page headers, table headers, data entries reporting values
of a variety of fields, page footers and report footers.  Of these features,
data entries and table headers are most important from the perspective of
Data::Presenter.  The data entries are the data which will actually be
manipulated by Data::Presenter, while table headers will provide the
administrator guidance when writing the configuration file F<fields.XXX.data>.
Report and page headers and footers are generally irrelevant and will be
stripped out.

For example, let us suppose that a portion of a client census looks like
this:

    CLIENTS - AUGUST 1, 2001 - C O N F I D E N T I A L        PAGE  1
    SHRED WHEN NEW LIST IS RECEIVED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     LAST NAME     FIRST NAM  C. NO  BIRTH

     HERNANDEZ     HECTOR     456791 1963-07-16
     VASQUEZ       ADALBERTO  456792 1973-10-02
     WASHINGTON    ALBERT     906786 1953-03-31

The first two lines are probably report or page headers and should be
stripped out.  The third line consists of table column names and may give
clues as to how F<fields.census.data> should be written.  The fourth line is
blank and should be stripped out.  The next three lines constitute actual
rows of data; these will be the focus of Data::Presenter.

A moderately experienced Perl programmer will look at this report and say,
''Each row of data can be stored in a Perl array.  If each client's 'c. no'
is unique, then it can be used as the key of an entry in a Perl hash where
the entry's value is a reference to the array just mentioned.  A hash of
arrays -- I can use Data::Presenter!''

Our Perl programmer would then say, ''I'll open a filehandle to the source
file and read the file line-by-line into a C<while> loop.  I'll write lines
beginning C<next if> to bypass the headers and the blank lines.''  For
instance:

    next if (/^CLIENTS/);
    next if (/^SHRED/);
    next if (/^\s?LAST\sNAME/);
    next if (/^$/);

Our Perl hacker will then say, ''I could try to write regular expressions to
handle the rows of data.  But since the data appears to be strictly columnar,
I'll probably be better off using the Perl C<unpack> function.  I'll use the
column headers to suggest names for my variables.''  For instance:

    my ($lastname, $firstname, $cno, $datebirth) =
        unpack("x A14 x A10 x A6 x A10", $_);

Having provided a taste of what to do with the rows of the data structure, we
now turn to an analysis of the columns of the structure.

=head2 Preparation of Configuration File (F<fields.XXX.data>)

For each data source, the administrator must prepare a configuration file,
typically named as some variation on F<fields.XXX.data>.
F<fields.XXX.data> consists of three Perl variables:
C<@fields>, C<%parameters> and C<$index>.

=head3 C<@fields>

C<@fields> has one element for each column (field) that appears
in the data source.  The elements of C<@fields> I<must> appear in exactly the
same order as they appear in the data source.  Each element should be a
single Perl word, I<i.e.>, consist solely of letters, numerals or the
underscore character (C<_>).

In the sample configuration file F<fields.census.data> included with this
documentation, this variable reads:

    @fields = qw(
        lastname firstname cno unit ward dateadmission datebirth
    );

In another sample configuration file, F<fields.medinsure.data>, this variable
reads:

    @fields = qw(lastname firstname cno stateid medicare medicaid);

=head3 C<%parameters>

C<%parameters> is a bit trickier.  There must be one entry
in C<%parameters> for each element in C<@fields>.  Hence, there is one entry
in C<%parameters> for each column (field) in the data source.  However, the
keys of C<%parameters> are spelled C<$fields[0]>, C<$fields[1]>, and so on
through the highest index number in C<@fields> (which is 1 less than the
number of elements in C<@fields>).  Using the example above, we can begin to
construct C<%parameters> as follows:

    %parameters = (
        $fields[0] =>
        $fields[1] =>
        $fields[2] =>
        $fields[3] =>
        $fields[4] =>
        $fields[5] =>
        $fields[6] =>
    );

The value for each entry in C<%parameters> consists of an array of 4 elements
specified as follows:

=over 4

=item Element 0

A positive integer specifying the maximum number of characters which may be
displayed in any output format for the given column (field).  In the example
above, we will specify that column 'lastname' (C<$fields[0]>) may have a
maximum of 14 characters.

    $fields[0]        => [14,

=item Element 1

An upper-case letter 'U' or 'D' (for 'Up' or 'Down') enclosed in single
quotation marks indicating whether the given column should be sorted in
ascending or descending order.  In the example above, 'lastname' sorts in
ascending order.

    $fields[0]        => [14, 'U',

=item Element 2

A lower-case letter 'a', 'n' or 's' enclosed in single quotation marks
indicating whether the given column should be sorted alphabetically
(case-insensitive), numerically or ASCII-betically (case-sensitive).  In the
example above, 'lastname' sorts in alphabetical order.  (Data::Presenter
I<per se> does not yet have a facility for sorting in date or time order.  If
dates are entered as pure numerals in 'MMDD' order, they may be sorted
numerically.  If they are entered in the MySQL standard format '
YY-MM-DD', they may be sorted alphabetically.)

    $fields[0]        => [14, 'U', 'a',

=item Element 3

A string enclosed in single quotation marks to be used as a column header
when the data is outputted in some table-like format such as a Perl format
with a header or an HTML table.  The administrator may choose to use exactly
the same words here that were used in C<@fields>, but a more natural language
string is probably preferable.  In the example above, the first column will
carry the title 'Last Name' in any output.

    $fields[0]        => [14, 'U', 'a', 'Last Name'],

=back

Using the same example as previously, we can now complete C<%parameters> as:

    %parameters = (
        $fields[0]        => [14, 'U', 'a', 'Last Name'],
        $fields[1]        => [10, 'U', 'a', 'First Name'],
        $fields[2]        => [ 7, 'U', 'n', 'C No.'],
        $fields[3]        => [ 6, 'U', 'a', 'Unit'],
        $fields[4]        => [ 4, 'U', 'n', 'Ward'],
        $fields[5]        => [10, 'U', 'a', 'Date of Admission'],
        $fields[6]        => [10, 'U', 'a', 'Date of Birth'],
    );

=head3 C<$index>

C<$index> is the simplest element of I<fields.XXX.data>. It is the
array index for the entry in C<@fields> which describes the field in the data
source whose values uniquely identify each entry in the source.  If, in the
example above, C<'cno'> is the L<index field|"Index Field"> for the data in
I<census.txt>, then C<$index> is C<2>.  (Remember that Perl starts counting
array elements with C<0>.)

=head2 Preparation of Data::Presenter Subclasses

F<Data::Presenter.pm>, F<Data::Presenter::Combo.pm>,
F<Data::Presenter::Combo::Intersect.pm> and F<Data::Presenter::Combo::Union>
are ready to use ''as is.''  They require no further modification by the
administrator.  However, each report from which the operator draws data needs
to have a package subclassed beneath Data::Presenter and written specifically
for that report by the administrator.

Indeed, B<no object is ever constructed I<directly> from Data::Presenter.
All objects are constructed from subclasses of Data::Presenter.>

Hence:

    $dp1 = Data::Presenter->new(                    # INCORRECT
        $source, \@fields, \%parameters, $index);

    $dp1 = Data::Presenter::[Package1]->new(        # CORRECT
        $source, \@fields, \%parameters, $index);

Data::Presenter::[Package1], however, does not contain a C<new()> method.  It
inherits Data::Presenter's C<new()> method -- which then turns around and
delegates the task of populating the object with data to
Data::Presenter::[Package1]'s C<_init()> method!

This C<_init()> method must be customized by the administrator to properly
handle the specific features of each source file.  This requires that the
administrator be able to write a Perl script to 'clean up' the source file so
that only lines containing meaningful data are written to the Data::Presenter
object.  (See L<"Analysis of Source Files"> above.)  With that in mind, a
Data::Presenter::[Package1] package must always include the following
methods:

=over 4

=item * C<_init()>

This method is called from within the constructor and is used to populate the
hash which is blessed into the new object.  It opens a filehandle to the
source file and typically reads that source file line-by-line via a Perl
C<while> loop.  Perl techniques and functions such as regular expressions,
C<split> and C<unpack> are used to populate a hash of arrays and to strip out
lines in the data source not needed in the object.  Should the administrator
need to ''munge'' any of the incoming data so that it appears in a uniform
format (I<e.g.>, '2001-07-02' rather than '7/2/2001' or '07/02/2001'), the
administrator should write appropriate code within C<_init()> or in a separate
module imported into the main package.  Each element of each array used to
store a data record must have a defined value.  C<undef> is not permitted;
assign an empty string to the element instead.  A reference to this hash of
arrays is returned to the constructor, which blesses it into the object.

=item * C<_extract_rows>

This method is called from within the Data::Presenter C<select_rows> method.
In much the same manner as C<_init()>, it permits the administrator to
''munge'' operator-typed data to achieve a uniform format.

=back

The packages F<Data::Presenter::Census> and F<Data::Presenter::Medinsure>
found in the F<t/> directory in this distribution provide examples of
C<_init()> and C<_extract_rows>.  Search for the lines of code which read:

    # DATA MUNGING STARTS HERE
    # DATA MUNGING ENDS HERE

Here is a simple example of data munging.  In the sample configuration file
F<fields.census.data>, all elements of C<@fields> are entered entirely in
lower-case.  Hence, it would be advisable to transform the operator-specified
content of C<$column> to all lower-case so that the program does not fail
simply because an operator types an upper-case letter.  See C<_extract_rows()>
in the Data::Presenter::Census package included with this documentation for
an example.

Sample file F<Data::Presenter::Medinsure> contains an example of a subroutine
written to clean up repetitive coding within the data munging section.
Search for C<sub _prepare_record>.

=head1 USAGE:  Operator

Once the administrator has installed Data::Presenter and completed the
preparation of configuration files and Data::Presenter subclass packages, the
administrator may turn over to the operator the job of selecting particular
source files, output formats and particular entries and fields from within
the source files.

=head2 Construction of a Data::Presenter Object

=head3 Declarations

Using the hospital census example included with this documentation, the
operator would construct a Data::Presenter::Census object with the following
code:

    use Data::Presenter;
    use lib ("/usr/share/datapresenter");
    use Data::Presenter::Census;

    our @fields = ();
    our %parameters = ();
    our $index = q{};

    my $sourcefile = 'census.txt';
    my $configdir  = "/usr/share/datapresenter";
    my $configfile = "$configdir/fields.census.data";

    do $configfile;

=head3 C<new()>

    my $dp1 = Data::Presenter::Census->new(
        $sourcefile, \@fields, \%parameters, $index);

=head2 Methods to Report on the Data::Presenter Object Itself

=head3 C<get_data_count()>

Returns the current number of data entries in the
specified Data::Presenter object.  This number does I<not> include those
elements in the object whose keys are reserved words.  This method takes no
arguments and returns one numerical scalar.

    my $data_count = $dp1->get_data_count();
    print 'Data count is now:  ', $data_count, "\n";

=head3 C<print_data_count()>

Prints the current data count preceded by ''Current
data count:  ''.  This number does I<not> include those elements in the
object whose keys are reserved words.  This method takes no arguments and
returns no values.

    $dp1->print_data_count();

=head3 C<get_keys()>

Returns a reference to an array whose elements are an
ASCII-betically sorted list of keys to the hash blessed into the
Data::Presenter::[Package1] object.  This list does not include those
elements whose keys are reserved words.  This method takes no arguments and
returns only the array reference described.

    my $keysref = $dp1->get_keys();
    print "Current data points are:  @$keysref\n";

=head3 C<get_keys_seen()>

Returns a reference to a hash whose elements are
key-value pairs where the key is the key of an element blessed into the
Data::Presenter::[Package1] object and the value is 1, indicating that the
key has been seen (a 'seen-hash').  This list does not include those elements
whose keys are reserved words.  This method takes no arguments and returns
only the hash reference described.

    my $seenref = $dp1->get_keys_seen();
    print "Current data points are:  ";
    print "$_ " foreach (sort keys %{$seenref});
    print "\n";

=head3 C<seen_one_column()>

Takes as argument a single string which is the name of one of the fields
listed in C<@fields> in the configuration file.  Returns a reference to a hash
whose elements are keyed by the entries for that field in the data source and
whose values are the number of times each entry was seen in the data.

For example, if the data consisted of this:

    HERNANDEZ     HECTOR     1963-08-01 456791
    VASQUEZ       ADALBERTO  1973-08-17 786792
    VASQUEZ       ALBERTO    1953-02-28 906786

where the left-most column was described in C<@fields> as C<lastname>, then:

    $seenref = $dp1->seen_one_column('lastname');

and C<$seenref> would hold:

    {
        HERNANDEZ   => 1,
        VASQUEZ     => 2,
    }

=head2 Data::Presenter Selection, Sorting and Output Methods

=head3 C<select_rows()>

C<select_rows()> enables the operator to establish criteria
by which specific entries from the data can be selected for output.  It does
so I<not> by creating a new object but by striking out entries in the
L<object's current data structure|"Object's Current Data Structure"> which do
not meet the selection criteria.

If the operator were using Perl as an interface to a true database program,
selection of entries would most likely be handled by a module such as DBI and
an SQL-like query.  In that case, it would be possible to write complex
selection queries which operate on more than one field at a time such as:

    select rows where 'datebirth' is before 01/01/1960
    AND 'lastname' equals 'Vasquez'
    # (NOTE:  This is generic code,
    #  not true Perl or Perl DBI code.)

Complex selection queries are not yet possible in Data::Presenter.  However,
you could accomplish much the same objective with a series of simple
selection queries that operate on only one field at a time,

    select rows where 'datebirth" is before 01/01/1960

then

    select rows where 'lastname' equals 'Vasquez'

each of which narrows the selection criteria.

How do we accomplish this within Data::Presenter?  For each selection query,
the operator must define 3 variables:  C<$column>, C<$relation> and
C<@choices>.  These variables are passed to C<select_rows()>, which in turn
passes them to certain internal subroutines where their values are
manipulated as follows.

=over 4

=item * C<$column>

C<$column> must be an element of L<C<@fields>|"@fields"> found in the
L<configuration file|"Preparation of Configuration File (fields.XXX.data)">.

=item * C<$relation>

C<$relation> expresses the verb part of the selection query, I<i.e.,>
relations such as C<equals>, C<is less than>,  C<E>=>, C<after> and so
forth.  In an attempt to add natural language flexibility to the selection
query, Data::Presenter permits the operator to enter a wide variety of
mathematical and English expressions here:

=over 4

=item * equality

    'eq', 'equals', 'is', 'is equal to', 'is a member of',
    'is part of', '=', '=='

=item * non-equality

    'is', 'is not', 'is not equal to', 'is not a member of',
    'is not part of', 'is less than or greater than',
    'is less than or more than', 'is greater than or less than',
    'is more than or less than', 'does not equal', 'not',
    'not equal to ', 'not equals', '!=', '! =', '!==', '! =='

=item * less than

    '<', 'lt', 'is less than', 'is fewer than', 'before'

=item * greater than

    '>', 'gt', 'is more than', 'is greater than', 'after'

=item * less than or equal to

    '<=', 'le', 'is less than or equal to',
    'is fewer than or equal to', 'on or before', 'before or on'

=item * greater than or equal to

    '>=', 'ge', 'is more than or equal to', 'is greater than or equal to',
    'on or after', 'after or on'

=back

As long as the operator selects a string from the category desired,
Data::Presenter will convert it internally in an appropriate manner.

=item * C<@choices>

If the relationship being tested is one of equality or non-equality, then the
operator may enter more than one value here, any one of which may satisfy the
selection criterion.

    my ($column, $relation, @choices);

    $column = 'lastname';
    $relation = 'is';
    @choices = ('Smith', 'Jones');
    $dp1->select_rows($column, $relation, \@choices);

If, however, the relationship being tested is one of 'less than', 'greater
than', etc., then the operator should enter only one value, as the value is
establishing a limit above or below which the selection criterion will not be
met.

    $column = 'datebirth';
    $relation = 'before';
    @choices = ('01/01/1970');
    $dp1->select_rows($column, $relation, \@choices);

=back

=head3 C<sort_by_column()>

C<sort_by_column()> takes only 1 argument:  a reference
to an array consisting of the fields the operator wishes to present in the
final output, listed in the order in which those fields should be sorted.
All elements of this array must be elements in C<@fields>.  B<The index field
must always be included as one of the columns selected,> though it may be
placed last if it is not intrinsically important in the final output.
C<sort_by_column()> returns a reference to a hash of appropriately sorted data
which will be used as input to Data::Presenter methods such as
C<writeformat()>, C<writeformat_plus_header()> and C<writeHTML()>.

To illustrate:

    my @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

Suppose that the operator fails to include the index column in
C<@columns_selected>.  This risks having two or more identical data entries,
only the last of which would appear in the final output.  As a safety
precaution, C<sort_by_column()> throws a warning and places duplicate entries
in a text file called F<dupes.txt>.

Note:  If you want your output to report only selected entries from the
source, and if you want to apply one of the complex Data::Presenter output
methods which require application of C<sort_by_column()>, call C<select_rows>
I<before> calling C<sort_by_column()>.  Otherwise your report may contain
blank lines.

=head3 C<print_to_screen()>

C<print_to_screen()> prints to standard output (generally, the computer
monitor) a semicolon-delimited display of all entries in the object's
current data structure.  It takes no arguments and returns no values.

    $dp1->print_to_screen();

A typical line of output will look something like:

    VASQUEZ;JORGE;456787;LAVER;0105;1986-01-17;1956-01-13;

=head3 C<print_to_file()>

C<print_to_file()> prints to an operator-specified file a
semicolon-delimited display of all entries in the object's current data
structure.  It takes 1 argument -- the user-specified output file -- and
returns no values.

    $outputfile = 'census01.txt';
    $dp1->print_to_file($outputfile);

A typical line of output will look exactly like that produced by
L<C<print_to_screen>|"print_to_screen()">.

=head3 C<print_with_delimiter()>

C<print_with_delimiter()>, like C<print_to_file()>,
prints to an operator-specified file. C<print_with_delimiter()> allows the
operator to specify the character pattern which will be used to delimit
display of all entries in the object's current data structure.  It does not
print the delimiter after the final field in a particular data record.  It
takes 2 arguments -- the user-specified output file and the character pattern
to be used as delimiter -- and returns no values.

    $outputfile = 'delimited01.txt';
    $delimiter = '|||';
    $dp1->print_with_delimiter($outputfile, $delimiter);

The file created C<print_with_delimiter()> is designed to be used as an input
to functions such as 'Convert text to tabs' or 'Convert text to table' found
in commercial word processing programs.  Such functions require delimiter
characters in the input.  A typical line of output will look something like:

    VASQUEZ|||JORGE|||456787|||LAVER|||0105|||1986-01-17|||1956-01-13

=head3 C<full_report()>

C<full_report()> prints to an operator-specified file each
entry in the object's current data structure, sorted by the index and
explicitly naming each field name/field value pair.  It takes 1 argument --
the user-specified output file -- and returns no values.

    $outputfile = 'report01.txt';
    $dp1->full_report($outputfile);

The output for a given entry will look something like:

    456787
        lastname                VASQUEZ
        firstname               JORGE
        cno                     456787
        unit                    LAVER
        ward                    0105
        dateadmission           1986-01-17
        datebirth               1956-01-13

=head3 C<writeformat()>

C<writeformat()> writes data via Perl's C<formline> function
-- the function which internally powers Perl formats -- to an
operator-specified file.  C<writeformat()> takes a list of 3 key-value pairs:

    $dp1->writeformat(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
    );

=over 4

=item * C<sorted>

The value of C<sorted> is a hash reference which is the return value of
C<sort_by_column()>.  Hence, C<writeformat()> can only be called once
C<sort_by_column()> has been called.

=item * C<columns>

The value of C<columns> is a reference to the array of fields in the data
source selected for presentation in the output file.  It is the same variable
which is used as the argument to C<sort_by_column()>.

=item * C<file>

The value of C<file> is the name of a file arbitrarily selected by the
operator to hold the output of C<writeformat()>.

=back

Using the ''census'' example from above, the overall sequence of code needed
to use C<writeformat()> would be:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $dp1->writeformat(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
    );

The result of the above call would be a file named F<format01.txt> containing:

    HERNANDEZ     HECTOR     1963-08-01 456791
    VASQUEZ       ADALBERTO  1973-08-17 786792
    VASQUEZ       ALBERTO    1953-02-28 906786

The columnar appearance of the data is governed by choices made by the
administrator within the configuration file (here, within
F<fields.census.data>).  The choice of columns themselves is controlled by
the operator via C<\@columns_selected>.

=head3 C<writeformat_plus_header()>

C<writeformat_plus_header()> writes data via
Perl formats to an operator-specified file and writes a Perl format header to
that file as well.  C<writeformat_plus_header()> takes a list of 4 key-value
pairs.  Three of these pairs are the same as in C<writeformat()>; the fourth
is:

=over 4

=item * C<title>

        title       => $title,

C<title> holds text chosen by the operator.

=back

The complete call to C<writeformat_plus_header> looks like this:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $dp1->writeformat_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => $title,
    );

and will produce a header and formatted data like this:

    Hospital Census Report

                                          Date       Date of
    Unit   Ward Last Name      First Name of Birth   Admission  C No.
    ------------------------------------------------------------------
    LAVER  0105 VASQUEZ        JORGE      1956-01-13 1986-01-17 456787
    LAVER  0107 VASQUEZ        LEONARDO   1970-15-23 1990-08-23 456788
    SAMSON 0209 VASQUEZ        JOAQUIN    1970-03-25 1990-11-14 456789

The wording of the column headers is governed by choices made by the
administrator within the configuration file (here, within
F<fields.census.data>).  If a particular word in a column header is too long
to fit in the space allocated, it will be truncated.

=head3 C<writeformat_with_reprocessing()>

C<writeformat_with_reprocessing()> is an
advanced application of Data::Presenter and the reader may wish to skip this
section until other parts of the module have been mastered.

C<writeformat_with_reprocessing()> permits a sophisticated administrator to
activate ''last minute'' substitutions in the strings printed out from the
format accumulator variable C<$^A>.  Suppose, for example, that a school
administrator faced the problem of scheduling classes in different classrooms
and in various time slots.  Suppose further that, for ease of programming or
data entry, the time slots were identified by chronologically sequential
numbers and that instructors were identified by a unique ID built up from
their first and last names.  Applying an ordinary C<writeformat()> to such
data might show output like this

    11 Arithmetic                   Jones        4044 4044_11
    11 Language Studies             WilsonT      4054 4054_11
    12 Bible Study                  Eliade       4068 4068_12
    12 Introduction to Computers    Knuth        4086 4086_12
    13 Psychology                   Adler        4077 4077_13
    13 Social Science               JonesT       4044 4044_13
    51 World History                Wells        4052 4052_51
    51 Music Appreciation           WilsonW      4044 4044_51

where C<11> mapped to 'Monday, 9:00 am', C<12> to 'Monday, 10:00 am', C<51>
to 'Friday, 9:00 am' and so forth and where the fields underlying this output
were 'timeslot', 'classname', 'instructor', 'room' and 'sessionID'.  While
this presentation is useful, a client might wish to have the time slots and
instructor IDs decoded for more readable output:

    Monday, 9:00     Arithmetic                 E Jones        4044 4044_11
    Monday, 9:00     Language Studies           T Wilson       4054 4054_11
    Monday, 10:00    Bible Study                M Eliade       4068 4068_12
    Monday, 10:00    Introduction to Computers  D Knuth        4086 4086_12
    Monday, 11:00    Psychology                 A Adler        4077 4077_13
    Monday, 11:00    Social Science             T Jones        4044 4044_13
    Friday, 9:00     World History              H Wells        4052 4052_51
    Friday, 9:00     Music Appreciation         W Wilson       4044 4044_51

Time slots coded with chronologically sequential numbers can be ordered to
sort numerically in the C<%parameters> established in the
F<fields.[package1].data> file corresponding to a particular
Data::Presenter::[package1].  Their human-language equivalents, however, will
I<not> sort properly, as, for example, 'Friday' comes before 'Monday' in an
alphabetical or ASCII-betical sort.  Clearly, it would be desirable to
establish the sorting order by relying on the chronologically sequential time
slots and yet have the printed output reflect more human-readable days of the
week and times.  Analogously, for the instructor we might wish to display the
first initial and last name in our printed output rather than his/her ID
code.

The order in which data records appear in output is determined by
C<sort_by_column()> I<before> C<writeformat()> is called.  How can we preserve
this order in the final output?

Answer:  After we have stored a given formed line in C<$^A>, we I<reprocess>
that line by calling an internal subroutine defined in the invoking class,
C<Data::Presenter::[package1]::_reprocessor()>, which tells Perl to splice out
certain portions of the formed line and substitute more human-readable copy.
The information needed to make C<_reprocessor()> work comes from two places.

First, from a hash passed by reference as an argument to
C<writeformat_with_reprocessing()>.  C<writeformat_with_reprocessing()> takes
a list of four key-value pairs, the first three of which are the same as those
passed to C<writeformat()>.  The fourth key-value pair to
C<writeformat_with_reprocessing()> is a reference to a hash whose keys are
the names of the fields in the data records where we wish to make
substitutions and whose corresponding values are the number of characters
the field will be allocated I<after> substitution.  The call to
C<writeformat_with_reprocessing()> would therefore look like this:

    %reprocessing_info = (
        timeslot    => 17,
        instructor  => 15,
    );

    $dp1->writeformat_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        reprocess   => \%reprocessing_info,
    );

Second, C<writeformat_with_reprocessing()> takes advantage of the fact that
Data::Presenter's package global hash C<%reserved> contains four keys --
C<fields>, C<parameters>, C<index> and C<options> -- only the first
three of which are used in Data::Presenter's constructor or sorting methods.
Early in the development of Data::Presenter the keyword C<options> was
deliberately left unused so as to be available for future use.

The sophisticated administrator can make use of the C<options> key to store
metadata in a variety of ways.  In writing
C<Data::Presenter::[package1]::_init()>, the administrator prepares the way
for last-minute reprocessing by creating an C<options> key in the hash to
be blessed into the C<Data::Presenter::[package1]()> object.  The value
corresponding to the key C<options> is itself a hash with two elements
keyed by C<subs> and C<sources>.  If C<$dp1> is the object and C<%data>
is the hash blessed into the object, then we are looking at these two
elements:

    $data{options}{subs}
    $data{options}{sources}

The values corresponding to these two keys are references to yet more hashes.
 The hash which is the value for C<$data{options}{subs}> hash keys whose
elements are the name of subroutines, each of which is built up from the
string C<reprocess_> concatenated with the name of the field to be
reprocessed, I<e.g.>

    $data{options}{subs} = {
        reprocess_timeslot      => 1,
        reprocess_instructor    => 1,
    };

These field-specific internal reprocessing subroutines may be defined by the
administrator in C<Data::Presenter::[package1]()> or they may be imported from
some other module.  C<writeformat_with_reprocessing()> verifies that these
subroutines are actually present in C<Data::Presenter::[package1]()>
regardless of where they were originally found.

What about C<$data{options}{sources}>?  This location stores all the
original data from which substitutions are made.  Example:

    $data{options}{sources} = {
        timeslot   => {
            11 => ['Monday', '9:00 am'  ],
            12 => ['Monday', '10:00 am' ],
            13 => ['Monday', '11:00 am' ],
            51 => ['Friday', '9:00 am'  ],
        },
        instructor => {
            'Jones'     => ['Jones',  'E' ],
            'WilsonT'   => ['Wilson', 'T' ],
            'Eliade'    => ['Eliade', 'M' ],
            'Knuth'     => ['Knuth',  'D' ],
            'Adler'     => ['Adler',  'A' ],
            'JonesT'    => ['Jones',  'T' ],
            'Wells'     => ['Wells',  'H' ],
            'WilsonW'   => ['Wilson', 'W' ],
        }
    };

The point at which this data gets into the object is, of course,
C<Data::Presenter::[package1]::_init()>.  What the administrator does at that
point is limited only by his/her imagination.  Data::Presenter seeks to bless
a hash into its object.  That hash must meet the following requirements:

=over 4

=item *

With the exception of elements holding metadata, each element holds an array,
each of whose elements must be a number or a string.

=item *

Three metadata elements keyed as follows must be present:

=over 4

=item * C<fields>

=item * C<parameters>

=item * C<index>

=back

The fourth metadata element keyed by C<options> is required only if some
Data::Presenter method has been written which requires the information stored
therein.  C<writeformat_with_reprocessing()> is the only such method currently
present, but additional methods using the C<options> key may be added in
the future.

=back

The author has used two different approaches to the problem of initializing
Data::Presenter::[package1] objects.

=over 4

=item *

In the first, more standard approach, the name of a source file can be passed
to the constructor, which passes it on to the initializer, which then opens a
filehandle to the file and processes with regular expressions, C<unpack>,
etc. to build an array for each data record.  Keyed by a unique ID, a
reference to this array then becomes the value of an element of the hash
which, once metadata is added, is blessed into the
Data::Presenter::[package1] object.  The source for the metadata is the
F<fields.[package1].data> file and the C<@fields>, C<%parameters> and
C<$index> found therein.

=item *

A second approach asks:  ''Instead of having C<_init()> do data munging on a
file, why not directly pass it a hash of arrays?  Better still, why not pass
it a hash of arrays which already has an C<'options'> key defined?  And
better still yet, why not pass it an object produced by some other Perl
module and containing a blessed hash of arrays with an already defined
C<options> key?''  In this approach, C<Data::Presenter::[package1]::_init()>
does no data munging.  It is mainly concerned with defining the three
required metadata elements.

=back

=head3 C<writeformat_deluxe()>

C<writeformat_deluxe()> is an advanced application of
Data::Presenter and the reader may wish to skip this section until other
parts of the module have been mastered.

C<writeformat_deluxe()> enables the user to have I<both> column headers (as in
C<writeformat_plus_header()>) and dynamic, 'just-in-time' reprocessing of data
in selected fields (as in C<writeformat_with_reprocessing()>).  Call it just
as you would C<writeformat_with_reprocessing()>, but add a key-value pair
keyed by C<title>.

    %reprocessing_info = (
        timeslot    => 17,
        instructor  => 15,
    );

    $dp1->writeformat_deluxe(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        reprocess   => \%reprocessing_info,
        title       => $title,
    );

=head3 C<writedelimited()>

The C<Data::Presenter::writeformat...()> family of
methods discussed above write data to plain-text files in columns aligned
with whitespace via Perl's C<formline> function -- the function which
internally powers Perl formats.  This is suitable if the ultimate consumer of
the data is satisfied to read a plain-text file.  However, in many business
contexts data consumers are more accustomed to word processing files than to
plain-text files.  In particular, data consumers are accustomed to data
presented in tables created by commercial word processing programs. Such
programs generally have the capacity to take text in which individual lines
consist of data separated by delimiter characters such as tabs or commas and
transform that text into rows in a table where the delimiters signal the
borders between table cells.

To that end, the author has created the
C<Data::Presenter::writedelimited...()> family of subroutines to print output
to plain-text files intended for further processing within word processing
programs.  The simplest method in this family, C<writedelimited()>, takes a
list of three key-value pairs:

=over 4

=item * C<sorted>

The value keyed by C<sorted> is a hash reference which is the return value of
C<sort_by_column()>.  Hence, C<writedelimited()> can only be called once
C<sort_by_column()> has been called.

=item * C<file>

The value keyed by C<file> is the name of a file arbitrarily selected by
the operator to hold the output of C<writedelimited()>.

=item * C<delimiter>

The value keyed by C<delimiter> is the user-selected delimiter character or
characters which will delineate fields within an individual record in the
output file.  Typically, this character will be a tab (C<\t>), comma (C<,>)
or similar character that a word processing program's 'convert text to table'
feature can use to establish columns.

=back

Using the ''census'' example from above, the overall sequence of code needed
to use C<writedelimited()> would be:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $dp1->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => $delimiter,
    );

Note that, unlike C<writeformat()>, C<writedelimited()> does not require a
reference to C<@columns_selected> to be passed as an argument.

Depending on the number of characters in a text editor's tab-stop setting,
the result of the above call might look like:

    HERNANDEZ    HECTOR    1963-08-01    456791
    VASQUEZ    ADALBERTO    1973-08-17    786792
    VASQUEZ    ALBERTO 1953-02-28    906786

This is obviously less readable than the output of C<writeformat()> -- but
since the output of C<writedelimited()> is intended for further processing by
a word processing program rather than for final use, this is not a major
concern.

=head3 C<writedelimited_plus_header()>

Just as C<writeformat_plus_header()> extended
C<writeformat()> to include column headers, C<writedelimited_plus_header()>
extends C<writedelimited()> to include column headers, separated by the same
delimiter character as the data, in a plain-text file intended for further
processing by a word processing program.

C<writedelimited_plus_header()> takes a list of four key-value pairs:
C<sorted>, C<columns>, C<file>, and C<delimiter>.  The complete call
to C<writedelimited_plus_header> looks like this:

    @columns_selected = (
        'unit', 'ward', 'lastname', 'firstname',
        'datebirth', 'dateadmission', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $dp1->writedelimited_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => $delimiter,
    );

Note that, unlike C<writeformat_plus_header()>, C<writedelimited_plus_header()>
does not take C<$title> as an argument.  It is felt that any title would be
more likely to be supplied in the word-processing file which ultimately holds
the data prepared by C<writedelimited_plus_header()> and that its inclusion
at this point might interfere with the workings of the word processing
program's 'convert text to table' feature.

Depending on the number of characters in a text editor's tab-stop setting,
the result of the above call might look like:

                Date    Date of
    Unit    Ward    Last Name    First Name    of Birth       Admission    C No.
    LAVER    0105    VASQUEZ JORGE    1956-01-13    1986-01-17     456787
    LAVER    0107    VASQUEZ LEONARDO    1970-15-23    1990-08-23   456788
    SAMSON    0209    VASQUEZ JOAQUIN 1970-03-25    1990-11-14     456789

Again, the readability of the delimited copy in the plain-text file here is
not as important as how correctly the delimiter has been chosen in order to
produce good results once the file is further processed by a word processing
program.

Note that, unlike C<writeformat_plus_header()>, C<writedelimited_plus_header()>
does not produce a hyphen line.  The author feels that the separation of
header and body within the table is here better handled within the word
processing file which ultimately holds the data prepared by
C<writedelimited_plus_header()>.

Note further that, unlike C<writeformat_plus_header()>,
C<writedelimited_plus_header()> does not truncate the words in column headers.
This is because the C<writedelimited...()> family of methods does not impose
a maximum width on output fields as does the C<writeformat...()> family of
methods.  Hence, there is no need to truncate headers to fit within specified
column widths.  Column widths in the C<writedelimited...()> family are
ultimately determined by the word processing program which produces the final
output.

=head3 C<writedelimited_with_reprocessing()>

C<writedelimited_with_reprocessing()>
is an advanced application of Data::Presenter and the reader may wish to skip
this section until other parts of the module have been mastered.

C<writedelimited_with_reprocessing()>, like C<writeformat_with_reprocessing()>,
permits a sophisticated administrator to activate ''last minute''
substitutions in strings to be printed such that substitutions do not affect
the pre-established sorting order.  For a full discussion of the rationale
for this feature, see the discussion of L<"writeformat_with_reprocessing()">
above.

C<writedelimited_with_reprocessing()> takes a list of five key-value pairs,
four of which are the same arguments passed to
C<writeformat_with_reprocessing()>.  The fifth key-value pair is a reference
to an array holding a list of those columns selected for output upon which
the user chooses to perform reprocessing.

    @reprocessing_info = qw( instructor timeslot room );

    $dp1->writedelimited_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => $delimiter,
        reprocess   => \@reprocessing_info,
    );

Taking the classroom scheduling problem presented above,
C<writedelimited_with_reprocessing()> would produce output looking something
like this:

    Monday, 9:00    Arithmetic    E Jones 4044    4044_11
    Monday, 9:00    Language Studies    T Wilson    4054   4054_11
    Monday, 10:00    Bible Study    M Eliade    4068    4068_12
    Monday, 10:00    Introduction to Computers    D Knuth 4086   4086_12
    Monday, 11:00    Psychology    A Adler 4077    4077_13
    Monday, 11:00    Social Science    T Jones 4044    4044_13
    Friday, 9:00    World History    H Wells 4052    4052_51
    Friday, 9:00    Music Appreciation    W Wilson    4044   4044_51

Usage of C<writedelimited_with_reprocessing()> requires that the administrator
appropriately define C<Data::Presenter::[Package1]::_reprocess_delimit()> and
C<Data::Presenter::[Package1]::_init()> subroutines in the invoking package,
along with appropriate subroutines specific to each argument capable of being
reprocessed.  Again, see the discussion in L<"writeformat_with_reprocessing()">.

=head3 C<writedelimited_deluxe()>

C<writedelimited_deluxe()> is an advanced
application of Data::Presenter and the reader may wish to skip this section
until other parts of the module have been mastered.

C<writedelimited_deluxe()> completes the parallel structure between the
C<writeformat...()> and C<writedelimited...()> families of Data::Presenter
methods by enabling the user to have I<both> column headers (as in
C<writedelimited_plus_header()>) and dynamic, 'just-in-time' reprocessing of
data in selected fields (as in C<writedelimited_with_reprocessing()>).  Except
for the name of the method called, the call to C<writedelimited_deluxe()> is
the same as for C<writedelimited_with_reprocessing()>:

    @reprocessing_info = qw( instructor timeslot );

    $dp1->writedelimited_deluxe(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => $delimiter,
        reprocess   => \@reprocessing_info,
    );

Using the classroom scheduling example from above,the output from
C<writedelimited_deluxe()> might look like this:

    Timeslot    Group    Instructor    Room    GroupID
    Monday, 9:00    Arithmetic    E Jones 4044    4044_11
    Monday, 9:00    Language Studies    T Wilson    4054   4054_11
    Monday, 10:00    Bible Study    M Eliade    4068    4068_12
    Monday, 10:00    Introduction to Computers    D Knuth 4086   4086_12
    Monday, 11:00    Psychology    A Adler 4077    4077_13
    Monday, 11:00    Social Science    T Jones 4044    4044_13
    Friday, 9:00    World History    H Wells 4052    4052_51
    Friday, 9:00    Music Appreciation    W Wilson    4044   4044_51

As with C<writedelimited_with_reprocessing()>, C<writedelimited_deluxe()>
requires careful preparation on the part of the administrator.  See the
discussion under L<"writeformat_with_reprocessing()"> above.

=head3 C<writeHTML()>

In its current formulation, C<writeHTML()> works very much
like C<writeformat_plus_header()>.  It  writes data to an operator-specified
HTML file and writes an appropriate header to that file as well.
C<writeHTML()> takes the same 4 arguments as C<writeformat_plus_header()>:
C<$sorted_data>, C<\@columns_selected>, C<$outputfile> and C<$title>.  The
body of the resulting HTML file is more similar to a Perl format than to an
HTML table.  (This may be upgraded to a true HTML table in a future release.)

    $dp1->writeHTML(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $HTMLoutputfile,  # must have .html extension
        title       => $title,
    );

=head2 Data::Presenter::Combo Objects

It is quite possible that we may have two or more different database reports
which present data on the same underlying universe or population.  If these
reports share a common index field which can be used to uniquely identify
each entry in the underlying population, then we would like to be able to
combine these sources, manipulate the data and re-output them via the simple
and complex Data::Presenter output methods described in the L<"Synopsis">
above.

In other words, if we have already created

    my $dp1 = Data::Presenter::[Package1]->new(
        $sourcefile, \@fields,\%parameters, $index);
    my $dp2 = Data::Presenter::[Package2]->new(
        $sourcefile, \@fields,\%parameters, $index);
    ...
    my $dpx = Data::Presenter::[Package2]->new(
        $sourcefile, \@fields,\%parameters, $index);

we would like to be able to define an array of the objects we have created
and construct a new object combining the first two in an orderly manner:

    my @objects = ($dp1, $dp2, ... $dpx);
    my $dpC = Data::Presenter::[some subclass]->new(\@objects);

We would then like to be able to call all the Data::Presenter sorting,
selecting and output methods discussed above on C<$dpC> B<without having to
re-specify C<$sourcefile>, C<\@fields>, C<\%parameters> or C<$index>>.

Can we do this?  Yes, we can.  More precisely, we can create I<two> new types
of objects:  one in which the data entries comprise those entries found in
I<each> of the original sources, and one in which the data entries comprise
those found in I<any> of the sources.  In mathematical terms, we can create
either a new object which represents the I<intersection> of the sources or
one which represents the I<union> of the sources.  We call these as follows:

    my $dpI = Data::Presenter::Combo::Intersect->new(\@objects);

and

    my $dpU = Data::Presenter::Combo::Union->new(\@objects);

Note the following:

=over 4

=item *

For Combo objects, unlike all other Data::Presenter::[Package1] objects, we
pass only one variable -- a reference to an array of Data::Presenter objects
-- to the constructor instead of three.

=item *

Combo objects are always called from a subclass of Data::Presenter::Combo
such as Data::Presenter::Combo::Intersect or Data::Presenter::Combo::Union.
They are not called from Data::Presenter::Combo itself.

=item *

The regular Data::Presenter objects which are selected to make up a
Data::Presenter::Combo object must share a field which serves as the L<index
field|"Index Field"> for each object.  This field must carry the same name in
C<@fields> in the I<fields.XXX.data> configuration files corresponding to each of
the objects, though that field does not have to appear in the same element
position in C<@fields> in each such file.  Similarly, the parameters on the
value side of C<%parameters> for the index field must be specified
identically in each configuration file.  If these conditions are not met, a
Data::Presenter::Combo object cannot be constructed and the program will die
with an error message.

Let us illlustrate this point.  Suppose that we have two configuration files,
I<fields1.data> and I<fields2.data>, corresponding to two different
Data::Presenter objects, C<$obj1> and C<$obj2>.  For I<fields1.data>, we
have:

    @fields = qw(lastname, firstname, cno);

    %parameters = (
        $fields[0]        => [14, 'U', 'a', 'Last Name'],
        $fields[1]        => [10, 'U', 'a', 'First Name'],
        $fields[2]        => [ 7, 'U', 'n', 'C No.'],
    );

    $index = 2;

For I<fields2.data>, we have:

    @fields = qw(cno, dateadmission, datebirth);

    %parameters = (
        $fields[0]        => [ 7, 'U', 'n', 'C No.'],
        $fields[1]        => [10, 'U', 'a', 'Date of Admission'],
        $fields[2]        => [10, 'U', 'a', 'Date of Birth'],
    );

    $index = 0;

Can C<$obj1> and C<$obj2> be combined into a Data::Presenter::Combo object?
Yes, they can.  C<cno> is named as the index field in each configuration
file, and the values assigned to C<$fields[$index]> in each are identical:
C<[ 7, 'U', 'n', 'C No.']>.

Suppose, however, that we had a third configuration file, I<fields3.data>,
corresponding to yet another Data::Presenter object, C<$obj3>.  If the
contents of I<fields3.data> were:

    @fields = qw(cno, dateadmission, datebirth);

    %parameters = (
        $fields[0]        => [ 7, 'U', 'n', 'Serial No.'],
        $fields[1]        => [10, 'U', 'a', 'Date of Admission'],
        $fields[2]        => [10, 'U', 'a', 'Date of Birth'],
    );

    $index = 0;

then C<$obj3> could not be combined with either C<$obj1> or C<$obj2> because
the elements of C<$parameters{$fields[$index]}> in C<$obj3> are not identical
to those in the first two objects.

=back

Here are some things to consider in using Data::Presenter::Combo objects:

=over 4

=item *

Q:  What happens if C<$dp1> has entries not found in C<$dp2> (or vice versa)?

A:  It depends on whether you are interested in only those entries found in
each of the data sources (the mathematical intersection of the sources) or
those found in any of the sources (the mathematical union).  Only those
entries found in I<both> C<$dp1> and C<$dp2> are included in a
Data::Presenter::Combo::Intersect object.  But if you are constructing a
Data::Presenter::Combo::Union object, any entry found in either source file
will be represented in the Union object.  These properties would hold no
matter how many sources you used as arguments.

=item *

Q:  What happens if both C<$dp1> and C<$dp2> have fields named, for instance,
C<'lastname'>?

A:  Left-to-right precedence determines which object's C<'lastname'> field is
entered into C<$dpC>.  Assuming that C<$dp1> is listed first in C<@objects>,
I<all> the fields in C<$dp1> will appear in C<$dpC>.  Only those fields in
C<$dp2> I<not> found in C<$dp1> will be added to C<$dpC>.  If, however,
C<@objects> were defined as C<($dp2, $dp1)>, then C<$dp2>'s fields would have
precedence over those of C<$dp1>.  If a C<$dp3> object were constructed based
on yet another data source, only those fields entries I<not> found in C<$dp1>
or C<$dp2> would be included in the Combo object -- and so forth.  This
left-to-right precedence rule governs both the data entries in C<$dpC> as
well as the selection, sorting and output characteristics.

=back

=head1 BUGS

It was discovered that in versions 0.68 and earlier, C<sort_by_column()>
failed to sort data properly in descending order.  This has been fixed.
See F<Changes>.

=head1 REFERENCES

The fundamental reference for this program is, of course, the Camel book:
Larry Wall, Tom Christiansen, Jon Orwant.  <I<Programming Perl>, 3rd ed.
O'Reilly & Associates, 2000, L<http://www.oreilly.com/catalog/pperl3/>.

A careful reading of the code will tell any competent Perl hacker that many
tricks were taken from the Ram book:  Tom Christiansen & Nathan Torkington.
I<Perl Cookbook>.  O'Reilly & Associates, 1998,
L<http://www.oreilly.com/catalog/cookbook/>.

The object-oriented programming skills needed to develop this program were
learned via extensive re-reading of Chapters 3, 6 and 7 of Damian Conway's
I<Object Oriented Perl>.  Manning Publications, 2000,
L<http://www.manning.com/Conway/index.html>.

This program goes to great length to follow the principle of 'Repeated Code
is a Mistake' L<http://www.perl.com/pub/a/2000/11/repair3.html> -- a specific
application of the general Perl principle of Laziness.  The author grasped
this principle best following a 2001 talk by Mark-Jason Dominus
L<http://perl.plover.com/> to the New York Perlmongers L<http://ny.pm.org/>.

Most of the code in the C<_init()> subroutines was written before the author
read I<Data Munging with Perl> L<http://www.manning.com/cross/index.html> by
Dave Cross.  Nonetheless, that is an excellent discussion of the problems
involved in understanding the structure of data sources.

The discussion of bugs in this program benefitted from discussions on the
Perl Seminar New York  mailing list
L<http://groups.yahoo.com/group/perlsemny>, particularly with Martin
Heinsdorf.

Correcting the bug involving sorting in descending order entailed a complete
rewrite of much code.  This rewrite was greatly assisted by C<brian d foy> and
Tanktalus in the Perlmonks thread ''Building a sorting subroutine on the
fly'' (L<http://perlmonks.org/?node_id=512460>).

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 25, 2001.
Last modification date:  February 10, 2008.
Copyright (c) 2001-5 James E. Keenan.  United States.
All rights reserved.

All data presented in this documentation or in the sample files in the
archive accompanying this documentation are dummy copy.  The data was
entirely fabricated by the author for heuristic purposes.  Any resemblance to
any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl
itself.

=cut


