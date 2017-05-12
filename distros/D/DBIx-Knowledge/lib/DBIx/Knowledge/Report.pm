#
# $Id: Report.pm,v 1.12 2006/04/17 00:19:04 dennisl Exp $
#


package DBIx::Knowledge::Report;

use vars qw(%allowed_crit_fields %np_allowed_crit_fields);

use strict;
use CGI::AutoForm;
use DBIx::IO::Search;
use DBIx::IO::GenLib ();
use POSIX ();
use DBIx::Knowledge;
use DBIx::Knowledge::Output;
use CGI::CRUD::TableIO;

use constant OK => 0;

$DBIx::Knowledge::Report::REPORT_SELECT_LIST_TABLE_NAME = 'dbix_knowledge_data_point';

my $potential_select_fields;
##at anyway to make this readonly?
my %potential_select_fields_by_id;
##at anyway to make this readonly?
my %potential_select_fields_by_order_legend;

my $title_field = {
    FIELD_NAME => 'REPORT_TITLE',
    INPUT_CONTROL_TYPE => 'TEXT',
    SEARCH_CONTROL_TYPE => 'TEXT',
    HEADING => 'Report title',
    DATATYPE => 'CHAR',
    REQUIRED => 'N',
    INSERTABLE => 'Y',
    SEARCHABLE => 'Y',
    HELP_SUMMARY => 'Title of this report',
};

# I've been working on some Business Intelligence libraries for data sets that exhibit Linear Convergence and was able to acheive such a convergence temporally (over an axis of time) for much of the data in OP with the help of some key data aggregation
##at should use NULLIF(poa.preopt_priority,0), NULLIF(poa.opt_priority_override,0), NULLIF(o.opt_priority_override,0), etc...
my $select_field = {
    FIELD_NAME => 'SELECT_FIELD',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
    SEARCH_MULT_SELECT => 7,
    HEADING => 'Report on',
    DATATYPE => 'CHAR',
    REQUIRED => 'Y',
    INSERTABLE => 'Y',
    SEARCHABLE => 'Y',
    HELP_SUMMARY => <<EOH,
Choose the data points to include
in this report.
EOH
};

##at anyway to make this readonly?
my @select_field_picklist = ();
##at anyway to make this readonly?
my @np_select_field_picklist = ();

my $subtotal_field = {
    FIELD_NAME => 'SUBTOTAL_FIELD',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
    SEARCH_MULT_SELECT => 4,
    HEADING => 'Summary totals on',
    DATATYPE => 'CHAR',
    REQUIRED => 'N',
    INSERTABLE => 'Y',
    SEARCHABLE => 'Y',
    HELP_SUMMARY => <<EOH,
Choose which data points will have
subtotal summary lines. Must be a
subset of the fields selected above.
EOH
};

##at anyway to make this readonly?
my @subtotal_field_picklist;

##at anyway to make this readonly?
my @np_subtotal_field_picklist = ();

my $aux_info_field = {
    FIELD_NAME => 'AUX_INFO_FIELD',
    INPUT_CONTROL_TYPE => 'SELECT',
    SEARCH_CONTROL_TYPE => 'SELECT',
    SEARCH_MULT_SELECT => 4,
    HEADING => 'Auxiliary info fields',
    DATATYPE => 'CHAR',
    REQUIRED => 'N',
    INSERTABLE => 'Y',
    SEARCHABLE => 'Y',
    HELP_SUMMARY => <<EOH,
For advanced use only.
EOH
};

my $head_repeat_field = {
    FIELD_NAME => 'HEADER_REPEAT',
    INPUT_CONTROL_TYPE => 'RADIO',
    SEARCH_CONTROL_TYPE => 'RADIO',
    HEADING => 'Repeat header on subtotals',
    DATATYPE => 'CHAR',
    DEFAULT_VALUE => '0',
    REQUIRED => 'N',
    INSERTABLE => 'Y',
    SEARCHABLE => 'Y',
    HELP_SUMMARY => <<EOH,
Repeat field headers for
every subtotal row?
EOH
};

my $head_repeat_picklist = [
    { ID => 0, MASK => 'No', },
    { ID => 1, MASK => 'Yes', },
];

my $orderby_field = {
    FIELD_NAME => 'ORDER_FIELD',
    INPUT_CONTROL_TYPE => 'TEXT',
    SEARCH_CONTROL_TYPE => 'TEXT',
    SEARCH_MULT_SELECT => 4,
    HEADING => 'Order by',
    DATATYPE => 'CHAR',
    REQUIRED => 'N',
    INSERTABLE => 'Y',
    SEARCHABLE => 'Y',
    INPUT_SIZE => 50,
    INPUT_MAXLENGTH => 200,
    HELP_SUMMARY => <<EOH,
For each data point selected above,
there is an abbreviation of the field in
parenthesis. Use those abbreviations
here separated by commas to
override the default ordering of
this report. The word "desc"
may be appended to each abbreviation
to specify order polarity.
EOH
};

my $limit_field = {
    FIELD_NAME => 'RESULT_LIMIT',
    INPUT_CONTROL_TYPE => 'TEXT',
    SEARCH_CONTROL_TYPE => 'TEXT',
    HEADING => 'Limit result set',
    DATATYPE => 'INT UNSIGNED',
    REQUIRED => 'N',
    INSERTABLE => 'Y',
    SEARCHABLE => 'Y',
    INPUT_SIZE => 6,
    INPUT_MAXLENGTH => 10,
    HELP_SUMMARY => <<EOH,
Limit the result set to this number
of rows.
EOH
};

=head1 NAME

DBIx::Knowledge::Report - Handler routines to serve report builder form and report execution

=head1 SYNOPSIS

 use DBIx::Knowledge::Report;
 use CGI::CRUD::SkipperOutput;

 # Example implementation in mod_perl
 $crud = new CGI::CRUD::SkipperOutput($r) or return OK;
 $report = new DBIx::Knowledge::Report($crud,'PROCESS_LOAD_LOG') or return OK;
 $report->select_list_from_table() or return OK;
 return $report->take_action();

=head1 DESCRIPTION

Provides methods to display a report builder form and to execute the reports. To be run in the context
of a webserver.

See SmartCruddy! L<http://www.thesmbexchange.com/smartcruddy/> for more info and an implementation.

=head1 DETAILS

=head2 Linear convergent data sets

Your data set must be in a form that can be grouped by a set of fields. An example
may be as simple as a table populated with webserver log records. This table can be aggregated by the timestamp field
of the webserver request (say you want to report on the number of hits to /index.html from 9am to 10am)
and will fit nicely into a model that can readily be used by this abstraction.

This may be accomplished by creating views or semi-aggregated tables (materialized views) usually along
an axis of time (temporal linear convergence). Semi-aggregated tables are useful for reducing the size of very large data sets
aggregated by key fields analysts might be interested in so they can be queried efficiently in real-time.

=head2 Data point definitions

Once you have an appropriate table or view to build reports from (see L<Linear convergent data sets>) you'll need to define
a set of data points the report builder can present.
A data point may be a field in the table or view or a derivative of field(s), essentially any valid expression in a 
select list of an SQL SELECT statement. Example:

SELECT request_date, TO_CHAR(request_date, 'YYYY') FROM...

represents two data points.

CAREFUL! the terms "field" and "data point" may be used interchangeably below but they are not the same thing (the author
will try to avoid such confusion).

These data point
definitions may exist in a table C<DBIX_KNOWLEDGE_DATA_POINT> so they can be managed easily (probably
by data analysts, preferably someone who knows SQL). Each record in the table defines a data point and
each column is explained below:

=over 2

=item TABLE_NAME

Name of table or view. Name doesn't actually have to refer to an object in the database, this is a way to identify a group
of data points and this name will be passed to methods in this class. Syntax rules for general identifiers apply - no whitespace, alphanumeric characters only,
may want to use ALL CAPS for consistency.
E.g. APACHE_LOG

=item FIELD_NAME

Name of the data point - don't confuse this with an actual column name in a table or view, although they may be the same. The
syntax rules for general identifiers apply - no whitespace, alphanumeric characters only, may want to use ALL CAPS for consistency.
E.g. REQUEST_YEAR

=item APPEAR_ORDER

Ordering of the data points as they will appear in the report builder form and the final report. I recommend spacing by 10 (10, 20, 30, etc).

=item HEADER

Friendly name of C<FIELD_NAME> that will appear in the report builder and reports.

=item SELECT_SQL

Valid SQL that will appear in the select list of a SELECT statement (example above).
This is how the data point will appear in the report so any formatting should happen here.

=item ORDER_LEGEND

Another alias for the data point name, this will appear in the report builder and allows the report ordering
to be modified by specifying a comma-separated list of these aliases in the "Order by" box of the report builder. The reason for another set of aliases
is an abbreviation of C<HEADER> with stricter syntax that can be easily parsed when comma-separated.

The syntax rules for general identifiers apply - no whitespace, alphabetic characters only. Additionally, THESE MUST BE IN ALL CAPS.

When using these aliases in the "Order by" box, each may be appended with "desc" to specify order polarity.

=item ORDER_BY_SQL

Allows you to achieve an ordering in the report for this data point different from how it would
order by in its appearance in the report (C<SELECT_SQL>). Example is for formatted dates where

SELECT_SQL = TO_CHAR(base_hour,'MM/DD/YY')

You'll want to order this field chronologically:

ORDER_BY_SQL = TO_CHAR(base_hour,'YYYYMMDD')

or simply

ORDER_BY_SQL = base_hour

=item GROUP_BY_EXPR

Evaluated as a perl boolean as to whether or not this data point (C<SELECT_SQL>) is a group by expression (e.g. SUM(error_count) IS a group by expression).

=item GROUP_BY_SQL

If this data point is a group by expression and the C<SELECT_SQL> expression references fields that are not part of the group by expression, they must appear here
so they are included in the GROUP BY clause. The field name(s) must be enclosed in quotes; multiple field names may be entered separated by commas. Example:

SELECT_SQL = TO_CHAR((payin_amt - payout_amt) * SUM(export_count),'L99,990.99')

The payin_amt and payout_amt fields are not part of any group by functions, so:

GROUP_BY_SQL = 'payin_amt', 'payout_amt'

=item NO_DEFAULT_ORDER_BY

The default ordering of the report is used if the "Order by" box is empty in the report builder. The default ordering uses the list of data points
that are NOT group by expressions, (non-group by expressions are the ones that will appear in the GROUP BY clause) unless C<NO_DEFAULT_ORDER_BY> evaluates
true as a perl boolean.

=item NO_REPEAT

To make the report look cleaner, within subgroups the name of this data point will only appear in the first line of many.

=item HTML_CLASS

HTML classes that will be prepended to those assigned to the E<lt>tdE<gt> element (see L<CSS>).
Class name(s) must be enclosed in quotes; multiple class names may be entered separated by commas. Example:

HTML_CLASS = 'revenue', 'data_align_right'

=item NP_ALLOW

Advanced: For authenticated users in the "np" group, this data point will appear
in reports if C<NP_ALLOW> evaluates to true as a perl boolean.

=item NP_HEADER

Advanced: For authenticated users in the "np" group, an alternate friendly name that will appear in reports.

=back

You may also pass an array of hash references to the constructor instead of managing records in C<DBIX_KNOWLEDGE_DATA_POINT>.
Each hash having key/value pairs corresponding to a record as described above with the following
differences:

TABLE_NAME is not needed (the array is the group). Rename `FIELD_NAME' to `ID' (UPPER CASE). All other field names must be lower case
as keys in each hash. This array is passed to the constructor.

=head2 Report Builder

Once the data points have been defined, you will be able to build a report. The first screen presented by the L<take_action> method will be
a report builder form. The first section lets you add a title,
pick the fields to report on, which fields to subtotal, specify repeated headings, auxiliary fields (advanced, see the code),
override ordering and set result
limits. The next section of the form allows you to set criteria on the result set.

=head2 CSS

Class attributes are hooked into the HTML that is generated to allow custom styling with CSS.
The following is a list of class names and how/where they influence the presentation.

=over

=item report_data

All C<table> elements are tagged with this class.

=item report_summary

The final C<tr> element is tagged with this class if a grand total report summary is requested.

=item data_subtotalX

Where X is an integer indicating the subtotal rank or nesting level. C<tr> elements on summary (subtotal) rows are tagged with this
class, the name of which varies depending on the nesting level or subtotal rank. Example: if you subtotal on year/month/day, the
yearly subtotal row C<tr> element will be tagged with a class named C<data_subtotal1>, month with C<data_subtotal2>, etc.

=item subtotal_label

C<td> elements are tagged with this class only if they follow C<tr> elements tagged with a C<data_subtotalX> or C<report_summary> classes.
These fields normally won't contain data, just a label indicating this row is a summary row.

=item custom HTML_CLASS

C<td> elements of data points with C<HTML_CLASS> populated (see above) are tagged with a set of classes prepended with the class(es) appearing in C<HTML_CLASS>.

=back

=head2 Saving and editing reports

At the bottom of every report generated are two links.

=over

=item Save report URL for later

If you right click this link in most browsers you should have the option to copy the URL link location. You can then past it in an HTML
document and anchor it, etc.

=item Further customize this report

This link will take you to the report builder with all parameters saved and pre-selected.

=back


=head1 METHOD DETAILS

=over 4

=item C<new> (constructor)

 $report = new DBIx::Knowledge::Report($crud_output, $report_table_name[, $data_points, $cache_list]);

Create a $report object where $crud_output is a L<CGI::CRUD> output object and $report_table_name
is the name of the table or view to be reported upon.
An optional array reference $data_points may be given as described in L<Data point definitions>,
otherwise you must invoke C<select_list_from_table()>.
Optional boolean $cache_list will cache the data point list.

Upon error, C<server_error()> will be called on $crud_output and undef will be returned.

=cut

sub new
{
    my $caller = shift;

    my ($output,$report_table_name,$potential_select_fields_in,$cache_list) = @_;

    my $self = {
        report_table_name => $report_table_name,
        output => $output,
    };

    create_select_list($potential_select_fields_in,$cache_list) if defined($potential_select_fields_in);

    my $class = ref($caller) || $caller;
    bless($self,$class);

    my $sqlclass = $self->_pull_driver($output->dbh());
    ($output->server_error(),return undef) unless defined($sqlclass);

    $self->{sql_gen} = $sqlclass->new();
    
    return $self;
}

sub _pull_driver
{
    my ($caller,$dbh) = @_;

    return $caller->{sqlclass} if ref($caller) && defined($caller->{sqlclass});

    # SQL classes must be named after the DBI driver name
    my $sqlclass = "DBIx::Knowledge::$dbh->{Driver}{Name}SQL";
    eval qq(require $sqlclass) || (warn("Database driver not supported"),return undef);

    $caller->{sqlclass} = $sqlclass if ref($caller);
    return $sqlclass;
}

sub create_select_list
{
    my ($potential_select_fields_in,$cache_list) = @_;
    return 1 if $cache_list && $potential_select_fields;

    $potential_select_fields = $potential_select_fields_in;

    %potential_select_fields_by_id = ();
    %potential_select_fields_by_order_legend = ();
    @select_field_picklist = ();
    @np_select_field_picklist = ();
    @subtotal_field_picklist = ();
    @np_subtotal_field_picklist = ();

    map { $potential_select_fields_by_id{$_->{ID}} = $_ } @$potential_select_fields;

    map { $potential_select_fields_by_order_legend{$_->{order_legend}} = $_ } @$potential_select_fields;
    @select_field_picklist = map({ ID => $_->{ID}, MASK => "$_->{header} ($_->{order_legend})" },@$potential_select_fields);
    map { push(@np_select_field_picklist,{ ID => $_->{ID}, MASK => ($_->{np_header} ? $_->{np_header} : $_->{header}) . ' ($_->{order_legend})' }) if $_->{np_allow} } @$potential_select_fields;
    map { push(@subtotal_field_picklist,
                {
                    ID => $_->{ID},
                    MASK => "$_->{header} ($_->{order_legend})"
                }
               )
            unless $_->{group_by_expr}
        }
        reverse @$potential_select_fields;
    push(@subtotal_field_picklist,{ ID => $DBIx::Knowledge::REPORT_TOTAL_KEY, MASK => 'Report grand total (GRANDTOT)' });
    map { push(@np_subtotal_field_picklist,
                {
                    ID => $_->{ID},
                    MASK => "$_->{header} ($_->{order_legend})"
                }
               )
            if $_->{np_allow} && !$_->{group_by_expr}
        }
        reverse @$potential_select_fields;
    push(@np_subtotal_field_picklist,{ ID => $DBIx::Knowledge::REPORT_TOTAL_KEY, MASK => 'Report grand total (GRANDTOT)' });
}

=pod

=item C<select_list_from_table>

 $bool = $report->select_list_from_table([$report_table_name, $cache_list, $dbh, $select_field_table_name]);

Retrieve the list of data points for report building from a database table.
Optional $report_table_name overrides the same parameter given to the constructor only for the purpose of identifying the group of datapoints by matching the C<TABLE_NAME>
column in the data points table. 
Boolean $cache_list will cache the data point list, $dbh is an appropriate DBI database handle.
The table that stores the data points may be given by
$select_field_table_name table, which defaults to $DBIx::Knowledge::Report::REPORT_SELECT_LIST_TABLE_NAME.

Upon error, C<server_error()> or C<perror> will be called on $crud_output and false will be returned, otherwise return true.

=cut

sub select_list_from_table
{
    my ($self,$report_table_name,$cache_list,$dbh,$select_field_table_name) = @_;
    return 1 if $cache_list && $potential_select_fields;

    my @select_list;

    $dbh ||= $self->{output}->dbh();
    $report_table_name ||= $self->{report_table_name};
    $select_field_table_name ||= $DBIx::Knowledge::Report::REPORT_SELECT_LIST_TABLE_NAME;

    my $searcher = new DBIx::IO::Search($dbh,$select_field_table_name);
    my $recs;
    if (ref($searcher))
    {
        $searcher->build_scalar_crit('TABLE_NAME','=',$report_table_name);
        $recs = $searcher->search(undef,[ 'APPEAR_ORDER' ]) || return undef;
    }
    elsif (!defined($searcher))
    {
        $self->{output}->server_error();
        return undef;
    }
    elsif (!$searcher)
    {
        warn("$report_table_name does not seem to exist so no select list could be found");
        return 1;
    }
    else
    {
        die("A horrible death");
    }

    foreach my $rec (@$recs)
    {
        my ($k,$v);
        my %select_attrs;
        while (($k,$v) = each(%$rec))
        {
            if ($k eq 'GROUP_BY_SQL' || $k eq 'HTML_CLASS')
            {
                eval("\$select_attrs{lc(\$k)} = [ $v ];") if length($v);
                if ($@)
                {
                    $self->{output}->perror("parse error for value found in $report_table_name.$k [$v]");
                    return 0;
                }
            }
            elsif ($k eq 'FIELD_NAME')
            {
                $select_attrs{ID} = $v;
            }
            else
            {
                $select_attrs{lc($k)} = $v;
            }
        }
        push(@select_list,\%select_attrs);
    }

    create_select_list(\@select_list);

    return 1;
}

=pod

=item C<take_action>

 $status = $report->take_action();

Call within a webserver context to display a report builder form or execute and display report results.
May return an error page if there are any problems along the way.

Return 0 (equivalent to Apache status code `OK').

=cut

sub take_action
{
    my ($self) = @_;
    my $r = $self->{output};
    my $action = $r->param('__SDAT_TAB_ACTION.ACTION') || '';

    if ($action eq 'RR')
    {
        $self->report_results($r);
    }
    else
    {
        $self->report_defn_request($r);
    }
    return OK;
}

sub report_defn_form
{
    my ($self,$r) = @_;
    my $form = $r->form($r->dbh());
    $form->action($self->{action});
    $form->heading($self->{form_heading} || 'Custom Reports');
    $form->submit_value('Report');

    $form->add_group('SEARCHABLE',undef,'Data Points','FORMAT');
    my $select_pick;
    my $subtotal_pick;
    if (length($r->{np_uname}))
    {
        $select_pick = \@np_select_field_picklist;
        $subtotal_pick = \@np_subtotal_field_picklist;
    }
    else
    {
        $select_pick = \@select_field_picklist;
        $subtotal_pick = \@subtotal_field_picklist;
    }

    $form->add_field($title_field);

    $form->add_field($select_field,$select_pick);
    my $field = $form->field_by_name('SELECT_FIELD');
    $field->{REQUIRED} = 'Y';
    $form->add_field($subtotal_field,$subtotal_pick);

    $form->add_field($head_repeat_field,$head_repeat_picklist);
    my $q = $r->query();
    $q->{'FORMAT.HEADER_REPEAT'} = '0' unless length($q->{'FORMAT.HEADER_REPEAT'});

    $form->add_field($aux_info_field,$select_pick);
    $form->add_field($orderby_field);
    $form->add_field($limit_field);
    
    $r->graceful_add_form_group($form,'SEARCHABLE',$self->{report_table_name},'Result Criteria','CRITERIA') or return undef;

    # disallow some criteria fields for network partner report
    if (length($r->{np_uname}))
    {
        my $fields = $form->field_list();
        my @fields_s = @$fields;
        foreach my $field (@fields_s)
        {
            $form->delete_field($field->{FIELD_NAME}) unless $np_allowed_crit_fields{$field->{FIELD_NAME}};
        }
    }
    $form->reset_group();
    
    return $form;
}

sub report_defn_request
{
    my ($self,$r) = @_;
    my $form = $self->report_defn_form($r) or return undef;
    my $q = $r->query();
    $q->{'__SDAT_TAB_ACTION.ACTION'} = 'RR';
    $r->output($form->prepare($q),($ENV{SMARTCRUDDY_FAST_TEMPLATE_MAIN} || 'smartcruddy.tpl'));
}

sub report_results
{
    my ($self,$r) = @_;
    
    # keep in mind this is NOT normalized or unescaped until later
    my $q = $r->query();

    $r->{tpl_vars}{REPORT_TITLE} = $q->{'FORMAT.REPORT_TITLE'} || 'Custom Report';
##at should use $r->{apache}->request_time()
    $r->{tpl_vars}{REPORT_DATE} = POSIX::strftime('%c',localtime());

    my $form = $self->report_defn_form($r) || return undef;
    unless ($form->validate_query($q))
    {
        $r->output($form->prepare($q),($ENV{SMARTCRUDDY_FAST_TEMPLATE_MAIN} || 'smartcruddy.tpl'));
        return OK;
    }

    $q = $form->format_query($r->query());

    my $tq = $r->query();
    $r->{tpl_vars}{FULL_SAVED_QUERY} = CGI::CRUD::TableIO::stringify_query($tq);
    $tq = { %$tq };
    delete($tq->{'__SDAT_TAB_ACTION.ACTION'});
    $r->{tpl_vars}{CUSTOM_SAVED_QUERY} = CGI::CRUD::TableIO::stringify_query($tq);

    my $select_fields_q = $q->{FORMAT}{SELECT_FIELD};
    $select_fields_q = [ $select_fields_q ] unless ref($select_fields_q);
    my %select_fields_q;
    @select_fields_q{ @$select_fields_q } = (1) x @$select_fields_q;
    my @select_fields = ();

    if (length($r->{np_uname})) 
    {
        foreach my $item (@np_select_field_picklist) 
        {
            if ($select_fields_q{$item->{ID}}) 
            {
                my %f = %{$potential_select_fields_by_id{$item->{ID}}}; 
                # overwrite header with np_header for np report
                $f{header} = $f{np_header} if ($f{np_header}); 
                push(@select_fields, \%f);
            }
        }
    }
    else 
    {
        map { push(@select_fields,$potential_select_fields_by_id{$_->{ID}}) if $select_fields_q{$_->{ID}} } @select_field_picklist;
    }

    my $subtotal_fields_q = $q->{FORMAT}{SUBTOTAL_FIELD};
    my @subtotal_fields = ();
    if ($subtotal_fields_q)
    {
        $subtotal_fields_q = [ $subtotal_fields_q ] unless ref($subtotal_fields_q);
        my %subtotal_fields_q;
        @subtotal_fields_q{ @$subtotal_fields_q } = (1) x @$subtotal_fields_q;
        map { ($r->perror("'Summary totals on' fields must be a subset of the 'Report on' fields [$_ is not], please try again"),return undef)
            unless exists($select_fields_q{$_}) || $_ eq $DBIx::Knowledge::REPORT_TOTAL_KEY } @$subtotal_fields_q;
        map { push(@subtotal_fields,$_->{ID}) if $subtotal_fields_q{$_->{ID}} } @subtotal_field_picklist;
##at on freeform field, please mind the LEGEND key 'GRANDTOT'
    }

##at by default, results will be sorted in the same order as the order of the select list
    my $orderby_q = $q->{FORMAT}{ORDER_FIELD};
    my @order_fields = ();
    if (length($orderby_q))
    {
        foreach my $order_term (split(/\s*,\s*/,$orderby_q))
        {
            my $desc_needed = $order_term =~ s/\s+desc//i;
            $order_term = uc($order_term);
##at should be done in validate_query()
            ($r->perror("Invalid term entered in 'Order by' sequence [$order_term], please go back and correct"),return undef)
                unless exists($potential_select_fields_by_order_legend{$order_term});
            my $term_id = $potential_select_fields_by_order_legend{$order_term};
            ($r->perror("'Ordered by' fields must be a subset of the 'Report on' fields [$order_term is not], please try again"),return undef)
                unless exists($select_fields_q{$term_id->{ID}});
            my %order_field = ( %{$term_id} );
            $order_field{descending_order} = $desc_needed;
            push(@order_fields,\%order_field) unless length($r->{np_uname}) && !$term_id->{np_allow};
        }
    }

    my $result_limit = $q->{FORMAT}{RESULT_LIMIT};

    my $where_sql = '';
    if ($q->{CRITERIA})
    {
        my $crit = $q->{CRITERIA};
        my @keys = keys(%$crit);
        foreach my $key (@keys)
        {
            delete($crit->{$key}) if length($r->{np_uname}) && !$np_allowed_crit_fields{$key};
        }
        $crit->{NP_USERNAME} = $r->{np_uname} if length($r->{np_uname});
        my $where = new CGI::CRUD::TableIO($r->dbh());
        $where_sql = $where->where_sql($crit,$self->{report_table_name});
        defined($where_sql) or ($r->server_error(),return undef);
    }

    my %want_subtotal_fields = ();

    my $sql = $self->{sql_gen}->sql_rollup($self->{report_table_name},\@select_fields,$where_sql,\@subtotal_fields,\@order_fields,\%want_subtotal_fields) or
        ($r->perror("Report definition is invalid:<br>$self->{sql_gen}->{errstr}<br>Please go back and try again"),return undef);

    my $dbh = $r->dbh();
    my $report_sth = $dbh->prepare($sql) or ($r->perror("Report definition is invalid, please go back and try again"),return undef);
    $report_sth->execute() or ($r->server_error(),return undef);

    my $title = CGI::AutoForm->escape($r->{tpl_vars}{REPORT_TITLE});
    my $tdate = CGI::AutoForm->escape($r->{tpl_vars}{REPORT_DATE});
    
    my $html = <<HTML;
<H3 style="padding-bottom:0px;margin-bottom:0px;margin-top: 10px;">$title</H3>
<p style="padding-top:0px;margin-top:0px;">Report created $tdate</p>
HTML

    my $aux_info_fields = $q->{FORMAT}{AUX_INFO_FIELD};
    $aux_info_fields = [ $aux_info_fields ] unless ref $aux_info_fields;

    mark_aux_fields(\@select_fields, $aux_info_fields);

    my $out = new DBIx::Knowledge::Output($q->{FORMAT}{HEADER_REPEAT});
#OPDebugUtil::ddump(\@select_fields);
    my $outp = $out->generate_html($report_sth,\@select_fields,\%want_subtotal_fields) or ($r->server_error(),return undef);

    $html .= $$outp;
    
    $html .= <<HTML;
<p style="margin: 30px;">
<a href="$r->{action}?$r->{tpl_vars}{FULL_SAVED_QUERY}">Save report URL for later</a><br>
<a href="$r->{action}?$r->{tpl_vars}{CUSTOM_SAVED_QUERY}">Further customize this report</a>
</p>
HTML
    
    $r->{tpl_vars}{CSS_MAIN} = '/smartcruddy.css';
    $r->output($html,($ENV{SMARTCRUDDY_FAST_TEMPLATE_MAIN} || 'smartcruddy.tpl'));
}

# AUX_INFO_FIELD columns are not displayed in the report body but are
# shown in the summary rows.  We will mark all AUX_INFO_FIELDS here in
# this sub and the DBIx::Knowledge module will then act appropriately.
# Arguments are a reference to an array of query select fields and a
# reference to an array of the aux info field names.
sub mark_aux_fields
{
    my ($select_fields, $aux_fields) = @_;

    # clear aux_info flags. they could have been cached previously by mod_perl
    for my $se (@$select_fields) {
        $se->{aux_info} = 0;
    }

    # mark aux_info flags
    for my $aux (@$aux_fields) {
        for my $sel (@$select_fields) {
            if ($aux eq $sel->{ID}) {
                $sel->{aux_info} = 1;
            }
        }    
    }
}


=pod

=back

=cut

1;

__END__

=head1 BUGS

No known bugs.

=head1 SEE ALSO

L<DBIx::Knowledge>, L<CGI::CRUD>, L<CGI::AutoForm>, SmartCruddy! L<http://www.thesmbexchange.com/smartcruddy/index.html>, Cruddy! L<http://www.thesmbexchange.com/cruddy/index.html>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

