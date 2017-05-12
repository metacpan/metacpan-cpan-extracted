package CGI::Ex::Recipes::Delete;

use utf8;
use warnings;
use strict;
use base qw(CGI::Ex::Recipes);

our $VERSION = '0.03';


sub info_complete { 1 }

sub finalize {
    my $self = shift;
    $self->dbh->prepare("DELETE FROM recipes WHERE id = ?")->execute($self->form->{'id'});

    $self->add_to_form(success => "Recipe deleted from the database");
        #make so default page displays the category in which this item is
    $self->form->{'id'} = $self->form->{step_args}{'pid'};
    return 1;
}

1; # End of CGI::Ex::Recipes::Delete

__END__ 

=head1 NAME

CGI::Ex::Recipes::Delete - Implements the "delete" step!

=head1 SYNOPSIS

    http://localhost:8081/recipes/index.pl/delete/16
    ...

=head1 METHIODS

=head2 info_complete

=head2 finalize

Deletes the given record found in the path_info and adds the C<success> message to the form to be displayed.  

=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

