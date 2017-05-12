package CatalystX::Features::Role::Feature;
$CatalystX::Features::Role::Feature::VERSION = '0.26';
use Moose::Role;

# attributes
requires 'path';
requires 'backend';

# methods
requires 'id';
requires 'name';
requires 'version';
requires 'version_number';
requires qw/root lib t/;

=head1 NAME

CatalystX::Features::Role::Feature - Role for implementing a single feature. 

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This role is an interface. No code here.

=head1 REQUIRED ATTRIBUTES

=head2 path

Needed by the constructor. Receives a full path to the feature, i.e. 

	/home/myapp/features/my.simple.feature_1.0.0

=head2 backend

Needed by the constructor. Passed the instance of the controller.
Should have a type of L<CatalystX::Features::Role::Backend>.

	has 'backend' => ( is=>'ro', isa=>'CatalystX::Features::Role::Backend', required=>1 );

=head1 REQUIRED METHODS

=head2 id

The last folder in the feature path, say C<my.feature_1.0>. It's used as a unique identifier for this feature.

=head2 name

The name of the feature, say C<my.simple.feature>. This is also a unique identifier application wide. 
There should not exist 2 or more features with the same name loaded at any given time. 

=head2 version

A version token of any format. 

=head2 version_number

A version long integer that can be compared easily.

=head2 root

Returns the full path to the C</root> dir for a given feature. Used by many C<View> modifiers.

=head2 lib

Returns the full path of the C</lib> dir for a given feature. Used by C<@INC> modifiers or any plugins.  

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut 

1;
