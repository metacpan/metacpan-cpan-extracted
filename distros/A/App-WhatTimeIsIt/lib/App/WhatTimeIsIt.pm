package App::WhatTimeIsIt;
use strict;
use warnings;
use Time::Local ();
use POSIX ();
use Config::CmdRC '.what_time_is_it';

our $VERSION = '0.01';

my $FORMAT = "%a, %d %b %Y %H:%M";

sub new {
    my ($class, $opt) = @_;
    bless { opt => $opt } => $class;
}

sub opt { $_[0]->{opt} }

sub run {
    my $self = shift;

    my $format = $self->opt->{'--format'} || RC->{format} || $FORMAT;
    my $out    = ($self->opt->{'--stderr'} || RC->{stderr}) ? *STDERR : *STDOUT;

    my $gmt = Time::Local::timegm(gmtime);

    for my $data (@{$self->opt->{'--city'}}, @{RC->{city} || []}) {
        my ($city, $offset) = split ':', ($data || '');
        my $date = POSIX::strftime(
            $format,
            gmtime($gmt + $offset*60*60),
        );
        print $out "$city\t$date\n";
    }
}

1;

__END__

=head1 NAME

App::WhatTimeIsIt - Now?


=head1 SYNOPSIS

    $ what_time_is_it --city Tokyo:9 --city NY:-4
    Tokyo   Sat, 20 Jul 2013 09:43
    NY      Fri, 19 Jul 2013 20:43


=head1 DESCRIPTION

See command L<what_time_is_it> for more detail.


=head1 METHODS

=head2 new

=head2 opt

=head2 run


=head1 SEE ALSO

L<what_time_is_it>


=head1 REPOSITORY

App::WhatTimeIsIt is hosted on github
<http://github.com/bayashi/App-WhatTimeIsIt>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
