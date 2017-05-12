package Data::Keys;

=head1 NAME

Data::Keys - get/set key+value extensible manipulations, base module for Data::Keys::E::*

=head1 SYNOPSIS

    use Date::Keys;
	my $dk = Data::Keys->new(
		'base_dir'    => '/folder/full/of/json/files',
		'extend_with' => ['Store::Dir', 'Value::InfDef'],
		'inflate'     => sub { JSON::Util->decode($_[0]) },
		'deflate'     => sub { JSON::Util->encode($_[0]) },
	);

	my %data = %{$dk->get('abcd.json')};
	$dk->set('abcd.json', \%data);

=head1 WARNING

experimental, use at your own risk :-)

=head1 DESCRIPTION

L<Data::Keys> is just a base class module that purpose is to allow loading
extensions in C<Data::Keys::E::*> namespace.

=head1 EXTENSIONS

=head2 storage

L<Data::Keys::E::Store::Dir>, L<Data::Keys::E::Store::Mem>

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose;
use Moose::Util;
use Carp::Clan 'confess';
use List::MoreUtils 'none';

=head1 PROPERTIES

=head2 extend_with

Array ref list of extensions to apply to the object.

=cut

has 'extend_with' => ( isa => 'ArrayRef', is => 'ro', lazy => 1, default => sub { [] });
has '_extend_arg' => ( isa => 'HashRef',  is => 'ro');

# store all attributes from extensions
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    my $extend_with = $args{'extend_with'};
    if ((defined $extend_with) and (not ref $extend_with)) {
        $extend_with = [ $extend_with ];
        $args{'extend_with'} = $extend_with;
    }
    
    # load extension modules that are not loaded already
    foreach my $extension (@{$extend_with}) {
        my $package = 'Data::Keys::E::'.$extension;
        my $package_file = $package.'.pm';
        $package_file =~ s{::}{/}g;
        if (not $INC{$package_file}) {
            eval 'use '.$package;
            confess 'failed to load '.$package
                if $@;
        }
    }
    
    my %e_attrs =
        map  { $_ => delete $args{$_} }
        grep { defined $args{$_} }
        map  { $_->meta->get_attribute_list }
        map  { 'Data::Keys::E::'.$_ }
        @{$extend_with}
    ;
    $args{_extend_arg} = \%e_attrs;
    
    my @attrs = Data::Keys->meta->get_attribute_list;
    my @unknown_keys =
        grep { my $attr = $_; none { $_ eq $attr } @attrs }
        keys %args
    ;
    confess 'unknown attributes - '.join(', ', @unknown_keys)
        if @unknown_keys;
    
    return $class->$orig(%args);
};

=head2 BUILD

Loads all extensions when L<Key::Values> object is created and calls
C<< $self->init(); >> which can be used to initialize an extension.

=cut

sub BUILD {
    my $self = shift;
        
    my $extend_with = $self->extend_with;
    if (defined $extend_with) {
        foreach my $to_extend (@{$extend_with}) {
            $to_extend = 'Data::Keys::E::'.$to_extend;
            $to_extend->meta->apply($self);
        }        
    }
    
    # init all attributes from extensions
    my $extend_arg = $self->_extend_arg;
    foreach my $name (keys %{$extend_arg}) {
        confess 'extended attribute '.$name.' not found'
            if not $self->can($name);
        $self->$name(delete $extend_arg->{$name});
    }
    
    $self->init();
}

__PACKAGE__->meta->make_immutable;

=head1 METHODS

=head2 new()

Object constructor.

=head2 init()

Called after the object is C<BUILD>.

=cut

sub init {
    my $self = shift;
    
    confess 'role with set/get is mandatory'
        if not $self->can('set');
    confess 'role with set/get is mandatory'
        if not $self->can('get');
    
    return;
}
 
1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut


=head1 AUTHOR

jozef@kutej.net, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-keys at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Keys>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Keys


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Keys>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Keys>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Keys>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Keys/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 jozef@kutej.net.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Keys
