package Const::Fast::Exporter;
$Const::Fast::Exporter::VERSION = '0.02';
require 5.010;

use strict;
use warnings;
use Const::Fast;

my %is_readonly = (
    SCALAR => sub { Internals::SvREADONLY(${ $_[0] }) },
    HASH   => sub { Internals::SvREADONLY(%{ $_[0] }) },
    ARRAY  => sub { Internals::SvREADONLY(@{ $_[0] }) },
);

my @TYPES = keys %is_readonly;

#=======================================================================
# This is the import function that we put in the module which is
# exporting const::fast variables. We look for all const variables
# and export them into the namespace that use'd the constants module.
#
# NOTE:
# when @FOOBAR is defined, the glob will also have *{...::FOOBAR}{SCALAR}
# defined. This is due to an assumption made in early versions of Perl 5.
# So we find all names in the symbol table, and then check whether
# (a) the relevant glob slot is filled, and then (b) whether the package
# variable has been marked as readonly (i.e. looks to be a Const::Fast
# immutable variable. If so, then we export it.
#
# Another approach would be to use Package::Stash::has_symbol('@FOOBAR'),
# or if we wanted to keep the number of dependencies down, we could
# lift the code here:
#  https://metacpan.org/source/DOY/Package-Stash-0.37/lib/Package/Stash/PP.pm#L244-256
# Thanks to HAARG and Nicholas, who answered questions about this on #p5p
#=======================================================================

my $immutable_variables_exporter = sub {
    my $exporting_package = shift;
    my $importing_package = caller();
    my $symbol_table_ref  = eval "\\\%${exporting_package}::";

    foreach my $variable (keys %$symbol_table_ref) {
        foreach my $type (@TYPES) {
            no strict 'refs';
            my $globref = *{"${exporting_package}::${variable}"}{$type};
            if (defined($globref) && &{ $is_readonly{$type} }($globref)) {
                *{"${importing_package}::${variable}"} = $globref;
            }
        }
    }
};

#=======================================================================
# When someone uses Const::Fast::Exporter we drop Const::Fast::const
# into their namespace (so they don't have to use Const::Fast as well)
# and we also give their package an import() function, which will
# export all Const::Fast read-only variables.
#=======================================================================
sub import
{
    my $exporting_package = shift;
    my $importing_package = caller();

    no strict 'refs';

    *{"${importing_package}::const"} = *{"Const::Fast::const"}{CODE};
    *{"${importing_package}::import"} = $immutable_variables_exporter;
}

1;

=head1 NAME

Const::Fast::Exporter - create a module that exports Const::Fast immutable variables

=head1 SYNOPSIS

Create your module that defines the constants:

 package MyConstants;
 use Const::Fast::Exporter;

 const our $ANSWER => 42;
 const our @COLORS => qw/ red green blue /;
 const our %ORIGIN => { x => 0, y => 0 };

 1;

And then to use the constants:

 use MyConstants;

 print "The answer = $ANSWER\n";

=head1 DESCRIPTION

This module is helpful if you want to create a module
that defines L<Const::Fast> immutable variables, 
which are then exported.
The SYNOPSIS provides just about everything you need to know.
When you use C<Const::Fast::Exporter>,
it loads C<Const::Fast> for you,
which is why there isn't a C<use Const::Fast> line in the SYNOPSIS.

B<Note:> the interface should be considered unstable.
At the moment it is very simple -- it just exports all symbols.
Possibly there should be an option to specify whether everything is an optional export, with a C<-all> switch. Maybe you'd do something like:

 use Const::Fast::Exporter -requested;

Which says that people have to specifically request the constants they want,
rather than getting all of them by default.

If you want to define tags,
then you should probably just use L<Exporter> or similar.


=head1 SEE ALSO

L<Const::Fast> - lets you define read-only scalars, hashes, and arrays.

L<Const::Exporter> - another module you can use to create your
own module that exports constant and immutable variables.

L<Exporter::Constants> - declare and export function-based constants,
similar to those declared with the L<constant> pragma.

L<Constant::Exporter> - declare and export function-based constants.

L<Constant::Export::Lazy> - create a module that exports constants,
where the value is only generated the first time its used.

=head1 REPOSITORY

L<https://github.com/neilb/Const-Fast-Exporter>


=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

