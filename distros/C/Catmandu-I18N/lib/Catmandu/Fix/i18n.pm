package Catmandu::Fix::i18n;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Catmandu::Fix::Has;
use Catmandu::I18N;

has path => ( fix_arg => 1 );

has config => ( fix_opt => 1, required => 1 );

has lang => ( fix_opt => 1, required => 1 );

has args => ( fix_opt => 1 );

has i18n => ( is => "lazy" );

with "Catmandu::Fix::SimpleGetValue";

sub _build_i18n {
    my $self = $_[0];

    Catmandu::I18N->new(
        config => $self->config(),
        on_failure => "undef",
        fallback_languages => []
    );
}

sub emit_value {
    my ($self, $var, $fixer) = @_;

    my $perl = "";

    my $args = $fixer->generate_var();
    $perl .= "my ${args} = [];";

    if(is_string($self->args)){
        my $path_args = $fixer->split_path($self->args);
        my $key_args = pop @$path_args;
        $perl .= $fixer->emit_walk_path($fixer->var,$path_args,sub {
            my $var = shift;
            $fixer->emit_get_key($var,$key_args,sub{
                my $var = shift;
                my $p = <<EOF;
${args} = is_array_ref(${var}) ? ${var} : [];
EOF
            $p;
            })
        });
    }

    my $i18n = $fixer->capture( $self->i18n() );
    my $lang = $self->lang();

    $perl .= <<EOF;
${var} = ${i18n}\->t("${lang}",${var},\@${args});
EOF

    $perl;
}

=encoding utf8

=head1 NAME

Catmandu::Fix::i18n - lookup value in I18N

=head1 SYNOPSIS

    use Catmandu::Sane;
    use Catmandu;

    #In your catmandu config

    Catmandu->config->{i18n} = {
        en => [
          "Gettext",
          "/path/to/en.po"
        ],
        nl => [
          "Gettext",
          "/path/to/nl.po"
        ]
    };

    #In your fix

    #simple lookup
    i18n( "title", config => "i18n", lang => "en" )

    #lookup with arguments
    add_field("args.$append","Nicolas")
    i18n( "greeting", config => "i18n", lang => "en", args => "args" )

=head1 CONSTRUCTOR ARGUMENTS

=over

=item path

* path to i18n key

* specified as fix argument

* required

=item config

* path to i18n configuration in the Catmandu config

* specified as fix option

* required

=item lang

* language to use

* specified as fix option

* required

=item args

* path in current record where arguments are stored. Must be an array.

* specified as fix option

* optional

=back

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::I18N>, L<Catmandu>, L<Locale::Maketext>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
