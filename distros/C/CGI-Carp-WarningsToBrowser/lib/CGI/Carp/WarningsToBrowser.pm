package CGI::Carp::WarningsToBrowser;

our $VERSION = 0.02;

=pod

=head1 NAME

CGI::Carp::WarningsToBrowser - A version of L<CGI::Carp>'s warningsToBrowser()
that displays the warnings loudly and boldly

=head1 RATIONALE

The author feels that it's important to expose warnings as early as possible in
the software development lifecycle, preferably by the same developer who created
them, as part of the "L<shift left|https://devopedia.org/shift-left>" effort.
"Shift left" basically means that the earlier in the SDLC that a problem can be
found, the cheaper it is to fix it.

=head1 SYNOPSIS

Put this at the top of your CGI script (the earlier the better, otherwise some
warnings might not get captured):

 use CGI::Carp::WarningsToBrowser;

Warnings will now be displayed at the very top of the web page, rather than
hidden in HTML comments like L<CGI::Carp>'s version.  This is intended mainly
for dev and test environments, not for prod, so it's a good idea to use L<if>:

 use if $is_dev, 'CGI::Carp::WarningsToBrowser';

=head1 HANDLING ERRORS

This module does not handle fatal errors, because L<CGI::Carp> does an adequate
job at that task.

=head1 COMPATIBILITY

Javascript must be enabled on the browser side, otherwise the warnings will
appear at the very bottom of the document. (the warnings are actually output in
an C<END { }> block, and three lines of Javascript are used to move them to the
top of the HTML page)

=head1 AUTHOR

Dee Newcum <deenewcum@cpan.org>

=head1 CONTRIBUTING

Please use L<Github's issue tracker|https://github.com/DeeNewcum/CGI-Carp-WarningsToBrowser/issues>
to file both bugs and feature requests. Contributions to the project in form of
Github's pull requests are welcome.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

use strict;
use warnings;

use HTML::Entities 3.00 ();

our @WARNINGS;

sub import {
    # if we're under the debugger, don't interfere with the warnings
    return if (exists $INC{'perl5db.pl'} && $DB::{single});
    # if we're under perl -c, don't interfere with the warnings
    return if ($^C);
    $main::SIG{__WARN__} = \&_handle_warn;
}


sub _handle_warn {
    push @WARNINGS, shift;
}


END {
    _print_warnings();
}


sub _print_warnings {
    return unless (@WARNINGS);
    # TODO: Hopefully we have output a text/html document. Is there a way to
    # detect this, and avoid printing on other kinds of documents (which could
    # corrupt file downloads, for example)
    #       see -- Tie::StdHandle or Tie::Handle::Base

    # TODO: What do we do about encoding? Is there a way to auto-detect what
    # kind of encoding was specified? Or should we just use
    # Unicode::Diacritic::Strip (to strip diacritics) and/or Text::Unidecode (to
    # output string-representations of non-ASCII Unicode characters)?
    #       see -- Tie::StdHandle or Tie::Handle::Base

    # In some situations, the HTTP response header won't have been output yet.
    # Try to auto-detect this.
    my $bytes_written = tell(STDOUT);
    if (!defined($bytes_written) || $bytes_written <= 0) {
        # The HTTP response header *probably* hasn't been output yet, so output
        # one of our own.
        # (though see https://perldoc.perl.org/functions/tell for caveats)

        # TODO: Do we want to output an encoding along with this?
        print STDOUT "Status: 500\n";
        print STDOUT "Content-type: text/html\n\n";
    }

    # print the warning-header
    print STDOUT <<'EOF';
    <div id="CGI::Carp::WarningsToBrowser" style="background-color:#faa; border:1px solid #000; padding:0.3em; margin-bottom:1em">
    <b>Perl warnings</b>
    <pre style="font-size:85%">
EOF
    foreach my $warning (@WARNINGS) {
        print STDOUT HTML::Entities::encode_entities($warning);
    }

    # print the warning-footer
    print STDOUT <<'EOF';
</pre></div>
<!-- move the warnings <div> to the very top of the document -->
<script type="text/javascript">
    var warningsToBrowser_pre = document.getElementById('CGI::Carp::WarningsToBrowser');
    if (warningsToBrowser_pre) {
        warningsToBrowser_pre.remove();
        document.body.prepend(warningsToBrowser_pre);
    }
</script>
EOF
}

1;
