##----------------------------------------------------------------------------
## Class Generic - ~/lib/Class/Number.pm
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
package Class::Number;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Number );
    use vars qw( $SUPPORTED_LOCALES $DEFAULT );
    $SUPPORTED_LOCALES = $Module::Generic::Number::SUPPORTED_LOCALES;
    $DEFAULT = $Module::Generic::Number::DEFAULT;
    our $VERSION = 'v0.1.2';
};

1;

__END__

=encoding utf8

=head1 NAME

Class::Number - A Number Object Class

=head1 SYNOPSIS

    use Class::Number;
    my $num = Class::Number->new;

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

This package provides a versatile number class object for the manipulation and chaining of numbers.

See L<Module::Generic::Number> for more information.

=head1 SEE ALSO

L<Class::Generic>, L<Class::Array>, L<Class::Scalar>, L<Class::Number>, L<Class::Boolean>, L<Class::Assoc>, L<Class::File>, L<Class::DateTime>, L<Class::Exception>, L<Class::Finfo>, L<Class::NullChain>, L<Class::DateTime>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
