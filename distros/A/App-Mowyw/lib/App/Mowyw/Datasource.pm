package App::Mowyw::Datasource;
use strict;
use warnings;
use Carp qw(confess);

our %type_map = (
    xml     => 'XML',
    dbi     => 'DBI',
    array   => 'Array',
);

sub new {
    my ($base, $opts) = @_;
    my $type = lc($opts->{type}) or confess "No 'type' given";
    delete $opts->{type};
    my $type_name = $type_map{$type} || confess "Don't know what to do with datasource type '$type'";
    $type_name = "App::Mowyw::Datasource::$type_name";
    eval "use $type_name;";
    confess $@ if $@;
    my $obj =  eval $type_name . "->new(\$opts)" or confess $@;
    return $obj;
}

# these are stubs for inherited classes

sub reset        { confess "Called virtual method in base class!" }
sub get          { confess "Called virtual method in base class!" }
sub next         { confess "Called virtual method in base class!" }
sub is_exhausted { confess "Called virtual method in base class!" }

1;
