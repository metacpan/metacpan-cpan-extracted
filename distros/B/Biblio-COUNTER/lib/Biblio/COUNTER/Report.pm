package Biblio::COUNTER::Report;

use strict;
use warnings;

use Biblio::COUNTER;

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    MAY_BE_BLANK
    NOT_BLANK   
    EXACT_MATCH
    REQUESTS 
    SEARCHES
    SESSIONS
    TURNAWAYS
);

# --- Constants

# Scope -- where are we in the report?
use constant REPORT => 'report';
use constant RECORD => 'record';  # In the records that the report contains

# Field names
use constant NAME         => 'name';
use constant CODE         => 'code';
use constant RELEASE      => 'release';
use constant DESCRIPTION  => 'description';
use constant DATE_RUN     => 'date_run';
use constant CRITERIA     => 'criteria';
use constant PERIOD_COVERED => 'period_covered';  # JR1a
use constant LABEL        => 'label';
use constant PERIOD_LABEL => 'period_label';
use constant BLANK        => 'blank_field';
use constant PERIODS      => 'periods';
use constant COUNT        => 'count';
use constant TITLE        => 'title';
use constant PUBLISHER    => 'publisher';
use constant PLATFORM     => 'platform';
use constant PRINT_ISSN   => 'print_issn';
use constant ONLINE_ISSN  => 'online_issn';
use constant YTD_HTML     => 'ytd_html';
use constant YTD_PDF      => 'ytd_pdf';
use constant YTD_TOTAL    => 'ytd';

# Metrics
use constant REQUESTS  => 'requests';
use constant SEARCHES  => 'searches';
use constant SESSIONS  => 'sessions';
use constant TURNAWAYS => 'turnaways';

# Field matching
use constant MAY_BE_BLANK => 0;
use constant NOT_BLANK    => 1;
use constant EXACT_MATCH  => 2;

# Useful constants
use constant INVALID => 0;
use constant VALID   => 1;
use constant FIXED   => 2;

# --- Variables

my %mon2num = qw(
    jan 01
    feb 02
    mar 03
    apr 04
    may 05
    jun 06
    jul 07
    aug 08
    sep 09
    oct 10
    nov 11
    dec 12
);

my @num2mon = qw(
    ---
    jan
    feb
    mar
    apr
    may
    jun
    jul
    aug
    sep
    oct
    nov
    dec
);

my $rx_mon = qr/(?i)jan|feb|mar|apr|may|june?|july?|aug|sept?|oct|nov|dec|0[1-9]|1[0-2]/;
my $rx_year = qr/(?:2[012])?\d\d/;  # Good through 2299

# ------------------------------------------------------------ PUBLIC METHODS --

sub new {
    my ($cls, %args) = @_;
    bless {
        'treat_blank_counts_as_zero' => 0,
        'change_not_available_to_blank' => 0,
        'dont_reread_next_row' => 0,
        %args,
    }, $cls;
}

sub process {
    my ($self) = @_;
    $self->begin_file
         ->begin_report
         ->process_header
         ->process_body
         ->end_report
         ->end_file;
}

# ---------------------------------------------- TOP-LEVEL STRUCTURAL METHODS --

sub begin_file {
    my ($self) = @_;
    $self->trigger_callback('begin_file', $self->{'file'});
}

sub end_file {
    my ($self) = @_;
    $self->trigger_callback('end_file', $self->{'file'});
}

sub begin_report {
    my ($self) = @_;
    $self->trigger_callback('begin_report');
    $self->_orient;
}

sub end_report {
    my ($self) = @_;
    $self->{'is_valid'} = !$self->{'errors'};
    $self->trigger_callback('end_report');
    undef $self->{'fh'};
    return $self;
}

sub process_header {
    my ($self) = @_;
    $self->begin_header;
    $self->process_header_rows;
    $self->end_header;
}

sub process_header_rows {
    die "Every report must have its own header-processing code";
}

sub process_body {
    my ($self) = @_;
    $self->_in_scope(RECORD);
    $self->begin_body;
    while (!$self->_eof) {
        $self->begin_record;
        $self->process_record;
        $self->end_record;
    }
    $self->end_body;
    return $self;
}

sub begin_body {
    my ($self) = @_;
    $self->trigger_callback('begin_body');
    return $self;
}

sub end_body {
    my ($self) = @_;
    $self->trigger_callback('end_body');
    return $self;
}

sub process_record {
    die "Every report must have its own record-parsing code";
}

# ----------------------------------------------------------------- ACCESSORS --

sub name        { @_ > 1 ? $_[0]->{'report'}->{NAME()       } = $_[1] : $_[0]->{'report'}->{NAME()       } }
sub code        { @_ > 1 ? $_[0]->{'report'}->{CODE()       } = $_[1] : $_[0]->{'report'}->{CODE()       } }
sub release     { @_ > 1 ? $_[0]->{'report'}->{RELEASE()    } = $_[1] : $_[0]->{'report'}->{RELEASE()    } }
sub description { @_ > 1 ? $_[0]->{'report'}->{DESCRIPTION()} = $_[1] : $_[0]->{'report'}->{DESCRIPTION()} }
sub date_run    { @_ > 1 ? $_[0]->{'report'}->{DATE_RUN()   } = $_[1] : $_[0]->{'report'}->{DATE_RUN()   } }
sub criteria    { @_ > 1 ? $_[0]->{'report'}->{CRITERIA()   } = $_[1] : $_[0]->{'report'}->{CRITERIA()   } }
sub publisher   { @_ > 1 ? $_[0]->{'report'}->{PUBLISHER()  } = $_[1] : $_[0]->{'report'}->{PUBLISHER()  } }
sub platform    { @_ > 1 ? $_[0]->{'report'}->{PLATFORM()   } = $_[1] : $_[0]->{'report'}->{PLATFORM()   } }
sub periods     { @_ > 1 ? $_[0]->{'report'}->{PERIODS()    } = $_[1] : $_[0]->{'report'}->{PERIODS()    } }

sub records { @{ $_[0]->{'records'} ||= [] } }

sub is_valid { $_[0]->{'is_valid'} }
sub warnings { $_[0]->{'warnings'} }
sub errors { $_[0]->{'errors'} }

# ---------------------------- METHODS THAT SUBCLASSES MIGHT WANT TO OVERRIDE --

# --- Position setting

sub begin_row {
    my ($self) = @_;
    $self->trigger_callback('begin_row');
    my $fh = $self->{'fh'};
    while (!eof $fh) {
        my $row = $self->_read_next_row;
        my $row_str = join('', @$row);
        last if $row_str =~ /\S/;
        # Oops -- blank row where one wasn't expected
        $self->trigger_callback('fixed', '<row>', '<blank>', '<skipped>');
        $self->{'warnings'}++;
    }
    return $self;
}

# --- Field methods

sub check_blank {
    # Any blank field
    my ($self) = @_;
    my $cur = $self->_ref_to_cur_cell;
    $self->_in_field(BLANK)->_trim($cur);
    if ($$cur eq '') {
        $self->_ok($cur);
    }
    else {
        $self->_fix('');
    }
    $self->_next;
}

sub check_report_name {
    my ($self) = @_;
    my $name = $self->canonical_report_name;
    $self->_check_field(NAME, _force_exact_match_sub($name))->_next;
}

sub check_report_description {
    my ($self) = @_;
    my $description = $self->canonical_report_description;
    $self->_check_field(DESCRIPTION, _force_exact_match_sub($description))->_next;
}

sub check_date_run {
    my ($self) = @_;
    $self->_check_field(DATE_RUN, \&_is_yyyymmdd)->_next;
}

sub check_count_by_periods {
    my ($self, $metric) = @_;
    my $periods = $self->{'periods'};
    $self->_in_field(COUNT);
    foreach my $period (@$periods) {
        $self->_check_count($metric, $period);
    }
    return $self;
}

sub check_report_criteria {
    my ($self) = @_;
    $self->_check_free_text_field(CRITERIA, NOT_BLANK)->_next;
}

sub check_period_covered {
    my ($self) = @_;
    $self->_check_free_text_field(PERIOD_COVERED, NOT_BLANK)->_next;
}

sub check_title {
    my ($self, $mode, $str) = @_;
    $self->_check_free_text_field(TITLE, $mode, $str);
}

sub check_publisher {
    my ($self, $mode, $str) = @_;
    $self->_check_free_text_field(PUBLISHER, $mode, $str);
}

sub check_platform {
    my ($self, $mode, $str) = @_;
    $self->_check_free_text_field(PLATFORM, $mode, $str);
}

sub check_print_issn {
    my ($self) = @_;
    $self->_check_field(PRINT_ISSN, \&_is_issn)->_next;
}

sub check_online_issn {
    my ($self) = @_;
    $self->_check_field(ONLINE_ISSN, \&_is_issn)->_next;
}

sub check_ytd_total {
    my ($self, $metric) = @_;
    $self->_check_count($metric, YTD_TOTAL);
}

sub check_ytd_html {
    my ($self, $metric) = @_;
    $self->_check_count($metric, YTD_HTML);
}

sub check_ytd_pdf {
    my ($self, $metric) = @_;
    $self->_check_count($metric, YTD_PDF);
}

sub check_period_labels {
    my ($self) = @_;
    my @periods;
    $self->_in_field(PERIOD_LABEL);
    while (my $period = $self->_period_label) {
        push @periods, $period;
    }
    if (@periods == 0) {
        # Too few periods
        $self->_cant_fix('<at least 1 periodic usage column>');
    }
    elsif (@periods > 12) {
        $self->_cant_fix('<no more than 12 periodic usage columns>');
    }
    $self->{'periods'} = \@periods;
    return $self;
}

sub _period_label {
    my ($self, $cur) = @_;
    $cur ||= $self->_ref_to_cur_cell;
    # If the current cell has two digits in a row, we assume it's meant to be a period label
    return unless $$cur =~ /\d\d/;
    $self->_trim($cur);
    my ($result, $period) = $self->parse_period($$cur);
    if ($result == VALID) {
        $self->_ok($cur);
    }
    elsif ($result == FIXED) {
        $self->_fix($period);
    }
    else {
        $self->_cant_fix('<period label>');
    }
    $self->_next;
    return $period;
}

sub end_row {
    # Make sure we've reached the end of the row
    my ($self) = @_;
    my $row = $self->{'row'};
    my $c = $self->{'c'};
    my $ci = _col2idx($c);
    if (@$row > $ci) {
        # Oops -- we're not at the end of the row
        my $n = @$row - $ci;
        my $to_delete = join('', @$row[-$n..-1]);
        if ($to_delete =~ /\S/) {
            # Double oops -- there's at least non-blank cell beyond where
            # the row should end
            foreach (1..$n) {
                my $cur = $self->_ref_to_cur_cell;
                if ($$cur =~ /\S/) {
                    $self->trigger_callback('cant_fix', '<nothing>', $$cur, '<end of row>');
                    $self->{'errors'}++;
                }
                else {
                    $self->_trim($cur);
                    $self->{'warnings'}++;
                }
                $self->_next;
            }
        }
        else {
            # No big deal, we'll just strip off the blank cells
            foreach (1..$n) {
                my $cur = $self->_ref_to_cur_cell;
                $self->_trim($cur);
                $self->trigger_callback('deleted', $$cur);
                $self->_next;
            }
            splice @$row, -$n;
        }
    }
    # Output the row
    $self->trigger_callback('output', join("\t", @$row));
    $self->trigger_callback('end_row', $row);
    return $self;
}

sub blank_row {
    my ($self) = @_;
    return $self if $self->_eof;
    $self->_read_next_row;  # This is probably a blank row
    my $row = $self->{row};
    my $row_str = join('', @$row);
    if (@$row == 0) {
        # No cells at all -- perfect!
        # ??? $self->_read_next_row;
    }
    elsif ($row_str eq '') {
        # All cells are empty -- ok
        # XXX Callback??
        # ??? $self->_read_next_row;
    }
    elsif ($row_str =~ /\S/) {
        # Hmm, no blank row
        $self->{'warnings'}++;
        # XXX Need a callback for inserted blank lines
        # *Don't* read the next row
    }
    else {
        # Cells are blank but not empty
        foreach my $i (1..@$row) {
            my $cur = $self->_ref_to_cur_cell;
            $self->_in_field(BLANK)->_trim($cur)->_next;
        }
        # ??? $self->_read_next_row;
    }
    # Output a blank line regardless of what we found
    $self->trigger_callback('output', '');
    return $self;
}

# --- Generic data checking methods

sub check_label {
    my ($self, $str, $rx) = @_;
    $self->_in_field(LABEL)->_must_match($str, $rx);
}

sub begin_header {
    my ($self) = @_;
    my $hdr = $self->{'container'} = $self->{'header'} = {
        'name' => $self->canonical_report_name,
        'description' => $self->canonical_report_description,
        'code' => $self->canonical_report_code,
        'release' => $self->release_number,
    };
    $self->trigger_callback('begin_header', $hdr);
    return $self;
}

sub end_header {
    my ($self) = @_;
    my $hdr = $self->{'header'};
    $self->trigger_callback('end_header', $hdr);
    return $self;
}

sub begin_record {
    my ($self) = @_;
    my $rec = $self->{'container'} = $self->{'record'} = {};
    $self->trigger_callback('begin_record', $rec);
    return $self;
}

sub end_record {
    my ($self) = @_;
    my $rec = $self->{'record'};
    push @{ $self->{'records'} ||= [] }, $rec;
    $self->trigger_callback('end_record', $rec);
    return $self;
}

# ----------------------------------------------------------- PRIVATE METHODS --

# --- Record field checking methods

sub _check_field {
    my ($self, $field, $check) = @_;
    $self->_in_field($field);
    my $container = $self->{'container'};
    my $cur = $self->_ref_to_cur_cell;
    $self->_trim($cur);
    if ($check->($self, $field, $cur)) {
        $container->{$field} = $$cur;
    }
    return $self;
}

sub _check_free_text_field {
    my ($self, $field, $mode, $str) = @_;
    if ($mode == EXACT_MATCH) {
        $str = '' unless defined $str;
        $self->_check_field($field, _exact_match_sub($str));
    }
    elsif ($mode == NOT_BLANK) {
        $self->_check_field($field, \&_is_not_blank);
    }
    else {
        $self->_check_field($field, \&_is_anything);
    }
    $self->_next;
}

sub _not_available {
    my ($self) = @_;
    if ($self->{'change_not_available_to_blank'}) {
        $self->_fix('');
    }
    else {
        $self->_cant_fix('<count>');
    }
    return $self;
}

sub _check_count {
    my ($self, $field, $period) = @_;
    my $cur = $self->_ref_to_cur_cell;
    $self->_trim($cur);
    my $val = $$cur;
    my $container = $self->{'container'};
    if (defined $period) {
        # Usage for a particular period
        my ($result, $normalized_period);
        ($result, $period, $normalized_period) = $self->parse_period($period);
        if ($val =~ /^\d+$/) {
            if ($result != INVALID) {
                $container->{'count'}->{$normalized_period}->{$field} = $val;
                $self->trigger_callback('count', $self->{'scope'}, $field, $period, $val);
            }
        }
        elsif ($val eq '') {
            if ($self->{'treat_blank_counts_as_zero'}) {
                $container->{'count'}->{$normalized_period}->{$field} = $val;
                $self->trigger_callback('count', $self->{'scope'}, $field, $period, 0);
            }
        }
        elsif ($val =~ m{^n/a$}i) {
            $self->_not_available;
        }
        else {
            $self->_cant_fix('<count>');
        }
    }
    else {
        # YTD usage
        if ($val =~ /^\d+$/) {
            $container->{'count'}->{$field} = $val;
            $self->trigger_callback("count_$field", $self->{'scope'}, $field, $val);
        }
        elsif ($val eq '') {
            if ($self->{'treat_blank_counts_as_zero'}) {
                $container->{'count'}->{$field} = $val;
                $self->trigger_callback("count_$field", $self->{'scope'}, $field, 0);
            }
        }
        elsif ($val =~ m{^n/a$}i) {
            $self->_not_available;
        }
        else {
            $self->_cant_fix('<count>');
        }
    }
    $self->_next;
}

sub _exact_match_sub {
    # Return a ref to code that compares the current cell's value to the given string
    my ($str) = @_;
    return sub {
        my ($self, $field, $cur) = @_;
        $cur ||= $self->_ref_to_cur_cell;
        if ($$cur eq $str) {
            $self->_ok($cur);
        }
        else {
            $self->_cant_fix($str);
        }
        return $self;
    };
}

sub _force_exact_match_sub {
    # Return a ref to code that forces the current cell's value to the given string
    my ($str) = @_;
    return sub {
        my ($self, $field, $cur) = @_;
        if ($$cur eq $str) {
            $self->_ok($cur);
        }
        else {
            $self->_fix($str);
        }
        return $self;
    };
}

sub _is_yyyymmdd {
    my ($self) = @_;
    my $cur = $self->_ref_to_cur_cell;
    my $val = $$cur;
    if ($val =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
        # Nothing to do
        return $self->_ok($cur);
    }
    elsif ($val =~ m{^(\d\d?)/(\d\d?)/(\d\d)?(\d\d)$}) {
        # Ack!  Try to fix
        if ($1 < 13 && $2 >= 13) {
            # mm/dd/(cc)?yy
            return $self->_fix(sprintf('%02d%02d-%02d-%02d', $3 || 20, $4, $1, $2));
        }
        elsif ($2 < 13 && $1 >= 13) {
            # dd/mm/(cc)?yy
            return $self->_fix(sprintf('%02d%02d-%02d-%02d', $3 || 20, $4, $2, $1));
        }
    }
    return $self->_cant_fix('<yyyy-mm-dd>');
}

sub _is_anything {
    my ($self) = @_;
    $self->_trim;
}

sub _is_issn {
    my ($self, $field, $cur) = @_;
    $self->_trim;
    my $val = $$cur;
    if (length $val) {
        if ($val =~ /^\d{4}-\d{3}[\dX]$/) {
            $self->_ok($cur);
        }
        elsif ($val =~ /^(\d{3,4})-?(\d{3})([\dXx])$/) {
            $self->_fix(sprintf("%04d-%03d%s", $1, $2, lc $3));
        }
        else {
            $self->_cant_fix('<issn>');
        }
    }
    return $self;
}

sub _is_count {
    my ($self, $field, $cur) = @_;
    if ($$cur =~ /^\d+$/) {
        $self->_ok($cur);
    }
    else {
        $self->_cant_fix('<count>');
    }
    return $self;
}

sub _is_not_blank {
    my ($self, $field, $cur) = @_;
    if ($$cur eq '') {
        $self->_cant_fix('<not blank>');
        return;
    }
    else {
        $self->_ok($cur);
    }
    return $self;
}

sub _must_match {
    my ($self, $str, $rx) = @_;
    $rx ||= _str2rx($str);
    my $cur = $self->_ref_to_cur_cell;
    $self->_trim($cur);
    if ($$cur eq $str) {
        $self->_ok($cur);
    }
    elsif ($$cur =~ /$rx/) {
        $self->_fix($str);
    }
    else {
        $self->_cant_fix($str);
    }
    $self->_next;
}

sub _read_next_line {
    my ($self) = @_;
    # Fetch the next line
    my $fh = $self->{'fh'};
    my $line = <$fh>;
    return unless defined $line;
    chomp $line;
    $self->trigger_callback('line', $.);
    $self->trigger_callback('input', $line);
    return $line;
}

sub _read_next_row {
    my ($self) = @_;
    if ($self->{'dont_reread_next_row'}) {
        $self->{'dont_reread_next_row'} = 0;
        return $self->{'row'};
    }
    my $line = $self->_read_next_line;
    return unless defined $line;
    $line =~s/\x0d$//;  # Strip CR at end of line
    my $begin_row = $self->{'row'} = [ $self->_parse_line($line) ];
    push @{ $self->{'rows'} }, $begin_row;
    $self->{'r'}++;
    $self->{'c'} = 'A';
    return $begin_row;
}

sub _parse_line {
    my ($self, $line) = @_;
    chomp $line;
    if ($line =~ /\t/) {
        return split /\t/, $line;
    }
    elsif ($line =~ /,/) {
        my $csv = $self->{'csv_parser'};
        if (!defined $csv) {
            eval "use Text::CSV; 1" or die "Can't use Text::CSV";
            $csv = $self->{'csv_parser'} ||= Text::CSV->new({'binary' => 1});
        }
        my @cells;
        my $status  = $csv->parse($line);  # parse a CSV string into fields
        if ($status) {
            @cells = $csv->fields;        # get the parsed fields
        }
        else {
            # Text::CSV can't handle it -- fall back to simplistic CSV parsing
            @cells = split /,/, $line;
            s/^"|"$//g for @cells;
            s/""/"/g for @cells;
        }
        return @cells;
    }
    elsif ($line =~ s/^"|"$//g) {
        # XXX All this needs some tweaking to account for extremely unlikely edge cases
        $line =~ s/""/"/g;
        $line =~ s/\\"/"/g;
    }
    return $line;
}

sub _drop_row {
    my ($self) = @_;
    return $self;
}

sub _orient {
    my ($self) = @_;
    $self->_in_scope(REPORT);
    my $rows = $self->{'rows'};
    my ($row, $line);
    while (!$self->_eof) {
        $row = $self->_read_next_row;
        $line = join("\t", @$row);
        if ($line =~ /\S/) {
            # Not a blank line
            $self->{'dont_reread_next_row'} = 1;  # Don't re-read this row
            last;
        }
        else {
            # Blank line
            $self->trigger_callback('skip_blank_row');
            shift @$rows;
        }
    }
    die "Not a COUNTER report?"    unless $row;
    die "Totally malformed report" unless @$row >= 2;
    my ($name, $title) = @$row;
    if (@$row > 2) {
        # XXX Just silently fix the problem?
        @$row = ($name, $title);
    }
    return Biblio::COUNTER->report($name, %$self);
}

# --- Cursor moving and reading

sub current_position {
    my ($self) = @_;
    my ($r, $c) = $self->_pos;
    return $c . $r;
}

sub current_value {
    my ($self) = @_;
    my $cur = $self->_ref_to_cur_cell;
    return $$cur;
}

sub _pos {
    my ($self) = @_;
    return ($self->{'r'}, $self->{'c'});
}

sub _eof {
    my ($self) = @_;
    eof $self->{'fh'};
}

sub _sr {
    my ($self) = @_;
    # Show row -- for debugging purposes
    my $row = $self->{row};
    my ($rcur, $ccur) = $self->_pos;
    my $c = 'A';
    foreach my $val (@$row) {
        print STDERR $c eq $ccur ? "\e[32m-> " : '   ';
        printf STDERR "%s%d %s\e[0m\n", $c++, $rcur, _hilite_for_debugging($val, $c eq $ccur);
    }
    if ($ccur eq $c) {
        print STDERR "\e[32m->\e[0m\n";
    }
}

sub _hilite_for_debugging {
    my ($str, $is_cur) = @_;
    my $reset = $is_cur ? "\e[32m" : "\e[0m";
    if ($str eq '') {
        $str = "\e[31m<empty>$reset";
    }
    else {
        $str =~ s/(^\s+|\s+$)/"\e[31m" . ('_' x length($1)) . $reset/eg;
    }
    return $str;
}


sub _next {
    # Move to the next column in the current row
    my ($self) = @_;
    my $new_col = ++$self->{'c'};
    if (length($new_col) > 1) {
        # XXX Deal with AA, AB, etc.
        die "Biblio::COUNTER only supports reports with 26 columns or fewer";
    }
    return $self;
}

sub _in_scope {
    my ($self, $scope) = @_;
    $self->{'scope'} = $scope;
    return $self;
}

sub _in_field {
    my ($self, $field) = @_;
    $self->{'field'} = $field;
    return $self;
}

# --- Data fetching functions

sub _ref_to_cur_cell {
    # Return a reference to the datum in the current cell
    my ($self) = @_;
    my $c = $self->{'c'};
    my $row = $self->{'row'};
    my $ci = _col2idx($c);
    while ($ci >= @$row) {
        push @$row, '';
        $self->_cant_fix('<in existence>');
    }
    return \$row->[$ci];
}

# --- Callback-invoking methods

sub trigger_callback {
    my ($self, $name, @args) = @_;
    my $cb = $self->{'callback'};
    if ($cb->{$name}) {
        # Regular callback
        $cb->{$name}->($self, @args);
    }
    elsif ($cb->{'*'}) {
        # Fallback callback (got that?)
        $cb->{'*'}->($self, $name, @args);
    }
    return $self;
}

sub _ok {
    my ($self, $cur) = @_;
    $cur ||= $self->_ref_to_cur_cell;
    $self->trigger_callback('ok', $self->{'field'}, $$cur);
    return $self;
}

sub _fix {
    my ($self, $str) = @_;
    my $cur = $self->_ref_to_cur_cell;
    $self->trigger_callback('fixed', $self->{'field'}, $$cur, $str);
    $$cur = $str;
    $self->{'warnings'}++;
    return $self;
}

sub _cant_fix {
    my ($self, $expected) = @_;
    my $cur = $self->_ref_to_cur_cell;
    my $field = $self->{'field'};
    $expected = "<$field>" unless defined $expected;
    $self->trigger_callback('cant_fix', $field, $$cur, $expected);
    $self->{'errors'}++;
    return $self;
}

sub _trim {
    my ($self, $cur) = @_;
    $cur ||= $self->_ref_to_cur_cell;
    if ($$cur =~ s/^\s+|\s+$//g) {
        $self->_trimmed($cur);
    }
    return $self;
}

sub _trimmed {
    my ($self, $cur) = @_;
    $cur ||= $self->_ref_to_cur_cell;
    $self->trigger_callback('trimmed', $self->{'field'}, $$cur);
    $self->{'warnings'}++;
    return $self;
}

sub parse_period {
    my ($self, $str) = @_;
    if ($str =~ /^(?:($rx_mon)-($rx_year)|($rx_year)-($rx_mon))$/ig) {
        my ($m, $y) = $1 ? ($1, $2) : ($4, $3);
        my $period = _normalize_mon($m) . '-' . _normalize_yyyy($y);
        my $normalized_period = $y . '-' . ($mon2num{lc $m} || $m);
        if ($period eq $str) {
            return (VALID, $period, $normalized_period);
        }
        else {
            return (FIXED, $period, $normalized_period);
        }
    }
    return (INVALID);
}

sub _normalize_mon {
    my ($m) = @_;
    if ($m =~ /^\d/) {
        return $num2mon[$m];
    }
    else {
        return ucfirst lc substr($m, 0, 3);
    }
}

sub _normalize_yyyy {
    my ($y) = @_;
    if (length($y) == 2) {
        # We ignore 1999 and earlier
        return 2000 + $y;
    }
    else {
        return $y;
    }
}

# --- Utility functions

sub _str2rx {
    my ($str) = @_;
    my $rx = quotemeta lc $str;
    return qr/$rx/;
}

sub _col2idx {
    my ($c) = @_;
    return ord($c) - ord('A');
}


1;


=pod

=head1 NAME

Biblio::COUNTER::Report - a COUNTER-compliant (or not) report

=head1 SYNOPSIS

    $report = Biblio::COUNTER::Report->new(
        'file' => $file,
    );

=head1 DESCRIPTION

=head1 PUBLIC METHODS

=cut

