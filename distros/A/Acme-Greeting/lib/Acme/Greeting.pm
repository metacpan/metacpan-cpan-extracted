package Acme::Greeting;
use strict;
use warnings;
use v5.12.3;
use utf8;
use self;

our $VERSION = '0.0.3';

my $last = "";

sub new {
    my %opt = args;
    $opt{language} = "en" unless defined $opt{language};
    $opt{target} = "guest" unless defined $opt{target};

    my $realfile = "";
    my $db = "Acme/Greeting/$opt{language}.pm";
    for my $prefix (@INC) {
        $realfile = "$prefix/$db";
        last if (-f $realfile);
    }

    my @greeting = ();

    my $DB;
    open($DB, "<:utf8", $realfile) and do {
        while (<$DB>) {
            chomp;
            if ( m/^=item\ (.+)$ /x ) {
                push @greeting, $1;
            }
        }
        close $DB;
    };

    if (@greeting == 0) {
        push @greeting, __PACKAGE__ . ' says hi, $u';
    }

    my $greeting = $last;
    while ($greeting eq $last) {
        $greeting = $greeting[ int(rand(@greeting)) ];
        $greeting =~ s/\$u/$opt{target}/g;
    }

    $last = $greeting;
    return $greeting;
}

"Greeting";

__END__

=head1 NAME

Acme::Greeting - Greeting from Perl.

=head1 VERSION

This document describes Acme::Greeting version 0.0.1


=head1 SYNOPSIS

    use Acme::Greeting;


    Acme::Greeting->new(); # "Hello, guest"

=head1 DESCRIPTION

This module generates greeting messages in several languages.

=head1 INTERFACE

=over

=item new(%opt)

Generates a new greeting message. Return a string. %opt hash
can have these values:

B<language>, to specify the language of this greeting message. Default
is C<"en">.

B<target>, to specify the greeting target. Default is C<"guest">.

=back

=head1 DIAGNOSTICS

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

Acme::Greeting requires no configuration files or environment variables.

=head1 DEPENDENCIES

Perl hackers around the world to submit greeting messages in their
native speaking languages.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-greeting@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kang-min Liu C<< <gugod@gugod.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
