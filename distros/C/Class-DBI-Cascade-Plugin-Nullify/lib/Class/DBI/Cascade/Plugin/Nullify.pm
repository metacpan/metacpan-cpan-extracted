package Class::DBI::Cascade::Plugin::Nullify;

use strict;
use warnings;

use base 'Class::DBI::Cascade::None';

our $VERSION = 0.05;

sub cascade {
	my ($self, $obj) = @_;
	my $foreign_objects = $self->foreign_for($obj); # get all foreign objects
	my $foreign_key = $self->{_rel}->args->{foreign_key}; # get the foreign key
	
	while ( my $foreign_object = $foreign_objects->next) {	
		$foreign_object->$foreign_key(undef); # set foreign key value to null
		$foreign_object->update(); # update the object
	}
}

1;

__END__

=head1 NAME

Class::DBI::Cascade::Plugin::Nullify - Nullify related Class::DBI objects

=head1 SYNOPSIS

    package Music::Artist;
    # define your class here
    Music::Artist->has_many(cds => 'Music::CD', {cascade => 'Class::DBI::Cascade::Plugin::Nullify'});

=head1 DESCRIPTION

This is a cascading nullify strategy (i.e. 'on delete set null') that will nullify any related L<Class::DBI> objects.

THIS MODULE IS NOT LONGER DEVELOPED. Please consider L<Rose::DB::Object> as a alternative to L<Class::DBI>.

=head1 METHODS

=head2 C<cascade>

implementation of the cascading nullify strategy.

=head1 AUTHOR

Xufeng (Danny) Liang (danny.glue@gmail.com)

=head1 COPYRIGHT & LICENSE

Copyright 2006-2010 Xufeng (Danny) Liang, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut