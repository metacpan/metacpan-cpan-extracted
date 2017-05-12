# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Row;

use Data::Tabular::Cell;
use Carp qw(croak);

use overload '@{}' => \&array,
             '""'  => \&str;

sub new
{
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $self = { @_ };
    if (ref($caller)) {
        croak(q|Don't know how to copy object: | . $class)
	    unless $caller->isa(__PACKAGE__);
	$self = $caller->clone();
    }
    $self = bless $self, $class;

    die caller unless $self->table->headers;
    croak 'need table' unless $self->table->headers;
    croak 'need table' unless $self->table;

    $self;
}

sub str
{
    my $self = shift;
    'Row : '. $self->{input_row} . ';';
}

sub headers
{
    my $self = shift;
    my @list1 = $self->table->headers;
    my @list2 = $self->output->headers;

    my %tmp;
    
    $tmp{$_} = 1 for (@list1);

    my @list3 = grep({$tmp{$_}} @list2);

warn 'bug' unless @list3;
    return @list1 unless @list3;

    return @list3;
}

sub html_attribute_string
{
    my $self = shift;
    my $ret  = ' class="ende"';

    $ret;
}

sub cells
{
    my $self = shift;
    my @ret = ();

    my @headers = $self->headers(@_);

    my $x = 0;
    for my $header (@headers) {
        next unless $header;
        push(@ret, 
	    Data::Tabular::Cell->new(
		row => $self,
		cell => $header,
		colspan => $self->colspan($header),
		id => $x++,
	    )
	);
    }
    @ret;
}

sub output
{
    my $self = shift;

    $self->{output} || die;
}

sub colspan
{
    1;
}

sub table
{
    shift->{table};
}

sub hdr
{
}

sub id
{
    my $self = shift;

    $self->{row_id} || 'No ID available';
}

sub cell_html_attributes
{
    {
        align => undef,
    };
}

sub type
{
    my $self = shift;
    warn 'No type for ' . ref($self);
    'unknown';
}

sub is_title { 0 };

1;
__END__

