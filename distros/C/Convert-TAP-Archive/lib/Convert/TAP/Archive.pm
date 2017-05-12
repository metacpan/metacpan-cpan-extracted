# ABSTRACT: Read from a TAP archive and convert it for displaying

package Convert::TAP::Archive;
{
  $Convert::TAP::Archive::VERSION = '0.005';
}

use strict;
use warnings;

use Capture::Tiny qw( capture_merged );
use TAP::Harness;
use TAP::Harness::Archive;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(convert_from_taparchive);

# one and only subroutine of this module
sub convert_from_taparchive {

    my %args = @_;

    # Input Arguments: archive, formatter, force_inline
    # Set default values:
    die 'no archive specified'
        unless (exists $args{archive});
    $args{formatter} = 'TAP::Formatter::HTML'
        unless (exists $args{formatter});
    $args{force_inline} = 0
        unless (exists $args{force_inline});

    # This is the complicate but flexible version to:
    #   use TAP::Formatter::HTML;
    #   my $formatter = TAP::Formatter::HTML->new;
    my $formatter;
    (my $require_name = $args{formatter} . ".pm") =~ s{::}{/}g;
    eval {
        require $require_name;
        $formatter = $args{formatter}->new();
    };  
    die "Problems with formatter $args{formatter}"
      . " at $require_name: $@"
        if $@;

    # if set, include all CSS and JS in HTML file
    if ($args{force_inline}) {
        $formatter->force_inline_css(1);
        $formatter->force_inline_js (1);
    }

    # Now we do a lot of magic to convert this stuff...

    my $harness = TAP::Harness->new({ formatter => $formatter }); 

    $formatter->really_quiet(1);
    $formatter->prepare;

    my $session;
    my $aggregator = TAP::Harness::Archive->aggregator_from_archive({ 
        archive          => $args{archive},
        parser_callbacks => {
            ALL => sub {
                $session->result( $_[0] );
            },  
        },  
        made_parser_callback => sub {
            $session = $formatter->open_test( $_[1], $_[0] );
        }   
    });

    $aggregator->start;
    $aggregator->stop;

    # This code also prints to STDOUT but we will catch it!
    return capture_merged { $formatter->summary($aggregator) };

}

1;

__END__

=pod

=head1 NAME

Convert::TAP::Archive - Read from a TAP archive and convert it for displaying

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Convert::TAP::Archive qw(convert_from_taparchive);

 my $html = convert_from_taparchive(
                archive   => '/must/be/the/complete/path/to/test.tar.gz',
                formatter => 'TAP::Formatter::HTML',
            );

=encoding utf8

=head1 IMPORTANT NOTE

B<THIS MODULE IS DEPRECATED!>
Please see L<Archive::TAP::Convert> instead.

=head1 ABOUT

This modul can be of help for you if you have TAP archives (e.g. created with C<prove -a> and now you wish to have the content of this archives in a special format like HTML or JUnit (or whatever format).

=head1 EXPORTED METHODS

=head2 convert_from_taparchive

The method takes three arguments.
Only C<archive> is required.
It takes the B<full> path to your TAP archive.
The C<formatter> defaults to C<TAP::Formatter::HTML>, but you can give any other formatter.
The method will return the content of the TAP archive, parsed according to the formatter you have specified.

 my $html = convert_from_taparchive(
                archive      => '/must/be/the/complete/path/to/test.tar.gz',
                formatter    =>'TAP::Formatter::HTML',
                force_inline => 1,
            );

You can give any optional true value to C<force_inline> and it will pack all Javascript and CSS inside the HTML instead of linking to to files from L<TAP::Formatter::HTML>.
This defaults to zero, meaning do not inline.

=head1 BUGS AND LIMITATIONS

No known issues.

=head1 SEE ALSO

=over

=item *

This module is no longer maintained!
Please see L<Archive::TAP::Convert> for the same funcionality.

=item *

L<Test::Harness>

=item *

L<TAP::Formatter::Base> and its implementations for L<HTML|TAP::Formatter::HTML>, L<JUnit|TAP::Formatter::JUnit> or L<Console|TAP::Formatter::Console>.

=back

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>, Renée Bäcker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Boris Däppen, Renée Bäcker, plusW.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
