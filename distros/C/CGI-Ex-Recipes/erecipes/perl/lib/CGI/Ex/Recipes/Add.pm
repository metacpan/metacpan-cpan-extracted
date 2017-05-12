package CGI::Ex::Recipes::Add;
use utf8;
use warnings;
use strict;
use base qw(CGI::Ex::Recipes);
our $VERSION = sprintf "%d.%03d", q$Revision 0.001$ =~ /(\d+)/g;


sub skip { 0 }
sub name_step { 'edit' }


sub finalize {
    my $self = shift;
    my $form = $self->form;

    my $s = "SELECT COUNT(*) FROM recipes WHERE title = ?";
    my ($count) = $self->dbh->selectrow_array($s, {}, $form->{'title'});
    if ($count) {
        $self->add_errors(title => 'A recipe by this title already exists');
        return 0;
    }

    $s = "INSERT INTO recipes (pid, is_category, title, problem, analysis, solution, sortorder, tstamp, date_added)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    my $tstamp = $self->now;
    $self->dbh->prepare($s)->execute(
                           $form->{'pid'},
                           $form->{'is_category'}||0,
                           $form->{'title'},
                           $form->{'problem'},
                           $form->{'analysis'},
                           $form->{'solution'},
                           $form->{'sortorder'},
                           $tstamp,
                           $tstamp,);
    $self->add_to_form(success => "Recipe added to the database");
    return 1;
}

1; # End of CGI::Ex::Recipes::Add

__END__

=head1 NAME

CGI::Ex::Recipes::Add - Implements the creation of a new recipe!

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Perhaps a little code snippet.

    sub skip { 0 }
    sub name_step { 'edit' }
    ...


=head1 METHODS

See the general documentations for these methods in L<CGI::Ex::App>

=head2 skip

=head2 name_step

Returns C<edit> in order the edit.tthtml template to be used

=head2 finalize

The real work is done here. First checks for abs record in the recipes table with the same title and if found adds an error to the template. Otherwise inserts the new record. See the code foreach details.


=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 BUGS

Not known

=head1 SUPPORT

    perldoc CGI::Ex::Recipes

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
