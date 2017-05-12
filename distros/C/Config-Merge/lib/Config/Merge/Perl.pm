package Config::Merge::Perl;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

=head1 NAME

Config::Merge::Perl - Load Perl config files

=head1 DESCRIPTION

Loads Perl files. Example:

    {
        name => 'TestApp',
        'Controller::Foo' => {
            foo => 'bar'
        },
        'Model::Baz' => {
            qux => 'xyzzy'
        }
    }

Any error/warning in the file will throw a fatal error.

=head1 METHODS

=head2 extensions( )

return an array of valid extensions (C<pl>, C<perl>).

=cut

sub extensions {qw( pl perl );}

=head2 load( $file )

Attempts to load C<$file> as a Perl file.

=cut


sub load {
    my $class = shift;
    my $file  = shift;
    delete $INC{$file};
    local ($^W) = 1;
    local $SIG{__WARN__} = sub { die $_[0]};
    require $file;
}

=head1 SEE ALSO

L<Config::Merge>

=head1 THANKS

Thanks to Joel Bernstein and Brian Cassidy for the original Config::Any::Perl
module

=head1 BUGS

None known

=head1 AUTHOR

Clinton Gormley, E<lt>clinton@traveljury.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Clinton Gormley

=cut

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;