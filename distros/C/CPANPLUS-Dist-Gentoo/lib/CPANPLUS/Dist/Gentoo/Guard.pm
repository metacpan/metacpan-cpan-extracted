package CPANPLUS::Dist::Gentoo::Guard;

use strict;
use warnings;

=head1 NAME

CPANPLUS::Dist::Gentoo::Guard - Scope guard object.

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 DESCRIPTION

This is a scope guard object helper for L<CPANPLUS::Dist::Gentoo>.

=head1 METHODS

=head2 C<new $coderef>

Creates a new L<CPANPLUS::Dist::Gentoo::Guard> object that will call C<$coderef> when destroyed.

=cut

sub new {
 my ($class, $code) = @_;
 $class = ref($class) || $class;

 bless {
  code  => $code,
  armed => 1,
 }, $class;
}

=head2 C<unarm>

Tells the object not to call the stored callback on destruction.

=cut

sub unarm { $_[0]->{armed} = 0 }

=head2 C<DESTROY>

Calls the stored callback if the guard object is still armed.

=cut

sub DESTROY {
 my ($self) = @_;

 $self->{code}->() if $self->{armed};
 $self->unarm;

 return;
}

=head1 SEE ALSO

L<CPANPLUS::Dist::Gentoo>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpanplus-dist-gentoo at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-Gentoo>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANPLUS::Dist::Gentoo

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2012 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of CPANPLUS::Dist::Gentoo::Guard
