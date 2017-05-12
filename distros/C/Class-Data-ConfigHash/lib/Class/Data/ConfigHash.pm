# $Id: /mirror/coderepos/lang/perl/Class-Data-ConfigHash/trunk/lib/Class/Data/ConfigHash.pm 69719 2008-08-27T02:20:26.319462Z daisuke  $

package Class::Data::ConfigHash;
use strict;
use warnings;
use base qw(Class::Data::Inheritable);
our $VERSION = '0.00002';

__PACKAGE__->mk_classdata(_config => {});

sub config {
    my $self = shift;
    my $config_sub = $self->can('_config');
    my $config = $self->$config_sub() || {};
    if (@_) {
        my $newconfig = { %{@_ > 1 ? {@_} : ($_[0] || {})} };
        $self->_config(
            $self->merge_config_hashes( $config, $newconfig )
        );
    } else {
        # this is a bit of a kludge, required to make
        # __PACKAGE__->config->{foo} = 'bar';
        # work in a subclass. Calling the Class::Data::Inheritable setter
        # will create a new _config method in the current class if it's
        # currently inherited from the superclass. So, the can() call will
        # return a different subref in that case and that means we know to
        # copy and reset the value stored in the class data.

        $self->_config( $config );

        if ((my $config_sub_now = $self->can('_config')) ne $config_sub) {
            
            $config = $self->merge_config_hashes( $config, {} );
            $self->$config_sub_now( $config );
        }
    }
    return $config;
}

sub merge_config_hashes
{
    my ($self, $lefthash, $righthash) = @_;
    return __merge_hashes($lefthash, $righthash);
}

sub __merge_hashes
{
    # XXX - If Catalyst is in effect, we might just as well use
    # Catalyst::Utils::merge_hashes, I suppose.
    my ( $lefthash, $righthash ) = @_;

    if ( !defined $righthash ) {
        return $lefthash;
    }

    if ( !defined $lefthash ) {
        return $righthash;
    }

    my %merged = %{$lefthash};
    for my $key ( keys %{$righthash} ) {
        my $right_ref = ( ref $righthash->{$key} || '' ) eq 'HASH';
        my $left_ref =
          ( ( exists $lefthash->{$key} && ref $lefthash->{$key} ) || '' ) eq
          'HASH';
        if ( $right_ref and $left_ref ) {
            $merged{$key} =
              __merge_hashes( $lefthash->{$key}, $righthash->{$key} );
        }
        else {
            $merged{$key} = $righthash->{$key};
        }
    }
    
    return \%merged;
}

1;

__END__

=head1 NAME

Class::Data::ConfigHash - Add Catalyst-Style Config To Your Class

=head1 NAME

  package MyClass;
  use base qw(Class::Data::ConfigHash);

  __PACKAGE__->config(
    foo => 'bar'
  );

=head1 DESCRIPTION

I often times find myself wanting a per-class config that can be used to
provide sane class-level defaults, but with the ability to easily customize
the values at run time.

  package MyClass;
  __PACKAGE__->config({
    foo => 1,
    bar => 2
  });

  # Later, in perhaps an initialize hook somewhere
  my %config = read_config_from_file() ; # say, %config = ( foo => 3 )
  MyClass->config(\%config);

  MyClass->config->{foo}; # yields 3
  MyClass->config->{bar}; # yields 2

The idea is that you can hardcode the defaults in your class, but you can also
easily override them by merging the original hash with a newly given hash.
This feature is handled beautifully in Catalyst.

So there, this module is basically that feature from Catalyst ripped out to a
separate module so it can be used elsewhere.

To use, simply subclass it in your module:

  package MyClass;
  use base qw(Class::Data::ConfigHash);

Done! Now you can use ->config in MyClass.

=head1 METHODS

=head2 config([\%hash])

Accessor for the underlying config.

  # set 
  $class->config(\%hash);
  $class->config->{whatever} = 'foo';

  # get
  $class->config->{whatever};

If given a hashref argument, the values in the hashref are merged with whatever
values that existed prior to that. This merge is performed recursively to the
entire hash.

=head2 merge_config_hashes(\%lefthash, \%righthash)

Merges the two config hashes.

=head1 CREDITS

Sebastian Riedel, Marcus Ramberg, Matt S Trout wrote the code.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >> - Stole the code from Catalyst and repackaged it

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut