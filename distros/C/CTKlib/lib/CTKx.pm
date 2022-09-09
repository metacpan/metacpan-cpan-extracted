package CTKx;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTKx - Singleton CTK extension

=head1 VERSION

Version 2.01

=head1 SYNOPSIS

    package main;

    use CTK;
    use CTKx;

    my $ctkx = CTKx->instance( ctk => new CTK );

    package MyApp;

    my $c = CTKx->instance->c;
    my $ctk = CTKx->instance->ctk;

=head1 DESCRIPTION

Extension for working with CTK as "Singleton Pattern"

=head2 c, ctk

    my $c = CTKx->instance->c;
    my $ctk = CTKx->instance->ctk;

Returns ctk-object

=head1 HISTORY

=over 8

=item B<1.00 / 15.10.2013>

Init version

=item B<1.00 Mon 29 Apr 22:26:18 MSK 2019>

New edition

=back

See C<Changes> file for details

=head1 DEPENDENCIES

L<Class::Singleton>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<Class::Singleton>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use base qw/Class::Singleton/;
use vars qw/$VERSION/;
$VERSION = '2.01';

sub c { shift->{ctk} }
sub ctk { shift->{ctk} }

1;

__END__
