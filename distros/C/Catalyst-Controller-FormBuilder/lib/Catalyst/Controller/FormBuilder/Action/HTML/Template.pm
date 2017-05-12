package Catalyst::Controller::FormBuilder::Action::HTML::Template;

use strict;
use Tie::IxHash;
use base qw/Catalyst::Controller::FormBuilder::Action/;
use CGI::FormBuilder::Util qw/toname ismember optval/;

our %FORM_VARS;
# ensuring order to avoid FB's script before start warning msg
tie(
    %FORM_VARS, 'Tie::IxHash',
    'form-jshead'     => 'script',
    'js-head'         => 'script',
    'form-title'      => 'title',
    'form-start'      => 'start',
    'form-submit'     => 'submit',
    'form-reset'      => 'reset',
    'form-end'        => 'end',
    'form-invalid'    => 'invalid',
    'form-required'   => 'required',
    'form-statetags'  => 'statetags',
    'form-keepextras' => 'keepextras',
);

our %FIELD_VARS = (
    'cleanopts' => 'cleanopts-%s',
    'value'     => 'value-%s',
    'missing'   => 'missing-%s',
    'nameopts'  => 'nameopts-%s',
    'comment'   => 'comment-%s',
    'required'  => 'required-%s',
    'error'     => 'error-%s',
    'label'     => 'label-%s',
    'type'      => 'type-%s',
    'tag'       => 'field-%s',
    'invalid'   => 'invalid-%s'
);

sub setup_template_vars {
    my ( $self, $controller, $c ) = @_;

    my $tvar = {};
    my $form = $controller->_formbuilder;

    while ( my ( $to, $from ) = each %FORM_VARS ) {
        $tvar->{$to} = $form->$from;
    }

    #
    # For HTML::Template, each data struct is manually assigned
    # to a separate <tmpl_var> and <tmpl_loop> tag
    #
    my @fieldlist;
    for my $field ( $form->fields ) {

        # Field name is usually a good idea
        my $name = $field->name;

        # Get all values
        my @value   = $field->values;
        my @options = $field->options;

        #
        # Auto-expand all of our field tags, such as field, label, value
        # comment, error, etc, etc
        #

        while ( my ( $key, $str ) = each %FIELD_VARS ) {
            my $var = sprintf $str, $name;
            $tvar->{$var} = $field->$key;
        }

        #
        # Create a <tmpl_loop> for multi-values/multi-opts
        # we can't include the field, really, since this would involve
        # too much effort knowing what type
        #
        my @tmpl_loop = ();
        for my $opt (@options) {

            # Since our data structure is a series of ['',''] things,
            # we get the name from that. If not, then it's a list
            # of regular old data that we _toname if nameopts => 1
            my ( $o, $n ) = optval $opt;

            $n ||=
              $form->{"nameopts-$name"}
              ? toname($o)
              : $o;

            my ( $slct, $chk ) =
              ismember( $o, @value )
              ? ( 'selected', 'checked' )
              : ( '', '' );

            push @tmpl_loop,
              {
                label    => $n,
                value    => $o,
                checked  => $chk,
                selected => $slct,
              };
        }

        # Now assign our loop-field
        $form->{"loop-$name"} = \@tmpl_loop;

        # Finally, push onto a top-level loop named "fields"
        push @fieldlist,
          {
            field    => $tvar->{"field-$name"},
            value    => $tvar->{"value-$name"},
            values   => \@value,
            options  => \@options,
            label    => $tvar->{"label-$name"},
            comment  => $tvar->{"comment-$name"},
            error    => $tvar->{"error-$name"},
            required => $tvar->{"required-$name"},
            missing  => $tvar->{"missing-$name"},
            loop     => \@tmpl_loop
          };
    }

    # use Data::Dumper;
    # print STDERR Dumper( $fieldlist[0] );

    # kill our previous fields list
    $tvar->{fields} = \@fieldlist;

    # loop thru each field we have and set the tmpl_param
    while ( my ( $param, $tag ) = each %$tvar ) {
        $c->stash->{$param} = $tag;
    }
}

1;
