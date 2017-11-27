package DDG::Meta::Information;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: DDG plugin meta information storage
$DDG::Meta::Information::VERSION = '1018';
use strict;
use warnings;
use Carp qw( croak );
use Package::Stash;

require Moo::Role;

my %supported_types = (
	email => [ 'mailto:{{a}}', '{{b}}' ],
	twitter => [ 'https://twitter.com/{{a}}', '@{{b}}' ],
	web => [ '{{a}}', '{{b}}' ],
	github => [ 'https://github.com/{{a}}', '{{b}}' ],
	facebook => [ 'https://facebook.com/{{a}}', '{{b}}' ],
	cpan => [ 'https://metacpan.org/author/{{a}}', '{{a}}' ],
);

my @supported_categories = qw(
	bang
	calculations
	cheat_sheets
	computing_info
	computing_tools
	conversions
	dates
	entertainment
	facts
	finance
	food
	formulas
	forums
	geography
	ids
	language
	location_aware
	physical_properties
	programming
	q/a
	random
	reference
	special
	software
	time_sensitive
	transformations
);

my @supported_topics = qw(
	everyday
	economy_and_finance
        computing
	cryptography
	entertainment
	food_and_drink
	gaming
	geek
	geography
	math
	music
	programming
	science
	social
	special_interest
	sysadmin
	travel
	trivia
	web_design
	words_and_games
);


my %applied;

sub apply_keywords {
	my ( $class, $target ) = @_;

	return if exists $applied{$target};
	$applied{$target} = undef;

	my @attributions;
	my @topics;
	my @primary_example_queries;
	my @secondary_example_queries;
    	my $description;
    	my $source;
	my $icon;
	my $category;
	my $name;
	my $icon_url;
	my $code_url;
	my $status;
	my $url_regex = url_match_regex();

	my $stash = Package::Stash->new($target);


	$stash->add_symbol('&category', sub {
		croak "Only one category allowed."
			unless scalar @_ == 1;
		my $value = shift;
		croak $value." is not a valid category (Supported: ".join(',',@supported_categories).")"
			unless grep { $_ eq $value } @supported_categories;
		$category = $value;
		
	});


	$stash->add_symbol('&topics', sub {
		while (@_) {
			my $value = shift;
			croak $value." is not a valid topic (Supported: ".join(',',@supported_topics).")"
				unless grep { $_ eq $value } @supported_topics;
			push @topics, $value;
		}
	});


	$stash->add_symbol('&attribution', sub {
		while (@_) {
			my $type = shift;
			my $value = shift;
			croak $type." is not a valid attribution type (Supported: ".join(',',keys %supported_types).")"
				unless grep { $_ eq $type } keys %supported_types;
			push @attributions, [ $type, $value ];
		}
	});


	$stash->add_symbol('&name', sub {
		croak 'Only one name allowed.'
			unless scalar @_ == 1;
		my $value = shift;
		$name = $value;
	});


	$stash->add_symbol('&source', sub {
		croak 'Only one source allowed.'
			unless scalar @_ == 1;
		my $value = shift;
		$source = $value;
	});


	$stash->add_symbol('&description', sub {
		croak 'Only one description allowed.'
			unless scalar @_ == 1;
		my $value = shift;
		$description = $value;
	});


	$stash->add_symbol('&primary_example_queries', sub {
		while(@_){
			my $query = shift;
			push @primary_example_queries, $query;
		}
	});


	$stash->add_symbol('&secondary_example_queries', sub {
		while(@_){
			my $query = shift;
			push @secondary_example_queries, $query;
		}
	});


	$stash->add_symbol('&icon_url', sub {
		my $value = shift;
		croak $value." is not a valid URL."
			unless ($value =~ m/$url_regex/g or $value =~ /^\/(i\/)?(.+)\.(ico|png|jpe?g)$/ig);
		$icon_url = $value;
	});


	$stash->add_symbol('&code_url', sub {
		my $value = shift;
		croak $value." is not a valid URL."
			unless $value =~ m/$url_regex/g;
		$code_url = $value;
	});


	$stash->add_symbol('&status', sub {
		my $value = shift;
		croak $value." is not a valid status."
			unless $value =~ m/^(enabled|disabled)$/ig;
		$status = $value;
	});



	$stash->add_symbol('&get_category', sub {
		return $category;
	});


	$stash->add_symbol('&get_topics', sub {
		return \@topics;
	});


	$stash->add_symbol('&get_meta_information', sub {
		my %meta_information;
		
		$meta_information{name} = $name;
		$meta_information{primary_example_queries} = \@primary_example_queries;
		$meta_information{secondary_example_queries} = \@secondary_example_queries;
		$meta_information{icon_url} = $icon_url;
		$meta_information{description} = $description;
		$meta_information{source} = $source;
		$meta_information{code_url} = $code_url;
		$meta_information{status} = $status;

		return \%meta_information;
	});


	$stash->add_symbol('&get_attributions', sub {
		my @attribution_links;
		for (@attributions) {
			my $type = shift @{$_};
			my $value = shift @{$_};
			my ( $a, $b ) = ref $value eq 'ARRAY' ? ( $value->[0], $value->[1] ) : ( $value, $value );
			my ( $link, $val ) = @{$supported_types{$type}};
			$link =~ s/\Q{{a}}/$a/;
			$link =~ s/\Q{{b}}/$b/;
			$val =~ s/\Q{{a}}/$a/;
			$val =~ s/\Q{{b}}/$b/;
			push @attribution_links, $link, $val;
		}
		return \@attribution_links;
	});

	#
	# apply role
	#

	Moo::Role->apply_role_to_package($target,'DDG::HasAttribution');

}

#
# Function taken from URL::RegexMatching 
# - couldn't install due to bad Makefile
#
sub url_match_regex {
    return
      qr{(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))};
}

1;

__END__

=pod

=head1 NAME

DDG::Meta::Information - DDG plugin meta information storage

=head1 VERSION

version 1018

=head1 DESCRIPTION

TODO

=head1 EXPORTS FUNCTIONS

=head2 category

This function sets the category for the plugin. Plugins are only allowed one category.

=head2 topics

This function sets the topics for the plugin. Plugins are allowed multiple topics.

=head2 attribution

This function sets the attribution information for the plugin. The allowed operators are:
	email, twitter, web, github, facebook and cpan.
The allowed formats for each are listed in the %support_types hash above.

=head2 name

This function sets the name for the plugin.

=head2 source

This function sets the source for the plugin.

=head2 description

This function sets the description for the plugin.

=head2 primary_example_queries

This function sets the primary example queries for the plugin. 
This is used to show users example primary queries for the plugin.

=head2 secondary_example_queries

This function sets an array of secondary example queries for the plugin. 
This is used to show users examples of secondary queries for the plugin.

=head2 icon_url

This function sets the url used to fetch the icon for the plugin.

=head2 code_url

This function sets the url which links the plugin's code on github.

=head2 status

This function indicate the status of the plugin which is used to show it on the goodies page. 

=head2 get_category

This function returns the plugin's category

=head2 get_topics

This function returns the plugin's topics in an array

=head2 get_meta_information

This function returns the plugin's meta information in a hash

=head2 get_attributions

This function returns the plugin's attribution information in a hash

=head1 METHODS

=head2 apply_keywords

Uses a given classname to install the described keywords.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
