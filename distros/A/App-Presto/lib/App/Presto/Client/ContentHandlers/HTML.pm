package App::Presto::Client::ContentHandlers::HTML;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::Client::ContentHandlers::HTML::VERSION = '0.010';
# ABSTRACT: Handles deserializing of HTML responses

use Moo;
my $HAS_HTML_FORMATTEXT_WITHLINKS;
BEGIN {
    eval 'use HTML::FormatText::WithLinks; $HAS_HTML_FORMATTEXT_WITHLINKS = 1;'
}

sub can_deserialize {
	my $self = shift;
	my $content_type = shift;
	return unless $HAS_HTML_FORMATTEXT_WITHLINKS;
	return $content_type =~ m{^text/html}i;
}

sub deserialize {
	my $self = shift;
	my $content = shift;
	my $text;
	eval { $text = HTML::FormatText::WithLinks->format_string($content) || 1 } or do {
		warn "Unable to parse HTML: $@";
	};
	return $text;
}

sub can_serialize { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::Client::ContentHandlers::HTML - Handles deserializing of HTML responses

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
