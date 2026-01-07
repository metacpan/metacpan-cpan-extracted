package Dancer2::Plugin::SyntaxHighlight::Perl;

our $VERSION = '1.00';

use strict; use warnings;
use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;
use Dancer2::Plugin;
use PPI::HTML;

plugin_keywords(qw/
    highlight_perl
    highlight_output
/);

has line_numbers => (
    is      => 'lazy',
    builder => sub { $_[0]->config->{'line_numbers'} || 0 },
);

has skip_postprocessing => (
    is => 'lazy',
    builder => sub { $_[0]->config->{'skip_postprocessing'} || 0 },
);

sub highlight_perl {
    my ( $self, $code ) = @_;

    my $perl = $code;
    my $PPI  = PPI::HTML->new( line_numbers => $self->line_numbers );
    my $html = $PPI->html( $perl );

    return $self->_postprocess( $html );
}

sub highlight_output {
    my ( $self, $output ) = @_;

    my $raw   = PPI::Document->new( $output )->content;
    my @lines = split "\n", $raw;
    my $line_number = 0;
    my $html;
    for ( @lines ) {
        my $class = ++$line_number == 1 ? 'prompt' : 'output';
        $html .= qq{<span class="$class">$_</span><br>};
    }

    return $self->_postprocess( $html );
};

sub _postprocess {
    my ( $self, $html ) = @_;
    return $html if $self->skip_postprocessing;

    $html =~ s/<BR>/\n/gi;
    $html =~ s/\n{2}/\n/msg;
    $html =~ s/(?:\A\s+|\s+\Z)//msg;

    return $html;
}

1;

__END__

=pod

=head1 VERSION

version 1.00

=head1 NAME

Dancer2::Plugin::SyntaxHighlight::Perl - Generate pretty HTML from Perl code in a Dancer2 app

=head1 DESCRIPTION

This module provides on-the-fly conversion of Perl to syntax-highlighted HTML. For convenience it adds the keywords C<highlight_perl> and C<highlight_output> to the Dancer2 DSL.

=head1 SYNOPSIS

=head2 Configuration

  plugins:
    'SyntaxHighlight::Perl':
        line_numbers: 1

=head2 Application code

  get '/perl_tutorial' => sub {
      return template 'perl_tutorial', {
          example_code   => highlight_perl('/path/to/file.pl'),
          example_output => highlight_output('/path/to/file.txt'),
      };
  };

=head2 HTML template

  <div style="white-space: pre-wrap">
    [% example_code %]
  </div>

Or:

  <div>
    <pre>[% example_code %]</pre>
  </div>

=head1 EXAMPLE OUTPUT

=for HTML <p><img src="https://raw.githubusercontent.com/1nickt/Dancer2-Plugin-SyntaxHighlight-Perl/master/examples/background-light-code.png"></p>

=head1 FUNCTIONS

=head2 highlight_perl

Takes as input the full pathname of a file, or a filehandle, or a reference to a scalar. Expects what it is given to contain Perl code.

Outputs Perl code as HTML with syntax highlighting, in the form of C<< <span></span> >> tags, with the appropriate class names, around the elements of the Perl code after it has been parsed by C<PPI>.

If C<line_numbers> is set to true in the Dancer2 config, the output will have line numbers.

For more details on the format of the ouput, see C<PPI::HTML>, or examine the files in the C<examples/> directory in this distribution.

You will need to provide the CSS for the styling, see C<examples/> for examples.

B<Important>: This module removes the C<< <BR> >> tags from the end of the generated HTML lines, so you B<must> enclose the HTML in either C<< <pre></pre> >> tags or an element with C<style="white-space: pre-wrap">>.

You can override this transformation by setting C<skip_postprocessing> to true in the Dancer2 config.

=head2 highlight_output

Often when showing Perl code you will want to show also the output of the code, This function adds very simple highlighting to the saved output of Perl code.

Takes as input the full pathname of a file, or a filehandle, or a reference to a scalar.

Outputs the content with the first line wrapped in a C<< <span></span> >> tag with the special class C<prompt>, and all other with the class  C<word>.

This generated HTML also must be enclosed in either C<< <pre></pre> >> tags or an element with C<style="white-space: pre-wrap"> (or set C<skip_postprocessing> to true in the Dancer2 config).

=head1 SEE ALSO

C<PPI>, C<PPI::HTML>

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
