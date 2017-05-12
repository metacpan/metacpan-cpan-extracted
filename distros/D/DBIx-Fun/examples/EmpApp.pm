package EmpApp;

use strict;

use base 'CGI::Application';

use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::AutoRunmode;
use DBI;
use DBIx::Fun;
use Carp;

our $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger', { FetchHashKeyName => 'NAME_lc' } );
our $fun = DBIx::Fun->context( $dbh );

sub setup
{
    my $self = shift;
    $self->tt_config(
        TEMPLATE_OPTIONS => {
            INCLUDE_PATH => './template'
        }
    );
    $self->mode_param('mode');
}

sub list : StartRunMode
{     
    my $self = shift;
    
    my $employees;
    $fun->get_all_employees( \$employees );

    $self->tt_process( 'list.tmpl', {
        employees => $employees->fetchall_arrayref({})
    } );
}

sub view : RunMode
{     
    my $self = shift;
    my $employee_id = $self->query->param( 'employee_id' );

    $self->tt_process( 'view.tmpl', {
        emp => $fun->employee_detail( $employee_id )->fetchrow_hashref
    } );
}

sub edit : RunMode
{
    my $self = shift;
    my $employee_id = $self->query->param( 'employee_id' );

    $self->tt_process( 'edit.tmpl', {
        emp => $fun->employee_detail( $employee_id )->fetchrow_hashref,
        departments => $fun->list_departments->fetchall_arrayref({}),
        positions   => $fun->list_positions->fetchall_arrayref({}),
        locations   => $fun->list_locations->fetchall_arrayref({})
    } );
}

sub add : RunMode
{
    my $self = shift;

    $self->tt_process( 'edit.tmpl', {
        emp => { id => 'new' },
        departments => $fun->list_departments->fetchall_arrayref({}),
        positions   => $fun->list_positions->fetchall_arrayref({}),
        locations   => $fun->list_locations->fetchall_arrayref({})
    } );
}

sub save : RunMode
{
    my $self = shift;
    my $query = $self->query;
    my $employee_id = $query->param( 'employee_id' );

    croak "Unsupplied or invalid employee id ($employee_id)."
        unless $employee_id;

    my %data;
    foreach my $p ( qw(dept_id position_id location_id start_date end_date) ) {
        my $val = $query->param( $p );
        if ( defined $val && length $val ) {
            $data{$p} = $val;
        }
    }

    if ( $employee_id eq 'new' ) {
        $employee_id = '';
        my $junk = '';
        $data{emp_id} = \$employee_id;
        $data{disp_date} = \$junk;
        $fun->hire_employee( \%data );
    }
    else {
        $data{emp_id} = $employee_id;
        $fun->update_employee( \%data );
    }

    $self->tt_process( 'view.tmpl', {
        emp => $fun->employee_detail( $employee_id )->fetchrow_hashref
    } );
}

#    dept_id in number,
#    position_id in number,
#    location_id in number,
#    emp_id out number,
#    disp_date out varchar2


1;

