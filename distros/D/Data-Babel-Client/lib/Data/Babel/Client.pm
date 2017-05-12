package Data::Babel::Client;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.02';

use Carp;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;

use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %DEFAULTS @EXPORT_OK);

use Class::AutoClass qw(:all);
use base qw(Class::AutoClass);
@AUTO_ATTRIBUTES=qw(ua base_url);
%DEFAULTS=(base_url=>'http://babel.gdxbase.org/cgi-bin/translate.cgi',
	   ua=>LWP::UserAgent->new
	   );

Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
    my($self,$class,$args)=@_;
    return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this

    # object initialization goes here as needed
    $self;
}


# get the available idtypes
# returns results as perl array
sub idtypes {
    my ($self)=@_;
    my %args=(request_type=>'idtypes',
	output_format=>'json');
	      
    my $content=$self->_fetch(%args);
    my $table=decode_json($content);
    
    wantarray? @$table:$table;
}


# request translations
# return results as perl array
sub translate {
    my ($self,%argHash)=@_;
    my %args=(request_type=>'translate', output_format=>'json');
    delete @argHash{keys %args}; # override values
    @args{keys %argHash}=values %argHash if %argHash;

    # check for missing args:
    my @missing_args;
    my @required_args=qw(request_type input_type output_types output_format);
    push @missing_args, grep /\w/, map {$args{$_}? '' : $_} @required_args;
    push @missing_args, "input_ids or input_ids_all" unless $args{input_ids} || $args{input_ids_all};
    die sprintf("translate: missing args: %s\n", join(', ',@missing_args)) if @missing_args;
    die sprintf("translate: cannot request both input_ids and input_ids_all") if $args{input_ids} && $args{input_ids_all};

    my $json=$self->_fetch(%args);
    my $table=decode_json($json);

    wantarray? @$table:$table;
}

sub _fetch {
    my ($self,%args)=@_;
    my $req=POST($self->base_url,\%args);
    my $res=$self->ua->request($req);

    die sprintf("babel webservice error: %s\n",$res->status_line)
	unless $res->is_success;
    $res->content;
}


=head1 NAME

Data::Babel::Client - A Client to access the Babel web service.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

    use Data::Babel::Client;
    my $bc=new BabelClient;

    # Get a list of valid id types: each element is a two-element array containing the literal type and an English description
    my @idtypes=$bc->idtypes;
    my %idtypes=map {($_->[0],$_->[1])} @idtypes;         # convert to hash form

    # Translate some Entrez gene ids to various types; $table contains an array of arrays
    my %args=(input_type=>'gene_entrez',
	      input_ids=>[2983,1829,589,20383,293883],
	      output_types=>[qw(protein_ensembl peptide_pepatlas reaction_ec function_go gene_symbol_synonym)]);
    my $table=$bc->translate(%args);


=head2 Description


BabelClient.pm provides access to the babel web service.  The Babel web service provides
translations between biological identifiers of various types.  For example, given a list 
of Entrez gene ids, it can provide the corresponding Ensembl gene ids, UniProt
protien ids, and so forth.  The full list of available identifiers, and accompanying
English descriptions, can be obtained by making a call to the 'idtypes' method.

This web service client provides two calls, idtypes() and translate().  Both of these calls mimic 
calls of the same names found in Data::Babel, which also provides full documentation.  It is intended 
that the API's of the corresponding calls be exactly the same.

The main method is 'translate'.  It makes a request to the web service to translate identifiers.
The parameters to translate are:
- input_type: a string describing the type of the input identifiers.  This type must match
              exactly with one of the values returned by the 'idtypes' method.
- input_ids: a listref containing the actual identifiers to be translated.
- output_types: a listref containing the output types desired, ie, the translations from
                'input_type'.  For example, if you have a list of Uniprot ids and you
                would like to know what are the corresponding Ensembl gene ids, gene symbols,
                and associated OMIM numbers, you would pass the list [qw(gene_ensembl gene_symbol function_omim)]

As mentioned, the method 'idtypes' provides a list of all valid id types for use in the 'translate' method 
(for both 'input_type' and 'output_type').  The 'idtypes' method takes no parameters.

NOTE: not all translations are 1-to-1.  Many of the translations will return more than one output value
for a given input value.  For example, there are multiple Affymetrix probeset ids for many genes.
In this case, there will be one row for each unique combination of return values, so if there were
six Affymetrix probe ids for a given Entrez gene id, there would be six rows in the returned array
for that Entrez gene id, with the value for the Entrez gene id repeated in each row.  Were you to 
request two non-unique translations to a call to 'translate', the returned array would contain all
the different combinations of values, one on each row.  In this way the returned array can grow in 
size so as to overwhelm the capabilities of the server, the web, and so forth, and caution must be used
in making requests to the server.

=head2 Location of the web service:

The current URL for the web service is http://babel.gdxbase.org/cgi-bin/translate.cgi.  It
is encoded into this client, but can be overridden by passing the named argument 'base_url'
into the constructor, as in:

    my $bc=new BabelClient(base_url=>'http://some.other.url');
    
This assumes, of course, that there is another instance of the web service at the location
mentioned.

=head1 SUBROUTINES/METHODS



=cut

=head2 translate()

$table=translate(\%args) 

%args:

=head3 inputs_ids: 

an arrayref containing the ids you want translated.  They must all be
    of the type specified by $args{input_types}.

=head3 input_type: 

a string describing the type of the inputs.  Must be one of the known
    values.  For a list of known (legal) values, use the idtypes()
    function.

=head3 output_types

a list (ARRAY ref) of desired output types.  Similarly to
    $args{input_type}, each value must be one of
    the known (legal) types, as obtained by a call to idtypes().

=head3 return value

translate() returns an array (or arrayref) to a table of translated
    values.  Each row in the table contains one column for the
    passed-in input, and one column for each output_type desired, in
    the order that they were passed in.


=head2 idtypes()

$table=idtypes()

idtypes() takes no arguments.  It returns a table containing a list of
    all the legal identifier types.  Each row in the table is a
    2-element arrayref; the first element is the actual idtype, and
    the second element is a short description of the idtype.

=cut

=head1 AUTHOR

Victor Cassen, C<< <vcassen at systemsbiology.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-babel-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Babel-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Babel::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Babel-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Babel-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Babel-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Babel-Client/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Victor Cassen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Babel::Client
