##----------------------------------------------------------------------------
## Class Generic - ~/lib/Class/Array.pm
## Version v0.1.2
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/02/27
## Modified 2022/03/07
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Class::DateTime;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::DateTime );
    our $VERSION = 'v0.1.0';
};

1;

__END__

=encoding utf8

=head1 NAME

Class::DateTime - A thin Wrapper for DateTime Object Class

=head1 SYNOPSIS

    use Class::DateTime;
    use DateTime;
    my $dt = DateTime->now;
    my $dt2 = DateTime->now->add( days => 10 );
    my $a = Class::DateTime->new( $dt );
    my $b = Class::DateTime->new( $dt2 );
    my $interval = $b - $a;
    print $interval->days, "\n";

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

This package provides a thin wrapper around DateTime by inheriting from L<Module::Generic::DateTime>. It allows overloaded operations, including subtraction and conversion for L<Storable> or L<JSON>

See L<Module::Generic::DateTime> for more information.

=head1 SEE ALSO

L<Class::Generic>, L<Class::Array>, L<Class::Scalar>, L<Class::Number>, L<Class::Boolean>, L<Class::Assoc>, L<Class::File>, L<Class::DateTime>, L<Class::Exception>, L<Class::Finfo>, L<Class::NullChain>, L<Class::DateTime>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
