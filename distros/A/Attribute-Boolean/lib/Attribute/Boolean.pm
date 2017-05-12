package Attribute::Boolean;

use strict;
use warnings FATAL => 'all';
use 5.14.0;
use utf8;

=head1 NAME

Attribute::Boolean - Mark scalars as pure booleans

=cut

use Attribute::Handlers;
use Variable::Magic qw( wizard cast );
use parent 'Exporter';
use version;

use Attribute::Boolean::Value;

=head1 VERSION

Version v1.0.8

=cut

our $VERSION = version->declare('v1.0.8');
# Don't forget the version in the pod above.

=head1 SYNOPSYS

This allows you to flag a variable as a boolean.
In numeric context, it will have the value 0 or 1.
In string context is will have the value "false" or "true".
In JSON, it will correctly return false or true values.

    my $bool : Boolean;
    print $bool;    # "false"
    $bool = (1 + 2 == 3);
    print $bool;    # "true"
    print $bool ? "yes" : "no";	 # "yes"
    $bool = false;
    print $bool ? "yes" : "no";	 # "no"

=head1 EXPORT

This exports constants true and false.

=cut

our @EXPORT = qw{ true false };

sub import {
# add this package to callers @ISA, as attributes only work via inheritance
    my $class = shift;
    my $caller = caller;
    {
	no strict 'refs';
	push @{ "${ caller }::ISA" }, __PACKAGE__;
    }
    $class->export_to_level(1, $class, @_);
}

=head1 USAGE

An attribute can be declared boolean as follows:

    my $bool : Boolean;

or

    my $bool : Boolean = true;

If any perl B<true> value is assigned, the variable is true; if a
perl B<false> value is assigned, the variable is false.

=head2 true

This returns 1 in numeric context, "true" in string context.

=head2 false

This returns 0 in numeric context, "false" in string context.

=head2 TO_JSON

Provided that convert_blessed is set on the JSON (or JSON::XS) object,
the variable will correctly convert to JSON true or false.

    my $json = new JSON;
    $json->pretty->convert_blessed;
    my $bool : Boolean;
    my %hash = (
	value => $bool,
	me    => true,
    );
    print $json->encode(\%hash);    # {
				    #     "value" : false,
				    #     "me"    : true
				    # }
				    
=cut

sub Boolean : ATTR(SCALAR)
{
    my ($class, $symbol, $ref, $name, undef, $phase) = @_;
    cast $$ref, wizard(
	'set' => sub {
	    my $ref = shift;
	    $$ref = $$ref ? true : false;
	},
	'get' => sub {
	    my $ref = shift;
	    $$ref = $$ref ? true : false;
	},
    );
}

=head1 AUTHOR

Cliff Stanford, C<< <cpan@may.be> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-attribute-boolean+ at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=attribute-boolean+>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Attribute::Boolean

=head1 ACKNOWLEDGEMENTS

Alan Haggai Alavi C<< <alanhaggai@alanhaggai.org> >> for his
L<Scalar::Boolean> module  which was the inspiration
for this module.

=head1 LICENCE AND COPYRIGHT

Copyright 2014 Cliff Stanford.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Attribute::Boolean

