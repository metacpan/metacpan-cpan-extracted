#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2022 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Role::ComputeFunction 2.155;

# ABSTRACT: compute &index or &element functions

use Mouse::Role;
use strict;
use warnings;
use Carp;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("ComputeFunction");

sub compute_string {
    my ($self, $string, $check) = @_;
    $string =~ s/&(index|element)(?:\(([- \d])\))?/$self->eval_function($1,$2,$check)/eg;
    return $string;
}

sub eval_function {
    my ($self, $function, $up, $check) = @_;

    if (defined $up) {
        # get now the object referred
        $up =~ s/\s//g;
        $up =~ s/-(\d+)/'- ' x $1/e;        # change  -3 -> - - -
        $up =~ s/(-+)/'- ' x length($1)/e;  # change --- -> - - -
    }

    my $target = eval {
        defined $up ? $self->grab( step => $up, check => $check ) : $self;
    };

    if ($@) {
        my $e = $@;
        my $msg = ref($e) && $e->can('full_message')  ? $e->full_message : $e;
        Config::Model::Exception::Model->throw(
            object => $self,
            error  => "Compute function argument '$up':\n" . $msg
        );
    }

    my $result ;
    if ( $function eq 'element' ) {
        $result = $target->element_name;
        Config::Model::Exception::Model->throw(
            object => $self,
            error  => "Compute function error: '". $target->name. "' has no element name"
        ) unless defined $result;
    }
    elsif ( $function eq 'index' ) {
        $result = $target->index_value;
        Config::Model::Exception::Model->throw(
            object => $self,
            error  => "Compute function error: '". $target->name. "' has no index value"
        ) unless defined $result;
    }
    else {
        Config::Model::Exception::Model->throw(
            object => $self,
            error  => "Unknown compute function &$function, "
                . "expected &element(...) or &index(...)"
        );
    }

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Role::ComputeFunction - compute &index or &element functions

=head1 VERSION

version 2.155

=head1 SYNOPSIS

 $value->eval_function('index');
 $value->eval_function('element');

 $value->eval_function('index','-');
 $value->eval_function('index','- -');
 $value->eval_function('index','-3');

 $value->compute_string('&element(-)')
 $value->compute_string('&index(- -)');

=head1 DESCRIPTION

Role used to let a value object get the index or the element name of
C<$self> or of a node above.

=head1 METHODS

=head2 eval_function

Retrieve the index or the element name. Parameters are

 ( function_name , [ up  ])

=over

=item function_name

C<element> or C<index>

=item up

Optional parameter to indicate how many level to go up before
retrieving the index or element name. Each C<-> is equivalent to a
call to C<parent|Config::Model::Node/parent>. Can be repeated dashes
("C<->", "C<- ->", ...)
or a dash with a multiplier 
("C<->", "C<-2>", ...). White spaces are ignored.

=back

=head2 compute_string

Perform a similar function as C<eval_function> using a string where
function names are extracted.

E.g. C<compute_string('&element(-)')> calls C<eval_function('element','-')>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005-2022 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
