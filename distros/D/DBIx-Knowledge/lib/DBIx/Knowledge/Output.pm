#
# $Id: Output.pm,v 1.4 2005/07/14 20:26:15 scottb Exp $
#


package DBIx::Knowledge::Output;

use strict;
use DBIx::Knowledge;
use HTML::Entities;
use DBI;

=head1 NAME

DBIx::Knowledge::Output - Output generator (HTML currently)

=cut

sub new
{
    my ($caller,$header_repeat) = @_;

    my $class = ref($caller) || $caller;
    my $obj = {};

    $obj->{header_repeat} = $header_repeat;

    return bless($obj,$class);
}

sub generate_html
{
    my ($self,$report_sth,$select_fields,$want_subtotal_fields) = @_;
    $want_subtotal_fields ||= {};
    
    my $html = <<HTML;
<TABLE class="report_data" border="0" cellpadding="3" cellspacing="0">
<TR>
HTML

    $html .= header_row_html($select_fields);

    my $last_was_group = 1;
    my @recent_row = ();
    my $grouping_id = 0;
    my $want_sub = scalar(%$want_subtotal_fields);
    my @sum_row = ();
    while (my @row = $report_sth->fetchrow_array)
    {

        # The class will always add a psuedo-column to the result set at the end which is the GROUPING_ID() but only if subtotal fields were requested
        $grouping_id = pop(@row) if $want_sub;

        if ($want_sub && $grouping_id != 0)
        {
            my $field_text;
            my $field_position;
            my $html_class;
            my $grouping_advice = $want_subtotal_fields->{$grouping_id};
            if ($grouping_advice->{FIELD_ID} eq $DBIx::Knowledge::REPORT_TOTAL_KEY)
            {
                $field_text = 'Report Summary';
                $field_position = 0;
                $html_class = 'report_summary';
                @sum_row = @row;
                $sum_row[0] = 'Report Summary';
                next;
            }
            else
            {
                $field_text = "Summary for " . $recent_row[$grouping_advice->{POSITION}];
                $field_text .= aux_info_text(\@row,$select_fields);             
                $field_position = $grouping_advice->{POSITION};
                $html_class = "data_subtotal$grouping_advice->{SUBTOTAL_RANK}";
            }
            $row[$field_position] = $field_text;
            $html .= data_row_html(\@row,$select_fields,$html_class,\@recent_row);
            $html .= header_row_html($select_fields) if $self->{header_repeat};
            $last_was_group = 1;
        }
        else
        {
            if ($last_was_group)
            {
                @recent_row = @row;
            }
            my $recent = undef;
            $recent = $last_was_group ? [] : \@recent_row if $want_sub;
##at watch oblique dependency for html_class arg (should be undef)
            $html .= data_row_html(\@row,$select_fields,undef,$recent);
            $last_was_group = 0;
        }
        @recent_row = @row;
    }
    if (@sum_row)
    {
        $html .= data_row_html(\@sum_row,$select_fields,'report_summary');
    }
    return undef if $report_sth->err;

    $html .= qq[</TABLE>\n];

    return \$html;
}

sub header_row_html
{

    my $header_fields = shift;

    my $html = "<TR>\n";
    foreach my $header_field (@$header_fields)
    {

        # Don't output and aux_info fields.  These fields are only to
        # be added to a summary row.
        unless ($header_field->{aux_info}) {
            $html .= "<TH>" . encode_entities($header_field->{header}) . "</TH>";
        }
    }
    $html .= "</TR>\n";

    return $html;

}

sub data_row_html
{
    my ($row,$select_fields,$html_class,$recent_row) = @_;
    my $class = '';
    $class = qq[ class="$html_class" ] if defined($html_class);
    my $html = "<TR$class>";
    my $i = 0;

    # If this row only contains aux_info data suppress it - but only
    # if this is not a summary row.  We can tell if this is a summary
    # row because $html_class is currently only defined for summary rows.
    if (is_aux_info_row($row,$select_fields) && !defined $html_class)    
    {
       return '';
    }

    foreach my $val_orig (@$row)
    {

        # Do not output an aux info fields
        if ($select_fields->[$i]{aux_info}) {
            $i++;
            next;
        }

        my $val = $val_orig; # Copy, don't modify ref
        if (ref($recent_row))
        {
            my $prev_val = $recent_row->[$i];
            $val = '' if $prev_val eq $val && $select_fields->[$i]{no_repeat} && ($i == 0 || $i == 1);
        }

        if (length($val))
        {
            $val = encode_entities($val);
            # After escaping turn any newlines into HTML <br/> tags
            $val =~ s|\n|<br/>|gs;
        }
        else
        {
            $val = '&nbsp;';
        }

        my $classes = $select_fields->[$i]{html_class} || [];
        if (($html_class =~ /^data_subtotal/ || $html_class eq 'report_summary') && ($val =~ /^Summary for / || $val eq 'Report Summary'))
        {
            push(@$classes,'subtotal_label');
        }
        my $td_class = '';
        $td_class = qq[class="] . join(' ',@$classes) . qq["] if ref($classes);
        $html .= qq[<TD $td_class ] . (ref($select_fields->[$i]{td_attr}) ? join(' ',@{$select_fields->[$i]{td_attr}}) : '') . qq[>$val</TD>];
        $i++;
    }
    $html .= "</TR>\n";
    return $html;
}

# Extract the aux info summary information and return a string that
# can be added to the report summary row. Search the query select
# fields looking for an aux_info marker.  If found output the select
# header and corresponding value from the db result row. Arguments are
# a reference to an array of row values returned from the db and a
# reference to an array of the query select fields.
sub aux_info_text
{
    my ($select_data, $select_fields) = @_;
    my $aux_info_string = '';

    for (my $i=0; $i < scalar(@$select_fields); $i++) {
        my $select_field = $select_fields->[$i];
        if ($select_field->{aux_info}) {
            $aux_info_string .= sprintf("\n %s %s", 
                                        $select_field->{header}, 
                                        $select_data->[$i]);
        }
    }
            
    return $aux_info_string;
}

# Check a database row to see if it contains the data for an aux_info
# column.  Normally these rows should not be displayed in the report
# body but the value in the aux_info column is appended to the summary
# text in the summary row.  The test is not rigorous. First find if
# any aux_info_fields are defined, if so collect them.  Then check
# each element of the db_row array corresponding to an an aux_info
# column and see if the element in that position is not numerically 0.
# If the value is non-zero, consider this db_row an aux_info row and
# return true.  Arguments are an array ref to a database row and an
# array ref containing the query select fields.
sub is_aux_info_row
{
    my ($db_row, $select_fields) = @_;
##at this is a constant - should be populated once, not every time in this loop
    my @aux_info_fields = ();
    my $col;
    for ($col=0; $col<scalar(@$select_fields); $col++)
    {
        push(@aux_info_fields, $col) if $select_fields->[$col]{aux_info};
    }

    foreach $col (@aux_info_fields)
    {
        if ($db_row->[$col] != 0)
        {
            return 1;
        }
    }

    return 0;
}


1;

__END__


=head1 SEE ALSO

L<DBIx::Knowledge::Report>, SmartCruddy! L<http://www.thesmbexchange.com/smartcruddy/index.html>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

