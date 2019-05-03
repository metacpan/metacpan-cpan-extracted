package Data::Frame::Column::Helper;

use strict;
use warnings;

use Moo;

has dataframe => ( is => 'rw' ); # isa Data::Frame

use overload '&{}' => sub ($$) {
	my $self = shift;
	sub { $self->dataframe->column(@_); };
};

sub AUTOLOAD {
	my $self = shift;
	(my $colname = our $AUTOLOAD) =~ s/^@{[__PACKAGE__]}:://;
	$self->dataframe->column($colname);
}

# empty DESTROY to avoid call from AUTOLOAD
sub DESTROY { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Column::Helper

=head1 VERSION

version 0.0047

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
