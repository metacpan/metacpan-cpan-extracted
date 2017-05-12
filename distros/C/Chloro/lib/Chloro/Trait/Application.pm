package Chloro::Trait::Application;
BEGIN {
  $Chloro::Trait::Application::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

after apply_attributes => sub {
    shift->_apply_form_components(@_);
};

1;

# ABSTRACT: A trait that supports role application for roles with Chloro fields and groups



=pod

=head1 NAME

Chloro::Trait::Application - A trait that supports role application for roles with Chloro fields and groups

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This trait is used to allow the application of roles containing Chloro fields
and groups/

=head1 BUGS

See L<Chloro> for details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

