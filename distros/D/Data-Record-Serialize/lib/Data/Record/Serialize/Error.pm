package Data::Record::Serialize::Error;

# ABSTRACT: Error objects

use v5.12;
use strict;
use warnings;

our $VERSION = '2.02';

use Exporter::Shiny qw( error );

use custom::failures ( qw[
      attribute::value
      method::stub
] );











sub _exporter_validate_opts {
    my $class = shift;

    my ( $globals ) = @_;

    if ( defined $globals->{errors} ) {

        my @classes = @{ delete $globals->{errors}; };

        if ( @classes ) {
            $_ = _resolve_class( $_, $globals->{into} ) foreach @classes;
            custom::failures->import( @classes );
        }
    }

    $class->SUPER::_exporter_validate_opts( @_ );
}













sub error {
    my $class = shift;
    _resolve_class( $class, scalar caller(), __PACKAGE__ )->throw( @_ );
}

sub _resolve_class {
    my ( $class, $caller, @prefix ) = @_;

    return join(
        q{::}, @prefix,
        do {
            if ( $class =~ /^::(.*)/ ) {
                $1;
            }
            elsif ( $caller =~ /Data::Record::Serialize::(.*)/ ) {
                $1 . q{::} . $class;
            }
            else {
                $class;
            }
        },
    );
}

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory msg

=head1 NAME

Data::Record::Serialize::Error - Error objects

=head1 VERSION

version 2.02

=head1 SYNOPSIS

  use Data::Record::Serialize::Error -all;
  use Data::Record::Serialize::Error { errors =>
  [ qw( param
        connect
        schema
        create
        insert
   )] }, -all;

=head1 DESCRIPTION

=head2 For the user of C<Data::Record::Serialize>

Most errors result in exception objects being thrown, typically in the
C<Data::Record::Serialize::Error> hierarchy.  The exception objects
will stringify to an appropriate error message.  Additional payload
data may be returned as well (see the documentation for the individual
modules which throw exceptions).  The objects are derived from
L<failures> and have the attributes documented in
L<failures/Attributes>.

=head2 For the developer

This module organizes L<Data::Record::Serialize> errors based upon
L<custom::failures>.  It uses L<Exporter::Shiny>. The global option
C<errors> may be used to construct a set of error classes.  C<errors>
is passed an array of error names; if they begin with C<::> they are
relative to C<Data::Record::Serialize::Error>, otherwise they are
relative to the C<Error> sub-hierarchy under the calling package.

For example,

  package Data::Record::Serialize::Bar;
  use Data::Record::Serialize::Error { errors => [ '::foo', 'foo' ] };

will construct error classes C<Data::Record::Serialize::Error::foo>
and  C<Data::Record::Serialize::Bar::Error::foo>;

=head2 Error Class Names

Names (passed either during module import or to the L</error> subroutine)
are converted to fully qualified class names via the following:

=over

=item *

if a name begins with C<::> it is relative to C<Data::Record::Serialize::Error>

=item *

otherwise it is relative to the C<Error> sub-hierarchy under the calling package.

=back

For example, in

  package Data::Record::Serialize::Bar;
  use Data::Record::Serialize::Error { errors => [ '::foo', 'foo' ] };

  error( '::foo', @stuff );
  error( 'foo', @stuff );

C<::foo> will be converted to C<Data::Record::Serialize::Error::foo>
and C<foo> to C<Data::Record::Serialize::Bar::Error::foo>.

=head1 OBJECT ATTRIBUTES

=head2 msg

=head2 payload

=head2 trace

See L<failures/Attributes>.

=head1 SUBROUTINES

=head2 error

  error( $error_class, @_ );

Throw an error. C<$error_class> is converted to a fully qualified class
name; see L</Error Class Names>.  The remaining parameters are passed
directly to the L<failures> throw method (see L<failures/Throwing
failures>).

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
