use Object::Pad ':experimental(:all)';

package App::md2html;

class App::md2html;

use utf8;
use v5.40;

our $VERSION = '0.01.1';

use List::Util 'first';
use Encode qw(encode decode);
use Text::Markdown::Hoedown;
use HTML::Entities qw(encode_entities decode_entities);
use Const::Fast;
use Syntax::Keyword::Dynamically;
use IPC::Nosh::Common;

const our $CHARSET_DEFAULT => 'UTF-8';
const our %HTMLOPT_DEFAULT => (
    doctype => '<!DOCTYPE html>',
    head    => [ '<head>', qq!<meta charset="$CHARSET_DEFAULT">!, '</head>' ]
);

field $embedded : param : accessor //=
  first { $_ } @ENV{ ( map { "MD2HTML_$_" } qw'EMBEDDED FRAGMENT' ) };

field $doctype : param : accessor { $HTMLOPT_DEFAULT{doctype} };

field $htmlopt : param : accessor = { %HTMLOPT_DEFAULT, doctype => $doctype };

#ield $encodeopt :param : accessor = { in => $App:: out => $encoding_in}

field $encoding_in  : param : accessor { $App::md2html::CHARSET_DEFAULT };
field $encoding_out : param : accessor { $encoding_in };

field $html_options { HOEDOWN_HTML_HARD_WRAP | HOEDOWN_HTML_ESCAPE }
field $extensions {
    HOEDOWN_EXT_TABLES | HOEDOWN_EXT_FENCED_CODE | HOEDOWN_EXT_FOOTNOTES |
      HOEDOWN_EXT_AUTOLINK | HOEDOWN_EXT_STRIKETHROUGH |
      HOEDOWN_EXT_UNDERLINE | HOEDOWN_EXT_HIGHLIGHT | HOEDOWN_EXT_QUOTE |
      HOEDOWN_EXT_SUPERSCRIPT | HOEDOWN_EXT_MATH;
}

ADJUST {
    dmsg $self
}

method to_html ( $mdstr, %opt ) {

    dynamically $embedded = $opt{embedded} if $opt{embedded};

    foreach my ( $k, $v ) (%opt) {
        dynamically $$htmlopt{$k} = $v if $v;
    }

    dmsg $self, \%opt, $htmlopt, $embedded;

    my $mdstr = decode( $encoding_in, $mdstr );

    my $out = markdown(
        encode( $encoding_out, $mdstr ),
        html_options => $html_options,
        extensions   => $extensions
    );

    dmsg $out;

    unless ($embedded) {
        my $head = join "\n", $htmlopt->{head}->@*;
        my $body = "<body>$out</body>";

        $out = join "\n", ( $$htmlopt{doctype}, $head, $body )
          unless $embedded;
    }

    $out;
}

method head ( $line_aref = undef, %opt ) {
    return $$htmlopt{head} unless $line_aref;

    if ( $line_aref eq 'ARRAY' ) {
        $$htmlopt{head}->@* = (@$line_aref);
    }
    else {
        dmsg $line_aref, \%opt, $self;
        error "'$line_aref' is not an ARRAY ref";
    }

    $$htmlopt{head};
}

method md2html : common ($mdstr, %opt) {
    my $self = $class->new(%opt);
    $self->to_html($mdstr);
}

__END__

=encoding utf-8

=head1 NAME

App::md2html - Blah blah blah

=head1 SYNOPSIS

  use App::md2html;

=head1 DESCRIPTION

App::md2html is

=head1 AUTHOR

Ian P Bradley E<lt>crabapp@hikki.techE<gt>

=head1 COPYRIGHT

Copyright 2026- Ian P Bradley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
