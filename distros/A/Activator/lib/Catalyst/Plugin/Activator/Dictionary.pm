package Catalyst::Plugin::Activator::Dictionary;
use strict;
use warnings;
use Activator::Dictionary;


=head1 NAME

Catalyst::Plugin::Activator::Dictionary : Provide a Catalyst context
L<Activator::Dictionary> C<lookup()> function, and template lookup magic.

=head1 SYNOPSIS

  # in MyApp.pm
  use Catalyst qw/ Activator::Dictionary /;

  # Configure Activator::Dictionary

  # Later, in some controller:
  my $msg = $c->lookup( 'look_me_up' );

  # Even later, in some template:
  <p>%{look_me_up_too}</p>


=head1 DESCRIPTION

This Catalyst plugin provides a lookup subroutine and a template shortcut syntax for L<Activator::Dictionary>.

=head2 lookup

Gets the value for a key (using L<Activator::Dictionary> lookup() sub)
wherever you have access to the catalyst context object C<$c>.

Since L<Activator::Dictionary> provides different realms, we default this plugin to the web realm:

  # uses web realm
  $c->lookup('dict_key');

However, we can use any other realm we desire:

  $c->lookup('dict_key', 'error');
  $c->lookup('dict_key', 'other_realm');

=cut

sub lookup {
    my ( $c, $key, $realm ) = @_;
    $realm ||= 'web';
    my $dict = Activator::Dictionary->get_dict( $c->stash->{dict_lang} );
    return $dict->lookup( $key, $realm );
};


=head2 Automated lookups from templates

When using this plugin from templates, we provide a special syntax for
automated lookups.

During the finalize stage of the Catalyst execution stack, this plugin
does a regular expression replacement of C<%{}> formatted keys into
dictionary lookups from the C<web> realm.

Example:

In C</path/to/dictionary/en/web.dict>:

  nice_para  This is a nice paragraph.

In a template:

  <p>%{nice_para}</p>

Resulting HTML:

<p>This is a nice paragraph.</p>

=cut

sub finalize {
    my ($c) = @_;

    ## we have html output
    if( $c->res->status == 200 && $c->res->content_type =~ 'text/html' ) {
	my $dict = Activator::Dictionary->get_dict( $c->stash->{dict_lang} );
	my $body = $c->res->body();
	$body =~ s/\%\{([^\}]+)\}/$dict->lookup( $1, 'web' )/egi;
	$c->res->body( $body );
    }

    return $c->NEXT::finalize(@_);
}

=head1 SEE ALSO

L<Activator::Dictionary>, L<Catalyst>, L<Catalyst::Manual::Plugins>


=head1 AUTHOR

Karim A. Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License, or the Artistic License as specified in the Perl
README file.

=cut

1;
