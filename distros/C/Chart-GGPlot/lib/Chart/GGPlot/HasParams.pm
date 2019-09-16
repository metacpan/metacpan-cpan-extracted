package Chart::GGPlot::HasParams;

# ABSTRACT: The role for the 'extra_params' thing

use Chart::GGPlot::Role;
use namespace::autoclean;

our $VERSION = '0.0007'; # VERSION

use Types::Standard qw(ArrayRef);



# used by parameters()
classmethod _parameters() { [] }

classmethod extra_params() { [qw(na_rm)] }


# R ggplot2's Geom parameters() function automatically gets params from
# draw_panel and draw_group methods via introspection on the method
# arguments. Although Perl Function::Parameters supports introspection,
# I would now do it in a "dumb" way.
classmethod parameters( $extra = false ) {
    my $args = $class->_parameters;
    if ($extra) {
        $args = $args->union( $class->extra_params );
    }
    return $args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::HasParams - The role for the 'extra_params' thing

=head1 VERSION

version 0.0007

=head1 DESCRIPTION

=head1 CLASS METHODS

=head2 extra_params

    my $extra_params_names = $obj->extra_params();

Array ref for additional parameters that may be needed.
Default is C<['na_rm']>.

=head2 _parameters

This method is called internally by the C<parameters> method of this role.
This is for consumers of the role to override the result of C<parameters>
if necessary. Default is C<[]>. 

=head2 parameters

    parameters($extra=false)

If C<$extra> is true, returns a union of C<extra_params()> and
C<_parameters()>. If C<$extra> is false, returns C<_parameters()>.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
