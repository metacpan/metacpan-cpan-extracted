package [% module %];

use [% min_perl_version %];

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01';

use Carp;
use POSIX qw(strftime);

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@EXPORT      = qw(); # by default, don't do this unless absolutely necessary
@EXPORT_OK   = qw(); # on demand
%EXPORT_TAGS = (
    ALL => [ @EXPORT_OK ],
);

{
#-------------------------------------------------------------------------------
sub new {
    my ($class, $arg) = @_;

    my $self = bless {}, $class;

    $self->_init($args);

    return $self;
}

#-------------------------------------------------------------------------------
sub _init {
    my ($self, $arg) = @_;

#    $self->SUPER::_init($arg);

    return;
}

}
1;

__END__

=pod

=head1 NAME

[% module %] - <one line description>

=head1 VERSION

This documentation refers to [% module %] version 0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over

=item C<function_name>

=back

=head1 EXAMPLES

None.

=head1 DIAGNOSTICS

=over

=item B<Error Message>

=item B<Error Message>

=back

=head1 CONFIGURATION AND ENVIRONMENT

[% module %] requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item * Carp

=item * POSIX

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any issues or feature requests to C<[% support_email %]>. Patches are welcome.

=head1 AUTHOR

[% author %] C<< [% email %] >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) [% year %], [% author %] C<< [% email %] >>. All rights reserved.

[% license_body %]

=cut

