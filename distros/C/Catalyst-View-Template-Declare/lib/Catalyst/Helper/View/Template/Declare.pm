package Catalyst::Helper::View::Template::Declare;
use strict;
use warnings;


=head1 NAME

Catalyst::Helper::View::Template::Declare - Helper for creating a stub
Template::Declare view

=head1 SYNOPSIS

    script/create.pl view TD Template::Declare

=head1 DESCRIPTION

Helper for Template::Declare Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];
use strict;
use warnings;
use base 'Catalyst::View::Template::Declare';
1;

# Put templates in separate modules, each under the 
# [% class %]::* namespace.  Be sure to "use Template::Declare::Tags"
# in each one.

__END__
  
=head1 NAME

[% class %] - Template::Declare View for [% app %]

=head1 DESCRIPTION

Template::Declare View for [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

L<Catalyst::View::Template::Declare>

L<Template::Declare::Tags>

L<Template::Declare>

=cut

