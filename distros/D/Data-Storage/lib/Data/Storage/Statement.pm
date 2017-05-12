use 5.008;
use strict;
use warnings;

package Data::Storage::Statement;
BEGIN {
  $Data::Storage::Statement::VERSION = '1.102720';
}
# ABSTRACT: Wrapper for DBI statements
use Data::Miscellany 'value_of';
use parent qw(Class::Accessor::Complex Class::Accessor::Constructor);
__PACKAGE__
    ->mk_constructor
    ->mk_scalar_accessors(qw(sth));

# Define functions and class methods lest they be handled by AUTOLOAD, because
# there's no $self->sth to forward anything on in those cases.
sub DEFAULTS               { () }
sub FIRST_CONSTRUCTOR_ARGS { () }
sub DESTROY                { }

# Most methods are forwarded onto the statement handle, except for the ones
# handled differently below.
sub AUTOLOAD {
    (my $method = our $AUTOLOAD) =~ s/.*://;
    no strict 'refs';
    *$AUTOLOAD = sub {
        my $self = shift;

        # This package is just a wrapper, so report where the call came from
        local $Error::Depth = $Error::Depth + 1;
        $self->sth->$method(@_);
    };
    goto &$AUTOLOAD;
}

# Stringify potential value objects.
sub bind_param {
    my ($self, @args) = @_;
    $args[1] = value_of $args[1];

    # This package is just a wrapper, so report where the call came from
    local $Error::Depth = $Error::Depth + 1;
    $self->sth->bind_param(@args);
}

# If we are given a value object, redirect the binding to the value object's
# internal value directly.
sub bind_param_inout {
    my ($self, @args) = @_;
    my $result = ${ $args[1] };
    if (ref $result && UNIVERSAL::isa($result, 'Class::Value')) {
        $result->{_value} = undef unless exists $result->{_value};
        $args[1] = \$result->{_value};
    }

    # This package is just a wrapper, so report where the call came from
    local $Error::Depth = $Error::Depth + 1;
    $self->sth->bind_param_inout(@args);
}

sub Statement {
    my $self = shift;
    return $self->sth->{Statement} unless @_;
    $self->sth->{Statement} = $_[0];
}
1;


__END__
=pod

=head1 NAME

Data::Storage::Statement - Wrapper for DBI statements

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 DEFAULTS

FIXME

=head2 FIRST_CONSTRUCTOR_ARGS

FIXME

=head2 Statement

FIXME

=head2 bind_param

FIXME

=head2 bind_param_inout

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Storage>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Storage/>.

The development version lives at L<http://github.com/hanekomu/Data-Storage>
and may be cloned from L<git://github.com/hanekomu/Data-Storage>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

