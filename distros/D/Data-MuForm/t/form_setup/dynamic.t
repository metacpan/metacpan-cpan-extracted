use strict;
use warnings;
use Test::More;

use Data::MuForm;
my @select_options = ( {value => 1, label => 'One'}, {value => 2, label => 'Two'}, {value => 3, label => 'Three'} );
my $args =  {
    name       => 'test',
    field_list => [
        {
            name => 'username',
            type  => 'Text',
            apply => [ { check => qr/^[0-9a-z]*/, message => 'Contains invalid characters' } ],
        },
        {
            name => 'password',
            type => 'Text',
        },
        {
            name => 'a_number',
            type      => 'Integer',
            range_min => 12,
            range_max => 291,
        },
        {
            name => 'on_off',
            type           => 'Checkbox',
            checkbox_value => 'yes',
            input_without_param => 'no'
        },
        {
            name => 'long_text',
            type => 'Textarea',
        },
        {
            name => 'hidden_text',
            type    => 'Hidden',
            default => 'bob',
        },
        {
            name => 'a_select',
            type    => 'Select',
            options => \@select_options,
        },
        {
            name => 'b_select',
            type     => 'Select',
            options  => \@select_options,
            multiple => 1,
            size     => 4,
        },
        {
            name => 'c_select',
            type    => 'Select',
            options => \@select_options,
            widget  => 'radio_group',
        },
        {
            name => 'd_select',
            type     => 'Select',
            options  => \@select_options,
            multiple => 1,
            widget   => 'checkbox_group'
        },
        {
            name => 'sub',
            type => 'Compound',
        },
        {
            name => 'sub.user',
            type  => 'Text',
            apply => [ { check => qr/^[0-9a-z]*/, message => 'Not a valid user' } ],
        },
        {
            name => 'sub.name',
            type  => 'Text',
            apply => [ { check => qr/^[0-9a-z]*/, message => 'Not a valid name' } ],
        },
        {
            name => 'reset',
            type => 'Reset',
        },
        {
            name => 'submit',
            type => 'Submit',
        },
    ]
};
my $form = Data::MuForm->new( %$args );

ok( $form, 'form builds ok' );

is( $form->num_fields, 13, 'right number of fields' );

done_testing;
