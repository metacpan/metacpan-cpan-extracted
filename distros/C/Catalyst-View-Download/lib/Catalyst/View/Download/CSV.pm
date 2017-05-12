package Catalyst::View::Download::CSV;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Catalyst::Exception;
use Text::CSV;

=head1 NAME

Catalyst::View::Download::CSV

=head1 VERSION

0.05

=cut

our $VERSION = "0.05";
$VERSION = eval $VERSION;

__PACKAGE__->config(
    'stash_key'             => 'csv',
    'quote_char'            => '"',
    'escape_char'           => '"',
    'sep_char'              => ',',
    'eol'                   => "\n",
    'binary'                => 1,
    'allow_loose_quotes'    => 1,
    'allow_loose_escapes'   => 1,
    'allow_whitespace'      => 1,
    'always_quote'          => 1
);

sub process {
    my $self = shift;
    my ($c) = @_;

    my $template = $c->stash->{template};
    my $content = $self->render( $c, $template, $c->stash );

    $c->res->headers->header( "Content-Type" => "text/csv" )
      unless ( $c->res->headers->header("Content-Type") );
    $c->res->body($content);
}

sub render {
    my $self = shift;
    my ( $c, $template, $args ) = @_;

    my $stash_key = $self->config->{'stash_key'};
    return '' unless $args->{$stash_key} && ref($args->{$stash_key}) =~ /ARRAY/;

    my $csv = Text::CSV->new(
        {
            quote_char          => $self->config->{'quote_char'},
            escape_char         => $self->config->{'escape_char'},
            sep_char            => $self->config->{'sep_char'},
            eol                 => $self->config->{'eol'},
            binary              => $self->config->{'binary'},
            allow_loose_quotes  => $self->config->{'allow_loose_quotes'},
            allow_loose_escapes => $self->config->{'allow_loose_escapes'},
            allow_whitespace    => $self->config->{'allow_whitespace'},
            always_quote        => $self->config->{'always_quote'}
        }
    );

    my $content;
    foreach my $row ( @{ $args->{$stash_key} } ) {
        my $status = $csv->combine( @{ $row } );
        Catalyst::Exception->throw(
            "Text::CSV->combine Error: " . $csv->error_diag() )
          if ( !$status );
        $content .= $csv->string();
    }

    return $content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    # lib/MyApp/View/Download/CSV.pm
    package MyApp::View::Download::CSV;
    use base qw( Catalyst::View::Download::CSV );
    1;

    # lib/MyApp/Controller/SomeController.pm
    sub example_action_1 : Local {
        my ($self, $c) = @_;

        # Array reference of array references.
        my $data = [
          ['col 1','col 2','col ...','col N'], # row 1
          ['col 1','col 2','col ...','col N'], # row 2
          ['col 1','col 2','col ...','col N'], # row ...
          ['col 1','col 2','col ...','col N']  # row N
        ];

        # To output your data in comma seperated values pass your array by reference
        # into hatever stash key you have defined (default is 'csv'). Content passed
        # via the stash must be passed in a hashref in the key labeled 'data'.
        $c->stash->{'csv'} = $data;

        # Finally forward processing to the CSV View
        $c->forward('MyApp::View::Download::CSV');
    }

=head1 DESCRIPTION

Takes a nested array and outputs CSV formatted content.

=head1 SUBROUTINES

=head2 process

This method will be called by Catalyst if it is asked to forward to a component
without a specified action.

=head2 render

Allows others to use this view for much more fine-grained content generation.

=head1 CONFIG

=over 4

=item stash_key

Determines the key in the stash this view will look for when attempting to
retrieve data to process. If this key isn't found it will then look at the
stash as a whole, find any array references and process them. Data passed into
the defined stash_key must be a HASHREF with at least the key 'data' existing
with the nested array of data to create a CSV from.

	$c->view('MyApp::View::Download::CSV')->config->{'stash_key'} = 'data';

=item quote_char

Determines what value will be enclosed within if it contains whitespace or the
delimiter character. DEFAULT: '"'

  $c->view('MyApp::View::Download::CSV')->config->{'quote_char'} = '/';

=item escape_char

Determines what value will be to escape any delimiter's found in a column. DEFAULT: '"'

  $c->view('MyApp::View::Download::CSV')->config->{'escape_char'} = '/';

=item sep_char

Determines the separator between columns. DEFAULT: ','

  $c->view('MyApp::View::Download::CSV')->config->{'sep_char'} = '|';

=item eol

Any characters defined in eol will be placed at the end of a row. DEFAULT: '\n'

  $c->view('MyApp::View::Download::CSV')->config->{'eol'} = '\0';

=back

=head1 AUTHOR

Travis Chase, C<< <gaudeon at cpan dot org> >>

=head1 SEE ALSO

L<Catalyst> L<Catalyst::View> L<Catalyst::View::Download> L<Text::CSV>

=head1 LICENSE

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
