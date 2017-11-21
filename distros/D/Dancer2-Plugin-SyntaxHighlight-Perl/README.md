# NAME

Dancer2::Plugin::SyntaxHighlight::Perl - Generate pretty HTML from Perl code in a Dancer2 app

# DESCRIPTION

This module provides on-the-fly conversion of Perl to syntax-highlighted HTML. For convenience it adds the keywords `highlight_perl` and `highlight_output` to the Dancer2 DSL.

# SYNOPSIS

## Configuration

    plugins:
      'SyntaxHighlight::Perl':
          line_numbers: 1

## Application code

    get '/perl_tutorial' => sub {
        return template 'perl_tutorial', {
            example_code   => highlight_perl('/path/to/file.pl'),
            example_output => highlight_output('/path/to/file.txt'),
        };
    };

## HTML template

    <div style="white-space: pre-wrap">
      [% example_code %]
    </div>

Or:

    <div>
      <pre>[%example_code %]</pre>
    </div>

# EXAMPLE OUTPUT

# FUNCTIONS

## highlight\_perl

Takes as input the full pathname of a file, or a filehandle, or a reference to a scalar. Expects what it is given to contain Perl code.

Outputs Perl code as HTML with syntax highlighting, in the form of `<span></span>` tags, with the appropriate class names, around the elements of the Perl code after it has been parsed by `PPI`.

If `line_numbers` is set to true in the Dancer2 config, the output will have line numbers.

For more details on the format of the ouput, see `PPI::HTML`, or examine the files in the `examples/` directory in this distribution.

You will need to provide the CSS for the styling, see `examples/` for examples.

**Important**: This module removes the `<BR>` tags from the end of the generated HTML lines, so you **must** enclose the HTML in either `<pre></pre>` tags or an element with `style="white-space: pre-wrap"`>.

You can override this transformation by setting `skip_postprocessing` to true in the Dancer2 config.

## highlight\_output

Often when showing Perl code you will want to show also the output of the code, This function adds very simple highlighting to the saved output of Perl code.

Takes as input the full pathname of a file, or a filehandle, or a reference to a scalar.

Outputs the content with the first line wrapped in a `<span></span>` tag with the special class `prompt`, and all other with the class  `word`.

This generated HTML also must be enclosed in either `<pre></pre>` tags or an element with `style="white-space: pre-wrap"` (or set `skip_postprocessing` to true in the Dancer2 config).

# SEE ALSO

`PPI`, `PPI::HTML`
