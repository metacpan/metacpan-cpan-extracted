package Catalyst::Plugin::Prototype;

use strict;
use base 'Class::Data::Inheritable';
use HTML::Prototype;

our $VERSION = '1.33';

__PACKAGE__->mk_classdata('prototype');
eval { require HTML::Prototype::Useful; };

if ( $@ ) {
    __PACKAGE__->prototype( HTML::Prototype->new );
} else {
    __PACKAGE__->prototype( HTML::Prototype::Useful->new );
}

=head1 NAME

Catalyst::Plugin::Prototype - Plugin for Prototype

=head1 SYNOPSIS

    # use it
    use Catalyst qw/Prototype/;

=head2 INLINE USE

    # ...add this to your tt2 template...
    [% c.prototype.define_javascript_functions %]

=head2 REFERENCE USE

If you don't want to include the entire prototype library inline
on every hit, you can use "script/myapp_create.pl Prototype"
to generate static JavaScript files which then can be included
via remote "script" tags.

    # ...add this to your template...
    <script LANGUAGE="JavaScript1.2" type="text/javascript"
         src="/prototype.js"></script>
    <script LANGUAGE="JavaScript1.2" type="text/javascript"
         src="/effects.js"></script>
    <!-- .... -->


    # ...and use the helper methods...
    <div id="view"></div>
    <textarea id="editor" cols="80" rows="24"></textarea>
    [% uri = base _ 'edit/' _ page.title %]
    [% c.prototype.observe_field( 'editor', uri, { 'update' => 'view' } ) %]

=head1 DESCRIPTION

Some stuff to make Prototype fun.

This plugin replaces L<Catalyst::Helper::Prototype>.

=head2 METHODS

=head3 prototype

    Returns a ready to use L<HTML::Prototype> object.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
