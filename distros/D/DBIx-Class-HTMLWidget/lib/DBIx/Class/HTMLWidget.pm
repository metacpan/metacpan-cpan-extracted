package DBIx::Class::HTMLWidget;
use strict;
use warnings;
use Carp;
#use Data::Dump qw(dump);

our $VERSION = '0.16';
# pod after __END__

sub fill_widget {
    my ($dbic,$widget)=@_;

    croak('fill_widget needs a HTML::Widget object as argument') 
        unless ref $widget && $widget->isa('HTML::Widget');
    my @real_elements = $widget->find_elements;
    
    foreach my $element ( @real_elements ) {
        my $name=$element->name;
        next unless $name && $dbic->can($name) && $element->can('value');
        next if ($element->value());
        if($element->isa('HTML::Widget::Element::Checkbox')) {
			  $element->checked($dbic->$name?1:0);
		  } else {
		      if (ref $dbic->$name and $dbic->$name->can('id') and $dbic->$name->id) {
		          $element->value($dbic->$name->id);
		      } else {
			      $element->value($dbic->$name)
				    unless $element->isa('HTML::Widget::Element::Password');
			  }
		  }
    }
}


sub populate_from_widget {
	my ($dbic,$result)=@_;
    	croak('populate_from_widget needs a HTML::Widget::Result object as argument') 
        	unless ref $result && $result->isa('HTML::Widget::Result');

	#   find all checkboxes
    my %cb = map {$_->name => undef } grep { $_->isa('HTML::Widget::Element::Checkbox') } 
        $result->find_elements;

    foreach my $col ( $dbic->result_source->columns ) {
        my $col_info = $dbic->column_info($col);
        my $value = scalar($result->param($col));
        if ($col_info->{data_type} and $col_info->{data_type} =~ m/^timestamp|date|integer|numeric/i 
            and defined $value and $value eq '') {
            $value = undef;
            $dbic->$col(undef);
        }

        if (defined($value) and !ref($value) and $value eq 'undef') {
            $dbic->$col(undef);
            $value = undef;
        }
        if ($col_info->{data_type} and $col_info->{data_type} =~ m/boolean/i
            && exists $col_info->{is_nullable} && !$col_info->{is_nullable}
            && exists $cb{$col} && !defined($value) 
            && $dbic->result_source->schema->storage->sqlt_type eq 'PostgreSQL') {
            # We need to set the value to 0 if it is postgres
            $value = 0;
        }
        $dbic->$col($value)
            if defined $value || exists $cb{$col};
    }
    $dbic->insert_or_update;
    return $dbic;
}


sub experimental_populate_from_widget {
   my ($dbic,$result)=@_;
    foreach (@{$result->{_elements}} ) {
            # Its called a fair few times so save name
            my $name = $_->name;
			#prevent passwords being overwritten.
			next if $_->isa('HTML::Widget::Element::Password') && $result->param($name) eq "";
            $dbic->set_column($name, scalar $result->param($name))
				if (defined $result->param($name) || $_->isa('HTML::Widget::Element::Checkbox')) &&
				# Ignore this element if its readonly or not in the DBIC
				!$_->{attributes}{readonly} && $dbic->has_column($name);
    }
   $dbic->insert_or_update;
   return $dbic;
}

1;
__END__

=pod

=head1 NAME

DBIx::Class::HTMLWidget - Like FromForm but with DBIx::Class and HTML::Widget

=head1 SYNOPSIS

You'll need a working DBIx::Class setup and some knowledge of HTML::Widget
and Catalyst. If you have no idea what I'm talking about, check the (sparse)
docs of those modules.

   package My::Model::DBIC::Pet;
   use base 'DBIx::Class';
   __PACKAGE__->load_components(qw/HTMLWidget Core/);

   
   package My::Controller::Pet;    # Catalyst-style
   
   # define the widget in a sub (DRY)
   sub widget_pet {
     my ($self,$c)=@_;
     my $w=$c->widget('pet')->method('get');
     $w->element('Textfield','name')->label('Name');
     $w->element('Textfield','age')->label('Age');
     ...
     return $w;
   }
     
   # this renders an edit form with values filled in from the DB 
   sub edit : Local {
     my ($self,$c,$id)=@_;
  
     # get the object
     my $item=$c->model('DBIC::Pet')->find($id);
     $c->stash->{item}=$item;
  
     # get the widget
     my $w=$self->widget_pet($c);
     $w->action($c->uri_for('do_edit/'.$id));
    
     # fill widget with data from DB
     $item->fill_widget($w);
  }
  
  sub do_edit : Local {
    my ($self,$c,$id)=@_;
    
    # get the object from DB
    my $item=$c->model('DBIC::Pet')->find($id);
    $c->stash->{item}=$item;
    
    # get the widget
    my $w=$self->widget_pet($c);
    $w->action($c->uri_for('do_edit/'.$id));
    
    # process the form parameters
    my $result = $w->process($c->req);
    $c->stash->{'result'}=$result;
    
    # if there are no errors save the form values to the object
    unless ($result->has_errors) {
        $item->populate_from_widget($result);
        $c->res->redirect('/users/pet/'.$id);
    }

  }

  
=head1 DESCRIPTION

Something like Class::DBI::FromForm / Class::DBI::FromCGI but using
HTML::Widget for form creation and validation and DBIx::Class as a ORM.

=head2 Methods

=head3 fill_widget

   $dbic_object->fill_widget($widget);

Fill the values of a widgets elements with the values of the DBIC object.

=head3 populate_from_widget

   my $obj=$schema->resultset('pet)->new->populate_from_widget($result);
   my $item->populate_from_widget($result);

Create or update a DBIx::Class row from a HTML::Widget::Result object

=head1 CAEVATS / POSSIBLE PROBLEMS

=head2 PostgreSQL

=head3 ERROR:  null value in column "private" violates not-null constraint

This is a result of we trying to set a value to undef that should not be. This is typicaly
a problem when you have a colum such ass "private boolean not null". We have a special-case
for this, and if you set data_type => boolean, is_nullable => 0 in your ResultSource definition,
we update the value to 0 before attempting to insert or update

=head1 AUTHORS

Thomas Klausner, <domm@cpan.org>, http://domm.zsi.at

Marcus Ramberg, <mramberg@cpan.org>

Andreas Marienborg, <omega@palle.net>

=head1 CONTRIBUTORS

Simon Elliott, <cpan@browsing.co.uk>

Ashley Berlin

Guillermo Sansovic

=head1 LICENSE

This code is Copyright (c) 2003-2006 Thomas Klausner.
All rights reserved.

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut




