package DSL::HTML::Template;
use strict;
use warnings;
use v5.10;

use DSL::HTML::Rendering;
use Carp qw/croak/;
our @CARP_NOT = ( 'DSL::HTML::Rendering', 'DSL::HTML' );

sub name   { shift->{name}   }
sub params { shift->{params} }
sub block  { shift->{block}  }

sub indent { shift->params->{indent} }

sub new {
    my $class = shift;
    my ($name, $params, $block) = @_;

    $params ||= {};
    $params->{indent} //= "    ";

    return bless {
        name   => $name,
        params => $params,
        block  => $block,
    }, $class;
}

sub compile {
    my $self = shift;
    my $rendering = DSL::HTML::Rendering->new($self);
    return $rendering->compile(@_);
}

sub include {
    my $self = shift;
    my $rendering = DSL::HTML::Rendering->new($self);
    return $rendering->include(@_);
}

1;

__END__

=head1 NAME

DSL::HTML::Template - Used internally by L<DSL::HTML>

=head1 NOTES

You should never need to construct this yourself.

=head1 METHODS

=over 4

=item compile(@args)

Build the template, return the HTML.

=item include(@args)

Build the template, include it into the current template.

=item name  

=item params

=item block 

=item indent

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

DSL-HTML is free software; Standard perl license (GPL and Artistic).

DSL-HTML is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
