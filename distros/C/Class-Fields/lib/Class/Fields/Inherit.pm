package Class::Fields::Inherit;

use strict;
use vars qw(@ISA @EXPORT $VERSION);

$VERSION = '0.06';

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw( inherit_fields );

# This may seem backwards.  The subroutine was moved to base.pm to break
# base.pm's dependency on Class::Fields.
require base;
*inherit_fields = \&base::inherit_fields;


return 'IRS Estate Tax Return Form 706';
__END__
=pod

=head1 NAME

Class::Fields::Inherit - Inheritance of %FIELDS


=head1 SYNOPSIS

    use Class::Fields::Inherit;
    inherit_fields($derived_class, $base_class);


=head1 DESCRIPTION

A simple module to handle inheritance of the %FIELDS hash.  base.pm is
usually its only customer, though there's nothing stopping you from
using it.

=over 4

=item B<inherit_fields>

  inherit_fields($derived_class, $base_class);

The $derived_class will inherit all of the $base_class's fields.  This
is a good chunk of what happens when you use base.pm.

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> largely from code liberated from
fields.pm

=head1 SEE ALSO

L<base>, L<Class::Fields>
