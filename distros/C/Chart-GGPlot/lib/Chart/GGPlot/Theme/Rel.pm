package Chart::GGPlot::Theme::Rel;

# ABSTRACT: To specify sizes relative to the parent

use Chart::GGPlot::Setup;
use Function::Parameters qw(classmethod);

our $VERSION = '0.002000'; # VERSION

use overload '*' => fun( $self, $other, $swap ) { $self->value * $other },
  fallback       => 1;

# do not use Moose as this class is too simple.
classmethod new ($x) {
    return ( bless \$x, $class );
}

method value () {
    return $$self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Theme::Rel - To specify sizes relative to the parent

=head1 VERSION

version 0.002000

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
