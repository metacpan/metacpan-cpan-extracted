package DateTime::Format::Builder::Parser::Strptime;

use strict;
use warnings;

our $VERSION = '0.83';

use DateTime::Format::Strptime 1.04;
use Params::Validate qw( validate SCALAR HASHREF );

use parent 'DateTime::Format::Builder::Parser::generic';

__PACKAGE__->valid_params(
    strptime => {
        type => SCALAR
            | HASHREF,    # straight pattern or options to DTF::Strptime
    },
);

sub create_parser {
    my ( $self, %args ) = @_;

    # Arguments to DTF::Strptime
    my $pattern = $args{strptime};

    # Create our strptime parser
    my $strptime = DateTime::Format::Strptime->new(
        ( ref $pattern ? %$pattern : ( pattern => $pattern ) ),
    );
    unless ( ref $self ) {
        $self = $self->new(%args);
    }
    $self->{strptime} = $strptime;

    # Create our parser
    return $self->generic_parser(
        (
            map { exists $args{$_} ? ( $_ => $args{$_} ) : () }
                qw(
                on_match on_fail preprocess postprocess
                )
        ),
        label => $args{label},
    );
}

sub do_match {
    my $self = shift;
    my $date = shift;
    local $^W;    # bizarre bug
                  # Do the match!
    my $dt = eval { $self->{strptime}->parse_datetime($date) };
    return $@ ? undef : $dt;
}

sub post_match {
    return $_[2];
}

1;

# ABSTRACT: strptime based date parsing

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Builder::Parser::Strptime - strptime based date parsing

=head1 VERSION

version 0.83

=head1 SYNOPSIS

    my $parser = DateTime::Format::Builder->create_parser(
        strptime => '%e/%b/%Y:%H:%M:%S %z',
    );

=head1 SPECIFICATION

=over 4

=item * strptime

B<strptime> takes as its argument a strptime string. See
L<DateTime::Format::Strptime> for more information on valid patterns.

=back

=head1 SEE ALSO

C<datetime@perl.org> mailing list.

http://datetime.perl.org/

L<perl>, L<DateTime>,
L<DateTime::Format::Builder>

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/DateTime-Format-Builder/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for DateTime-Format-Builder can be found at L<https://github.com/houseabsolute/DateTime-Format-Builder>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Iain Truskett <spoon@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
