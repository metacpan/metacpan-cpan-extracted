package Data::Downloader::MetadataTransformation;
use Log::Log4perl qw/:easy/;
use strict;
use warnings;

=head1 NAME

Data::Downloader::MetadataTransformation

=head1 DESCRIPTION

Apply transformations to metadata before making linktrees.

A metadata transformation is an object which is
associated with a L<repository|Data::Downloader::Repository>, that
describes a transformation that should be applied before
the linktree template is filled in.

It consists of :

    input - the name of the metadata item to be transformed
    output - the name of the variable in the path template (or intermediate variable)
    function_name - the function to be applied
    function_params - the parameters to be sent to that function

Valid functions are currently :

  split - split an incoming piece of metadata using a regular expression.
    function_params : optional regex (defaults to whitespeace)

  match - match a piece of metadata against a pattern.
    function_params : regex to match against.

  extract - extract a captured portion of a regular expression.
    function_params : a regex with a set of capturing parentheses.

=head1 EXAMPLES

Suppose a metadata named "tags" contains a list of words separated by whitespace.
The following sequence of transformations would convert this single string into a
list of strings, but only include the words which contain the letter "g" or "p":

   metadata_transformations:
     - input         : tags
       output        : one_tag
       function_name : split
       order_key     : 1
     - input         : one_tag
       output        : tag
       function_name : match
       function_params : "g|p"
       order_key      : 2

After applying these transformations, the string "<tag>" may be used in the
linktree templates.

=head1 METHODS

=over

=cut

our $availableFunctions = {
    # each function takes 1 or more arguments :
    #   1. the scalar value on which the function should act.
    #   2. any additional arguments for the function.
    # and should return a list of scalars.
    "split" => sub {
        my $value = shift;
        my $regex = shift || qr/\s+/;
        return unless defined($value);
        return split /$regex/, $value;
      },
    "match" => sub {
       my $value = shift;
       my $regex = shift or LOGDIE "missing regex parameter for match";
       return ($value =~ /$regex/ ? $value : undef);
    },
    "extract" => sub {
       my $value = shift;
       my $regex = shift or LOGDIE "missing regex parameter for extract";
       my ($extracted) = $value =~ /$regex/;
       return $extracted;
     },
};

=item apply

Apply a transformation to a hash of data.

Input :
    - a hash of data, one of the keys should match the input for
      this transformation.

Output :
    - an array of hashes: all of the keys are the same as the input
     hash, but there is a new key in each hash which corresponds to
     the output of the transformation.

Example :

  $self->apply( { foo => "bar baz"} );
  where
     $self->input    is foo
     $self->output   is boo
     $self->function_name is split
  produces
    [ { foo => "bar baz", boo => "bar" },
      { foo => "bar baz", boo => "baz" } ]

=cut

sub apply {
    my $self  = shift;
    my $input_data = shift;
    our $availableFunctions;
    TRACE sprintf("applying transformation %s for %s", $self->function_name,$self->output);
    my $function = $availableFunctions->{ $self->function_name }
      or LOGDIE "Unknown function : " . $self->function_name;
    my @function_params = defined( $self->function_params )
      ? split /,/, $self->function_params
      : ();
    my @new_values = $function->(
        $input_data->{ ( $self->input || $self->output ) },
        @function_params
    );
    return map +{ ( %$input_data, $self->output => $_) }, grep defined, @new_values;
}

1;

