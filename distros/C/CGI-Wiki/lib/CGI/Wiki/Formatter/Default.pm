package CGI::Wiki::Formatter::Default;

use strict;

use vars qw( $VERSION @_links_found );
$VERSION = '0.02';

use CGI ":standard";
use Carp qw(croak carp);
use Text::WikiFormat as => 'wikiformat';
use HTML::PullParser;

=head1 NAME

CGI::Wiki::Formatter::Default - A formatter for CGI::Wiki.

=head1 DESCRIPTION

A formatter backend for L<CGI::Wiki>.

=head1 SYNOPSIS

  my $store     = CGI::Wiki::Store::SQLite->new( ... );
  # See below for parameter details.
  my $formatter = CGI::Wiki::Formatter::Default->new( %config );
  my $wiki      = CGI::Wiki->new( store     => $store,
                                  formatter => $formatter );

=head1 METHODS

=over 4

=item B<new>

  my $formatter = CGI::Wiki::Formatter::Default->new(
                 extended_links  => 0,
                 implicit_links  => 1,
                 allowed_tags    => [qw(b i)],  # defaults to none
                 macros          => {},
	         node_prefix     => 'wiki.cgi?node=' );

Parameters will default to the values shown above (apart from
C<allowed_tags>, which defaults to allowing no tags).

=over 4

=item * macros - be aware that macros are processed I<after> filtering
out disallowed HTML tags.  Currently macros are just strings, maybe later
we can add in subs if we think it might be useful.

=back

Macro example:

  macros => { qr/(^|\b)\@SEARCHBOX(\b|$)/ =>
 	        qq(<form action="wiki.cgi" method="get">
                   <input type="hidden" name="action" value="search">
                   <input type="text" size="20" name="terms">
                   <input type="submit"></form>) }

=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(@args) or return undef;
    return $self;
}

sub _init {
    my ($self, %args) = @_;

    # Store the parameters or their defaults.
    my %defs = ( extended_links  => 0,
	         implicit_links  => 1,
		 allowed_tags    => [],
		 macros          => {},
	         node_prefix     => 'wiki.cgi?node=',
	       );

    my %collated = (%defs, %args);
    foreach my $k (keys %defs) {
        $self->{"_".$k} = $collated{$k};
    }

    return $self;
}

=item B<format>

  my $html = $formatter->format( $content );

Escapes any tags which weren't specified as allowed on creation, then
interpolates any macros, then calls Text::WikiFormat::format (with the
config set up when B<new> was called) to translate the raw Wiki
language supplied into HTML.

=cut

sub format {
    my ($self, $raw) = @_;
    my $safe = "";

    my %allowed = map {lc($_) => 1, "/".lc($_) => 1} @{$self->{_allowed_tags}};

    if (scalar keys %allowed) {
        # If we are allowing some HTML, parse and get rid of the nasties.
	my $parser = HTML::PullParser->new(doc   => $raw,
					   start => '"TAG", tag, text',
					   end   => '"TAG", tag, text',
					   text  => '"TEXT", tag, text');
	while (my $token = $parser->get_token) {
            my ($flag, $tag, $text) = @$token;
	    if ($flag eq "TAG" and !defined $allowed{lc($tag)}) {
	        $safe .= CGI::escapeHTML($text);
	    } else {
                $safe .= $text;
            }
        }
    } else {
        # Else just escape everything.
        $safe = CGI::escapeHTML($raw);
    }

    # Now process any macros.
    my %macros = %{$self->{_macros}};
    foreach my $regexp (keys %macros) {
        $safe =~ s/$regexp/$macros{$regexp}/g;
    }

    return wikiformat($safe, {},
		      { extended       => $self->{_extended_links},
			prefix         => $self->{_node_prefix},
			implicit_links => $self->{_implicit_links} } );
}

=item B<find_internal_links>

  my @links_to = $formatter->find_internal_links( $content );

Returns a list of all nodes that the supplied content links to.
(Obviously this is dependent on object properties such as
C<extended_links> etc.)

=cut

sub find_internal_links {
    my ($self, $raw) = @_;

    @_links_found = ();

    my $foo = wikiformat($raw,
                      { link => sub {
                            my ($link, $opts) = @_;
                            $opts ||= {};
			    my $title;
			    ($link, $title) = split(/\|/, $link, 2)
			      if $opts->{extended};
			    push @CGI::Wiki::Formatter::Default::_links_found,
                              $link;
                            return ""; # don't care about output
                                     }
                      },
		      { extended       => $self->{_extended_links},
			prefix         => $self->{_node_prefix},
			implicit_links => $self->{_implicit_links} } );

    my @links = @_links_found;
    @_links_found = ();
    return @links;
}

=back

=head1 SEE ALSO

L<CGI::Wiki>

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2002-2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
