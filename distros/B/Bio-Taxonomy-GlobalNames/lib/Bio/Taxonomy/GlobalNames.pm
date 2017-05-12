package Bio::Taxonomy::GlobalNames;

use 5.10.0;
use strict;
use warnings;

use JSON qw(encode_json);
use JSON::Parse qw(parse_json);
use LWP::UserAgent;
use Moo::Lax;
use REST::Client;
use Scalar::Readonly;

=head1 NAME

Bio::Taxonomy::GlobalNames - Perlish OO bindings to the L<Global Names Resolver|http://resolver.globalnames.org/> API

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use Bio::Taxonomy::GlobalNames;

    # Provide the input data and parameters.
    my $query = Bio::Taxonomy::GlobalNames->new(
        names           => $names,
        data_source_ids => $data_source_ids,
        resolve_once    => $resolve_once,
    );

    my $output = $query->post();    # Perform a POST request and return the output.

    # Go through the Output object.
    my @data = @{ $output->data };

    foreach my $datum (@data)
    {
	
        # Check if a non-empty Results arrayref was returned.
        if ( my @results = @{ $datum->results } )
        {

            # Parse the Results objects.
            foreach my $result (@results)
            {

                # Retrieve the canonical name and score for each result.
                my $canonical_name = $result->canonical_form;
                my $score          = $result->score;
            }
        }
    }

=head1 DESCRIPTION

B<Bio::Taxonomy::GlobalNames> provides Perl objects and functions that 
interface with the Global Names Resolver web service. Using a REST client, 
input is sent to the service, whereas results are internally converted 
from JSON format to nested objects and returned to the user.

This module can be used for automated standardisation of species names, 
according to a variety of sources that can be manually selected, if needed. 
See also the example script, provided with this module.

=head2 Attributes for Bio::Taxonomy::GlobalNames objects

=over 1

=item data

A string with a list of names delimited by new lines. 
You may optionally supply your local id for each name as: 

     123|Parus major
     125|Parus thruppi
     126|Parus carpi

Names in the response will contain your supplied ids, facilitating integration. 

B<The attributes 'data', 'file' and 'names' are mutually exclusive.>

=item data_source_ids

A string with a pipe-delimited list of data sources. 
See the list of L<data sources|http://resolver.globalnames.org/data_sources>.

=item file

A file B<in Unicode encoding> with a list of names delimited by new lines, 
similar to the 'data' attribute.
This attribute is valid only when the post method is used.

B<The attributes 'data', 'file' and 'names' are mutually exclusive.>

=item names

A string with a list of names delimited by either pipe "|" or tab "\t". 
Use a pipe with the get method. 

B<The attributes 'data', 'file' and 'names' are mutually exclusive.>

=item resolve_once

A string with a boolean (true/false) value. Default: 'false'. 
Find the first available match instead of matches across all data sources with all possible renderings of a name. 

When 'true', response is rapid but incomplete.

=item with_context

A string with a boolean (true/false) value. Default: 'true'. 
Reduce the likelihood of matches to taxonomic homonyms. 

When 'true', a common taxonomic context is calculated for all supplied names 
from matches in data sources that have classification tree paths. 
Names out of determined context are penalized during score calculation. 

=back

=cut

###############################################
# Main object attributes with rw permissions. #
###############################################
has file => (
    is      => 'rw',
    default => q{},
);

has names => (
    is      => 'rw',
    default => q{},
);

has data => (
    is      => 'rw',
    default => q{},
);

has data_source_ids => (
    is      => 'rw',
    default => q{},
);

has resolve_once => (
    is      => 'rw',
    default => 'false',
    isa     => sub {
        die "resolve_once may be either true or false!\n"
          unless $_[0] =~ /^true|false$/;
    },
);

has with_context => (
    is      => 'rw',
    default => 'true',
    isa     => sub {
        die "with_context may be either true or false!\n"
          unless $_[0] =~ /^true|false$/;
    },
);

# Make sure that the website is up.
sub _check_status
{
    my ($url) = @_;

    my $ua = LWP::UserAgent->new( timeout => 5 );
    my $response = $ua->get($url);
    return $response->is_success ? 1 : 0;
}

=head3 Methods for Bio::Taxonomy::GlobalNames objects

=over 1

=item B<get>

Performs a GET request and returns an C<Output> object.

=back

=cut

sub get
{
    my $self = shift;

    my $name;

    # Make sure that only one source of names was given.
    if ( $self->names ne q{} && $self->data ne q{} )
    {
        die "The attributes 'names' and 'data' are mutually exclusive!\n";
    }
    elsif ( $self->names ne q{} )
    {
        my $proper_name = $self->names;

        # Substitute space with '+'.
        $proper_name =~ s/ /+/g;
        $name = '?names=' . $proper_name;
    }
    else
    {
        my $proper_data = $self->data;

        # Substitute space with '+'.
        $proper_data =~ s/ /+/g;
        $name = '?names=' . $proper_data;
    }

    my $gnr_url;
    if ( _check_status('http://resolver.globalnames.org/') )
    {
        $gnr_url = 'http://resolver.globalnames.org/name_resolvers.json';
    }
    elsif ( _check_status('http://resolver.globalnames.biodinfo.org') )
    {
        $gnr_url =
          'http://resolver.globalnames.biodinfo.org/name_resolvers.json';
    }
    else
    {
        die "The Global Names Resolver website is down.\n";
    }

    # Create the target url.
    my $url =
        $gnr_url 
      . $name
      . '&resolve_once='
      . $self->resolve_once
      . '&with_context='
      . $self->with_context
      . '&data_source_ids='
      . $self->data_source_ids;

    # Create the REST client and perform a GET request.
    my $rest_client = REST::Client->new();
    $rest_client->GET($url);

    # Parse the results in JSON format and return them
    # as an Output object.
    return Bio::Taxonomy::GlobalNames::Output::format_results(
        parse_json( $rest_client->responseContent() ) );
}

=over 1

=item B<post>

Performs a POST request and returns an C<Output> object. 
If you are supplying an input file, you have to use the 'post' method.

=back

=cut

sub post
{
    my $self = shift;

    my $body = {
        'format'          => 'json',
        'data_source_ids' => $self->data_source_ids,
        'resolve_once'    => $self->resolve_once,
        'with_context'    => $self->with_context,
    };

    # Check the number of valid name sources provided.
    my $input_check = 0;

    my @input_data = ( $self->file, $self->names, $self->data );

    foreach (@input_data)
    {

        # If the source is not empty, increment the counter.
        if ( $_ ne q{} )
        {
            $input_check++;
        }
    }

    # If the counter is bigger than 1, die.
    if ( $input_check > 1 )
    {
        die
          "The attributes 'file', 'names' and 'data' are mutually exclusive!\n";
    }
    elsif ( $self->file ne q{} && -r $self->file )
    {

        # If a readable file was provided, read its content.
        local $/ = undef;
        open my $fh, '<:encoding(UTF-8)', $self->file;

        $body->{'data'} = <$fh>;

        # Remove single and double quotes from the file's contents.
        $body->{'data'} =~ s/['"]//g;

        close $fh;
    }
    elsif ( $self->names ne q{} )
    {
        $body->{'names'} = $self->names;
    }
    else
    {
        $body->{'data'} = $self->data;
    }

    # Inform the server that we're sending JSON encoded content.
    my $headers = { Content_Type => 'application/json' };

    my $gnr_url;
    if ( _check_status('http://resolver.globalnames.org/') )
    {
        $gnr_url = 'http://resolver.globalnames.org/name_resolvers';
    }
    elsif ( _check_status('http://resolver.globalnames.biodinfo.org') )
    {
        $gnr_url = 'http://resolver.globalnames.biodinfo.org/name_resolvers';
    }
    else
    {
        die "The Global Names Resolver website is down.\n";
    }

    # Encode data to JSON format, create the REST client and perform
    # a POST request.
    my $data        = encode_json($body);
    my $rest_client = REST::Client->new();
    $rest_client->POST( $gnr_url, ( $data, $headers ) );

    # Parse the results in JSON format and return them
    # as an Output object.
    return Bio::Taxonomy::GlobalNames::Output::format_results(
        parse_json( $rest_client->responseContent() ) );
}

=head2 Attributes for Output objects

=over 1

=item $output->context

A C<Context> object, if 'with_context' parameter is set to true.

=item $output->data

An array reference of C<Data> objects, containing query input(s) and results.

    my @data = @{ $output->data };

=item $output->data_sources

An array reference of C<DataSources> objects, whose ids you used for name resolution. 
If no data sources were given, the array reference is empty.

    my @data_sources = @{ $output->data_sources };

=item $output->id

The resolver request id. Your request is stored temporarily in the remote database and is assigned an id.

=item $output->parameters

A C<Parameters> object, containing the parameters of the query.

=item $output->status B<or> $output->message

The final status of the request -- 'success' or 'failure'.

=item $output->status_message

The message associated with the status.

=item $output->url

The url at which you can access your results for 7 days.

=back

=cut

package Bio::Taxonomy::GlobalNames::Output;

use Moo::Lax;

#################################################
# Output object attributes with ro permissions. #
#################################################
has status         => ( is => 'ro', );
has data_sources   => ( is => 'ro', );
has data           => ( is => 'ro', );
has message        => ( is => 'ro', );
has parameters     => ( is => 'ro', );
has url            => ( is => 'ro', );
has context        => ( is => 'ro', );
has id             => ( is => 'ro', );
has status_message => ( is => 'ro', );

# Create an Output object with results and data as sub-objects.
sub format_results
{
    my ($input) = @_;

    my @elements = qw(
      status     data_sources data    message
      parameters url          context id
      status_message
    );

    # If something isn't defined, set it as the empty string.
    foreach (@elements)
    {

        # Avoid readonly variables caused by JSON conversion.
        if ( Scalar::Readonly::readonly( $input->{$_} ) )
        {
            Scalar::Readonly::readonly_off( $input->{$_} );
        }
        $input->{$_} //= q{};
    }

    # Build the object.
    my $results_object = Bio::Taxonomy::GlobalNames::Output->new(
        'status' => $input->{'status'},
        'data_sources' =>
          Bio::Taxonomy::GlobalNames::Output::DataSources::object(
            $input->{'data_sources'}
          ),
        'data' =>
          Bio::Taxonomy::GlobalNames::Output::Data::object( $input->{'data'} ),
        'message'    => $input->{'message'},
        'parameters' => Bio::Taxonomy::GlobalNames::Output::Parameters::object(
            $input->{'parameters'}
        ),
        'url'     => $input->{'url'},
        'context' => Bio::Taxonomy::GlobalNames::Output::Context::object(
            $input->{'context'}
        ),
        'id'             => $input->{'id'},
        'status_message' => $input->{'status_message'}
    );

    return $results_object;
}

=head2 Attributes for Data objects

=over 1

=item $datum->results

An array reference of C<Results> objects.

    my @results = @{ $datum->results };

=item $datum->supplied_id

The id of the name string in the query (if provided).

=item $datum->supplied_name_string

The name string in the query.

=back

=cut

package Bio::Taxonomy::GlobalNames::Output::Data;

use Moo::Lax;

#################################################
# Data object attributes with ro permissions.   #
#################################################
has supplied_name_string => ( is => 'ro', );
has supplied_id          => ( is => 'ro', );
has results              => ( is => 'ro', );

# Create an array of Data objects.
sub object
{
    my ($input) = @_;

    my @results;

    # If the input is empty, set it as an empty array.
    if ( $input eq q{} )
    {
        $input = [];
    }

    # If the arrayref isn't empty...
    foreach my $species ( @{$input} )
    {

        # If something isn't defined, set it as the empty string.
        for ( 'supplied_name_string', 'supplied_id', 'results' )
        {

            # Avoid readonly variables caused by JSON conversion.
            if ( Scalar::Readonly::readonly( $species->{$_} ) )
            {
                Scalar::Readonly::readonly_off( $species->{$_} );
            }
            $species->{$_} //= q{};
        }

        # Create the object.
        my $resulting_object = Bio::Taxonomy::GlobalNames::Output::Data->new(
            'supplied_name_string' => $species->{'supplied_name_string'},
            'supplied_id'          => $species->{'supplied_id'},
            'results' =>
              Bio::Taxonomy::GlobalNames::Output::Data::Results::object(
                $species->{'results'}
              ),
        );
        push @results, $resulting_object;
    }

    return \@results;
}

=head2 Attributes for Results objects

=over 1

=item $result->canonical_form

A "canonical" version of the name generated by the Global Names parser.

=item $result->classification_path

Tree path to the root if a name string was found within a data source classification.

=item $result->classification_path_ids

Tree path to the root using taxon_ids, if a name string was found within a data source classification.

=item $result->classification_path_ranks

=item $result->data_source_id

The id of the data source where a name was found.

=item $result->data_source_title

The title of the data source where a name was found.

=item $result->gni_uuid

An identifier for the found name string used in Global Names.

=item $result->local_id

Shows id local to the data source (if provided by the data source manager).

=item $result->match_type

Explains how resolver found the name. 
If the resolver cannot find names corresponding to the entire queried name string, 
it sequentially removes terminal portions of the name string until a match is found.

1 - Exact match

2 - Exact match by canonical form of a name

3 - Fuzzy match by canonical form

4 - Partial exact match by species part of canonical form

5 - Partial fuzzy match by species part of canonical form

6 - Exact match by genus part of a canonical form

=item $result->name_string

The name string found in this data source.

=item $result->prescore

Displays points used to calculate the score delimited by '|' -- 
"Match points|Author match points|Context points". 
Negative points decrease the final result.

=item $result->score

A confidence score calculated for the match. 
0.5 means an uncertain result that will require investigation. 
Results higher than 0.9 correspond to 'good' matches. 
Results between 0.5 and 0.9 should be taken with caution. 
Results less than 0.5 are likely poor matches. 
The scoring is described in more details at L<http://resolver.globalnames.org/about>.

=item $result->taxon_id

An identifier supplied in the source Darwin Core Archive for the name string record.

=back

=cut

package Bio::Taxonomy::GlobalNames::Output::Data::Results;

use Moo::Lax;

##################################################
# Results object attributes with ro permissions. #
##################################################
has data_source_title         => ( is => 'ro', );
has match_type                => ( is => 'ro', );
has gni_uuid                  => ( is => 'ro', );
has taxon_id                  => ( is => 'ro', );
has classification_path_ids   => ( is => 'ro', );
has canonical_form            => ( is => 'ro', );
has name_string               => ( is => 'ro', );
has score                     => ( is => 'ro', );
has prescore                  => ( is => 'ro', );
has classification_path       => ( is => 'ro', );
has classification_path_ranks => ( is => 'ro', );
has data_source_id            => ( is => 'ro', );
has local_id                  => ( is => 'ro', );

# Create an array of Results objects.
sub object
{
    my ($input) = @_;

    my @array = qw(
      data_source_title         match_type
      gni_uuid                  taxon_id
      classification_path_ids   canonical_form
      name_string               score
      prescore                  classification_path
      classification_path_ranks data_source_id
      local_id
    );

    my @results;

    # If the input is empty, set it as an empty array.
    if ( $input eq q{} )
    {
        $input = [];
    }

    # If the arrayref isn't empty...
    foreach my $hit ( @{$input} )
    {

        # If something isn't defined, set it as the empty string.
        foreach (@array)
        {

            # Avoid readonly variables caused by JSON conversion.
            if ( Scalar::Readonly::readonly( $hit->{$_} ) )
            {
                Scalar::Readonly::readonly_off( $hit->{$_} );
            }
            $hit->{$_} //= q{};
        }

        # Create the object.
        my $resulting_object =
          Bio::Taxonomy::GlobalNames::Output::Data::Results->new(
            'data_source_title'       => $hit->{'data_source_title'},
            'match_type'              => $hit->{'match_type'},
            'gni_uuid'                => $hit->{'gni_uuid'},
            'taxon_id'                => $hit->{'taxon_id'},
            'classification_path_ids' => $hit->{'classification_path_ids'},
            'canonical_form'          => $hit->{'canonical_form'},
            'name_string'             => $hit->{'name_string'},
            'score'                   => $hit->{'score'},
            'prescore'                => $hit->{'prescore'},
            'classification_path'     => $hit->{'classification_path_ranks'},
            'data_source_id'          => $hit->{'data_source_id'},
            'local_id'                => $hit->{'local_id'},
          );
        push @results, $resulting_object;
    }

    return \@results;
}

=head2 Attributes for DataSources objects

=over 1

=item $data_source->id

The ID of the data source.

=item $data_source->title

The name of the data source.

=back

=cut

package Bio::Taxonomy::GlobalNames::Output::DataSources;

use Moo::Lax;

######################################################
# DataSources object attributes with ro permissions. #
######################################################
has title => ( is => 'ro', );
has id    => ( is => 'ro', );

# Create an array of DataSources objects.
sub object
{
    my ($input) = @_;

    my @results;

    # If the input is empty, set it as the empty array.
    if ( $input eq q{} )
    {
        $input = [];
    }

    # If the arrayref isn't empty...
    foreach my $source ( @{$input} )
    {

        # If something isn't defined, set it as the empty string.
        foreach ( 'title', 'id' )
        {

            # Avoid readonly variables caused by JSON conversion.
            if ( Scalar::Readonly::readonly( $source->{$_} ) )
            {
                Scalar::Readonly::readonly_off( $source->{$_} );
            }
            $source->{$_} //= q{};
        }

        # Create the object.
        my $resulting_object =
          Bio::Taxonomy::GlobalNames::Output::DataSources->new(
            'title' => $source->{'title'},
            'id'    => $source->{'id'},
          );
        push @results, $resulting_object;
    }

    return \@results;
}

=head2 Attributes for Parameters objects

=over 1

=item $parameters->best_match_only

=item $parameters->data_sources

An array reference of data source ids you used for name resolution. If no data sources were given, the arrayref is empty.

     my @data_sources = @{ $parameters->data_sources };

=item $parameters->header_only

=item $parameters->preferred_data_sources

=item $parameters->resolve_once

True if 'resolve_once' parameter is set to true and vice versa.

=item $parameters->with_context

True if 'with_context' parameter is set to true and vice versa.

=back

=cut

package Bio::Taxonomy::GlobalNames::Output::Parameters;

use Moo::Lax;

#####################################################
# Parameters object attributes with ro permissions. #
#####################################################
has best_match_only        => ( is => 'ro', );
has resolve_once           => ( is => 'ro', );
has data_sources           => ( is => 'ro', );
has header_only            => ( is => 'ro', );
has with_context           => ( is => 'ro', );
has preferred_data_sources => ( is => 'ro', );

# Create the Parameters object.
sub object
{
    my ($input) = @_;

    my @array = qw(
      best_match_only resolve_once
      data_sources    header_only
      with_context    preferred_data_sources
    );

    # If something isn't defined, set it as the empty string.
    foreach (@array)
    {

        # Avoid readonly variables caused by JSON conversion.
        if ( Scalar::Readonly::readonly( $input->{$_} ) )
        {
            Scalar::Readonly::readonly_off( $input->{$_} );
        }
        $input->{$_} //= q{};
    }

    # Create the object.
    my $result = Bio::Taxonomy::GlobalNames::Output::Parameters->new(
        'best_match_only'        => $input->{'best_match_only'},
        'resolve_once'           => $input->{'resolve_once'},
        'data_sources'           => $input->{'data_sources'},
        'header_only'            => $input->{'header_only'},
        'with_context'           => $input->{'with_context'},
        'preferred_data_sources' => $input->{'preferred_data_sources'},
    );

    return $result;
}

=head2 Attributes for Context objects

=over 1

=item $context->context_clade

A lowest taxonomic level in the data source that contains 90% or more of all names found. 
If there are too few names to determine, this element remains empty.

=item $context->context_data_source_id

The id of a data source used to create the context.

=back

=cut

package Bio::Taxonomy::GlobalNames::Output::Context;

use Moo::Lax;

##################################################
# Context object attributes with ro permissions. #
##################################################
has context_data_source_id => ( is => 'ro', );
has context_clade          => ( is => 'ro', );

# Create a Context object.
sub object
{
    my ($input) = @_;

    # If the input is empty, set it as the empty array.
    if ( $input eq q{} )
    {
        $input = [];
    }

    # If something isn't defined, set it as the empty string.
    foreach ( 'context_data_source_id', 'context_clade' )
    {

        # Avoid readonly variables caused by JSON conversion.
        if ( Scalar::Readonly::readonly( $input->[0]->{$_} ) )
        {
            Scalar::Readonly::readonly_off( $input->[0]->{$_} );
        }
        $input->[0]->{$_} //= q{};
    }

    # Create the object.
    my $result = Bio::Taxonomy::GlobalNames::Output::Context->new(
        'context_data_source_id' => $input->[0]->{'context_data_source_id'},
        'context_clade'          => $input->[0]->{'context_clade'},
    );

    return $result;
}

=head1 AUTHOR

Dimitrios - Georgios Kontopoulos, C<< <d.kontopoulos13 at imperial.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-taxonomy-globalnames at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Taxonomy-GlobalNames>.

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

More details about Global Names Resolver's algorithm can be obtained from 
its L<website|http://resolver.globalnames.org/about>.

You can find documentation for this module with the perldoc command.

    perldoc Bio::Taxonomy::GlobalNames

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Taxonomy-GlobalNames>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Taxonomy-GlobalNames>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Taxonomy-GlobalNames>

=item * Search MetaCPAN

L<http://search.mcpan.org/dist/Bio-Taxonomy-GlobalNames/>

=item * GitHub

L<https://github.com/dgkontopoulos/Bio-Taxonomy-GlobalNames>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013-14 Dimitrios - Georgios Kontopoulos.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Bio::Taxonomy::GlobalNames
