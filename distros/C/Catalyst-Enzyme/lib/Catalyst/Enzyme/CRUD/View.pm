package Catalyst::Enzyme::CRUD::View;

our $VERSION = '0.10';



use strict;
use Data::Dumper;
use HTML::Element;



=head1 NAME

Catalyst::Enzyme::CRUD::View - Catalyst View helper methods for CRUD
templates

=head1 SYNOPSIS



=head1 DESCRIPTION

This is a mix-in for any (TT) View using the Enzyme CRUD.

=cut





=head2 METHODS


=head2 element_req($c, $action_name, $column, $type)

Return new HTML::Element for $column.

If the current action is $action_name, fill in data from the request.

If there is no $column field in the model class, return a HTML <INPUT
type="$type"> field with that name. Type = "textfield" | "textarea" |
"select"

=cut
sub element_req {
    my ($self, $c, $action_name, $column, $type) = @_;

    my $element = eval { $c->stash->{crud}->{model_class}->to_field($column, $type) };
    if(!$element) {
        if($type eq "textarea") {
            $element = HTML::Element->new("textarea", name => $column);
        } else {
            my $html_type = $type || "";
            $html_type eq "textfield" and $html_type = "text";
            $element = HTML::Element->new("input", name => $column, type => $html_type);
        }
    }
            

    if($c->action->name eq $action_name) {
        my $value = $c->req->param($column);
        if($element->tag eq  "textarea") {
            $element = $element->push_content($value);
        } elsif($element->tag eq "select") {
            for my $option ($element->content_list) {
                $option->attr("selected", "1"), last if($option->attr("value") eq $value);
            }
        } else {
            $element->attr("value", $value);
        }
    }
    
    return($element);
}





=head1 CATALYST METHODS

These methods are injected into the Catalyst class, available to call
on the $c object.


=head2 $c->this_request_except(%new_params)

Return uri which is identical to the current request, except
overwritten with the new parameters in %new_params.

=cut
use URI;
use URI::QueryParam;
sub Catalyst::this_request_except {
    my ( $c, %new_params ) = @_;

    my $uri = $c->req->uri->clone;
    while(my ($key, $val) = each(%new_params)) {
        $uri->query_param($key, $val);
    }

    return($uri);
}





=head2 $c->uri_for_controller($action, @params)

Return a URI that points to the $action in this controller, no matter
what the current request is (it could be to an action in another
Controller which forwarded to this Controller (by first forwarding to
this controller's C<set_crud_controller>).

The @params are added to the URI the same way as in C<uri_for>.

=cut
sub Catalyst::uri_for_controller {
    my ($c, $action, @params) = @_;
    return( $c->uri_for( $c->stash->{controller_namespace}, $action, @params) );
}





=head1 AUTHOR

Johan Lindstrom <johanl ÄT cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
