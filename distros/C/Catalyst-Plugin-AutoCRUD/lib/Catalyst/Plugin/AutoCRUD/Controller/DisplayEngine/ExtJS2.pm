package Catalyst::Plugin::AutoCRUD::Controller::DisplayEngine::ExtJS2;
{
  $Catalyst::Plugin::AutoCRUD::Controller::DisplayEngine::ExtJS2::VERSION = '2.143070';
}

use strict;
use warnings;

use base 'Catalyst::Controller';

sub _filter_datetime {
    my $val = shift;
    if (eval { $val->isa( 'DateTime' ) }) {
        my $iso = $val->iso8601;
        $iso =~ s/T/ /;
        return $iso;
    }
    else {
        $val =~ s/(\.\d+)?[+-]\d\d$//;
        return $val;
    }
}

my %filter_for = (
    timefield => {
        to_ext => \&_filter_datetime,
        from_ext   => sub { shift },
    },
    xdatetime => {
        to_ext => \&_filter_datetime,
        from_ext   => sub { shift },
    },
    checkbox => {
        to_ext => sub {
            my $val = shift;
            return 1 if $val eq 'true' or $val eq '1';
            return 0;
        },
        from_ext   => sub {
            my $val = shift;
            return 1 if $val eq 'on' or $val eq '1';
            return 0;
        },
    },
    numberfield => {
        to_ext => sub { shift },
        from_ext   => sub {
            my $val = shift;
            return undef if !defined $val or $val eq '';
            return $val;
        },
    },
);

sub base : Chained('/autocrud/ajax/base') PathPart('extjs2') CaptureArgs(0) {}
sub end : ActionClass('RenderView') {}
sub process : Private {}

sub list : Chained('base') Args(0) {
    my ($self, $c) = @_;
    # forward to backend action to get data
    $c->forward('/autocrud/ajax/list');

    my $conf = $c->stash->{cpac}->{tc};
    my $meta = $c->stash->{cpac}->{tm};
    my @columns = @{$conf->{cols}};

    # filter data types coming from the db for Ext
    foreach my $row (@{$c->stash->{json_data}->{rows}}) {
        foreach my $col (@columns) {
            my $ci = $meta->f->{$col};

            if ($ci->extra('extjs_xtype')
                and exists $filter_for{ $ci->extra('extjs_xtype') }) {

                $row->{$col} =
                    $filter_for{ $ci->extra('extjs_xtype') }->{to_ext}->(
                        $row->{$col});
            }
        }
    }

    # sneak in a 'top' row for applying the filters
    my %searchrow = ();
    foreach my $col (@columns) {
        my $ci = $meta->f->{$col};

        if ($ci->extra('extjs_xtype') and $ci->extra('extjs_xtype') eq 'checkbox') {
            $searchrow{$col} = '';
        }
        else {
            if (exists $c->req->params->{ 'cpac_filter.'. $col }) {
                $searchrow{$col} = $c->req->params->{ 'cpac_filter.'. $col };
            }
            else {
                $searchrow{$col} = '(click to add filter)';
            }
        }
    }
    unshift @{$c->stash->{json_data}->{rows}}, \%searchrow;
}

sub filter_from_ext : Private {
    my ($self, $c) = @_;
    my $conf = $c->stash->{cpac}->{tc};
    my $meta = $c->stash->{cpac}->{tm};
    my @columns = @{$conf->{cols}};

    my $do_filter = sub {
        my ($ci, $col) = @_;
        return unless exists $c->req->params->{$col}
            and defined $c->req->params->{$col};

        if ($ci->extra('extjs_xtype')
            and exists $filter_for{ $ci->extra('extjs_xtype') }) {

            $c->req->params->{$col} =
                $filter_for{ $ci->extra('extjs_xtype') }->{from_ext}->(
                    $c->req->params->{$col}
                );
        }
    };

    # filter data types coming from the Ext form
    foreach my $col (@columns) {
        my $ci = $meta->f->{$col};
        if ($ci->is_foreign_key) {
            next unless $ci->extra('ref_table');
            my $link = $c->stash->{cpac}->{m}->t->{ $ci->extra('ref_table') };
            next unless $link->extra('fields');

            foreach my $fcol (@{$link->extra('fields')}) {
                my $fci = $link->f->{$fcol};
                $do_filter->($fci, "$col.$fcol");
            }
        }
        else {
            $do_filter->($ci, $col);
        }
    }
}

sub create : Chained('base') Args(0) {
    my ($self, $c) = @_; 
    $c->forward('filter_from_ext');
    $c->forward('/autocrud/ajax/create');
}

sub update : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward('filter_from_ext');
    $c->forward('/autocrud/ajax/update');
}

sub delete : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward('/autocrud/ajax/delete');
}

sub list_stringified : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward('/autocrud/ajax/list_stringified');
}

1;
