package Data::Tabulate::Plugin::HTMLTable;

use warnings;
use strict;

use HTML::Table;

# ABSTRACT: HTML::Table plugin for Data::Tabulate

our $VERSION = '0.05';


sub new{
    return bless {},shift;
}


sub output {
    my ($self,@data) = @_;
    
    my %atts = $self->attributes();
    my $obj  = HTML::Table->new(%atts);

    for my $row_data ( @data ){
        my @row = map{ defined $_ ? $_ : '&nbsp;' }@{$row_data};
        $obj->addRow(@row);
    }
    
    return $obj->getTable();
}


sub attributes{
    my ($self,%atts) = @_;

    $self->{attributes} = {%atts} if keys %atts;

    my %return = %{ $self->{attributes} || {} };

    return %return;
}

1; # End of Data::Tabulate::Plugin::HTMLTable

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Tabulate::Plugin::HTMLTable - HTML::Table plugin for Data::Tabulate

=head1 VERSION

version 0.05

=head1 SYNOPSIS

This module renders the table for HTML

    use Data::Tabulate;
    
    my @array = (1..10);
    my $foo   = Data::Tabulate->new();
    my $html  = $foo->render('HTMLTable',{data => [@array]});

=head1 METHODS

=head2 new

create a new object of C<Data::Tabulate::Plugin::HTMLTable>.

    my $obj = Data::Tabulate::Plugin::HTML::Table->new;

=head2 output

returns a string that contains the HTML source for the table

    my $html_table = $obj->output(
        ['a1', 'b1', 'c1' ],
        ['a2', 'b2', 'c2' ],
        ['a3', 'b3', 'c3' ],
    );

=head2 attributes

set some attributes for L<HTML::Table>.

    my $obj = Data::Tabulate::Plugin::HTML::Table->new;
    $obj->attributes(
        -border => 1,
        -bgcolor => 'red',
    );

    my $html_table = $obj->output(
        ['a1', 'b1', 'c1' ],
        ['a2', 'b2', 'c2' ],
        ['a3', 'b3', 'c3' ],
    );

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
