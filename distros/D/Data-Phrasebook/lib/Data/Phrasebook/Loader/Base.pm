package Data::Phrasebook::Loader::Base;
use strict;
use warnings FATAL => 'all';
use base qw( Data::Phrasebook::Debug );
use Carp qw( croak );

use vars qw($VERSION);
$VERSION = '0.35';

=head1 NAME

Data::Phrasebook::Loader::Base - Base loader plugin class.

=head1 SYNOPSIS

  $class->new( %attributes );

=head1 DESCRIPTION

C<Data::Phrasebook::Loader::Base> acts as a base class for phrasebook
plugins.

=cut

my $something = 0;

=head1 CONSTRUCTOR

=head2 new

C<new> instantiates the plugin object, creating a blessed hash of any
attributes passed as arguments.

=cut

sub new {
    my $self = shift;
    my %hash = @_;
    ($hash{class}) = $self =~ /.*::(.*)$/;
    $self->store(3,"$self->new IN")	if($self->debug);
    my $atts = \%hash;
    bless $atts, $self;
    return $atts;
}

=head1 INHERITABLE METHODS

=head2 load

C<load> is an abstract method here. You must define your own in your
subclass. Loads the phrasebook.

=head2 get

C<get> is an abstract method here. You must define your own in your
subclass. Gets the phrase.

=head2 dicts

C<dicts> is an abstract method here. You must define your own in your
subclass. Returns the list of dictionaries available.

=head2 keywords

C<keywords> is an abstract method here. You must define your own in your
subclass. Returns the list of keywords available.

=head2 class

Returns the current C<class> of loader.

=cut

sub load     { return }
sub get      { return }
sub dicts    { return () }
sub keywords { return () }
sub class    { return shift->{class} }

1;

__END__

=head1 SEE ALSO

L<Data::Phrasebook>,
L<Data::Phrasebook::Loader>.

=head1 SUPPORT

Please see the README file.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
