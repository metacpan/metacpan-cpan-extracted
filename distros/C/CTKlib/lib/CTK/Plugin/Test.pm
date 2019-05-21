package CTK::Plugin::Test;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::Test - Test plugin as example for Your plugins

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "test",
        );
    print $ctk->foo;

=head1 DESCRIPTION

Test plugin as example for Your plugins. See L<CTK::Plugin>

=head2 init

Initializer. Optional method. See L<CTK::Plugin>

=head1 METHODS

=over 8

=item B<foo>

    print $ctk->foo;

Returns wrapped the tms value from CTK object

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/CTK::Plugin/;

sub init {
    my $self = shift; # It is CTK object!
    # ... you can also call any base CTK methods  here
    return 1;
}

__PACKAGE__->register_method(
    namespace => "CTK",
    method    => "foo",
    callback  => sub {
        my $self = shift; # It is CTK object!
        return sprintf("The %s was called as foo method defined in Test. Say: %s\n", __PACKAGE__, $self->tms);
});

1;

__END__
