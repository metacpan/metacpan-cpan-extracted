package CGI::Ex::Recipes::Edit;
use utf8;
use warnings;
use strict;
use CGI::Ex::Dump qw(debug dex_warn ctrace dex_trace);
use base qw(CGI::Ex::Recipes);
our $VERSION = '0.03';


sub hash_common {
    my $self = shift;
    return {} if $self->ready_validate;
    my $sth  = $self->dbh->prepare("SELECT * FROM recipes WHERE id = ?");
    $sth->execute($self->form->{'id'});
    $self->{hash_common} =  $sth->fetchrow_hashref;
    $self->{hash_common};
}


sub finalize {
    my $self = shift;
    my $form = $self->form;
    my $s = "SELECT COUNT(*) FROM recipes WHERE title = ? AND id != ?";
    my ($count) = $self->dbh->selectrow_array($s, {}, $form->{'title'}, $form->{'id'});
    if ($count) {
        $self->add_errors(title => 'A recipe by this title already exists');
        return 0;
    }

    $s = "UPDATE recipes 
            SET pid = ?, is_category = ?, title = ?, problem = ?, analysis = ?,solution = ?,
            sortorder = ?, tstamp = ?  
            WHERE id = ?";
    $self->dbh->prepare($s)->execute(         
        $form->{'pid'},
        $form->{'is_category'}||0,
        $form->{'title'},
        $form->{'problem'},
        $form->{'analysis'},
        $form->{'solution'},
        $form->{'sortorder'},
        $self->now,
        $form->{'id'}
    );
    $self->add_to_form(success => "Recipe updated in the database");
    #make so default page displays the category in which this item is
    #$form->{'id'} = $form->{'pid'};
    $self->set_ready_validate(0);
    
    #CGI::Ex::App also has methods that allow for dynamic changing of the path, 
    #so that each step can determine which step to do next 
    #(see the jump, append_path, insert_path, and replace_path methods).
    $self->append_path('view');
    $self->cache->clear;
    return 1;
}

=pod

sub next_step { 'view' }

=cut

1; # End of CGI::Ex::Recipes::Edit

__END__

=head1 NAME

CGI::Ex::Recipes::Edit - Implements editing of a recipe!

=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    http://localhost:8081/recipes/index.pl/edit/5

=head1 METHODS


=head2 hash_common

=head2 finalize


=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
