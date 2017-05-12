package Brick::UserGuide;

=pod

=encoding utf8

=head1 NAME

Brick::UserGuide - How to use Brick

=head1 SYNOPSIS

=head1 DESCRIPTION

Some one told you to use this module to validate data, and you need to
know the shortest way to get that done. Someone else has created all
the validation routines, or "bricks", already and you just have to use
them.

=head2 Construct your profile

Your validation description is the business rules that you want to
apply to your input. It's just a list of anonymous arrays that tell
Brick what to do (see L<Brick::Profile>):

	@Description = (
		[ label => constraint_name => { setup hash } ],
		...
		);

	my $Brick = Brick->new();

	my $profile = $Brick->profile_class->new( \@Description );

When you C<apply> this profile, Brick does it's magic.

	my $result = $Brick->apply( $profile, \%Input );

Brick goes through the profile one anonymous array at a time, and in order.
It validates one row of the anonymous array, saves the result, and moves on
to the next anonymous array. At the end, you have the results in C<$result>,
which is a C<Brick::Results> object.

That anonymous array's elements correspond item for item to the elements in
the profile. The first element in C<$result> goes with the first element
in C<@Profile>.

Each element in C<$result> is an anonymous array holding four items:

=over 4

=item The label of the profile element

=item The constraint it ran

=item The result: True if the data passed, and false otherwise.

=item The error message, if any, as an anonymous hash.

=back

=head2 Getting the error messages

	XXX: In progress

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/brick

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
