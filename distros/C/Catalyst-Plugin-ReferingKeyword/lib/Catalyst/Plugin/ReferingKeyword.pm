package Catalyst::Plugin::ReferingKeyword;
use base qw/ Class::Accessor::Fast /;

use strict;
use warnings;
use URI;
use URI::QueryParam;

__PACKAGE__->mk_accessors(qw/ refering_keyword /);

our $VERSION = "0.01";

sub setup {
    my $self = shift;

    my $config = ( $self->config->{refering_keyword} ||= {} );

    $config->{wordish} ||= qr/
                             (?:(?<=\s)|(?<=\A)|(?<="))
                             [[:alpha:]]+?[-']?[[:alpha:]]+:?
                             (?=\s|"|\z)
                             /x;

    $config->{too_long} ||= qr/\S{15}/;

    return $self->NEXT::setup(@_);
}


sub prepare {
    my $class = shift;
    my $self = $class->NEXT::prepare(@_);
    my $referer = $self->request->headers->referer;

    return $self unless $referer;

    my $ref = URI->new( $referer );

    # lying/invalid refering URIs throw fatals when we try to use them.
    # If the query string is absent we also don't need to continue.
    my $query;
    eval { $query = $ref->query };
    if ( not $query or $@ )
    {
        return $self;
    }
    my %weight;
    my $wordish = $self->config->{refering_keyword}{wordish};
    my $too_long = $self->config->{refering_keyword}{too_long};
    for my $key ( $ref->query_param ) {
        my $value = join(" and ", grep /[[:alpha:]]{2}/, $ref->query_param($key));
        next unless $value;
        $value =~ s/^\s+|\s+$//g;
        $value =~ s/[^\S ]+/ /g;
        next unless 2 < length $value;
        my $score = 0;
        $score += () = $value =~ /$wordish/g;
        $score -= () = $value =~ /$too_long/g;
        $score += 2 if $key =~ /^(?:q|p)$/;
        $score++ if $key =~ /qu?e?ry|search/i;
        $score-- if $value =~ /query|search/i;
        $score-- if $value !~ /[aeiou]/i;
        $score-- if $value =~ /[^-[:alpha:]"'+:,. ]/;
        next unless $score > 0;
        $weight{$value} = $score;
    }

    my $keyword;
    for my $q ( sort { $weight{$b} <=> $weight{$a} } keys %weight ) {
        $keyword = $q;
        last;
    }
    $keyword =~ s/[^[:print:]]//g; # be safe, no reason to pass this shite on

    $self->refering_keyword($keyword);

    return $self;
}



1;

__END__


=head1 NAME

Catalyst::Plugin::ReferingKeyword - Catch the keyword from a search that brought a visitor to your CatApp.


=head1 VERSION

0.01


=head1 SYNOPSIS

 use Catalyst qw(
                 Unicode
                 ReferingKeyword
                 );

 # ...then later, in a template perhaps

 You seek <i>[% c.refering_keyword || "nothing in particular" %]</i>.
  
=head1 DESCRIPTION

The aim is pretty simple though the task can be quite convoluted.
Take, when available, the refering (sic, we use refering b/c someone
somewhere decided to use referer, sigh) query string, when it exists,
and try to parse out the real search term the user had entered on the
refering site.

This is a sort of a toy plugin right now. Feedback might help turn it
into something more robust and fully documented.

=over 4

=item * setup

Does the regular configuration stuff. Not documented yet.

=item * prepare

Where we hook into the request->referer, when it's there.

=item * refering_keyword

Only public method. Returns the most important, as far as the software
can tell, value from the refering URI query parameters. E.g., a Google
search might look like:

  http://www.google.com/search?q=catalyst+plugins&ie=utf-8...

The refering_keyword that will be caught and returned is "catalyst
plugins." As there is no standard for query parameters key names,
there is no perfect way to capture them. It's possible to capture them
by things like key name lists per domain but that is a never ending
dictionary approach. In this module we use a weighting system to try
to see which value in the key=value pairs seems the most like a search
term and the least like application dialect.

=back

=head1 DIAGNOSTICS

Failures will typically be empty when there was one that could have
been caught or the wrong part of a query, such as "true." Improvements
to the algorithm are welcome.

=head1 CONFIGURATION AND ENVIRONMENT

Next version. :)

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalyst-plugin-referingquery@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Open algorithm to tweaking or other backends. Expand POD. Write more
tests than the stock stuff.

=head1 AUTHOR

Ashley Pond V  C<< <ashley@cpan.org> >>.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Ashley Pond V. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.
