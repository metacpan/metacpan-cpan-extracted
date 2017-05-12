package Data::AMF::Formatter;
use strict;
use warnings;

use Data::AMF::Formatter::AMF0;
use Data::AMF::Formatter::AMF3;

sub new {
    my $class = shift;
    my $args  = @_ > 1 ? {@_} : $_[0];
	
    return $args->{version} == 3
	  ? 'Data::AMF::Formatter::AMF3'
	  : 'Data::AMF::Formatter::AMF0';
}

=head1 NAME
 
Data::AMF::Formatter - serializer proxy class

=head1 SYNOPSIS

my $amf3_formatter_class = Data::AMF::Formatter->new( version => 3 );
my $amf0_formatter_class = Data::AMF::Formatter->new( version => 0 ); # or just new without option

=head1 METHODS

=head2 new

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
