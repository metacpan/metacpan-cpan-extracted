package DateTime::Format::Builder::Parser::Dispatch;

use strict;
use warnings;

our $VERSION = '0.83';

our %dispatch_data;
use Params::Validate qw( CODEREF validate );
use DateTime::Format::Builder::Parser;

{
    no strict 'refs';
    *dispatch_data = *DateTime::Format::Builder::dispatch_data;
    *params        = *DateTime::Format::Builder::Parser::params;
}

DateTime::Format::Builder::Parser->valid_params(
    Dispatch => {
        type => CODEREF,
    }
);

sub create_parser {
    my ( $self, %args ) = @_;
    my $coderef = $args{Dispatch};

    return sub {
        my ( $self, $date, $p, @args ) = @_;
        return unless defined $date;
        my $class = ref($self) || $self;

        my @results = $coderef->($date);
        return unless @results;
        return unless defined $results[0];

        for my $group (@results) {
            my $parser = $dispatch_data{$class}{$group};
            die "Unknown parsing group: $class\n" unless defined $parser;
            my $rv = eval { $parser->parse( $self, $date, $p, @args ) };
            return $rv unless $@ or not defined $rv;
        }
        return;
    };
}

1;

# ABSTRACT: Dispatch parsers by group

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Builder::Parser::Dispatch - Dispatch parsers by group

=head1 VERSION

version 0.83

=head1 SYNOPSIS

    package SampleDispatch;
    use DateTime::Format::Builder (
        parsers => {
            parse_datetime => [
                {
                    Dispatch => sub {
                        return 'fnerk';
                    }
                }
            ]
        },
        groups => {
            fnerk => [
                {
                    regex  => qr/^(\d{4})(\d\d)(\d\d)$/,
                    params => [qw( year month day )],
                },
            ]
        }
    );

=head1 DESCRIPTION

C<Dispatch> adds another parser type to C<Builder> permitting dispatch of
parsing according to group names.

=head1 SPECIFICATION

C<Dispatch> has just one key: C<Dispatch>. The value should be a reference to
a subroutine that returns one of:

=over 4

=item *

C<undef>, meaning no groups could be found.

=item *

An empty list, meaning no groups could be found.

=item *

A single string, meaning: use this group

=item *

A list of strings, meaning: use these groups in this order.

=back

Groups are specified much like the example in the L<SYNOPSIS>. They follow the
same format as when you specify them for methods.

=head1 SIDE EFFECTS

Your group parser can also be a Dispatch parser. Thus you could potentially
end up with an infinitely recursive parser.

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
