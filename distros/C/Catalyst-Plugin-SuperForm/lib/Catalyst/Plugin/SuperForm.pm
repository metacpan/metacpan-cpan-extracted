package Catalyst::Plugin::SuperForm;

use strict;
use HTML::SuperForm;
use HTML::SuperForm::Field;
use HTML::SuperForm::Field::Checkbox;
use HTML::SuperForm::Field::CheckboxGroup;
use HTML::SuperForm::Field::Hidden;
use HTML::SuperForm::Field::Password;
use HTML::SuperForm::Field::Radio;
use HTML::SuperForm::Field::RadioGroup;
use HTML::SuperForm::Field::Select;
use HTML::SuperForm::Field::Submit;
use HTML::SuperForm::Field::Text;
use HTML::SuperForm::Field::Textarea;

our $VERSION = '0.01';

*sform = \&superform;

sub superform {
    my $c = shift;

    unless ( $c->{superform} ) {
        $c->{superform} = HTML::SuperForm->new( $c->request->parameters );
        $c->{superform}->fallback(1);
        $c->{superform}->sticky(1);
    }

    return $c->{superform};
}

1;

__END__

=head1 NAME

Catalyst::Plugin::SuperForm - Create sticky HTML forms

=head1 SYNOPSIS

    use Catalyst qw[SuperForm];

    print $c->superform->text( 
        name => 'test'
    );

    print $c->superform->select(
        name   => 'select',
        labels => {
            'DE' => 'Germany',
            'SE' => 'Sweden',
            'US' => 'United States'
        }
    );

    # Alias
    print $c->sform->text( name => 'test' );


=head1 DESCRIPTION

Create sticky forms with C<HTML::SuperForm>.

=head1 METHODS

=over 4

=item sform

alias to superform

=item superform

Returns a instance of C<HTML::SuperForm>.

=back

=head1 SEE ALSO

L<HTML::SuperForm>, L<Catalyst>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut
