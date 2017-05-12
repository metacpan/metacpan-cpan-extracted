package Catalyst::Helper::View::TD;

use strict;
use warnings;

our $VERSION = '0.12';

=head1 Name

Catalyst::Helper::View::TD - Helper for TD Views

=head1 Synopsis

    ./script/myapp_create.pl view HTML TD

=head1 Description

Helper for TD Views.

=head2 Methods

=head3 mk_compclass

Creates a view class and corresponding template class.

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    (my $tclass = $helper->{class}) =~ s/::View::/::Templates::/;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file, { tclass => $tclass } );

    # Create a template, too.
    require Catalyst::Helper::TDClass;
    local $helper->{vclass} = $helper->{class};
    Catalyst::Helper::TDClass->mk_stuff( $helper );
}

=head3 mk_comptest

Creates a test script for the view class.

=cut

sub mk_comptest {
    my ( $self, $helper ) = @_;
    my $test = $helper->{test};
    $helper->render_file( 'comptest', $test );
}

=head1 SEE ALSO

L<Catalyst::View::TD>,  L<Catalyst::Helper::TDClass>

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 License

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=begin comment

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;
use parent 'Catalyst::View::TD';

# Unless auto_alias is false, Catalyst::View::TD will automatically load all
# modules below the [% tclass %] namespace and alias their
# templates into [% tclass %]. It's simplest to create your
# template classes there. See the Template::Declare documentation for a
# complete description of its init() parameters, all of which are supported
# here.

__PACKAGE__->config(
    # dispatch_to     => [qw([% tclass %])],
    # auto_alias      => 1,
    # strict          => 1,
    # postprocessor   => sub { ... },
    # around_template => sub { ... },
);

=head1 NAME

[% class %] - [% name %] View for [% app %]

=head1 DESCRIPTION

TD View for [% app %]. Templates are written in the
[% tclass %] namespace.

=head1 SEE ALSO

L<[% app %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
__comptest__
use strict;
use warnings;
use Test::More tests => 3;
# use Test::XPath;

BEGIN {
    use_ok '[% class %]' or die;
    use_ok '[% app %]' or die;
}

ok my $view = [% app %]->view('[% name %]'), 'Get [% name %] view object';

# ok my $output = $view->render(undef, 'hello', { user => 'Theory' }),
#     'Render the "hello" template';

# Test output using Test::XPath or similar.
# my $tx = Test::XPath->new( xml => $output, is_html => 1);
# $tx->ok('/html', 'Should have root html element');
# $tx->is('/html/head/title', 'Hello, Theory', 'Title should be correct');

__the_end__

=end comment

=cut
