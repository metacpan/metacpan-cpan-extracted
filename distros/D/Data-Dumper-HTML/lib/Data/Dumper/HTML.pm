package Data::Dumper::HTML;

use strict;
use warnings;
use version;our $VERSION = qv('0.0.2');

use base 'Exporter';
our @EXPORT_OK = qw(DumperHTML dumper_html);

use Data::Dumper;
use Text::InHTML;

our ($shu_hr, $tabs);

sub Data::Dumper::dump_html {
    my $dd = shift;
    Text::InHTML::encode_perl( join("\n", $dd->Dump(@_)), $shu_hr, $tabs );
}

sub Data::Dumper::DumpHTML {
    goto &Data::Dumper::dump_html;
}

sub dumper_html {
    Text::InHTML::encode_perl( join("\n", Data::Dumper::Dumper(@_)), $shu_hr, $tabs );
}

sub DumperHTML {
    goto &dumper_html;
}

1;

__END__

=head1 NAME

Data::Dumper::HTML - Perl extension to dump data in HTML safe format with syntax highlighting

=head1 SYNOPSIS

  use Data::Dumper::HTML qw(dumper_html);

  print CGI::header();
  print qq{<div style="font-family: monospace">\n};
  
  print dumper_html(@whatever);

  print "\n<br /><br />\n";
    
  # or with the OO (but Data::Dumper objects act strange so I usually recommend the function route)
  my $dd = Data::Dumper->new(\@whatever);
  print $dd->DumpHTML();
  print "\n</div>\n";

=head1 DESCRIPTION

Adds DumpHTML() and dump_html() method to Data::Dumper objects

And has exportable DumperHTML() and dumper_html() functions

There are "all lowercase/underscore" versions since that is the style I prefer. I also included the "smooshed together mixed case" to correspond to L<Data::Dumper>'s Dumper() function and Dump() method.

It will be Perl syntax highlighted if possible, see L<Text::inHTML> for more details.

=head1 SEE ALSO

L<Data::Dumper>, L<Text::InHTML>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut