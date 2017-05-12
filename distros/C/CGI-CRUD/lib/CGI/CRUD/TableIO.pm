#
# $Id: TableIO.pm,v 1.3 2005/01/27 21:33:26 rsandberg Exp $
#


package CGI::CRUD::TableIO;

use strict;
use DBIx::IO::Search;
use DBIx::IO::Table;
use CGI::CRUD::Table;
use CGI::AutoForm;
use CGI::Enurl ();

use constant OK => 0;

=pod

=head1 NAME

CGI::CRUD::TableIO - Virtual base class for a basic web front-end to an RDBMS

=head1 DESCRIPTION

Virtual base class provides skeletal CRUD routines for a web front-end. Subclass/override/customize
to your heart's content. One popular method to override is C<verify_input>.

=cut

# ctor
sub new
{
    my ($caller,$dbh) = @_;

    my $class = ref($caller) || $caller;
    my $obj = { dbh => $dbh };

    $obj = bless($obj,$class);

    $obj->{verify_input} = sub { $obj->verify_input(@_); };
    return $obj;
}

# Build SQL for the search form submission
sub where_sql
{
    my ($self,$table_dat,$table_name) = @_;
    
    my $searcher = $self->build_search($table_dat,$table_name) or return undef;
    $searcher->_build_sql();
    return $searcher->{where} || 0;
}

# Build the DBIx::IO::Search object to assist with where_sql()
sub build_search
{
    my ($self,$table_dat,$table_name) = @_;
    
    my $searcher = new DBIx::IO::Search($self->{dbh},$table_name) or return undef;
    my ($field,$val);
    while (($field,$val) = each(%$table_dat))
    {
        next if !length($val);
        if (ref($val) eq 'ARRAY')
        {
            $searcher->build_list_crit($field,$val);
        }
        elsif (ref($val) eq 'HASH')
        {
            if (exists($val->{_WM}))
            {
                $searcher->build_scalar_crit($field,'LIKE',$val->{_WM});
            }
            elsif (exists($val->{_CL}))
            {
                $searcher->build_list_crit($field,[split(/,/,$val->{_CL})]);
            }
            else
            {
                # Expect 2 keys from this hash for date range values
                $searcher->build_range_crit($field,$val->{_RS},$val->{_RE}) 
                    if (($searcher->{io}->is_date($field) || $searcher->{io}->is_datetime($field)) ? $val->{_UR} : 1);
            }
        }
        else
        {
            $searcher->build_scalar_crit($field,'=',$val);
        }
    }
    
    return $searcher;
}

# Perform record deletion operation
sub delete_req
{
    my ($self,$r) = @_;
    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    my $q = $r->query();
    my ($table,$rec);
    my $sq = CGI::AutoForm->format_query($q);
    unless (($table = new DBIx::IO::Table($r->dbh(),undef,undef,$table_name)) && ($rec = $table->fetch($sq->{__SDAT}{KEYS})))
    {
        defined($rec) && ($r->output("Record no longer exists"),return OK);
        $r->server_error();
        return undef;
    }
    unless ($table->delete())
    {
        $r->server_error();
        return undef;
    }
    my $msg = qq[<P>Record Deleted</P>];
    $msg .= $self->return_results($q);
    $r->output($msg);
}

sub return_results
{
    my ($self,$fq) = @_;
    my $msg = qq[<P><TABLE WIDTH="100%"><TR>];
    my $q = CGI::AutoForm->extract_query_group($fq,'__SDAT_TAB_ACTION');
    $q->{'__SDAT_TAB_ACTION.ACTION'} = 'SD';
    my $stq = CGI::AutoForm->extract_cut_query_group($fq,'__SDAT.SC');
    my $sq = stringify_query({ %$q, %$stq });
    $msg .= qq[<TD><A HREF="$self->{action}?$sq">Return to search results<A></TD>];
    $msg .= $self->sreturn($q);
    $msg .= qq[</TR></TABLE></P>];
    return $msg;
}

sub sreturn
{
    my ($self,$q) = @_;
    my $msg;
    my $eq = CGI::AutoForm->extract_query_group($q,'__SDAT_TAB_ACTION');
    $eq->{'__SDAT_TAB_ACTION.ACTION'} = 'SR';
    my $sq = stringify_query($eq);
    $msg .= qq[<TD><A HREF="$self->{action}?$sq">New Search with $q->{'__SDAT_TAB_ACTION.TABLE_NAME'}<A></TD>];
    $eq->{'__SDAT_TAB_ACTION.ACTION'} = 'IR';
    $sq = stringify_query($eq);
    $msg .= qq[<TD><A HREF="$self->{action}?$sq">Add to $q->{'__SDAT_TAB_ACTION.TABLE_NAME'}<A></TD>];
    $eq->{'__SDAT_TAB_ACTION.RESTART'} = 1;
    $sq = stringify_query($eq);
    $msg .= qq[<TD><A HREF="$self->{action}?$sq">New DB Operation<A></TD>];
    return $msg;
}

sub new_start
{
    my ($self,$q) = @_;
    my $msg = qq[<P><TABLE WIDTH="100%"><TR>];
    $msg .= $self->sreturn($q);
    $msg .= qq[</TR></TABLE></P>];
    return $msg;
}

# Perform update operation

# special value of NULL still recognized, however its sufficient to have an empty new value
# where the existing value is not empty, this will update the value to NULL a little more risky but much more
# convenient because values of length < 4 (e.g. YORN and date elements) will have to be expanded to 4
# losing some ability to constrain the values
# THIS MEANS IT IS UP TO YOU TO REPRESENT ALL VALUES IN AN UPDATE, OTHERWISE THEY **WILL BE SET TO NULL**
# e.g. submit a full record to form->add_record and make sure field_template has *all* fields, either by
# completely relying on the data dictionary or inserting a record for all fields in UI_TABLE_COLUMN
sub update_data
{
    my ($self,$r) = @_;
    my $form = $self->update_form($r) || return undef;
    my $q = $r->query();
    my %vq = %$q;
    map { $vq{$_} =~ s/^NULL$// } keys(%vq);
    unless ($form->validate_query(\%vq,$self->{verify_input}))
    {
        $r->output($form->prepare($q));
        return OK;
    }

    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    my ($table,$rec);
    my $sq = $form->format_query($q);
    unless (($table = new CGI::CRUD::Table($r->dbh(),$r->user,undef,undef,$table_name)) && ($rec = $table->fetch($sq->{__SDAT}{KEYS})))
    {
        defined($rec) && ($r->output("Record no longer exists"),return OK);
        $r->server_error();
        return undef;
    }
    my $table_dat = $sq->{uc($table_name)};

    # a special value of 'NULL' updates a value to NULL
    map { $table_dat->{$_} =~ s/^NULL$// } keys(%$table_dat);
    map { $table_dat->{$_} = '' unless exists($table_dat->{$_}) } keys(%{$table->column_types()});
    unless ($table->update($table_dat))
    {
        $r->server_error();
        return undef;
    }
    my $msg = qq[<P>Record Updated</P>];
    $msg .= $self->return_results($q);
    $r->output($msg);
}

# Build update form
sub update_form
{
    my ($self,$r) = @_;
    my $form = $r->form($r->dbh());
    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    $form->heading("Update $table_name");
    $form->action($self->{action});
    $form->submit_value('Update');
    $r->graceful_add_form_group($form,'DISPLAY EDIT',$table_name,'Edit fields and submit when done') || return undef;
    return $form;
}

# Build/present update form
sub update_req
{
    my ($self,$r) = @_;
    my $form = $self->update_form($r) || return undef;
    my $q = $r->query();
    $q->{'__SDAT_TAB_ACTION.ACTION'} = 'UD';
    my $sq = $form->format_query($q);
    my ($table,$rec);
    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    unless (($table = new DBIx::IO::Table($r->dbh(),undef,undef,$table_name)) && ($rec = $table->fetch($sq->{__SDAT}{KEYS})))
    {
        defined($rec) && ($r->output("Record no longer exists"),return OK);
        $r->server_error();
        return undef;
    }
    $form->add_record($rec);
    $r->output($form->prepare($q));
}

# Perform search operation and return results
sub search_results
{
    my ($self,$r) = @_;
    
    # keep in mind this is NOT normalized or unescaped
    my $q = $r->query();
    my $form = $self->search_form($r) || return undef;
    unless ($form->validate_query($q))
    {
        $r->output($form->prepare($q));
        return OK;
    }

    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    $form = new CGI::AutoForm($r->dbh());
    $r->graceful_add_form_group($form,'DISPLAY ONLY',$table_name,"Searching...",undef,1) || return undef;
    $q = $form->format_query($r->query());
    my $table_dat = $q->{uc($table_name)};
    my $searcher = $self->build_search($table_dat,$table_name) or ($r->server_error(),return undef);
    my $field_list = $form->field_list();
    my $ffield;
    foreach my $f (@$field_list)
    {
        if (length($f->{BRIEF_HEADING}))
        {
            $ffield = $f->{FIELD_NAME};
            last;
        }
    }
    $searcher->sortlist([ $ffield ]);

    my $results = $searcher->search();
    unless ($results)
    {
        $r->server_error();
        return $results;
    }
    unless (@$results)
    {
        $r->output("No results found");
        return 1;
    }
    my $recno = scalar(@$results);
    my $recapp = ($recno > 1 ? 's' : '');

    my $keys = $searcher->{pk};
    my $warnk = '';
    unless (@$keys)
    {
##at could workaround this for Oracle by using ROWID
        #warn("search requested for a table with no primary key");
        $warnk = qq[<P><FONT COLOR="RED">View/Edit/Delete of individual records disabled because there is no primary key defined for this table.</FONT></P>];
    }

    $form->current_group()->{heading} = "Found $recno record$recapp.$warnk";
    $form->add_record($results);

    # requires that $table_name has a primary key (via DBIx::IO)

    my $tq = $form->extract_query_group($r->query(),uc($table_name));
    my $search_cache = stringify_query($tq,"__SDAT.SC");

    # make sure there are no closure issues with, for example, $searcher shouldn't be any with an anonymous sub
    my $rec_callback = sub
    {
        my ($rec_html,$rec,$group) = @_;
        my $add;
        my $etab = CGI::Enurl::enurl($table_name);
        my $qs = CGI::Enurl::enURL(qq[__SDAT_TAB_ACTION.TABLE_NAME=]) . CGI::Enurl::enurl($table_name) . '&';
        my $ur = CGI::Enurl::enURL(qq[__SDAT_TAB_ACTION.ACTION=UR&]);
        my $dr = CGI::Enurl::enURL(qq[__SDAT_TAB_ACTION.ACTION=DR&]);
        foreach my $key (@$keys)
        {
            $qs .= CGI::Enurl::enurl("__SDAT.KEYS.$key") . '=' . CGI::Enurl::enurl($rec->{$key}) . "&";
        }
        chop($qs);
        $add .= qq[<TD><A HREF="$self->{action}?$ur$qs&$search_cache">View/Edit</A></TD>];
        $add .= qq[<TD style="width: 10px; text-align: center;">|</TD><TD><A HREF="$self->{action}?$dr$qs&$search_cache">Delete</A></TD>];
        return $rec_html . $add;
    };
    $form->{head_html} = qq[<H2>Search Results for $table_name</H2>];

    $form->{tail_html} = ' ';
    my $html = $form->prepare(undef,undef,(@$keys ? $rec_callback : undef()));
    $$html .= $self->new_start($r->query());
    $r->output($html);
}

# Build search form
sub search_form
{
    my ($self,$r) = @_;
    my $form = $r->form($r->dbh());
    $form->heading('Search Criteria');
    $form->action($self->{action});
    $form->submit_value('Search');
    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    $r->graceful_add_form_group($form,'SEARCHABLE',$table_name,"Build criteria to report on $table_name") || return undef;
    return $form;
}

# Build/present search form
sub search_req
{
    my ($self,$r) = @_;
    my $form = $self->search_form($r) || return undef;
    my $q = $r->query();
    $q->{'__SDAT_TAB_ACTION.ACTION'} = 'SD';
    $r->output($form->prepare($q));
}

# Override in subclass to perform custom checks on input
# Will be passed as a callback to CGI::AutoForm::validate_query()
# refer to those docs for parameters and expected return values
sub verify_input
{
    return 1;
}

# Perform insert operation
sub insert_data
{
    my ($self,$r) = @_;
    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    my $q = $r->query();
    $q->{'__SDAT_TAB_ACTION.ACTION'} = 'ID';
    my $form = $self->insert_form($r->dbh(),$table_name,$r) || return undef;
    unless ($form->validate_query($q,$self->{verify_input}))
    {
        $r->output($form->prepare($q));
        return OK;
    }

    my $table;
    my $sq = $form->format_query($q);
    my $rv;
    unless (($table = new CGI::CRUD::Table($r->dbh(),$r->user,undef,undef,$table_name)) && ($rv = $table->insert($sq->{uc($table_name)})))
    {
        $r->server_error();
        return undef;
    }
    if ($rv == -1.1)
    {
        $r->perror("No data to insert");
        return undef;
    }
    elsif ($rv == -1.4)
    {
        $r->perror("Duplicate key violation on insert.");
        return undef;
    }
    my $aq = $form->extract_query_group($q,'__SDAT_TAB_ACTION');
    if ($q->{'__SDAT.CONTINUE'})
    {
        $form->{top_message} = qq[<DIV>Data saved.</DIV>];
        $r->output($form->prepare($aq));
    }
    else
    {
        $r->output($self->insert_or_return($aq));
    }
}

# Build insert form
sub insert_form
{
    my ($self,$dbh,$table_name,$r) = @_;
    my $form = $r->form($dbh);
    $form->heading("Input for $table_name");
    $form->action($self->{action});

    $form->{tail_html} = qq[<P><TABLE WIDTH="100%"><TR ALIGN="CENTER"><TD><INPUT TYPE="RESET">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;] .
        qq[<INPUT TYPE="SUBMIT" NAME="__SDAT.CONTINUE" VALUE="Save/Continue">] .
        qq[&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE="SUBMIT" VALUE="Save"></TD></TR></TABLE></P></FORM>];
    $r->graceful_add_form_group($form,'INSERTABLE',$table_name,"Insert data for \U$table_name") || return undef;
    return $form;
}

sub insert_or_return
{
    my ($self,$q,$top_message) = @_;
    $q->{'__SDAT_TAB_ACTION.ACTION'} = 'IR';
    my $msg;
    $msg .= 'Data saved.';
    $msg .= "<BR>$top_message" if $top_message;
    $msg .= qq[<P><TABLE WIDTH="100%"><TR>];
    my $sq = stringify_query($q);
    $msg .= qq[<TD><A HREF="$self->{action}?$sq">Insert new record<A></TD>];
    $q->{'__SDAT_TAB_ACTION.RESTART'} = 1;
    $sq = stringify_query($q);
    $msg .= qq[<TD><A HREF="$self->{action}?$sq">Admin panel<A></TD>];
    $msg .= qq[</TR></TABLE></P>];
    return $msg;
}

# Build/present insert form
sub insert_req
{
    my ($self,$r) = @_;
    my $table_name = $r->param('__SDAT_TAB_ACTION.TABLE_NAME');
    my $q = $r->query();
    $q->{'__SDAT_TAB_ACTION.ACTION'} = 'ID';
    my $form = $self->insert_form($r->dbh(),$table_name,$r) || return undef;
    $r->output($form->prepare($q));
}

sub stringify_query
{
    my ($q,$prefix) = @_;
    if (length($prefix))
    {
        $prefix .= '.' unless substr($prefix,-1) eq '.';
    }
    my ($str,$field,$val);
    my %dates_expand;
    foreach my $fq (@{flatten_query($q)})
    {
        ($field,$val) = each(%$fq);
        if ($field =~ /(.*)\._(RE\.|RS\.|UR$)/)
        {
            push(@{$dates_expand{$1}{params}},{$field,$val});
            $dates_expand{$1}{ur} = 1 if $2 eq 'UR' && length($val);
        }
        else
        {
            $str .= CGI::Enurl::enurl("$prefix$field") . '=' . CGI::Enurl::enurl($val) . '&' if length($val);
        }
    }

    my ($f,$v);
    while (($f,$v) = each(%dates_expand))
    {
        if ($dates_expand{$f}{ur})
        {
            foreach my $fq (@{$dates_expand{$f}{params}})
            {
                ($field,$val) = each(%$fq);
                $str .= CGI::Enurl::enurl("$prefix$field") . '=' . CGI::Enurl::enurl($val) . '&' if length($val);
            }
        }
    }
    chop($str);
    return $str;
}

# Do not pass in a structured query
sub flatten_query
{
    my ($q) = @_;
    my (@flat,$name,$val);
    while (($name,$val) = each(%$q))
    {
        $val = [ $val ] unless ref($val);
        foreach my $v (@$val)
        {
            push(@flat,{ $name => $v });
        }
    }
    return \@flat;
}

1;

__END__

=head1 SEE ALSO

L<CGI::AutoForm>, L<DBIx::IO>, L<DBIx::IO::Table>, L<CGI::CRUD::Table>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2007 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

