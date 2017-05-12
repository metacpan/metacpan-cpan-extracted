package Data::HTMLDumper;
use strict; use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	Dumper
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	Dumper
);

our $VERSION = '0.08';

use Data::HTMLDumper::Output;
use Data::Dumper ();
use Parse::RecDescent;

our $actions  = new Data::HTMLDumper::Output();
our $Maxdepth;
our $Varname;
our $Sortkeys;

tie $Maxdepth, 'SpecialVars', \$Data::Dumper::Maxdepth;
tie $Varname,  'SpecialVars', \$Data::Dumper::Varname;
tie $Sortkeys, 'SpecialVars', \$Data::Dumper::Sortkeys;

sub actions {
    my $class   = shift;
    my $new_val = shift;

    $actions    = $new_val if (defined $new_val);
    return $actions;
}

#$::RD_HINT = 1;
#$::RD_TRACE = 1;

my $grammar = q{
    { our $actions = sub { return Data::HTMLDumper::actions(); } }
    output : expression(s) { &{$actions}->output($item[1]) }

    expression : SIGIL ID_NAME '=' item ';' {
                     &{$actions}->expression(%item);
                 }
               | <error>

    item : value       COMMA(?) { &{$actions}->item_value ($item{value},
                                                            $arg[0])     }
         | array       COMMA(?) { &{$actions}->item_array ($item{array}) }
         | hash        COMMA(?) { &{$actions}->item_hash  ($item{hash} ) }
         | object      COMMA(?) { &{$actions}->item_object($item{object})}
         | inside_out_object COMMA(?) {
                &{$actions}->item_inside_out_object(
                    $item{inside_out_object}
                );
           }

    array  : '[' item(s) ']'    { &{$actions}->array($item{'item(s)'}) }
           | '[' ']'            { &{$actions}->array_empty()           }

    hash   : '{' pair(s) '}'    { &{$actions}->hash($item{'pair(s)'}) }
           | '{' '}'            { &{$actions}->hash_empty()           }

    pair   : string '=>' item['make_row'] {
        &{$actions}->pair($item{string}, $item{item});
    }

    object : 'bless(' item string ')' {
        &{$actions}->object($item{item}, $item{string});
    }

    inside_out_object : 'bless(' do_block COMMA string ')' {
        &{$actions}->inside_out_object($item{do_block}, $item{string});
    }

    do_block : 'do' '{' NOT_BRACE '}' { $item{NOT_BRACE}; }

    NOT_BRACE : /[^\}]*/ { $item[1]; }

    value : string | NUMBER | 'undef'
    
    string : TICK text TICK { &{$actions}->string($item{text}) }

    KEY_NAME : /[.\w\d_]+/

    ID_NAME  : /\w[\w\d_]*/

    NUMBER : /[+-]?(\d\.?\d*|\d*.\d+)/

    SIGIL : '$' | '@' | '%'

    text  : text_letter(s)     {local $" = "", "@{$item{'text_letter(s)'}}" }

    text_letter : ESCAPED_TICK
                | NON_TICK
    
    NON_TICK : /[^'\\\]*/

    ESCAPED_TICK : /(\\\')/  { "'" }

    COMMA : ','

    TICK  : "'"
};

#    do_block : 'do' '{' /[^}]*/ '}' { $item[3]; }

my $parse   = new Parse::RecDescent($grammar);

sub Dumper  {
    my $original_output = Data::Dumper::Dumper(@_);
    my $output          = $parse->output($original_output);
    return $output;
}

sub new {
    my $class  = shift;
    my $dumper = Data::Dumper->new(@_);

    return bless {dumper => $dumper}, $class;
}

sub Dump {
    my $invocant = shift;
    my $original_output;
    my $output;

    if (ref $invocant) { $original_output = $invocant->{dumper}->Dump(@_); }
    else               { $original_output = Data::Dumper->Dump(@_);        }

    return $parse->output($original_output);
}

package SpecialVars;

sub TIESCALAR {
    my $class      = shift;
    my $dumper_var = shift;

    return bless $dumper_var, $class;
}

sub FETCH {
    my $self = shift;

    return $$self;
}

sub STORE {
    my $self  = shift;
    my $value = shift;

    $$self = $value;
}

1;
__END__

=head1 NAME

Data::HTMLDumper - Uses Data::Dumper to make HTML tables of structures

=head1 SYNOPSIS

  use Data::HTMLDumper;

  # to take control of the output:
  Data::HTMLDumper->actions($your_action_object);
  # See Data::HTMLDumper::Output.pm for what $your_action_object must do,
  # or see CONTROLLING OUTPUT below for a small example.

  ...

  print Dumper(\%hash, \@list);

  # or to supply names like Data::Dumper->Dump:
  print Data::HTMLDumper->Dump([\%hash, \@list], [qw(hash list)]);

=head1 ABSTRACT

  Data::HTMLDumper turns Data::Dumper output into HTML tables.
  It's for those who like Data::Dumper for quick peeks at their
  structures, but need to display the output in a web browser.

=head1 DESCRIPTION

If you like to use Data::Dumper for quick and dirty pictures of your structures
during development, but you are now developing for the web, this module might
be for you.  It uses Data::Dumper, but formats the results as HTML tables.

The format of the tables changed with the introduction of Parse::RecDescent
with version 0.04.  The new tables are more consistent.

As of version 0.06 the Dumper function handles any number of references.
The object oriented Dump method works like its analog in Data::Dumper.
The rest of the functions (except new) are not yet available (but
see 'SPECIAL VARIABLES' for how to avoid needing some of them).

=head1 SPECIAL VARIABLES

Several special variables are available as of version 0.06.  This include
Maxdepth (to limit how deep the traversal goes), Varname (to let you replace
$VAR2 with $YourPrefix2), and Sortkeys (which sorts hash keys as strings).
Currently you must use these through the following special variables:

    $Data::HTMLDumper::Maxdepth;
    $Data::HTMLDumper::Varname;
    $Data::HTMLDumper::Sortkeys;

Note that to even see the Varname prefix, you must implement your own
callback object, perhaps by subclassing Data::HTMLDumper::Output.

=head1 CONTROLLING OUTPUT

If you need to change the way the tables appear, you can (as of version 0.06)
subclass Data::HTMLDumper::Output to implement your changes.  You must also
tell Data::HTMLDumper to make the change.  Here is a sample similar to
one used in test number 09:

    use Data::HTMLDumper;

    Data::HTMLDumper->actions(MyOutput->new());

    my $data = [qw(some data)];

    print Data::HTMLDumper->Dump([$data], ['data']);

    package MyOutput;

    use base 'Data::HTMLDumper::Output';

    sub expression {
        my $self = shift;
        my %item = @_;

        return "<table border='1'><tr><th>$item{ID_NAME}</th></tr>\n"
             . "$item{item}</table>\n";
    }

This adds a heading row to each table listing the name supplied
to Dump (it would use VAR1 if you called Dumper).

The key is to create your own package (MyOutput above) making it inherit
from Data::HTMLDumper::Output (e.g. via use base).  This saves you having
to implement all of the Output methods (of which there are about 12).

=head2 EXPORT

Dumper

=head1 DEPENDENCIES

Data::Dumper
Parse::RecDescent
Data::HTMLDumper::Output

=head1 BUGS and OMISSIONS

Though Data::Dumper is used, not all (or even most) of its features are
implemented.

These features will be added as developer time permits:

    Seen
    Values
    Names
    Reset

Some of these may be implemented depending on interest:

    Terse
    Deepcopy
    Freezer

Here is a list of features that will never be available (with explanations
of what to do instead):

=over

=item Indent

this affects the appearance of the text output.  To affect the appearance
of the HTML tables (or to do something totally different) implement a
subclass of Data::HTMLDumper::Output

=item Purity

builds fully "eval"able code.  What we're doing here is making pretty HTML
tables.  There is no use to replicating Data::Dumper's ability to restore
data structures.

=item Pad

like indent, this affects the appearance of the output.

=item Useqq

controls how special characters in strings are masked.  HTML requires a
different approach, see Data::HTMLDumper::Output->string for an example
of the kind of work you need to do to have things rendered properly.

=item Toaster

allows objects to control how they are displayed.  Override the callback method
Data::HTMLDumper::Output->object to control object display.  Redispatch
to the object or its class if you like.

=item Quotekeys

controls whether quotes are always used around hash keys.  Data::HTMLDumper
strips these during parsing, whether they appear or not.  You can control
the appearance of hash keys by overriding Data::HTMLDumper::Output->pair.

=item Bless

allows the caller to replace the builtin bless with their own function.
Since we are only concerned with appearance here, you should implement
your own Data::HTMLDumper::Output->object.

=item Useperl

for developers of Data::Dumper to turn off XS use during debugging.

=item Deparse

tries to turn code references back into Perl source with B::Deparse.

=back

Attempts to access these concepts through direct use of Data::Dumper
is not wise.  Doing so will alter the output of Data::Dumper (duh).
That new form will not agree with my grammar and Bad Things will
happen, such as fatal parsing errors.

Starting with version 0.04 Data::HTMLDumper uses Parse::RecDescent instead
of its old regex substitution scheme.  This means that your structure will
produce nothing but an error if my grammar is not good enough.  If that
happens to you, please send me a sample of the structure so that I can
correct the grammar.

Starting with version 0.06 you can call Data::Dumper with multiple arguments,
but the test suite for this is not complete.  If you encounter problems,
please send in samples of what broke.

=head1 SEE ALSO

This module depends on Data::Dumper to do the real work.  Check its
documentation for details about how to call Dumper and Dump.

As of version 0.06 Data::HTMLDumper uses Data::HTMLDumper::Output to
produce the tables.  By subclassing it, or replacing it, you can
take a considerable amount of control over the appearance of the final
output.  You could even produce XML or something else.

=head1 AUTHOR

Phil Crow, E<lt>philcrow2000@yahoo.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-4 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.0 itself. 

=head1 CREDITS

Thanks to Dennis Sutch for patches and encouragement to make the module
substantially more robust.

=cut
