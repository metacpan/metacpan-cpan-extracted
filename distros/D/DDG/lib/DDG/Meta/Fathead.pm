package DDG::Meta::Fathead;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Functions for generating a L<DDG::ZeroClickInfo::Fathead> factory 
$DDG::Meta::Fathead::VERSION = '1016';
use strict;
use warnings;
use Package::Stash;

sub fathead_attributes {qw(
    mediawiki
    title_addon
)}



my %applied;

sub apply_keywords {
    my ( $class , $target ) = @_;

    return if exists $applied{$target};
    $applied{$target} = undef;

    my @parts = split( '::' , $target );
    shift @parts;
    shift @parts;
    my $answer_type = lc(join(' ', @parts));

    my $stash = Package::Stash->new($target);

    my %zci_params = (
        answer_type => $answer_type,
    );


    $stash->add_symbol('&fathead', sub {
        if (ref $_[0] eq 'HASH') {
            for (keys %{$_[0]}) {
                $zci_params{check_fathead_key($_)} = $_[0]->{$_};
            }
        } else {
            while (@_) {
                my $key = shift;
                my $value = shift;
                $zci_params{check_fathead_key($key)} = $value;
            }
        }
    });
}


sub check_fathead_key {
    my $key = shift;
    if (grep { $key eq $_ } fathead_attributes) {
        return $key;
    } else {
        croak $key." is not supported on DDG::Meta::Fathead";
    }
}

1;

__END__

=pod

=head1 NAME

DDG::Meta::Fathead - Functions for generating a L<DDG::ZeroClickInfo::Fathead> factory 

=head1 VERSION

version 1016

=head1 DESCRIPTION

=head1 EXPORTS FUNCTIONS

=head2 fathead

=head1 METHODS

=head2 apply_keywords

Uses a given classname to install the described keywords.

=head2 check_fathead_key

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
