package Class::DBI::Loader::Relationship;
use 5.006;
use strict;
use warnings;
our $VERSION = '1.2';
our $DEBUG = 0;

1;

=head1 NAME

Class::DBI::Loader::Relationship - Easier relationship specification in CDBI::L

=head1 SYNOPSIS

  use Class::DBI::Loader::Relationship;

  my $loader = Class::DBI::Loader->new( dsn => "mysql:beerdb",
                                        namespace => "BeerDB");

Now instead of saying

    BeerDB::Brewery->has_many(beers => "BeerDB::Beer");
    BeerDB::Beer->has_a(brewery => "BeerDB::Brewery");

    BeerDB::Handpump->has_a(beer => "BeerDB::Beer"); 
    BeerDB::Handpump->has_a(pub => "BeerDB::Pub");
    BeerDB::Pub->has_many(beers => [ BeerDB::Handpump => 'beer' ]);
    BeerDB::Beer->has_many(pubs => [ BeerDB::Handpump => 'pub' ]);

Just say

    $loader->relationship( "a brewery produces beers" );
    $loader->relationship( "a pub has beers on handpumps" );

=head1 DESCRIPTION

This module acts as a mix-in, adding the C<relationship> method to 
C<Class::DBI::Loader>. Since C<Class::DBI::Loader> knows how to map
between table names and class names, there ought to be no need to 
replicate the names.

In addition, it is common (but not universal) to want reverse relationships
defined for has-many relationships, and for has-a relationships to be
defined for the linkages surrounding a many-to-many table. 

The aim of C<CDBIL::Relationship> is to simplify the declaration of 
common database relationships by providing both of these features.

The C<relationship> takes a string. It recognises table names (singular
or plural, for convenience) and extracts them from the "sentence". 

=cut

package Class::DBI::Loader::Generic;
use Lingua::EN::Inflect::Number qw(PL to_PL to_S);
use Carp;

sub relationship {
    my $self = shift;
    my $text = shift;
    my %tables = map { $_ => $_, PL($_) => $_ } $self->tables;
    my $table_re = join "|", map quotemeta, 
                             sort { length $b <=> length $a } keys %tables;
    croak "Couldn't understand the first object you were talking about"
        unless $text =~ s/^((an?|the)\s+)?($table_re)\s*//i;
    my $from = $tables{$3};
    my $from_c = $self->find_class($from);
    $text =~ s/^(might\s+)?\w+(\s+an?)?\s+//i;
    my $method = "has_many";
    $method = "has_a" if $2;
    $method = "might_have" if $1;
    
    croak "Couldn't understand the second object you were talking about"
        unless $text =~ s/.*?($table_re)\b//i;
    my $to = $tables{$1};
    my $to_c = $self->find_class($to);
    my $mapper = $method eq "has_many" ? to_PL($to) : to_S($to);
    if ($text =~ /($table_re)/i) {
        my $via = $tables{$1}; my $via_c = $self->find_class($via);
        return "$via_c->has_a(".to_S($from)." => $from_c)\n".
               "$via_c->has_a(".to_S($to)." => $to_c)\n".
               "$from_c->$method($mapper => [ $via_c => ".to_S($to)." ])\n".
               "$to_c->has_many(".to_PL($from)." => [ $via_c => ".to_S($from)." ])\n"
        if $DEBUG;

        $via_c->has_a(to_S($from) => $from_c);
        $via_c->has_a(to_S($to) => $to_c);
        $from_c->$method($mapper => [ $via_c => to_S($to) ]);
        $to_c->has_many(to_PL($from) => [ $via_c => to_S($from) ]);
       return;
    } 
    return "$from_c->$method($mapper => $to_c);\n".
           ($method ne "has_a" && "$to_c->has_a(".to_S($from)." => $from_c);\n") 
           if $DEBUG;
    $from_c->$method($mapper => $to_c);
    $to_c->has_a(to_S($from) => $from_c) unless $method eq "has_a";
}

1;

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<Class::DBI::Loader>.

=cut
