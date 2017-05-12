package CatalystX::CRUD::YUI::Excel;
use strict;
use warnings;
use base qw( CatalystX::CRUD::View::Excel );
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro "c3";
use Path::Class;
use Class::Inspector;
use CatalystX::CRUD::YUI;
use CatalystX::CRUD::YUI::TT;

our $VERSION = '0.031';

=head1 NAME

CatalystX::CRUD::YUI::Excel - View class for Excel output

=head1 DESCRIPTION

CatalystX::CRUD::YUI::Excel is a subclass of CatalystX::CRUD::View::Excel.

=head1 CONFIGURATION

Configuration is the same as with CatalystX::CRUD::View::Excel. Read those docs.

The default config here is:

 __PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt'
 );

=cut

# default config here instead of new() so subclasses can more easily override.
__PACKAGE__->config( TEMPLATE_EXTENSION => '.tt' );
$Template::Directive::WHILE_MAX = 65000;

=head1 METHODS

The following methods are implemented in this class:

=cut

=head2 new

Overrides base new() method. Sets
etp_config->INCLUDE_PATH to the base
CatalystX::CRUD::YUI::TT .tt files plus your local app root.
This means you can override the default .tt behaviour
by putting a .tt file with the same name in your C<root> template dir.

For example, to customize your C<.xls.tt> file, just copy the default one
from the C<CatalystX/CRUD/YUI/TT/crud/list.xls.tt> in @INC and put it
in C<root/crud/list.xls.tt>.

=cut

sub new {
    my ( $class, $c, $arg ) = @_;
    my $self = $class->next::method( $c, $arg );

    my @inc_path = ( Path::Class::dir( $c->config->{root} ) );

    for my $tt_class (
        qw(
        CatalystX::CRUD::YUI::TT
        )
        )
    {

        my $template_base = Class::Inspector->loaded_filename($tt_class);
        $template_base =~ s/\.pm$//;
        push( @inc_path, Path::Class::dir($template_base) );
    }

    $self->etp_config->{INCLUDE_PATH} = \@inc_path;

    return $self;
}

=head2 get_template_filename

Always returns C<crud/list.xls.tt> rather than depending on current
Action path.

=cut

sub get_template_filename {'crud/list.xls.tt'}

=head2 get_template_params

Overrides base method to add some other default variables.

=over

=item

The C<yui> variable is a Rose::DBx::Garden::Catalyst::YUI object.

=back

=cut

sub get_template_params {
    my ( $self, $c ) = @_;
    my $cvar = $self->config->{CATALYST_VAR} || 'c';
    return (
        $cvar => $c,
        %{ $c->stash },
        yui => CatalystX::CRUD::YUI->new(),
    );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-yui@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
