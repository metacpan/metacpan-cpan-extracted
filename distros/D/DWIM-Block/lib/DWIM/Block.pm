package DWIM::Block;

use 5.022;
use warnings;
use Filter::Simple;
use PPR::X;
use AI::Chat;

# Look for DWIM {...} blocks in any source that loads this module...
FILTER {
    my %dwim;

    # This is what code with embedded DWIM blocks looks like...
    my $PERL_WITH_DWIM_BLOCKS = qr{
        (?&PerlEntireDocument)

        (?(DEFINE)
            (?<PerlControlBlock>
                DWIM \b  (?{ pos() - 4 })  (?>(?&PerlOWS))
                (?<REQUEST>  \{ (?>(?&PPR_X_balanced_curlies_interpolated)) \}  )
                (?{ $dwim{ $^R } = { block => 1, len => pos() - $^R, request => $+{REQUEST} } })
            |
                (?>(?&PerlStdControlBlock))
            )

            (?<PerlCall>
                DWIM \b  (?{ pos() - 4 }) (?>(?&PerlOWS))
                (?<REQUEST>  \{ (?>(?&PPR_X_balanced_curlies_interpolated)) \}  )
                (?{ $dwim{ $^R } = { len => pos() - $^R, request => $+{REQUEST} } })
            |
                (?>(?&PerlStdCall))
            )
        )

        $PPR::X::GRAMMAR
    }xms;

    # If we find DWIM blocks...
    if (/$PERL_WITH_DWIM_BLOCKS/) {
        # Work backwards from the end of the source (so the replacements don't mess up pos info)...
        for my $pos (sort {$b <=> $a} keys %dwim) {

            # Generate the replacement code...
            my $code = "do { DWIM::Block::_DWIM( qq$dwim{$pos}{request}) }";

            # Substitute the replacement code into the source...
            substr($_, $pos, $dwim{$pos}{len}) = $dwim{$pos}{block} ? "{$code}" : $code;
        }
    }
}

our $VERSION = '0.000002';

# This sub relays each request to the API and returns the result...
sub _DWIM {
    my ($request) = @_;

    # Discover and remember the API key...
    state $API_KEY = $ENV{'DWIM_API_KEY'}
                  // $ENV{'OPENAI_API_KEY'}
                  // die sprintf qq{Can't find API key at %s line %d\n}, (caller 0)[1,2];

    # Discover and remember the requested model...
    state $MODEL   = $ENV{'DWIM_MODEL'}
                  // $ENV{'OPENAI_MODEL'}
                  // q{};

    # Build and retain an API object...
    state $GPT = AI::Chat->new( key => $API_KEY, $MODEL ? ( model => $MODEL ) : () );

    # Send the request and return the response...
    return $GPT->prompt($request);
}


1; # Magic true value required at end of module
__END__

=head1 NAME

DWIM::Block - Use AI::Chat without having to write the infrastructure code


=head1 VERSION

This document describes DWIM::Block version 0.000002


=head1 SYNOPSIS

    use DWIM::Block;

    sub autoinflect ($text) {
        DWIM {
            Please inflect the following text so that its grammar is correct
            and its nouns and verbs agree in number and person.
            Please return only the inflected sentence, without any commentary:

            $text
        }
    }

    sub autoformat ($text, %opt) {
        $opt{width} //= 72;

        DWIM {
            Could you please reformat the following text quotation from an email,
            so that each line is no more than $opt{width} columns.
            Please preserve any leading email quoters and,
            if the plaintext contains a list of numbered points,
            ensure that the point numbers are sequential and remain outdented
            from the reformatted text of each point.
            Please return only the reformatted plaintext, without any commentary:

            $text
        }
    }

    dwim carp ($message) {
        Carp::carp(
            DWIM { Please convert the following text to a haiku: $message }
        );
    }


    # And then these "just work" (assuming ChatGPT actually understands your requests)...

    carp "Bad argument to method left()";

    say autoinflect "When you has did 6 impossible thing before breakfast...";

    say autoformat $wide_text, width => 42;


    # Now choose a more powerful model to generate better haiku...

    local $ENV{'DWIM_MODEL'} = 'gpt-4-turbo';

    carp "Bad argument to method left()";


=head1 DESCRIPTION

This module makes it easy to build code that sends a request to the OpenAI API
and then returns the response.

Instead of writing:

    sub autoinflect ($text) {
        use AI::Chat;

        state $GPT = AI::Chat->new(
            key   => $ENV{'DWIM_API_KEY'} // $ENV{'OPENAI_API_KEY'} // die "Can't find API key",
            model => 'gpt-4-turbo'
        );

        my $REQUEST = <<~"END_REQUEST"
            Please inflect the following text so that its grammar is correct
            and its nouns and verbs agree in number and person.
            Please return only the inflected sentence, without any commentary:

            $text
        END_REQUEST

        return $GPT->prompt($REQUEST);
    }

...you simply replace all the code needed to drive AI::Chat with a single
C<DWIM> block containing the actual request you want to send. Like so:

    sub autoinflect ($text) {
        DWIM {
            Please inflect the following text so that its grammar is correct
            and its nouns and verbs agree in number and person.
            Please return only the inflected sentence, without any commentary:

            $text
        }
    }

This automatically adds back in all the necessary boilerplate code to drive C<Chat::AI>.

Note that the contents of the C<DWIM> block behave exactly like a double-quoted
string, which is then passed to C<AI::Chat::prompt()>. This means that you can
put Perl variables inside the block and they will be interpolated into the
double-quoted string. For instance, note the use of C<$text> in the comment
in the preceding example.


=head2 Capturing the result of the query

Unlike regular Perl blocks, you can also use a DWIM block as part of a
larger expression (as you would a C<do> block). For example:

    dwim from_JSON ($JSON_data) {

        return eval DWIM { Please convert the following JSON object to a Perl hashref: JSON_data };

    }

Note that, if the query fails for any reason, the result of the C<DWIM> block may be C<undef>.

The module decides whether to treat a C<DWIM> as an control block or a C<do> block,
by examining its syntactic location. If a C<DWIM> is specified at the beginning of a statement,
it is treated as a control block (like an C<if> or C<for> block), and does not require
a semicolon after it. If it is not in a location where a control block could appear,
it is treated as a special form of C<do> block, and the expression containing it I<does>
require a semicolon (or a closing block delimiter) after it.


=head1 DIAGNOSTICS

=over

=item C<< Can't find API key >>

The module requires an OpenAI API key to allow it to connect with the AI server.
This key must be provided in an environment variable, which may be named
either C<DWIM_API_KEY> or C<OPENAI_API_KEY>.

You specified a C<DWIM> block, but it could not find either of those environment variables.

Set up the variable in your shell or IDE. For example, in your shell config file:

    # In your .bashrc or .zshrc file:
    export DWIM_API_KEY=sk-proj-y0ur0p3n41Pr0j3c74P1k3y6035H3r3TH150n35N07R34l

    # In your .cshrc file:
    setenv DWIM_API_KEY sk-proj-y0ur0p3n41Pr0j3c74P1k3y6035H3r3TH150n35N07R34l

    # In your .env file:
    DWIM_API_KEY=sk-proj-y0ur0p3n41Pr0j3c74P1k3y6035H3r3TH150n35N07R34l

=back


=head1 CONFIGURATION AND ENVIRONMENT

DWIM::Block requires no configuration files.

The module requires one of the following environment variables
to be set to a string representing a valid API key for the model
you are using:

    $ENV{'DWIM_API_KEY'}

    $ENV{'OPENAI_API_KEY'}

If both are set, then C<$ENV{'DWIM_API_KEY'}> is always used.

The module also looks for one of the following environment variables,
with which you can specify the specific model to be used:

    $ENV{'DWIM_MODEL'}

    $ENV{'OPENAI_MODEL'}

If both are set, then C<$ENV{'DWIM_MODEL'}> is always used.
If neither is set, then AI::Chat selects the model for you automatically.


=head1 DEPENDENCIES

This module requires the C<Filter::Simple>, C<PPR>, and C<AI::Chat> modules.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

What a C<DWIM> can be made to accomplish is limited primarily by your imagination.

Please report any bugs or feature requests to
C<bug-dwim-block@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2024, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
